// Data recovery into the existing Dev schema, NOT a full project clone.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';

export const DEV = 'dcrkfiooddkbzljibomo';
const appTables = ['account_deletions', 'bike_document_history', 'bike_documents',
  'bike_image_retirements', 'guest_cleanup_log', 'guest_cleanup_settings', 'guest_transfers'];
const restored = ['auth.users', 'auth.identities', ...appTables.filter(x => x !== 'guest_transfers').map(x => `public.${x}`)];
const quote = value => '"' + value.replaceAll('"', '""') + '"';
const tableSQL = name => name.split('.').map(quote).join('.');
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');

export function decodeCopy(value) {
  if (value === '\\N') return null;
  return value.replace(/\\([0-7]{1,3}|x[0-9a-fA-F]{1,2}|[\s\S])/g, (_, c) => {
    if (/^[0-7]/.test(c)) return String.fromCharCode(parseInt(c, 8));
    if (c.startsWith('x')) return String.fromCharCode(parseInt(c.slice(1), 16));
    return ({b:'\b', f:'\f', n:'\n', r:'\r', t:'\t', v:'\v', '\\':'\\'})[c] ?? c;
  });
}

export function parseDump(text) {
  const tables = new Map();
  const lines = text.replaceAll('\r\n', '\n').split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i].startsWith('COPY ')) continue;
    const m = /^COPY "(\w+)"\."(\w+)" \((.+)\) FROM stdin;$/.exec(lines[i]);
    if (!m) throw Error('Unbekanntes COPY-Format.');
    const columns = m[3].split(', ').map(c => {
      if (!/^"\w+"$/.test(c)) throw Error('Unbekannte Spalte.');
      return c.slice(1,-1);
    });
    const rows = [];
    while (++i < lines.length && lines[i] !== '\\.') {
      const values = lines[i].split('\t').map(decodeCopy);
      if (values.length !== columns.length) throw Error('Unvollstaendige COPY-Zeile.');
      rows.push(Object.fromEntries(columns.map((c,j) => [c, values[j]])));
    }
    if (i === lines.length) throw Error('COPY-Block nicht abgeschlossen.');
    const name = `${m[1]}.${m[2]}`;
    if (tables.has(name)) throw Error('Doppelter COPY-Block.');
    tables.set(name, {columns, rows});
  }
  return tables;
}

export function inspectBackup(folder) {
  const root = fs.realpathSync(folder);
  const tables = parseDump(fs.readFileSync(path.join(root, 'data.sql'), 'utf8'));
  for (const name of [...restored, 'public.guest_transfers', 'storage.objects', 'storage.buckets']) {
    if (!tables.has(name)) throw Error(`Backup unvollstaendig: ${name}`);
  }
  if (!tables.get('auth.users').rows.length) throw Error('Backup enthaelt keine Nutzer.');
  for (const [name, t] of tables) {
    if (name.startsWith('public.') && !appTables.includes(name.slice(7))) throw Error(`Unbekannte App-Tabelle: ${name}`);
    if ((name.startsWith('auth.mfa_') && name !== 'auth.mfa_amr_claims' || /auth\.(saml|sso|webauthn|custom_oauth)/.test(name)) && t.rows.length) {
      throw Error('Dieses Backup benoetigt eine erweiterte Auth-Wiederherstellung.');
    }
  }
  const bucket = tables.get('storage.buckets').rows;
  if (bucket.length !== 1 || bucket[0].id !== 'bike-images' || bucket[0].public !== 'f') throw Error('Unerwartete Buckets.');
  const users = new Set(tables.get('auth.users').rows.map(r => r.id));
  const images = tables.get('storage.objects').rows.map(row => {
    const parts = row.name.split('/');
    if (row.bucket_id !== 'bike-images' || parts.length !== 3 || !users.has(parts[0]) ||
        !/^[a-f0-9-]{36}$/.test(parts[1]) || !/^[a-f0-9]{64}$/.test(parts[2])) throw Error('Unerwarteter Bildpfad.');
    const filename = fs.realpathSync(path.join(root, 'bike-images', ...parts));
    if (!filename.startsWith(root + path.sep)) throw Error('Bild ausserhalb des Backups.');
    const bytes = fs.readFileSync(filename);
    if (hash(bytes) !== parts[2]) throw Error('Bild-Pruefsumme stimmt nicht.');
    const metadata = JSON.parse(row.metadata);
    if (!['image/jpeg','image/png','image/webp','image/gif'].includes(metadata.mimetype)) throw Error('Unbekannter Bildtyp.');
    return {row, bytes, mime: metadata.mimetype};
  });
  const names = new Set(images.map(i => i.row.name));
  for (const name of ['public.bike_documents', 'public.bike_document_history']) {
    for (const row of tables.get(name).rows) {
      if (!users.has(row.user_id)) throw Error('App-Dokument ohne Nutzer.');
      const payload = row.payload ? JSON.parse(row.payload) : null;
      const check = value => {
        if (typeof value === 'string' && value.startsWith('cloud:') && !names.has(value.slice(6))) throw Error('Referenziertes Bild fehlt im Backup.');
        if (value && typeof value === 'object') Object.values(value).forEach(check);
      };
      check(payload);
    }
  }
  return {root, tables, images};
}

