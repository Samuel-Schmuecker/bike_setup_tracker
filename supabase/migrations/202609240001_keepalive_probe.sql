-- Run once in the target project's Supabase SQL Editor before running the workflow.
begin;

create table if not exists public.keepalive_probe (
  id integer primary key check (id = 1)
);

insert into public.keepalive_probe (id) values (1)
on conflict (id) do nothing;

alter table public.keepalive_probe enable row level security;
revoke all on public.keepalive_probe from anon, authenticated;
grant select on public.keepalive_probe to anon, authenticated;

drop policy if exists read_keepalive_probe on public.keepalive_probe;
create policy read_keepalive_probe on public.keepalive_probe
  for select to anon, authenticated using (true);

commit;
