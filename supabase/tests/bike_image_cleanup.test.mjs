import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

// Install the isolated test runtime as documented in docs/bike-image-cleanup.md.
const { PGlite } = await import(process.env.PGLITE_MODULE ?? '../../.tmp/image-cleanup-tests/node_modules/@electric-sql/pglite/dist/index.js');
const uid = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
const photo = `${uid}/${'a'.repeat(64)}`;

async function fixture(t) {
  const db = new PGlite();
  t.after(() => db.close());
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema auth; create schema storage;
    create table auth.users(id uuid primary key, is_anonymous boolean default false);
    create function auth.uid() returns uuid language sql as
      $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    create table storage.buckets(id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);
    create table storage.objects(id uuid primary key default gen_random_uuid(), bucket_id text, name text unique, created_at timestamptz default now());
    create function storage.foldername(text) returns text[] language sql as $$ select string_to_array($1, '/') $$;
    insert into auth.users(id) values ('${uid}'), ('${other}');
  `);
  for (const migration of ['202609150001_accounts_and_sync.sql', '202609160001_account_deletion.sql',
    '202609170001_guest_transfer.sql', '202609180001_bike_image_cleanup.sql']) {
    await db.exec(await readFile(new URL(`../migrations/${migration}`, import.meta.url), 'utf8'));
  }
  await db.query("select set_config('request.jwt.claim.sub', $1, false)", [uid]);
  const upload = (name = photo, old = false) => db.query(
    "insert into storage.objects(bucket_id,name,created_at) values ('bike-images',$1,now() - $2::interval)", [name, old ? '2 hours' : '0 hours']);
  const save = async (id, revision, image = photo) => (await db.query(
    'select public.save_bike_document($1,$2,$3::jsonb) as value',
    [`bike:${id}`, revision, image === null ? null : JSON.stringify({ id, imagePath: `cloud:${image}` })])).rows[0].value;
  const claim = async () => (await db.query('select * from public.claim_bike_image_cleanup($1)', [uid])).rows.map((row) => row.name);
  return { db, upload, save, claim };
}

test('history expires across accounts without deleting current bikes; RLS enforces the boundary', async (t) => {
  const { db, save } = await fixture(t);
  await save('bike', 0, null);
  await db.exec(`
    insert into public.bike_document_history(user_id, document_id, revision, payload, saved_at) values
      ('${uid}', 'bike:old', 1, '{}', now() - interval '8 days'),
      ('${other}', 'bike:old', 1, '{}', now() - interval '8 days'),
      ('${uid}', 'bike:recent', 1, '{}', now() - interval '6 days');
    create schema cron;
    create table cron.job(jobname text, schedule text, command text);
    create function cron.schedule(text,text,text) returns bigint language sql as $$
      insert into cron.job values ($1,$2,$3) returning 1::bigint;
    $$;
  `);
  // PGlite has no scheduler extension. Execute the real migration with only
  // extension installation omitted and capture its scheduling request above.
  const migration = await readFile(new URL('../migrations/202609190001_history_retention.sql', import.meta.url), 'utf8');
  await db.exec(migration.replace('create extension if not exists pg_cron with schema pg_catalog;', ''));
  assert.equal((await db.query('select * from public.bike_document_history')).rows.length, 1);
  assert.equal((await db.query('select * from public.bike_documents')).rows.length, 1);
  assert.equal((await db.query('select schedule from cron.job')).rows[0].schedule, '* * * * *');
  await db.exec(`insert into public.bike_document_history(user_id,document_id,revision,payload,saved_at)
    values ('${uid}','bike:expired',1,'{}',now() - interval '7 days'),
           ('${other}','bike:private',1,'{}',now());
    set role authenticated;`);
  assert.deepEqual((await db.query('select document_id from public.bike_document_history')).rows,
    [{ document_id: 'bike:recent' }]);
  await assert.rejects(db.query('select public.purge_expired_bike_history()'), /permission denied/);
  await db.exec('reset role; select public.purge_expired_bike_history();');
  assert.equal((await db.query('select * from public.bike_document_history')).rows.length, 2);
});

test('deletion releases its photos but preserves setup history without image references', async (t) => {
  const { db, upload, save, claim } = await fixture(t);
  await upload(); await save('bike', 0); await save('bike', 1, null);
  assert.deepEqual(await claim(), [photo]);
  const history = (await db.query('select payload from public.bike_document_history')).rows;
  assert.equal(history[0].payload.id, 'bike');
  assert.equal(history[0].payload.imagePath, undefined);
  // Claiming does not pretend to remove physical files or their metadata.
  assert.equal((await db.query('select * from storage.objects')).rows.length, 1);
  await assert.rejects(db.query('select public.finish_bike_image_cleanup($1,$2)', [uid, [photo]]), /IMAGE_DELETE_INCOMPLETE/);
  // Simulate Storage API completion, then acknowledge it.
  await db.query('delete from storage.objects where name=$1', [photo]);
  await db.query('select public.finish_bike_image_cleanup($1,$2)', [uid, [photo]]);
  assert.deepEqual(await claim(), []);
  await assert.rejects(upload(), /IMAGE_RETIRED/);
  await assert.rejects(save('restored', 0), /IMAGE_RETIRED/);
  const fresh = `${photo}-new-copy`;
  await upload(fresh); await save('restored', 0, fresh);
  assert.deepEqual(await claim(), []);
});

test('shared active photos and photos in another live bikes history remain', async (t) => {
  const { upload, save, claim } = await fixture(t);
  await upload(); await save('a', 0); await save('b', 0);
  await save('a', 1, null);
  assert.deepEqual(await claim(), []);
  const replacement = `${photo}-replacement`;
  await upload(replacement); await save('b', 1, replacement);
  assert.deepEqual(await claim(), []);
  await save('b', 2, null);
  assert.deepEqual((await claim()).sort(), [photo, replacement].sort());
});

test('old unreferenced uploads are collected; fresh uploads and foreign accounts remain', async (t) => {
  const { upload, claim } = await fixture(t);
  const recent = `${photo}-recent`;
  const foreign = `${other}/foreign`;
  await upload(photo, true); await upload(recent); await upload(foreign, true);
  assert.deepEqual(await claim(), [photo]);
  // Lost response and parallel workers receive the same immutable job safely.
  assert.deepEqual(await claim(), [photo]);
});

test('document writes cannot reference missing or foreign photos and stale revisions fail', async (t) => {
  const { upload, save } = await fixture(t);
  await assert.rejects(save('a', 0), /IMAGE_UPLOAD_REQUIRED/);
  await assert.rejects(save('a', 0, `${other}/photo`), /INVALID_IMAGE_OWNER/);
  await upload(); await save('a', 0);
  await assert.rejects(save('a', 0, null), /SYNC_CONFLICT/);
});

test('cleanup RPCs and job records are unavailable to ordinary clients', async (t) => {
  const { db } = await fixture(t);
  await db.exec('set role authenticated');
  await assert.rejects(db.query('select * from public.claim_bike_image_cleanup($1)', [uid]), /permission denied/);
  await assert.rejects(db.query('select public.finish_bike_image_cleanup($1,$2)', [uid, [photo]]), /permission denied/);
  await assert.rejects(db.query('select * from public.bike_image_retirements'), /permission denied/);
});
