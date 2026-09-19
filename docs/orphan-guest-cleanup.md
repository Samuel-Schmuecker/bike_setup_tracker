# Verwaiste Gastkonten bereinigen

Die Migration `202609190002_guest_account_cleanup.sql` ergänzt den Job
`cleanup-guest-accounts`: sonntags 03:15 UTC (Frankfurt: 04:15 Winterzeit,
05:15 Sommerzeit). Anfangs sind `enabled=false` und `dry_run=true` gesetzt.
Es werden bei der Installation keine Konten gelöscht.

## Auswahl und Schutz

- Ausschließlich `is_anonymous=true`, ohne nicht-anonyme Auth-Identität.
  Damit sind Google und vorsorglich auch andere verknüpfte Provider ausgeschlossen.
- Ohne Dokumente: mindestens 7 Tage inaktiv; mit Daten: mindestens 90 Tage.
  Konservativ zählen auch `order`, Tombstones, Historie und verbleibende Bilder
  als Daten. Setups liegen im Bike-Dokument.
- Aktivität ist das Maximum aus Erstellung, `last_sign_in_at`, Sitzungsaktualisierung,
  Dokumentänderung, Historie und Bild-Upload. NULL bei `last_sign_in_at` fällt auf
  die Erstellung zurück. Laufende Gastübertragungen werden übersprungen.
- Lesen ohne Sitzungsaktualisierung oder ausschließlich lokale Nutzung ist auf
  dem Server nicht erkennbar. Die Fristen entsprechend dem Produktversprechen wählen.
- Vor dem Start wird unter Auth-Zeilensperre und bestehender Kontosperre erneut
  geprüft. Der vorhandene Löschmarker verhindert weitere Dokument-/Bildschreibzugriffe
  und Google-Upgrades; ein ergänzender Identity-Trigger schützt auch direkte
  Verknüpfungen. Bereits begonnene Löschungen sind nicht rückgängig zu machen.

Die öffentliche `delete-account`-Schnittstelle verlangt eine echte Nutzersitzung;
ein Service-Key plus beliebige User-ID funktioniert dort bewusst nicht. Der neue
Worker importiert deshalb den **unveränderten** `createDeleteHandler` und stellt
ihm ausschließlich nach erfolgreichem `claim_guest_cleanup` einen internen
Identitätsadapter bereit. Es werden keine Nutzer-JWTs erzeugt. Ziel-IDs stammen
nur aus der Datenbank; HTTP-Body-Felder können weder Ziel noch Dry-Run überschreiben.
Der originale Handler entfernt Bilder über die Storage API und danach den User
über die Auth Admin API. Fremdschlüssel löschen Dokumente und Historie mit.
Bestehende RLS, Sync-/Transfer-Funktionen und `delete-account` bleiben unverändert.

## Einrichten und Vorschau

1. Migrationen in Reihenfolge anwenden (`supabase db push` für das verknüpfte
   Projekt). Supabase Vault, pg_cron und pg_net müssen verfügbar sein.
2. Ein zufälliges Secret mit mindestens 32 Zeichen erstellen. Dasselbe Secret
   als Edge-Secret `GUEST_CLEANUP_SECRET` (Dashboard oder `supabase secrets set`)
   und in Vault hinterlegen. Nicht ins Repository, Flutter oder Client-Konfiguration schreiben.
   Im SQL Editor als Betreiber:

   ```sql
   select vault.create_secret('https://PROJECT_REF.supabase.co', 'guest_cleanup_project_url');
   select vault.create_secret('REPLACE_WITH_RANDOM_SECRET_AT_LEAST_32_CHARS', 'guest_cleanup_secret');
   ```

   Bei Rotation bestehende Vault-Einträge mit `vault.update_secret` aktualisieren.
3. `supabase functions deploy cleanup-guest-accounts` ausführen. Der eigene
   Secret-Check übernimmt die Authentifizierung (`verify_jwt=false` in config.toml).
4. Im SQL Editor Vorschau prüfen; sie funktioniert auch bei deaktiviertem Job:

   ```sql
   select * from public.preview_guest_cleanup() order by eligible_at, user_id;
   select category, count(*) from public.preview_guest_cleanup() group by category;
   ```

