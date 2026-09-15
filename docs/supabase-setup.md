# Supabase einrichten

Die öffentliche Projekt-URL und der Publishable Key sind in
`lib/cloud/cloud_config.dart` hinterlegt. Das sind Client-Zugangsdaten, keine
Verwaltungsschlüssel. Niemals `service_role`, Secret Keys oder das
Datenbankpasswort in die Flutter-App übernehmen.

## 1. Datenbank und Bilder aktivieren

1. Im Supabase-Projekt **SQL Editor → New query** öffnen.
2. Den vollständigen Inhalt von
   `supabase/migrations/202609150001_accounts_and_sync.sql` einfügen.
3. **Run** ausführen. Das Skript legt Tabellen, private Bildablage,
   Zugriffsregeln und die Funktion für versionsgeprüfte Schreibzugriffe an.
4. In Authentication anonyme Anmeldung und E-Mail-Anmeldung aktivieren;
   E-Mail-Bestätigung eingeschaltet lassen.

Die Tabellen brauchen keine manuelle Bearbeitung. Direkte Schreibzugriffe
aus dem Client sind gesperrt. Nur die Funktion `save_bike_document` schreibt
mit der geprüften Nutzer-ID aus dem Anmeldetoken. Anonyme angemeldete Nutzer
verwenden wie registrierte Nutzer die Datenbankrolle `authenticated`.

## 2. E-Mail-Codes einrichten

Die App verwendet eingegebene Codes, damit die Verknüpfung auch ohne
App-Links auf Android, iOS, Desktop und Web funktioniert.

Unter **Authentication → Email → Templates** in den Vorlagen
**Change Email Address** und **Reset Password** den Code anzeigen:

```html
<h2>Bike Setup Tracker</h2>
<p>Dein Bestätigungscode lautet:</p>
<p><strong>{{ .Token }}</strong></p>
<p>Gib diesen Code in der App ein. Teile ihn nicht mit anderen Personen.</p>
```

Vorhandene Betreffzeilen können erhalten bleiben. Einen Bestätigungslink
benötigt dieser Ablauf nicht. In der App zunächst den Code anfordern und dann
Code und gewünschtes Passwort eingeben. Beim Verknüpfen bleibt die Nutzer-ID
unverändert. Scheitert nur das Setzen des Passworts nach bestätigter E-Mail,
kann es auf der Kontoseite erneut gesetzt werden.

Für echte Nutzer **Custom SMTP** konfigurieren. Der Supabase-Testversand ist
eingeschränkt und reicht nicht für öffentliche Registrierung. Den Dienst,
Absender und Zugangsdaten richtet der Projektinhaber im Dashboard ein;
SMTP-Zugangsdaten gehören nicht in die App.

## 3. App starten und kontrollieren

Nach Paketinstallation die App vollständig neu starten (kein bloßes Hot Reload,
da neue Plattform-Plugins hinzugekommen sind).

1. Einstellungen → **Konto & Datensicherung** öffnen.
2. **Jetzt synchronisieren** wählen; der Status soll auf **Mit Cloud
   synchronisiert** wechseln. Bei fehlendem SQL bleibt die App lokal benutzbar.
3. Ein Bike, ein Setup und ein eigenes Bild anlegen; erneut synchronisieren.
4. E-Mail verknüpfen, Code bestätigen und Passwort speichern.
5. Auf einem zweiten Gerät oder in einem getrennten Browserprofil
   **Ich habe bereits ein Konto** wählen und anmelden. Gastimport deaktiviert
   lassen, wenn dort nur die Demo-Bikes vorhanden sind.
6. Bike, Setup, eigene Felder, Historie und Bild prüfen.
7. Offline ändern, Verbindung wiederherstellen und die Übertragung prüfen.
8. Dasselbe Bike auf zwei Geräten offline unterschiedlich bearbeiten: Bei einem
   Konflikt **Beide Fassungen behalten** testen.
9. Datei exportieren und auf einem anderen Gerät als Kopien importieren.

Diese Prüfung benötigt eingerichtete Tabellen und funktionierenden E-Mail-Versand.
Lokale automatisierte Tests ersetzen den Test gegen das echte Projekt nicht.

## Datenmodell und Grenzen dieser Version

