begin;
create table public.account_deletions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  started_at timestamptz not null default now()
);
alter table public.account_deletions enable row level security;
revoke all on public.account_deletions from public, anon, authenticated;
grant all on public.account_deletions to service_role;

create function public.begin_account_deletion(p_user_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text, 816));
  insert into public.account_deletions(user_id) values(p_user_id) on conflict do nothing;
end;
$$;
revoke all on function public.begin_account_deletion(uuid) from public, anon, authenticated;
grant execute on function public.begin_account_deletion(uuid) to service_role;

create function public.account_deletion_images(p_user_id uuid)
returns table(name text) language sql security definer set search_path = '' as $$
  select name from storage.objects where bucket_id = 'bike-images'
  and name like p_user_id::text || '/%' order by name limit 100;
$$;
revoke all on function public.account_deletion_images(uuid) from public, anon, authenticated;
grant execute on function public.account_deletion_images(uuid) to service_role;

-- Serialize new writes against the deletion marker, including other devices.
create function public.reject_deleted_account_write()
returns trigger language plpgsql security definer set search_path = '' as $$
declare uid uuid := auth.uid();
begin
  if uid is null then return new; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(uid::text, 816));
  if not exists(select 1 from auth.users where id = uid) or
     exists(select 1 from public.account_deletions where user_id = uid) then
    raise exception 'ACCOUNT_DELETION_PENDING' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function public.reject_deleted_account_write() from public, anon, authenticated;
create trigger reject_deleted_document_write before insert or update on public.bike_documents
for each row execute function public.reject_deleted_account_write();
create trigger reject_deleted_image_write before insert or update on storage.objects
for each row when (new.bucket_id = 'bike-images') execute function public.reject_deleted_account_write();
commit;
