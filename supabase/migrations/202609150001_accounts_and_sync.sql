-- Run once in the Supabase SQL Editor. No service/secret key belongs in the app.
begin;

create table if not exists public.bike_documents (
  user_id uuid not null references auth.users(id) on delete cascade,
  document_id text not null check (length(document_id) between 1 and 160),
  payload jsonb,
  revision bigint not null default 1,
  updated_at timestamptz not null default now(),
  primary key (user_id, document_id)
);
create table if not exists public.bike_document_history (
  user_id uuid not null references auth.users(id) on delete cascade,
  document_id text not null,
  revision bigint not null,
  payload jsonb,
  saved_at timestamptz not null default now(),
  primary key (user_id, document_id, revision)
);
alter table public.bike_documents enable row level security;
alter table public.bike_document_history enable row level security;
revoke all on public.bike_documents, public.bike_document_history from anon, authenticated;
grant select on public.bike_documents, public.bike_document_history to authenticated;
drop policy if exists own_documents on public.bike_documents;
create policy own_documents on public.bike_documents for select to authenticated
  using ((select auth.uid()) = user_id);
drop policy if exists own_history on public.bike_document_history;
create policy own_history on public.bike_document_history for select to authenticated
  using ((select auth.uid()) = user_id);

-- Compare-and-swap: stale devices cannot overwrite a newer revision.
-- A retry after a lost response returns the existing identical revision.
create or replace function public.save_bike_document(
  p_document_id text, p_expected_revision bigint, p_payload jsonb
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  current_row public.bike_documents;
begin
  if uid is null then raise exception 'Authentication required'; end if;
  if p_document_id is null or length(p_document_id) > 160 or
     not (p_document_id in ('library', 'order') or p_document_id like 'bike:%') then
    raise exception 'Invalid document id';
  end if;
  if p_expected_revision is null or p_expected_revision < 0 then
    raise exception 'Invalid revision';
  end if;
  if pg_catalog.pg_column_size(p_payload) > 1048576 then
    raise exception 'Document exceeds 1 MB';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(uid::text || p_document_id, 0));
  select * into current_row from public.bike_documents
    where user_id = uid and document_id = p_document_id for update;
  if found then
    if current_row.payload is not distinct from p_payload then
      return pg_catalog.to_jsonb(current_row);
    end if;
    if current_row.revision <> p_expected_revision then
      raise exception 'SYNC_CONFLICT' using errcode = 'P0001';
    end if;
    insert into public.bike_document_history(user_id, document_id, revision, payload)
      values(uid, p_document_id, current_row.revision, current_row.payload);
    update public.bike_documents set payload = p_payload,
      revision = revision + 1, updated_at = now()
      where user_id = uid and document_id = p_document_id returning * into current_row;
    -- Keep the 20 preceding versions of each document, including deletions.
    delete from public.bike_document_history h where h.user_id = uid
      and h.document_id = p_document_id and h.revision in (
        select revision from public.bike_document_history
        where user_id = uid and document_id = p_document_id
        order by revision desc offset 20
      );
  else
    if p_expected_revision <> 0 then
      raise exception 'SYNC_CONFLICT' using errcode = 'P0001';
    end if;
    insert into public.bike_documents(user_id, document_id, payload)
      values(uid, p_document_id, p_payload) returning * into current_row;
  end if;
  return pg_catalog.to_jsonb(current_row);
end;
$$;
revoke all on function public.save_bike_document(text, bigint, jsonb) from public, anon;
grant execute on function public.save_bike_document(text, bigint, jsonb) to authenticated;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('bike-images', 'bike-images', false, 5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif'])
on conflict (id) do nothing;
drop policy if exists own_bike_images_read on storage.objects;
create policy own_bike_images_read on storage.objects for select to authenticated
  using (bucket_id = 'bike-images' and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists own_bike_images_insert on storage.objects;
create policy own_bike_images_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'bike-images' and (storage.foldername(name))[1] = (select auth.uid())::text);
-- Images are immutable and retained for old revisions; no client overwrite/delete.
commit;