5. Einen HTTP-Dry-Run auslösen:

   ```sql
   update public.guest_cleanup_settings set enabled=true, dry_run=true;
   select public.dispatch_guest_cleanup(); -- liefert pg_net request_id
   ```

   Der HTTP-Aufruf startet erst nach Commit. Anschließend im Dashboard die
   Function Logs (`guest_cleanup_dry_run`) oder die Antwort anhand der Request-ID
   in `net._http_response` prüfen. Ein erfolgreicher Cron-Lauf bestätigt zunächst
   nur den Versand, nicht die erfolgreiche Ausführung des Workers.
6. Erst nach Prüfung scharf schalten:

   ```sql
   update public.guest_cleanup_settings set enabled=true, dry_run=false;
   ```

## Fristen, Protokoll und Betrieb

```sql
-- Beispiel: 14 / 180 Tage; Minimum für leere Konten ist 7 Tage.
update public.guest_cleanup_settings
set empty_after=interval '14 days', data_after=interval '180 days', batch_size=20;

-- Löschungen mit IDs und Zeitstempeln (bleiben nach User-Löschung erhalten):
select * from public.guest_cleanup_log order by started_at desc;
select date_trunc('day',deleted_at) as day, category, count(*)
from public.guest_cleanup_log where deleted_at is not null group by 1,2 order by 1 desc;

-- Begonnene, noch nicht abgeschlossene Löschungen / Fehler:
select * from public.guest_cleanup_log where deleted_at is null order by attempted_at;
select * from cron.job_run_details
where jobid=(select jobid from cron.job where jobname='cleanup-guest-accounts')
order by start_time desc limit 20;

-- Weitere Löschstarts stoppen; bereits laufende Storage-Aufrufe können enden:
update public.guest_cleanup_settings set enabled=false;
```

Pro Aufruf maximal `batch_size` Konten (Standard 20, Maximum 100); nach 120 Sekunden
beginnt der Worker kein weiteres Konto. Der bestehende Handler verarbeitet je Konto
maximal 50 Bild-Batches. Bei Teilfehlern bleiben Löschmarker und Audit erhalten;
der nächste Lauf nimmt diese Konten zuerst wieder auf, ältester Versuch zuerst.
Ein Prozessabbruch lässt einen offenen Audit-Eintrag zurück. `deleted_at` wird
atomar beim tatsächlichen Auth-DELETE gesetzt, auch bei verlorener HTTP-Antwort.
Fehler stehen in `last_error` und Function Logs. Bei großem Rückstand den Job
häufiger planen oder `dispatch_guest_cleanup()` erneut ausführen und überwachen.
Ein dauerhaft fehlerhafter Rückstand kann neue Löschungen verzögern.

Dry-Run erzeugt keine Löschmarker/Audit-Einträge; er zeigt neue Kandidaten.
Bereits begonnene Löschungen stehen separat im Audit und werden im Dry-Run
ebenfalls nicht fortgesetzt. Audit-IDs sind personenbezogen; eine passende
Aufbewahrungsfrist für dieses Protokoll betrieblich festlegen.

Cleanup reduziert gespeicherte Konten und Daten. Es verhindert nicht die
MAU-Erfassung beim ursprünglichen anonymen Sign-in und ist keine rückwirkende
Abrechnungskorrektur. Häufige ungenutzte Neuanmeldungen zusätzlich an der Quelle vermeiden.

## Tests

```powershell
npm install --prefix .tmp/image-cleanup-tests --no-save @electric-sql/pglite
node --test supabase/tests/guest_account_cleanup.test.mjs supabase/functions/cleanup-guest-accounts/handler.test.mjs supabase/functions/delete-account/handler.test.mjs
```

PGlite führt die SQL-Funktionen und Trigger aus; pg_cron wird als Test-Stub
abgebildet, Extension-Installation ausgelassen. Echte Auth-/Storage-APIs,
parallele Auth-Transaktionen, Vault, pg_net und Edge-Deployment zusätzlich in
einem Supabase-Testprojekt vor Aktivierung prüfen.

Grundlage für die Zeitplanung: [Supabase: Scheduling Edge Functions](https://supabase.com/docs/guides/functions/schedule-functions).