export function validateKey(key) {
  // Require a project-bound legacy service_role JWT, not an ambiguous secret.
  let claims;
  try { claims = JSON.parse(Buffer.from(key.split('.')[1], 'base64url')); } catch { throw Error('Dev-service_role-Key ist kein JWT.'); }
  if (claims.ref !== DEV || claims.role !== 'service_role') throw Error('Key gehoert nicht zum Dev-Projekt/service_role.');
}

export function databaseTLS(certificatePath) {
  if (!certificatePath) return {rejectUnauthorized:true};
  // Accept PEM and DER downloads; parse them before attempting any connection.
  const certificate = new crypto.X509Certificate(fs.readFileSync(certificatePath));
  if (!certificate.ca) throw Error('Die Zertifikatsdatei enthaelt kein CA-Zertifikat.');
  if (Date.parse(certificate.validTo) <= Date.now() || Date.parse(certificate.validFrom) > Date.now()) {
    throw Error('Das CA-Zertifikat ist abgelaufen oder noch nicht gueltig.');
  }
  return {rejectUnauthorized:true, ca:certificate.toString()};
}

export async function affectedTables(db, seeds, allowed) {
  // Every explicitly cleared table is a root, including session/flow tables
  // which need not have a foreign key leading back to auth.users.
  const dependencies = await db.query(`WITH RECURSIVE affected(oid) AS (
    SELECT unnest($1::text[])::regclass::oid UNION
    SELECT c.conrelid FROM pg_constraint c JOIN affected a ON c.confrelid=a.oid WHERE c.contype='f'
  ) SELECT n.nspname AS schema, c.relname AS name FROM affected a
    JOIN pg_class c ON c.oid=a.oid JOIN pg_namespace n ON n.oid=c.relnamespace`, [[...seeds]]);
  const affected = new Set(dependencies.rows.map(r => `${r.schema}.${r.name}`));
  for (const name of affected) if (!allowed.has(name)) throw Error(`Unerwartete abhaengige Tabelle: ${name}`);
  return affected;
}

