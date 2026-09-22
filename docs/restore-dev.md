# Main-Backup in das bestehende Dev-Projekt laden

Dieses Werkzeug ersetzt Nutzer und App-Daten in **dcrkfiooddkbzljibomo**.
Es testet die Datenwiederherstellung in der vorhandenen Dev-Installation;
es ist kein kompletter Neuaufbau aus `schema.sql` und `roles.sql`.
Dev-Funktionen, RLS-Regeln, OAuth-Einstellungen und Vault bleiben erhalten.

## Start unter Windows

Dev-App auf allen Geräten schließen. In PowerShell ausführen:

```powershell
& 'D:\06_App\bike_setup_tracker\tool\restore-dev.ps1' -Mode Restore
```

Das Werkzeug fragt verdeckt nach:

1. dem **Datenbankpasswort von Dev** (nicht dem Supabase-Kontopasswort);
2. dem **service_role JWT von Dev**: Supabase-Projekt → Settings → API Keys →
   Legacy API Keys → `service_role` anzeigen/kopieren.

Der Service-Key wird nur für Auth-Prüfung und Storage verwendet. Das Werkzeug
prüft dessen Projektkennung und Rolle und prüft den Key zusätzlich am Dev-Server.
Main-Keys und Publishable-/Anon-Keys werden abgelehnt. Keine Zugangsdaten in
Dateien oder Chat schreiben. Die lokalen Umgebungsvariablen werden danach entfernt.
Node.js 22+ und npm werden benötigt; die Pakete sind versionsgebunden.

Falls PowerShell lokale Skripte blockiert, kann dieser einzelne Aufruf verwendet werden:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'D:\06_App\bike_setup_tracker\tool\restore-dev.ps1' -Mode Restore
```

Der Standardpfad ist:
`D:\06_App\00_Backups\bike-setup-tracker-backups-main\bike-setup-tracker-backups-main\latest`.
Einen anderen Pfad mit `-BackupPath '...\latest'` übergeben.

## Prüfungen und Änderungen

- `-Mode Inspect`: Backup ausschließlich lokal prüfen, ohne Zugangsdaten.
- `-Mode Check`: zusätzlich Dev-Zugang, Spalten, Bucket und vorhandene Policies
  lesen. Keine Änderungen. Es ist keine vollständige Schema-Kompatibilitätsprüfung.
- `-Mode Restore`: führt diese Prüfungen ebenfalls aus und ersetzt dann die Daten.

Vor dem Austausch werden betroffene Dev-Tabellen und Cron-Einstellungen unter
`.tmp/restore-dev/before-*.json` gesichert. Diese Dateien enthalten sensible
Auth-Daten, sind durch `.gitignore` ausgeschlossen und keine vollständige
Supabase-Projektsicherung. Alte Dev-Bilddateien werden nicht gelöscht.

Der Datenbankimport läuft in einer Transaktion; ein Fehler vor dem Commit rollt
ihn zurück. Unbekannte Tabellenabhängigkeiten werden nicht automatisch gelöscht.
Nutzer-IDs, Identitäten und App-Daten werden übernommen. Alte Sessions,
Refresh-Tokens und Gast-Transfer-Tickets werden nicht aus Main übernommen.
MFA-/SSO-Sonderfälle werden derzeit abgelehnt. Gastkonten bleiben als Datensätze
erhalten, lassen sich ohne ihre ursprüngliche Sitzung aber nicht einfach neu anmelden.

Alle Dev-Cron-Jobs bleiben nach dem Import deaktiviert; die Gastbereinigung wird
zusätzlich abgeschaltet. Erst nach Prüfung der Dev-Konfiguration gezielt wieder
aktivieren. Vault und Edge-Function-Secrets werden nicht aus Main importiert.

Die Bilder werden danach über die Storage-API mit ursprünglichem Pfad und MIME-Typ
hochgeladen, `owner_id` zugeordnet und erneut heruntergeladen/hash-geprüft.
Diese Phase ist nicht mit der Datenbank atomar. Bei Bildfehlern bleiben importierte
Daten bestehen; denselben Lauf nach Fehlerbehebung wiederholen. Storage-interne
IDs und Zeitstempel werden nicht als identische Kopie wiederhergestellt.

Bei einem TLS-Zertifikatsfehler nicht die Zertifikatsprüfung abschalten; zunächst
die vertrauenswürdige CA-Konfiguration für die Supabase-Verbindung korrigieren.
Bei `self-signed certificate in certificate chain` in den
[Dev-Datenbankeinstellungen](https://supabase.com/dashboard/project/dcrkfiooddkbzljibomo/database/settings)
das Server-Root-/CA-Zertifikat herunterladen. Anschließend beispielsweise:

```powershell
& 'D:\06_App\bike_setup_tracker\tool\restore-dev.ps1' -Mode Restore -CertificatePath "$env:USERPROFILE\Downloads\prod-supabase.cer"
```

Den Dateinamen an den tatsächlichen Download anpassen. Die Datei wird ausschließlich
für diese Datenbankverbindung genutzt; Zertifikatskette und Hostname werden weiterhin
geprüft. PEM und DER werden unterstützt. Der Downloadname kann `prod` enthalten,
auch wenn das gewählte Projekt Dev ist.

## Anschließend prüfen

In einem frischen Browserprofil die Dev-App öffnen:
https://samuel-schmuecker.github.io/bike_setup_tracker/dev/

Mit einem wiederhergestellten Google-Konto anmelden; Bikes, Setups, Historie
und Bilder prüfen. Google-OAuth muss bereits für Dev eingerichtet sein.
Mit einem zweiten Konto prüfen, dass keine fremden Bikes oder Bilder zugänglich
sind. Der technische Import bestätigt noch nicht diese Anmeldung und RLS-Prüfung.
Die App blendet ältere Historie entsprechend ihrer Aufbewahrungsregeln aus.

Referenzen: [Supabase Restore](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore),
[Storage-Eigentümer](https://supabase.com/docs/guides/storage/security/ownership).
