begin;

-- Retired names are never reused. This makes retries (including two concurrent
-- cleanup workers) harmless even after the same photo is uploaded again.
create table public.bike_image_retirements (
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  retired_at timestamptz not null default now(),
  deleted_at timestamptz,
  primary key (user_id, name),
  check (name like user_id::text || '/%')
);
alter table public.bike_image_retirements enable row level security;
revoke all on public.bike_image_retirements from public, anon, authenticated;
grant all on public.bike_image_retirements to service_role;

create index bike_documents_image_reference
  on public.bike_documents(user_id, (payload->>'imagePath'));
create index bike_history_image_reference
  on public.bike_document_history(user_id, (payload->>'imagePath'));

create function public.guard_bike_image_reference()
returns trigger language plpgsql security definer set search_path = '' as $$
declare image text := new.payload->>'imagePath'; object_name text;
begin
  if image is null or image not like 'cloud:%' then return new; end if;
  object_name := substr(image, 7);
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(new.user_id::text, 816));
  if object_name not like new.user_id::text || '/%' then
    raise exception 'INVALID_IMAGE_OWNER' using errcode = '42501';
  end if;
  if exists(select 1 from public.bike_image_retirements
      where user_id = new.user_id and name = object_name) then
    raise exception 'IMAGE_RETIRED' using errcode = 'P0001';
  end if;
  if not exists(select 1 from storage.objects
      where bucket_id = 'bike-images' and name = object_name) then
    raise exception 'IMAGE_UPLOAD_REQUIRED' using errcode = 'P0001';
  end if;
  return new;
end;
$$;
revoke all on function public.guard_bike_image_reference() from public, anon, authenticated;
create trigger guard_bike_image_reference before insert or update on public.bike_documents
for each row execute function public.guard_bike_image_reference();

create function public.reject_retired_bike_image()
returns trigger language plpgsql security definer set search_path = '' as $$
declare uid uuid := split_part(new.name, '/', 1)::uuid;
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(uid::text, 816));
  if exists(select 1 from public.bike_image_retirements where user_id = uid and name = new.name) then
    raise exception 'IMAGE_RETIRED' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function public.reject_retired_bike_image() from public, anon, authenticated;
create trigger reject_retired_bike_image before insert or update on storage.objects
for each row when (new.bucket_id = 'bike-images') execute function public.reject_retired_bike_image();

-- Take the account lock before writing history, using the same lock order as
-- cleanup and account deletion. Keep the existing revision/conflict contract.
create or replace function public.save_bike_document(
  p_document_id text, p_expected_revision bigint, p_payload jsonb
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid(); current_row public.bike_documents;
begin
  if uid is null then raise exception 'Authentication required'; end if;
  if p_document_id is null or length(p_document_id) > 160 or
     not (p_document_id in ('library', 'order') or p_document_id like 'bike:%') then
    raise exception 'Invalid document id';
  end if;
  if p_expected_revision is null or p_expected_revision < 0 then raise exception 'Invalid revision'; end if;
  if pg_catalog.pg_column_size(p_payload) > 1048576 then raise exception 'Document exceeds 1 MB'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(uid::text, 816));
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(uid::text || p_document_id, 0));
  select * into current_row from public.bike_documents
    where user_id = uid and document_id = p_document_id for update;
  if found then
    if current_row.payload is not distinct from p_payload then return pg_catalog.to_jsonb(current_row); end if;
    if current_row.revision <> p_expected_revision then raise exception 'SYNC_CONFLICT' using errcode = 'P0001'; end if;
    insert into public.bike_document_history(user_id, document_id, revision, payload)
      values(uid, p_document_id, current_row.revision, current_row.payload);
    update public.bike_documents set payload = p_payload, revision = revision + 1, updated_at = now()
      where user_id = uid and document_id = p_document_id returning * into current_row;
    delete from public.bike_document_history h where h.user_id = uid and h.document_id = p_document_id
      and h.revision in (select revision from public.bike_document_history
        where user_id = uid and document_id = p_document_id order by revision desc offset 20);
  else
    if p_expected_revision <> 0 then raise exception 'SYNC_CONFLICT' using errcode = 'P0001'; end if;
    insert into public.bike_documents(user_id, document_id, payload)
      values(uid, p_document_id, p_payload) returning * into current_row;
  end if;
  return pg_catalog.to_jsonb(current_row);
end;
$$;
revoke all on function public.save_bike_document(text, bigint, jsonb) from public, anon;
grant execute on function public.save_bike_document(text, bigint, jsonb) to authenticated;

-- Called only by the verified Edge Function, never with a client-supplied UID.
create function public.claim_bike_image_cleanup(p_user_id uuid)
returns table(name text) language plpgsql security definer set search_path = '' as $$
declare deleted_images text[];
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text, 816));
  if exists(select 1 from public.account_deletions where user_id = p_user_id) then
    raise exception 'ACCOUNT_DELETION_PENDING';
  end if;
  -- Deleted bikes remain restorable as data, without retaining their photos.
  select array_agg(distinct substr(h.payload->>'imagePath', 7)) into deleted_images
    from public.bike_document_history h join public.bike_documents d
      on d.user_id = h.user_id and d.document_id = h.document_id
    where h.user_id = p_user_id and d.payload is null
      and h.payload->>'imagePath' like 'cloud:' || p_user_id::text || '/%';
  update public.bike_document_history h set payload = h.payload - 'imagePath'
    from public.bike_documents d where d.user_id = h.user_id and d.document_id = h.document_id
      and h.user_id = p_user_id and d.payload is null and h.payload->>'imagePath' like 'cloud:%';

  insert into public.bike_image_retirements(user_id, name)
    select p_user_id, o.name from storage.objects o
    where o.bucket_id = 'bike-images' and o.name like p_user_id::text || '/%'
      -- A grace period protects uploads not yet attached to a document.
      and (o.name = any(coalesce(deleted_images, '{}'::text[])) or o.created_at < now() - interval '1 hour')
      and not exists(select 1 from public.bike_documents d
        where d.user_id = p_user_id and d.payload->>'imagePath' = 'cloud:' || o.name)
      and not exists(select 1 from public.bike_document_history h
        where h.user_id = p_user_id and h.payload->>'imagePath' = 'cloud:' || o.name)
    on conflict do nothing;
  return query select r.name from public.bike_image_retirements r
    where r.user_id = p_user_id and r.deleted_at is null order by r.name limit 100;
end;
$$;
revoke all on function public.claim_bike_image_cleanup(uuid) from public, anon, authenticated;
grant execute on function public.claim_bike_image_cleanup(uuid) to service_role;

create function public.finish_bike_image_cleanup(p_user_id uuid, p_names text[])
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text, 816));
  if exists(select 1 from storage.objects o where o.bucket_id = 'bike-images' and o.name = any(p_names)) then
    raise exception 'IMAGE_DELETE_INCOMPLETE';
  end if;
  update public.bike_image_retirements set deleted_at = now()
    where user_id = p_user_id and name = any(p_names) and deleted_at is null;
end;
$$;
revoke all on function public.finish_bike_image_cleanup(uuid,text[]) from public, anon, authenticated;
grant execute on function public.finish_bike_image_cleanup(uuid,text[]) to service_role;
commit;
