-- Read-only deployment check. Run in the Supabase SQL Editor as project owner.
-- Does NOT dispatch the worker, change settings or delete users.
-- Secret values are never returned. Requires the cleanup migration to exist.
select jsonb_build_object(
  'settings', (select to_jsonb(s) from public.guest_cleanup_settings s),
  'cron_jobs', (select coalesce(jsonb_agg(jsonb_build_object(
    'jobid',jobid,'schedule',schedule,'active',active,
    'expected_command',command='select public.dispatch_guest_cleanup()'
  )), '[]'::jsonb) from cron.job where jobname='cleanup-guest-accounts'),
  'extensions', (select jsonb_agg(extname) from pg_extension
    where extname in ('pg_cron','pg_net','supabase_vault')),
  'vault', (select jsonb_build_object(
    'url_entries',count(*) filter(where name='guest_cleanup_project_url'),
    'secret_entries',count(*) filter(where name='guest_cleanup_secret'),
    'secret_length_ok',coalesce(bool_and(length(decrypted_secret)>=32)
      filter(where name='guest_cleanup_secret'),false)
  ) from vault.decrypted_secrets
    where name in ('guest_cleanup_project_url','guest_cleanup_secret')),
  'candidates', (select jsonb_build_object(
    'empty',count(*) filter(where category='empty'),
    'with_data',count(*) filter(where category='with_data')
  ) from public.preview_guest_cleanup()),
  'audit', (select jsonb_build_object(
    'deleted',count(*) filter(where deleted_at is not null),
    'pending',count(*) filter(where deleted_at is null),
    'failed',count(*) filter(where deleted_at is null and last_error is not null)
  ) from public.guest_cleanup_log),
  'recent_cron_runs', (select coalesce(jsonb_agg(to_jsonb(r)), '[]'::jsonb) from (
    select status,start_time,end_time,return_message from cron.job_run_details
    where jobid in (select jobid from cron.job where jobname='cleanup-guest-accounts')
    order by start_time desc limit 5
  ) r)
) as cleanup_check;
