-- Setup, preview, activation and recovery: docs/orphan-guest-cleanup.md.
begin;

create table public.guest_cleanup_settings (
  singleton boolean primary key default true check (singleton),
  enabled boolean not null default false,
  dry_run boolean not null default true,
  empty_after interval not null default interval '7 days' check (empty_after >= interval '7 days'),
  data_after interval not null default interval '90 days' check (data_after >= empty_after),
  batch_size integer not null default 20 check (batch_size between 1 and 100)
);
insert into public.guest_cleanup_settings default values;
-- No FK: the audit must survive deletion of auth.users.
create table public.guest_cleanup_log (
  user_id uuid primary key,
  category text not null,
  last_activity_at timestamptz not null,
  started_at timestamptz not null default now(),
  attempted_at timestamptz not null default now(),
  attempts integer not null default 1,
  deleted_at timestamptz,
  last_error text
);
alter table public.guest_cleanup_settings enable row level security;
alter table public.guest_cleanup_log enable row level security;
revoke all on public.guest_cleanup_settings, public.guest_cleanup_log from public, anon, authenticated;
grant select on public.guest_cleanup_settings to service_role;
grant select, update on public.guest_cleanup_log to service_role;

create function public.preview_guest_cleanup()
returns table(user_id uuid, category text, last_activity_at timestamptz, eligible_at timestamptz)
language sql security definer set search_path = '' as $$
  select u.id, case when d.has_data then 'with_data' else 'empty' end,
    a.last_activity, a.last_activity + case when d.has_data then c.data_after else c.empty_after end
  from auth.users u cross join public.guest_cleanup_settings c
  cross join lateral (select
    exists(select 1 from public.bike_documents where user_id=u.id) or
    exists(select 1 from public.bike_document_history where user_id=u.id) or
    exists(select 1 from storage.objects where bucket_id='bike-images' and name like u.id::text || '/%') as has_data
  ) d
  cross join lateral (select greatest(u.created_at, u.last_sign_in_at,
    (select max(updated_at) from auth.sessions where user_id=u.id),
    (select max(updated_at) from public.bike_documents where user_id=u.id),
    (select max(saved_at) from public.bike_document_history where user_id=u.id),
    (select max(created_at) from storage.objects where bucket_id='bike-images' and name like u.id::text || '/%')
  ) as last_activity) a
  where u.is_anonymous is true
    and not exists(select 1 from auth.identities where user_id=u.id and provider <> 'anonymous')
    and not exists(select 1 from public.guest_transfers where (source_id=u.id or target_id=u.id) and expires_at > now())
    and not exists(select 1 from public.account_deletions where user_id=u.id)
    and a.last_activity < now() - case when d.has_data then c.data_after else c.empty_after end;
$$;

-- Lock Auth first (as Auth UPDATE does), then the existing account write lock.
-- Recheck inside the lock; a preview is never authorization to delete.
create function public.claim_guest_cleanup(p_user_id uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
declare candidate record;
begin
  if not exists(select 1 from public.guest_cleanup_settings where enabled and not dry_run) then return false; end if;
  perform 1 from auth.users where id=p_user_id and is_anonymous is true for update;
  if not found then return false; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_user_id::text, 816));
  if exists(select 1 from auth.identities where user_id=p_user_id and provider <> 'anonymous') then return false; end if;
  -- Retry only accounts already claimed by this cleanup, never other deletions.
  if exists(select 1 from public.guest_cleanup_log where user_id=p_user_id and deleted_at is null)
     and exists(select 1 from public.account_deletions where user_id=p_user_id) then
    update public.guest_cleanup_log set attempts=attempts+1, attempted_at=now(), last_error=null where user_id=p_user_id;
    return true;
  end if;
  select * into candidate from public.preview_guest_cleanup() where user_id=p_user_id;
  if not found then return false; end if;
  perform public.begin_account_deletion(p_user_id);
  insert into public.guest_cleanup_log(user_id,category,last_activity_at)
    values(p_user_id,candidate.category,candidate.last_activity_at);
  return true;
end;
$$;

-- Protect identity linking even if an Auth release inserts the identity before
-- updating is_anonymous. Existing upgrade and document guards remain unchanged.
create function public.guard_guest_cleanup_identity()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform 1 from auth.users where id=new.user_id for update;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(new.user_id::text, 816));
  if exists(select 1 from public.guest_cleanup_log l join public.account_deletions d using(user_id)
    where l.user_id=new.user_id and l.deleted_at is null) then
    raise exception 'ACCOUNT_DELETION_PENDING';
  end if;
  return new;
end;
$$;
create trigger guard_guest_cleanup_identity before insert or update on auth.identities
for each row execute function public.guard_guest_cleanup_identity();

-- Atomic audit completion, including a worker crash after the Auth API succeeds.
create function public.record_guest_cleanup_deletion()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.guest_cleanup_log set deleted_at=now(), last_error=null where user_id=old.id;
  return old;
end;
$$;
create trigger record_guest_cleanup_deletion after delete on auth.users
for each row execute function public.record_guest_cleanup_deletion();

revoke all on function public.preview_guest_cleanup(), public.claim_guest_cleanup(uuid),
  public.guard_guest_cleanup_identity(), public.record_guest_cleanup_deletion() from public, anon, authenticated;
grant execute on function public.preview_guest_cleanup(), public.claim_guest_cleanup(uuid) to service_role;

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;
create function public.dispatch_guest_cleanup()
returns bigint language plpgsql security definer set search_path = '' as $$
declare project_url text; secret text; request_id bigint;
begin
  if not exists(select 1 from public.guest_cleanup_settings where enabled) then return null; end if;
  select decrypted_secret into project_url from vault.decrypted_secrets where name='guest_cleanup_project_url';
  select decrypted_secret into secret from vault.decrypted_secrets where name='guest_cleanup_secret';
  if project_url is null or secret is null or length(secret)<32 then raise exception 'GUEST_CLEANUP_SECRETS_MISSING'; end if;
  select net.http_post(url := rtrim(project_url,'/') || '/functions/v1/cleanup-guest-accounts',
    headers := jsonb_build_object('Content-Type','application/json','x-cleanup-secret',secret),
    body := '{}'::jsonb, timeout_milliseconds := 180000) into request_id;
  return request_id;
end;
$$;
revoke all on function public.dispatch_guest_cleanup() from public, anon, authenticated;
-- Sunday 03:15 UTC = 04:15 CET / 05:15 CEST. Disabled through settings initially.
select cron.schedule('cleanup-guest-accounts', '15 3 * * 0', 'select public.dispatch_guest_cleanup()');
commit;
