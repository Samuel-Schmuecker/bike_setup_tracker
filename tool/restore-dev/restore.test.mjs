import test from 'node:test';
import assert from 'node:assert/strict';
import {decodeCopy, parseDump, validateKey, replaceRows, affectedTables, databaseTLS, DEV} from './restore.mjs';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {X509Certificate} from 'node:crypto';
import {rootCertificates} from 'node:tls';
import {PGlite} from '@electric-sql/pglite';

test('COPY preserves null, literal backslashes, JSON and embedded separators', () => {
  assert.equal(decodeCopy('\\N'), null);
  assert.equal(decodeCopy('\\\\N'), '\\N');
  assert.equal(decodeCopy('a\\tb\\nc\\rd\\\\e'), 'a\tb\nc\rd\\e');
  assert.equal(decodeCopy('\\101\\x42'), 'AB');
  const source = 'COPY "public"."bike_documents" ("id", "payload") FROM stdin;\n1\t{"text":"line\\\\nnext", "path":"C:\\\\temp"}\n\\.\n';
  const row = parseDump(source).get('public.bike_documents').rows[0];
  assert.equal(JSON.parse(row.payload).text, 'line\nnext');
});

test('malformed or truncated COPY blocks fail closed', () => {
  for (const source of [
    'COPY "public"."x" ("a") FROM stdin;\n1\n',
    'COPY "public"."x" ("a", "b") FROM stdin;\n1\n\\.\n',
    'COPY public.x (a) FROM stdin;\n1\n\\.\n',
  ]) assert.throws(() => parseDump(source));
});

test('Main keys and non-admin keys are refused before connecting', () => {
  const key = claims => `header.${Buffer.from(JSON.stringify(claims)).toString('base64url')}.signature`;
  assert.throws(() => validateKey(key({ref:'iwmrlwouyfpmizzirmby',role:'service_role'})));
  assert.throws(() => validateKey(key({ref:DEV,role:'anon'})));
  assert.throws(() => validateKey('sb_secret_not_a_project_bound_jwt'));
  assert.doesNotThrow(() => validateKey(key({ref:DEV,role:'service_role'})));
});

test('CA loading accepts PEM and DER while retaining certificate verification', () => {
  const folder = fs.mkdtempSync(path.join(os.tmpdir(), 'restore-ca-test-'));
  try {
    const cert = rootCertificates.map(pem => new X509Certificate(pem)).find(c =>
      c.ca && Date.parse(c.validFrom) < Date.now() && Date.parse(c.validTo) > Date.now());
    assert.ok(cert);
    for (const [name, bytes] of [['root.pem',cert.toString()],['root.cer',cert.raw]]) {
      const file = path.join(folder,name);
      fs.writeFileSync(file,bytes);
      const config = databaseTLS(file);
      assert.equal(config.rejectUnauthorized,true);
      assert.equal(new X509Certificate(config.ca).fingerprint256,cert.fingerprint256);
    }
    assert.deepEqual(databaseTLS(),{rejectUnauthorized:true});
    const bad = path.join(folder,'invalid.cer');
    fs.writeFileSync(bad,'not a certificate');
    assert.throws(() => databaseTLS(bad));
  } finally {
    for (const file of fs.readdirSync(folder)) fs.unlinkSync(path.join(folder,file));
    fs.rmdirSync(folder);
  }
});

async function fixture() {
  const db = new PGlite();
  await db.exec(`CREATE SCHEMA auth; CREATE SCHEMA cron;
    CREATE TABLE cron.job (jobid bigint PRIMARY KEY, active boolean);
    INSERT INTO cron.job VALUES (1, true);
    -- Model the extension's permission boundary: read table, mutate via API.
    CREATE FUNCTION cron.alter_job(job_id bigint, active boolean) RETURNS void
      LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog AS
      'UPDATE cron.job SET active=$2 WHERE jobid=$1';
    CREATE TABLE auth.users (id text PRIMARY KEY);
    CREATE TABLE auth.identities (user_id text REFERENCES auth.users(id));
    CREATE TABLE auth.sessions (user_id text REFERENCES auth.users(id));
    CREATE TABLE public.bike_documents (user_id text REFERENCES auth.users(id), payload jsonb);
    CREATE TABLE public.guest_cleanup_settings (enabled boolean, dry_run boolean);
    INSERT INTO auth.users VALUES ('old'); INSERT INTO auth.sessions VALUES ('old');`);
  const tables = new Map([
    ['auth.users', {columns:['id'], rows:[{id:'new'}]}],
    ['auth.identities', {columns:['user_id'], rows:[{user_id:'new'}]}],
    ['public.bike_documents', {columns:['user_id','payload'], rows:[{user_id:'new',payload:'{"text":"O\'Brien; DROP TABLE auth.users; --"}'}]}],
    ['public.guest_cleanup_settings', {columns:['enabled','dry_run'], rows:[{enabled:'t',dry_run:'f'}]}],
  ]);
  for (const t of ['account_deletions','bike_document_history','bike_image_retirements','guest_cleanup_log','guest_transfers']) {
    await db.exec(`CREATE TABLE public.${t} (id text)`);
    tables.set(`public.${t}`,{columns:['id'],rows:[]});
  }
  const affected = new Set([...tables.keys(),'auth.sessions']);
  return {db,tables,affected};
}

