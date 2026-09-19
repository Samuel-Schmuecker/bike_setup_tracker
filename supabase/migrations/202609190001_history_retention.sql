begin;

create index if not exists bike_document_history_saved_at
  on public.bike_document_history(saved_at);

-- Expired versions are inaccessible immediately, even between cleanup runs.
drop policy if exists own_history on public.bike_document_history;
create policy own_history on public.bike_document_history
  for select to authenticated using (
    (select auth.uid()) = user_id
    and saved_at > now() - interval '7 days'
  );

create or replace function public.purge_expired_bike_history()
returns void language sql security definer set search_path = '' as $$
  delete from public.bike_document_history
  where saved_at <= now() - interval '7 days';
$$;
revoke all on function public.purge_expired_bike_history()
  from public, anon, authenticated;

-- Remove existing expired data when deploying, then run without app activity.
select public.purge_expired_bike_history();
create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('purge-expired-bike-history', '* * * * *',
  'select public.purge_expired_bike_history()');

commit;
