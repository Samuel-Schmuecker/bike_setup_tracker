# Cloud history retention

Apply `supabase/migrations/202609190001_history_retention.sql` after the existing
migrations using the Supabase SQL Editor or the normal migration deployment.
The migration enables pg_cron and installs a named job that runs every minute.
Reference: https://supabase.com/docs/guides/cron

Historical document versions expire seven days after archival (`saved_at`).
Row-level security makes them inaccessible at expiry; the scheduled job physically
deletes them on its next run (normally within one minute). Existing expired rows
are deleted during deployment. The existing cap of 20 versions per document still
applies. Current bikes, setups and the field library do not expire. This policy
does not change local backups, exported files or infrastructure backups.

The UI hides internal ordering records and shows bike names, local dates and a
restore action. The field library remains restorable. Its query also filters out
expired rows and deletion markers before applying the result limit.

Verify deployment:

```sql
select jobname, schedule, active from cron.job
where jobname = 'purge-expired-bike-history';
select count(*) from public.bike_document_history
where saved_at <= now() - interval '7 days';
```

Monitor failures in `cron.job_run_details`. Photo objects use the existing image
cleanup flow; this migration deletes historical database records, not Storage
objects. Physical deletion timing depends on the scheduler being operational.