test('transaction replaces users, preserves payloads and disables cleanup', async () => {
  const {db,tables,affected} = await fixture();
  try {
    await db.exec('BEGIN');
    await replaceRows(db,tables,affected);
    await db.exec('COMMIT');
    assert.deepEqual((await db.query('SELECT id FROM auth.users')).rows,[{id:'new'}]);
    assert.equal((await db.query('SELECT * FROM auth.sessions')).rows.length,0);
    assert.equal((await db.query('SELECT payload FROM public.bike_documents')).rows[0].payload.text,"O'Brien; DROP TABLE auth.users; --");
    assert.deepEqual((await db.query('SELECT * FROM public.guest_cleanup_settings')).rows,[{enabled:false,dry_run:true}]);
    assert.equal((await db.query('SELECT active FROM cron.job')).rows[0].active,false);
  } finally { await db.close(); }
});

test('failed import rolls back old users and cron state', async () => {
  const {db,tables,affected} = await fixture();
  try {
    tables.get('auth.users').rows.push({id:'new'});
    await db.exec('BEGIN');
    await assert.rejects(replaceRows(db,tables,affected));
    await db.exec('ROLLBACK');
    assert.deepEqual((await db.query('SELECT id FROM auth.users')).rows,[{id:'old'}]);
    assert.equal((await db.query('SELECT active FROM cron.job')).rows[0].active,true);
  } finally { await db.close(); }
});

test('restore works when cron table updates are forbidden but alter_job is allowed', async () => {
  const {db,tables,affected} = await fixture();
  try {
    await db.exec(`CREATE ROLE restore_user;
      GRANT USAGE ON SCHEMA auth, public, cron TO restore_user;
      GRANT ALL ON ALL TABLES IN SCHEMA auth, public TO restore_user;
      GRANT SELECT ON cron.job TO restore_user;
      REVOKE ALL ON FUNCTION cron.alter_job(bigint, boolean) FROM PUBLIC;
      GRANT EXECUTE ON FUNCTION cron.alter_job(bigint, boolean) TO restore_user;
      SET ROLE restore_user;`);
    await assert.rejects(db.query('UPDATE cron.job SET active=false'), {code:'42501'});
    await db.exec('BEGIN');
    await replaceRows(db,tables,affected);
    await db.exec('COMMIT');
    assert.equal((await db.query('SELECT active FROM cron.job')).rows[0].active,false);
    assert.deepEqual((await db.query('SELECT id FROM auth.users')).rows,[{id:'new'}]);
  } finally { await db.close(); }
});

test('unknown dependency prevents truncate without erasing any table', async () => {
  const {db,tables,affected} = await fixture();
  try {
    await db.exec("CREATE TABLE public.unexpected (user_id text REFERENCES auth.users(id)); INSERT INTO public.unexpected VALUES ('old')");
    await db.exec('BEGIN');
    await assert.rejects(replaceRows(db,tables,affected));
    await db.exec('ROLLBACK');
    assert.deepEqual((await db.query('SELECT * FROM public.unexpected')).rows,[{user_id:'old'}]);
  } finally { await db.close(); }
});

test('dependency discovery includes tables referencing independent auth flows recursively', async () => {
  const {db,tables,affected} = await fixture();
  try {
    await db.exec(`CREATE TABLE auth.flow_state (id text PRIMARY KEY);
      CREATE TABLE auth.saml_relay_states (id text PRIMARY KEY, flow_state_id text REFERENCES auth.flow_state(id));
      CREATE TABLE auth.flow_details (relay_id text REFERENCES auth.saml_relay_states(id));
      INSERT INTO auth.flow_state VALUES ('old-flow');
      INSERT INTO auth.saml_relay_states VALUES ('old-relay','old-flow');
      INSERT INTO auth.flow_details VALUES ('old-relay');`);
    const seeds = [...affected, 'auth.flow_state'];
    const allowed = new Set([...seeds,'auth.saml_relay_states','auth.flow_details']);
    // Reproduce the old failure: flow_state was added after walking users' FKs.
    await db.exec('BEGIN');
    await assert.rejects(replaceRows(db,tables,new Set(seeds)), {code:'0A000'});
    await db.exec('ROLLBACK');
    const complete = await affectedTables(db,seeds,allowed);
    assert.ok(complete.has('auth.saml_relay_states'));
    assert.ok(complete.has('auth.flow_details'));
    await db.exec('BEGIN');
    await replaceRows(db,tables,complete);
    await db.exec('COMMIT');
    assert.deepEqual((await db.query('SELECT id FROM auth.users')).rows,[{id:'new'}]);
    assert.equal((await db.query('SELECT * FROM auth.flow_details')).rows.length,0);
  } finally { await db.close(); }
});

test('dependency discovery refuses unknown tables before any data is changed', async () => {
  const {db,affected} = await fixture();
  try {
    await db.exec('CREATE TABLE public.unexpected (user_id text REFERENCES auth.users(id))');
    await assert.rejects(affectedTables(db,affected,affected), /Unerwartete abhaengige Tabelle: public.unexpected/);
    assert.deepEqual((await db.query('SELECT id FROM auth.users')).rows,[{id:'old'}]);
    assert.equal((await db.query('SELECT active FROM cron.job')).rows[0].active,true);
  } finally { await db.close(); }
});
