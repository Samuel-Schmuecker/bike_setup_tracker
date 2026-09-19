# Dev und Produktion

Die Projektzuordnung ist mit dem Betreiber bestätigt. Im Produktionsprojekt
liegen zum Zeitpunkt der Trennung noch keine echten Nutzerdaten.

| Umgebung | Git-Branch | Supabase-Projekt | Web-Adresse |
| --- | --- | --- | --- |
| Produktion | `main` | `iwmrlwouyfpmizzirmby` | https://samuel-schmuecker.github.io/bike_setup_tracker/ |
| Entwicklung | `dev` | `dcrkfiooddkbzljibomo` | https://samuel-schmuecker.github.io/bike_setup_tracker/dev/ |

## Builds und lokaler Speicher

Beide Deployments verwenden ausdrücklich Flutter **3.38.9**, passend zum lokal
getesteten SDK. Die Version bei einem Upgrade in beiden Workflows zusammen ändern
und Web-Build sowie Cache-Tests erneut prüfen. Neuere Flutter-Versionen ersetzen
den bisherigen Offline-Worker durch einen Worker, der sich abmeldet; das
Cache-Skript lässt diesen unverändert. Ein SDK-Upgrade kann deshalb die Fähigkeit
ändern, die App ohne Netzwerk neu zu öffnen; lokale Nutzerdaten bleiben erhalten.

Beide Workflows übergeben `APP_ENV`, Supabase-URL, öffentlichen Client-Key und
den Namen der Bildbereinigung ausdrücklich. Ohne Parameter startet Flutter in
Dev. Eine falsche Kombination aus Umgebung und Projekt-URL stoppt den App-Start.
Die öffentlichen Publishable Keys dürfen im Client stehen; Service-Keys niemals.

Main behält `bike_tracker_v2` und das bisherige Preferences-Präfix `flutter.`.
Dev verwendet `bike_tracker_dev_v2` und `bike_tracker_dev.`. So sind Offline-Daten,
lokale Sicherungen, Alt-Datenimport, Einstellungen, Onboarding und OAuth-PKCE
getrennt. Supabase speichert Web-Anmeldetokens bereits pro Projekt.
Dev startet nach diesem Update mit einem frischen lokalen Bestand; bisherige
gemeinsame Daten werden nicht gelöscht und nicht automatisch nach Dev kopiert.

Ein Unterordner trennt Browser-Speicher nicht: Beide URLs haben dieselbe Origin.
Die Workflows trennen auch die drei generierten Flutter-Offline-Caches nach
Service-Worker-Scope (`dart run tool/isolate_web_cache.dart` nach dem Web-Build).
Bei manuellen Veröffentlichungen diesen Schritt ebenfalls ausführen.
Die Trennung durch Speichernamen verhindert versehentliche Zugriffe dieser App,
ist aber keine Sicherheitsgrenze für beliebigen Code auf derselben Domain.
Für unabhängige Service Worker und eine vollständige Browser-Sicherheitsgrenze
Dev später auf einer eigenen Origin hosten. Bis dahin kann ein separates
Browserprofil für Dev zusätzlich alte Sessions und Service Worker isolieren.

## Neues Supabase-Projekt vollständig einrichten

Ein zweites Projekt übernimmt die Einrichtung des ersten nicht automatisch.
Für **beide Projekte getrennt** prüfen:

1. Alle SQL-Dateien unter `supabase/migrations/` in aufsteigender Reihenfolge
   anwenden, einschließlich `202609190003_guest_cleanup_auth_header.sql`.
2. Edge Functions `delete-account`, `cleanup-bike-images` und
   `cleanup-guest-accounts` mit den jeweiligen Repository-Dateien bereitstellen.
   In Dev erwartet der bestehende Build den Bildbereinigungs-Slug `super-function`,
   in Main `cleanup-bike-images`. Bei Vereinheitlichung Dev-Workflow und
   `cloud_config.dart` gemeinsam ändern. Die Handlers übernehmen die Auth-Prüfung;
   die Gateway-JWT-Prüfung ist gemäß `supabase/config.toml` deaktiviert.
