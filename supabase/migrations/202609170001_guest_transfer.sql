begin;
create table public.guest_transfers (
  ticket uuid primary key default gen_random_uuid(),
  source_id uuid not null,
  target_id uuid,
  revisions jsonb not null,
  expires_at timestamptz not null default now() + interval '7 days'
);
alter table public.guest_transfers enable row level security;
revoke all on public.guest_transfers from public, anon, authenticated;
grant all on public.guest_transfers to service_role;

create function public.prepare_guest_transfer(p_source uuid, p_revisions jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare current_revisions jsonb; result uuid;
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_source::text, 816));
  if not exists(select 1 from auth.users where id=p_source and is_anonymous=true) then
    raise exception 'GUEST_REQUIRED';
  end if;
  select coalesce(jsonb_object_agg(document_id, revision), '{}'::jsonb)
    into current_revisions from public.bike_documents where user_id=p_source;
  if current_revisions <> p_revisions then raise exception 'GUEST_CHANGED'; end if;
  delete from public.guest_transfers where expires_at < now();
  insert into public.guest_transfers(source_id, revisions) values(p_source, current_revisions)
    returning ticket into result;
  return result;
end;
$$;
revoke all on function public.prepare_guest_transfer(uuid,jsonb) from public, anon, authenticated;
grant execute on function public.prepare_guest_transfer(uuid,jsonb) to service_role;

create function public.claim_guest_transfer(p_ticket uuid, p_target uuid)
returns uuid language plpgsql security definer set search_path = '' as $$
declare transfer public.guest_transfers; current_revisions jsonb;
begin
  select * into transfer from public.guest_transfers where ticket=p_ticket for update;
  if not found or transfer.expires_at < now() then raise exception 'TRANSFER_EXPIRED'; end if;
  if transfer.target_id is not null and transfer.target_id <> p_target then raise exception 'TARGET_MISMATCH'; end if;
  if transfer.source_id = p_target then raise exception 'SAME_ACCOUNT'; end if;
  if not exists(select 1 from auth.users where id=p_target and is_anonymous=false) then raise exception 'LOGIN_REQUIRED'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(transfer.source_id::text, 816));
  -- A receipt survives source deletion so a lost response can be retried.
  if exists(select 1 from auth.users where id=transfer.source_id) then
    if not exists(select 1 from auth.users where id=transfer.source_id and is_anonymous=true) then
      raise exception 'SOURCE_NO_LONGER_GUEST';
    end if;
    select coalesce(jsonb_object_agg(document_id, revision), '{}'::jsonb)
      into current_revisions from public.bike_documents where user_id=transfer.source_id;
    if current_revisions <> transfer.revisions then raise exception 'GUEST_CHANGED'; end if;
    perform public.begin_account_deletion(transfer.source_id);
  end if;
  update public.guest_transfers set target_id=p_target where ticket=p_ticket;
  return transfer.source_id;
end;
$$;
revoke all on function public.claim_guest_transfer(uuid,uuid) from public, anon, authenticated;
grant execute on function public.claim_guest_transfer(uuid,uuid) to service_role;

-- Serialize a concurrent Google upgrade against deletion of the guest account.
create function public.guard_guest_upgrade()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(old.id::text, 816));
  if exists(select 1 from public.account_deletions where user_id=old.id) then
    raise exception 'ACCOUNT_DELETION_PENDING';
  end if;
  return new;
end;
$$;
revoke all on function public.guard_guest_upgrade() from public, anon, authenticated;
create trigger guard_guest_upgrade before update of is_anonymous on auth.users
for each row when (old.is_anonymous=true and new.is_anonymous=false)
execute function public.guard_guest_upgrade();
commit;
