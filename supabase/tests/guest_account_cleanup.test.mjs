import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const { PGlite } = await import(process.env.PGLITE_MODULE ?? '../../.tmp/image-cleanup-tests/node_modules/@electric-sql/pglite/dist/index.js');
const id = (n) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;

async function fixture(t) {
  const db = new PGlite();
  t.after(() => db.close());
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema auth; create schema storage; create schema cron;
    create table auth.users(id uuid primary key, is_anonymous boolean default true,
      created_at timestamptz default now()-interval '100 days', last_sign_in_at timestamptz);
    create table auth.identities(user_id uuid references auth.users on delete cascade, provider text);
    create table auth.sessions(user_id uuid references auth.users on delete cascade, updated_at timestamptz);
    create function auth.uid() returns uuid language sql as $$ select null::uuid $$;
    create table storage.buckets(id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);
    create table storage.objects(bucket_id text, name text, created_at timestamptz default now());
    create function storage.foldername(text) returns text[] language sql as $$ select string_to_array($1,'/') $$;
    create table cron.job(name text, schedule text, command text);
    create function cron.schedule(text,text,text) returns bigint language sql as $$ insert into cron.job values($1,$2,$3) returning 1::bigint $$;
  `);
  for (const file of ['202609150001_accounts_and_sync.sql', '202609160001_account_deletion.sql',
    '202609170001_guest_transfer.sql', '202609180001_bike_image_cleanup.sql',
    '202609190001_history_retention.sql', '202609190002_guest_account_cleanup.sql']) {
    const sql = await readFile(new URL(`../migrations/${file}`, import.meta.url), 'utf8');
    await db.exec(sql.replace(/^create extension .*;$/gm, ''));
  }
  const add = async (n, days = 100) => db.query('insert into auth.users(id,created_at) values($1,now()-$2::interval)', [id(n), `${days} days`]);
  const preview = async () => (await db.query('select * from public.preview_guest_cleanup() order by user_id')).rows;
  const claim = async (n) => (await db.query('select public.claim_guest_cleanup($1) as claimed', [id(n)])).rows[0].claimed;
  return { db, add, preview, claim };
}

test('7/90 days, null sign-in fallback, documents/history/images and activity protection', async (t) => {
  const { db, add, preview } = await fixture(t);
  for (let n=1; n<=10; n++) await add(n, n === 2 ? 6 : n === 3 ? 89 : 100);
  await db.exec(`
    insert into public.bike_documents(user_id,document_id,payload,updated_at) values
      ('${id(3)}','library','{}',now()-interval '89 days'),
      ('${id(4)}','order',null,now()-interval '100 days'),
      ('${id(5)}','bike:recent','{}',now());
    insert into auth.identities values('${id(6)}','google');
    update auth.users set is_anonymous=false where id='${id(7)}';
    insert into auth.sessions values('${id(8)}',now());
    insert into public.guest_transfers(source_id,revisions) values('${id(9)}','{}');
    insert into storage.objects values('bike-images','${id(10)}/photo',now()-interval '100 days');
  `);
  assert.deepEqual((await preview()).map(r => [r.user_id,r.category]), [[id(1),'empty'],[id(4),'with_data'],[id(10),'with_data']]);
  await db.exec(`update auth.users set last_sign_in_at=now() where id='${id(1)}'`);
  assert.equal((await preview()).length, 2);
  assert.equal((await db.query("select schedule from cron.job where name='cleanup-guest-accounts'")).rows[0].schedule, '15 3 * * 0');
});

test('disabled/dry-run never claim; recheck, link guard, retries and durable atomic audit', async (t) => {
  const { db, add, claim, preview } = await fixture(t);
  await add(1); await add(2);
  assert.equal(await claim(1), false);
  await db.exec('update public.guest_cleanup_settings set enabled=true');
  assert.equal(await claim(1), false);
  await db.exec('update public.guest_cleanup_settings set dry_run=false');
  await preview();
  await db.exec(`insert into auth.identities values('${id(2)}','google')`);
  assert.equal(await claim(2), false);
  assert.equal(await claim(1), true);
  assert.equal(await claim(1), true);
  await assert.rejects(db.exec(`insert into auth.identities values('${id(1)}','google')`), /ACCOUNT_DELETION_PENDING/);
  await assert.rejects(db.exec(`update auth.users set is_anonymous=false where id='${id(1)}'`), /ACCOUNT_DELETION_PENDING/);
  assert.equal((await db.query('select attempts from public.guest_cleanup_log')).rows[0].attempts, 2);
  // Simulate the Auth API's final DELETE, not a production cleanup implementation.
  await db.exec(`delete from auth.users where id='${id(1)}'`);
  assert.ok((await db.query('select deleted_at from public.guest_cleanup_log')).rows[0].deleted_at);
  assert.equal((await db.query('select * from public.account_deletions')).rows.length, 0);
});

test('client roles cannot preview, claim, dispatch or read audit/settings', async (t) => {
  const { db } = await fixture(t);
  for (const role of ['anon','authenticated']) {
    await db.exec(`set role ${role}`);
    for (const sql of ['select * from public.guest_cleanup_log', 'select * from public.guest_cleanup_settings',
      'select public.preview_guest_cleanup()', `select public.claim_guest_cleanup('${id(1)}')`, 'select public.dispatch_guest_cleanup()']) {
      await assert.rejects(db.exec(sql), /permission denied/);
    }
    await db.exec('reset role');
  }
});
