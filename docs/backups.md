# Supabase-Backups

Der Workflow `.github/workflows/backup.yml` sichert sonntags um 03:00 UTC
und bei manuellem Start nach `Samuel-Schmuecker/bike-setup-tracker-backups`.
Das Ziel muss **privat** sein und mindestens einen Commit haben (z. B. README).
Es wird dessen Standardbranch verwendet. Branch-Regeln müssen direkte Pushes
mit dem PAT erlauben.

## Secrets einrichten

Im **App-Repository** unter Settings → Secrets and variables → Actions diese
Repository-Secrets hinterlegen. Werte niemals in die YAML-Datei schreiben.

| Secret | Inhalt |
| --- | --- |
| `BACKUP_REPO_PAT` | Fine-grained GitHub PAT für das Backup-Repository mit **Contents: Read and write**. Ablaufdatum beachten. |
| `SUPABASE_DB_URL` | PostgreSQL-Verbindungsstring inklusive Datenbankpasswort aus Supabase → Connect. Für GitHub-Runner den IPv4-fähigen **Session pooler**, Port **5432**, verwenden. Sonderzeichen im Passwort URL-kodieren. Kein API-Key und keine HTTPS-Projekt-URL. |
| `SUPABASE_S3_ACCESS_KEY_ID` | S3 Access Key aus den Supabase-Storage-Einstellungen. |
| `SUPABASE_S3_SECRET_ACCESS_KEY` | Zugehöriger S3 Secret Access Key; kein Publishable-/Anon-Key. |
| `SUPABASE_S3_REGION` | Region aus derselben S3-Konfiguration. |
| `SUPABASE_S3_ENDPOINT` | Vollständiger HTTPS-S3-Endpunkt aus derselben Konfiguration, ohne angehängten Bucketnamen. |

Datenbank-URL und S3-Zugang müssen zum **selben** Supabase-Projekt gehören.
Es gibt separate Dev- und Produktionsprojekte; dieser Workflow sichert genau
das durch diese Secrets ausgewählte Projekt. Der Git-Branch wählt kein Projekt.
Environment-Secrets werden ohne entsprechendes `environment:` im Job nicht
geladen. Der normale `GITHUB_TOKEN` ersetzt den PAT für das zweite Repo nicht.

## Inhalt und Fehlerverhalten

Unter `latest/` liegen `roles.sql`, `schema.sql`, `data.sql` sowie die Dateien
aus `bike-images/`. Der frühere Export `db.sql` enthielt nur das Schema;
für Datensätze ist `--data-only` erforderlich.

Vor dem Export prüft der Workflow fehlende Secrets, privaten Repository-Status
und Schreibzugriff. Erst nach erfolgreichen Exporten ersetzt er `latest/`
und pusht einen Commit. Frühere Sicherungen bleiben in der Git-Historie.
Fehler bei Export, Commit oder Push lassen den Lauf fehlschlagen. Docker,
AWS CLI, GitHub CLI, jq und rsync werden vom Ubuntu-Runner verwendet.

## Ersten Lauf prüfen

1. Die Änderung auf GitHub übernehmen. Zeitgesteuerte Läufe nutzen den
   Standardbranch; dafür muss die korrigierte Datei dort vorhanden sein.
2. Actions → **Backup Supabase DB & Storage** → **Run workflow** öffnen und
   den Branch mit dem korrigierten Workflow auswählen.
3. Einen erfolgreichen Lauf und einen neuen Commit im privaten Backup-Repo
   prüfen. `data.sql` muss die erwarteten Tabellen-Daten enthalten; Bilddateien
   müssen zu den gespeicherten Objekten passen. SQL-Dateien enthalten sensible
   Nutzerdaten und gehören nicht in öffentliche Issues oder Logs.
4. Bei `repository not found` Repository-Name und PAT-Zugriff prüfen; bei 403
   Contents-Schreibrecht, Token-Ablauf und Branch-Regeln prüfen. Bei DB-Timeouts
   Session-pooler-Verbindung und Netzwerkfreigaben in Supabase prüfen.

## Umfang und Wiederherstellung

Das ist ein logisches Datenbank-Backup plus der Bucket `bike-images`, kein
vollständiges Projekt-Abbild. Weitere Buckets, Edge-Function-Secrets und
Dashboard-/OAuth-Konfiguration werden nicht gesichert. Lokal noch nicht
synchronisierte App-Daten sind ebenfalls nicht enthalten. Datenbank und
Storage werden nacheinander gelesen und bilden bei parallelen Schreibzugriffen
keinen gemeinsamen atomaren Zeitpunkt ab.

Eine Wiederherstellung zuerst in einem separaten Testprojekt anhand der
[Supabase-Anleitung](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore)
erproben: Rollen, Schema und Daten in der dort beschriebenen Reihenfolge
importieren und Storage-Dateien separat über die Storage-/S3-API wiederherstellen.
Dabei Storage-Metadaten und Eigentümer-Zuordnung berücksichtigen; ein Datei-Upload
allein beweist keine korrekten Zugriffsrechte. Anmeldung, Bike-Sync und Bildzugriff
mit einem Testkonto prüfen, bevor die Sicherung als wiederherstellbar gilt.

GitHub begrenzt einzelne Git-Dateien auf 100 MiB; wachsende SQL-Dumps oder
Bildhistorien benötigen langfristig eine angepasste Ablage. Gelöschte Nutzerdaten
bleiben in alten Backup-Commits erhalten; Aufbewahrung und Zugriff auf dieses
private Repo entsprechend festlegen.

Referenzen: [Supabase GitHub-Backups](https://supabase.com/docs/guides/deployment/ci/backups),
[S3-Zugang](https://supabase.com/docs/guides/storage/s3/authentication),
[Checkout eines privaten zweiten Repositories](https://github.com/actions/checkout#checkout-multiple-repos-private).