3. Bei CLI-Befehlen immer `--project-ref` angeben. Für Produktion beispielsweise:

   ```sh
   supabase functions deploy delete-account --project-ref iwmrlwouyfpmizzirmby
   supabase functions deploy cleanup-bike-images --project-ref iwmrlwouyfpmizzirmby
   supabase functions deploy cleanup-guest-accounts --project-ref iwmrlwouyfpmizzirmby
   ```

4. Anonyme Anmeldung, Google-Provider und manuelle Kontoverknüpfung in jedem
   Projekt aktivieren. In Google OAuth beide Supabase-Callbacks hinterlegen:
   `https://iwmrlwouyfpmizzirmby.supabase.co/auth/v1/callback` und
   `https://dcrkfiooddkbzljibomo.supabase.co/auth/v1/callback`.
5. Je Projekt die passende Web-Adresse aus der Tabelle als Site URL und erlaubte
   Redirect URL setzen. Lokale Test-Rückleitungen nur bei Dev hinzufügen.
6. Gastbereinigung separat konfigurieren: `GUEST_CLEANUP_SECRET` je Projekt
   unterschiedlich wählen. Vault-Werte `guest_cleanup_project_url`,
   `guest_cleanup_secret` und `guest_cleanup_anon_key` müssen alle zum selben
   Projekt gehören. Keine Dev-Vault-Werte nach Produktion kopieren. Zunächst
   deaktiviert bzw. im Dry-Run belassen; siehe [Gastbereinigung](orphan-guest-cleanup.md).

## Arbeitsablauf

Auf `dev` entwickeln und pushen; nur die Dev-Web-App wird neu gebaut. Änderungen
an SQL und Edge Functions zuerst ausschließlich im Dev-Projekt einrichten und
testen. Ein Merge/Push auf `main` veröffentlicht die Produktions-Web-App.
Die Workflows deployen **keine** Supabase-Migrationen oder Edge Functions.
Benötigte kompatible Backend-Änderungen daher vor dem Main-Release im
Produktionsprojekt bereitstellen.

Beide Pages-Workflows verwenden dieselbe Concurrency-Gruppe und erhalten mit
`keep_files: true` die jeweils andere Web-Version im gemeinsamen `gh-pages`-Branch.
Bei schnellen Push-Folgen kann GitHub einen älteren wartenden Lauf ersetzen;
im Actions-Tab kontrollieren, ob beide gewünschten Branch-Stände veröffentlicht sind.

## Abnahme vor den ersten Nutzern

Mit Testkonten in beiden Umgebungen Google-Anmeldung, Gastverknüpfung, Sync,
Bilder, Wiederherstellung und Kontolöschung prüfen. Ein in Dev angelegtes Bike
darf weder lokal in Main noch in dessen Supabase-Projekt erscheinen. Auch
Dev-Einstellungen und Dev-Kontolöschung dürfen Main nicht beeinflussen.
Mit zwei Konten die Daten-/Bild-Zugriffsregeln im Produktionsprojekt prüfen.

Die Repository-Tests prüfen Anwendungscode; sie beweisen nicht, dass die
Dashboard-Einstellungen, SQL-Migrationen oder Functions tatsächlich live sind.

## Prüfung am 19. September 2026

Die öffentliche Auth-Konfiguration meldet Google in beiden Projekten als aktiv.
Anonyme Anmeldung ist in Dev aktiv, in Produktion jedoch **deaktiviert**.
Vor dem Release im Produktionsprojekt unter Authentication → Sign In / Providers
die anonyme Anmeldung aktivieren; sonst funktionieren Gastkonten und Gast-Sync nicht.

Die drei erwarteten Function-URLs antworten in beiden Projekten: Kontolöschung
und Bildbereinigung mit HTTP 200 auf OPTIONS, Gastbereinigung mit dem erwarteten
HTTP 405 (`method_not_allowed`). Das bestätigt die Erreichbarkeit, nicht die
korrekte Einrichtung aller Datenbankfunktionen, Secrets oder Berechtigungen.
SQL-Migrationsstand, Google-Rückleitungen, manuelle Kontoverknüpfung und Cron-/Vault-
Konfiguration wurden ohne Dashboard-/Verwaltungszugriff nicht live verifiziert.

Referenzen: [Browser-Speicher und Origin](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Basic_Terminology),
[Pages-Deployment und keep_files](https://github.com/peaceiris/actions-gh-pages).