- Lokal: transaktionaler Sembast-Speicher, auf Web IndexedDB, sonst im
  Dokumentenverzeichnis. Nutzerdaten und Synchronisierungsbasis liegen in
  einem gemeinsamen Datensatz. Die bisherigen SharedPreferences bleiben als
  Rückfallkopie erhalten; fehlerhafte Altbestände werden nicht überschrieben.
- Cloud: ein Dokument pro Bike einschließlich Setups und Historie, dazu ein
  Dokument für die Feldbibliothek und eines für die Bike-Reihenfolge.
  Gleichzeitige Änderungen an verschiedenen Setups desselben Bikes werden
  vorsichtshalber als Konflikt behandelt. Eine spätere feinere Aufteilung ist möglich.
- Die Cloud prüft die erwartete Revision atomar. Löschungen bleiben als
  Löschmarkierungen erhalten. Die letzten 20 vorherigen Versionen je Dokument
  können wiederhergestellt werden. Die Oberfläche zeigt die 100 neuesten
  historischen Einträge des Kontos.
- Bilder: private, unveränderliche Objekte anhand ihres Inhalts-Hashs,
  maximal 5 MB pro Datei. Auf dem zweiten Gerät werden sie lokal eingebettet
  gespeichert, damit sie offline angezeigt werden können.
- Abmelden und Anmelden trennen lokale Kontobestände. Beim Gastimport entstehen
  neue IDs; lokale Sicherungen sind als Kopien wiederherstellbar. Noch nicht
  synchronisierte Daten können nur auf dem ursprünglichen Gerät vorhanden sein.
- Automatische Übertragung nach Änderungen (2 Sekunden), bei Rückkehr in die
  App und alle 45 Sekunden, solange die App läuft. Kein Betriebssystem-Dienst
  für Uploads bei geschlossener App. Im Browser dieselbe Installation nicht
  gleichzeitig in mehreren Tabs bearbeiten: Ein veralteter zweiter Tab darf
  lokale Änderungen nicht überschreiben und muss nach Export eventueller
  ungespeicherter Änderungen neu geladen werden.
- Ein verlorenes anonymes Anmeldetoken ist nicht durch die UID ersetzbar.
  Ohne verknüpfte E-Mail bleiben Daten nach Geräteverlust eventuell unerreichbar.
- Konto-Selbstlöschung, Google/Apple-Anmeldung und automatisierte externe
  Betreiber-Backups sind noch nicht Bestandteil dieser ersten Version.
  Vor öffentlicher Veröffentlichung Kontolöschung und Betreiber-Backups ergänzen.
- Der lokale Versionsbestand und verwaiste Bilder werden noch nicht automatisch
  bereinigt. Speicherverbrauch überwachen; vor einer Bereinigung Referenzen aus
  der Cloud-Historie berücksichtigen. Nicht pauschal anonyme Accounts löschen.

## Vor öffentlicher Veröffentlichung

- Mit zwei realen Nutzern prüfen, dass Daten- und Bildzugriffe des anderen
  Kontos abgewiesen werden. RPC-Konflikttest ebenfalls gegen Supabase ausführen.
- E-Mail-Versand, Ratenlimits und Schutz vor massenhaften anonymen Anmeldungen
  konfigurieren. Falls CAPTCHA aktiviert wird, muss dessen Token-Übergabe in
  der App ergänzt werden; diese Version hat noch keine CAPTCHA-Oberfläche.
- Separate Backups von Datenbank **und Bilddateien** einrichten und eine
  Wiederherstellung testen. Die Dokumenthistorie ist kein unabhängiges Backup.
- Kostenloses Supabase-Projekt: Inaktivitätspausen und Speicher-/Traffic-Limits
  beachten. Ein kostenloser Nutzeraccount muss nicht bedeuten, dass der
  App-Betrieb dauerhaft kostenlos bleibt.
- Native Zielplattformen einschließlich E-Mail-Codes und Dateifreigabe auf
  echten Geräten prüfen. Ein Web-Build beweist keine iOS-/Android-Funktion.

## Quellen

- https://supabase.com/docs/guides/auth/auth-anonymous
- https://supabase.com/docs/guides/auth/auth-smtp
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/pricing