export async function replaceRows(db, tables, affected) {
  // Supabase permits reading cron.job, but changes go through pg_cron's API.
  await db.query('SELECT cron.alter_job(jobid, active := false) FROM cron.job WHERE active');
  await db.query(`TRUNCATE ${[...affected].sort().map(tableSQL).join(',')} RESTRICT`);
  for (const name of restored) {
    const t = tables.get(name);
    for (const row of t.rows) {
      await db.query(`INSERT INTO ${tableSQL(name)} (${t.columns.map(quote).join(',')}) VALUES (${t.columns.map((_,i) => `$${i+1}`).join(',')})`, t.columns.map(c => row[c]));
    }
    const count = await db.query(`SELECT count(*)::int AS n FROM ${tableSQL(name)}`);
    if (count.rows[0].n !== t.rows.length) throw Error(`Zeilenanzahl falsch: ${name}`);
  }
  await db.query('UPDATE public.guest_cleanup_settings SET enabled=false, dry_run=true');
  const orphans = await db.query('SELECT count(*)::int AS n FROM public.bike_documents d LEFT JOIN auth.users u ON u.id=d.user_id WHERE u.id IS NULL');
  if (orphans.rows[0].n) throw Error('Nutzerzuordnung fehlerhaft.');
}

async function run() {
  const [mode, folder] = process.argv.slice(2);
  if (!['--inspect', '--check', '--restore'].includes(mode) || !folder) throw Error('Aufruf: restore.mjs --inspect|--check|--restore <latest-Ordner>');
  const backup = inspectBackup(folder);
  const {tables, images} = backup;
  console.log(`Backup: ${tables.get('auth.users').rows.length} Nutzer, ${tables.get('public.bike_documents').rows.length} Dokumente, ${images.length} gepruefte Bilder.`);
  if (mode === '--inspect') return;
  const key = process.env.DEV_RESTORE_SERVICE_KEY;
  validateKey(key);
  if (!process.env.DEV_RESTORE_DB_PASSWORD) throw Error('Dev-Datenbankpasswort fehlt.');
  const {Client} = await import('pg');
  const {createClient} = await import('@supabase/supabase-js');
  const db = new Client({host:'aws-0-eu-central-1.pooler.supabase.com', port:5432,
    user:`postgres.${DEV}`, database:'postgres', password:process.env.DEV_RESTORE_DB_PASSWORD,
    ssl:databaseTLS(process.env.DEV_RESTORE_CA_FILE), connectionTimeoutMillis:15000, statement_timeout:30000});
  const api = createClient(`https://${DEV}.supabase.co`, key,
    {auth:{persistSession:false, autoRefreshToken:false, detectSessionInUrl:false}});
  let committed = false;
  await db.connect();
  try {
    const {data:bucket, error:bucketError} = await api.storage.getBucket('bike-images');
    if (bucketError || !bucket || bucket.public) throw Error('Privater Dev-Bucket bike-images fehlt oder Key ungueltig.');
    const authCheck = await api.auth.admin.listUsers({page:1,perPage:1});
    if (authCheck.error) throw Error('Dev-service_role-Zugriff fehlgeschlagen.');
    // Reject schema differences before any mutation. Keep existing Dev functions/RLS.
    for (const name of restored) {
      await db.query(`SELECT ${tables.get(name).columns.map(quote).join(',')} FROM ${tableSQL(name)} LIMIT 0`);
    }
    const policies = await db.query("SELECT policyname FROM pg_policies WHERE schemaname='storage' AND tablename='objects' AND policyname IN ('own_bike_images_read','own_bike_images_insert')");
    if (policies.rowCount !== 2) throw Error('Dev-Storage-Regeln fehlen.');
    // Enumerate precisely what TRUNCATE CASCADE would touch; never blindly cascade.
    const allowed = new Set([...tables.keys()].filter(n => n.startsWith('auth.') || n.startsWith('public.')));
    const transient = ['auth.flow_state', 'auth.sessions', 'auth.refresh_tokens', 'auth.one_time_tokens', 'auth.mfa_amr_claims'];
    const affected = await affectedTables(db, ['auth.users', ...appTables.map(n => `public.${n}`), ...transient], allowed);
    const jobs = await db.query("SELECT jobid FROM cron.job WHERE active");
    console.log(`Dev erreichbar. Betroffene Tabellen: ${affected.size}; aktive Cron-Jobs: ${jobs.rowCount}.`);
    if (mode === '--check') { console.log('Nur geprueft. Keine Daten geaendert.'); return; }

    const snapshotDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../.tmp/restore-dev');
    fs.mkdirSync(snapshotDir,{recursive:true});
    const snapshotFile = path.join(snapshotDir, `before-${Date.now()}.json`);
    await db.query('BEGIN ISOLATION LEVEL SERIALIZABLE');
    await db.query("SET LOCAL lock_timeout='10s'");
    await db.query("SET LOCAL session_replication_role='replica'");
    // Explicit table list + RESTRICT prevents newly discovered dependencies being erased.
    await db.query(`LOCK TABLE ${[...affected].sort().map(tableSQL).join(',')} IN ACCESS EXCLUSIVE MODE`);
    const snapshot = {project:DEV, tables:{}, cron:(await db.query('SELECT * FROM cron.job')).rows};
    for (const name of affected) snapshot.tables[name] = (await db.query(`SELECT * FROM ${tableSQL(name)}`)).rows;
    fs.writeFileSync(snapshotFile, JSON.stringify(snapshot), {flag:'wx',mode:0o600});
    console.log(`Dev-Daten vor Import lokal gesichert: ${snapshotFile}`);
    await replaceRows(db, tables, affected);
    await db.query('COMMIT');
    committed = true;
    console.log('Nutzer und App-Daten importiert. Cron-Jobs bleiben fuer den Test deaktiviert.');
    for (const image of images) {
      const {error} = await api.storage.from('bike-images').upload(image.row.name, image.bytes,
        {upsert:true,contentType:image.mime});
      if (error) throw Error('Bild-Upload fehlgeschlagen; Datenbank ist bereits importiert.');
      const owner = await db.query("UPDATE storage.objects SET owner_id=$1 WHERE bucket_id='bike-images' AND name=$2 RETURNING id",[image.row.owner_id, image.row.name]);
      if (owner.rowCount !== 1) throw Error('Bildzuordnung fehlgeschlagen.');
      const downloaded = await api.storage.from('bike-images').download(image.row.name);
      if (downloaded.error || hash(Buffer.from(await downloaded.data.arrayBuffer())) !== hash(image.bytes)) throw Error('Bildpruefung nach Upload fehlgeschlagen.');
    }
    console.log(`RESTORE FERTIG: ${images.length} Bilder nach Download hash-geprueft. Anmeldung und Nutzertrennung jetzt in frischem Browserprofil testen.`);
    console.log('Alte Dev-Bilddateien wurden nicht geloescht. Main-Sessions, Transfer-Tickets und Vault-Secrets wurden nicht importiert.');
  } catch (error) {
    if (!committed) { await db.query('ROLLBACK').catch(() => {}); console.error('Datenbank-Transaktion nicht uebernommen.'); }
    else console.error('Datenbank bereits uebernommen; Bildphase unvollstaendig. Nach Behebung kann derselbe Restore erneut laufen.');
    throw error;
  } finally { await db.end(); }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  run().catch(error => {
    if (['SELF_SIGNED_CERT_IN_CHAIN','DEPTH_ZERO_SELF_SIGNED_CERT','UNABLE_TO_VERIFY_LEAF_SIGNATURE','UNABLE_TO_GET_ISSUER_CERT_LOCALLY'].includes(error.code)) {
      console.error('TLS: Supabase-CA aus den Dev-Datenbankeinstellungen herunterladen und -CertificatePath angeben. Die Zertifikatspruefung bleibt aktiv.');
    }
    // Never log server detail/rows, credentials, or the complete error object.
    console.error(`Abbruch: ${String(error.message).replaceAll(process.env.DEV_RESTORE_DB_PASSWORD || '\u0000','[redacted]').replaceAll(process.env.DEV_RESTORE_SERVICE_KEY || '\u0000','[redacted]')}`);
    process.exitCode=1;
  });
}
