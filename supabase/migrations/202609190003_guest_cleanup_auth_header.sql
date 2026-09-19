begin;
create or replace function public.dispatch_guest_cleanup()
returns bigint language plpgsql security definer set search_path = '' as $$
declare project_url text; secret text; anon_key text; request_id bigint;
begin
  if not exists(select 1 from public.guest_cleanup_settings where enabled) then return null; end if;
  select decrypted_secret into project_url from vault.decrypted_secrets where name='guest_cleanup_project_url';
  select decrypted_secret into secret from vault.decrypted_secrets where name='guest_cleanup_secret';
  select decrypted_secret into anon_key from vault.decrypted_secrets where name='guest_cleanup_anon_key';
  if project_url is null or secret is null or length(secret)<32 or anon_key is null then
    raise exception 'GUEST_CLEANUP_SECRETS_MISSING';
  end if;
  select net.http_post(url := rtrim(project_url,'/') || '/functions/v1/cleanup-guest-accounts',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'x-cleanup-secret',secret,
      'Authorization','Bearer ' || anon_key
    ),
    body := '{}'::jsonb, timeout_milliseconds := 180000) into request_id;
  return request_id;
end;
$$;
revoke all on function public.dispatch_guest_cleanup() from public, anon, authenticated;
commit;