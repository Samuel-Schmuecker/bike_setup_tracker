# Kontolöschung aktivieren

Die App enthält jetzt „Konto und Daten löschen“, auch für Gastkonten. Vorher wird
ein Export angeboten; die endgültige Bestätigung erfordert die Eingabe `DELETE`.
Die Datenschutz-HTML wurde nicht verändert.

## Supabase einrichten (vor dem App-Deployment)

1. Im SQL Editor den Inhalt von
   `supabase/migrations/202609160001_account_deletion.sql` ausführen.
   Voraussetzung ist die vorhandene Accounts-and-Sync-Migration.
2. Edge Function **delete-account** bereitstellen. Mit Supabase CLI:

   ```sh
   supabase functions deploy delete-account --project-ref dcrkfiooddkbzljibomo --no-verify-jwt
   ```

   Alternativ im Dashboard eine Edge Function mit diesem Namen erstellen und
   **beide** Dateien `index.ts` und `handler.mjs` aus
   `supabase/functions/delete-account/` übernehmen. JWT-Prüfung im Gateway
   ausschalten: Die Funktion prüft JWT-Signatur, Ablauf und Issuer selbst über
   Supabase Auth und validiert bestehende Nutzer zusätzlich mit `getUser`.
   Ohne gültiges Nutzertoken ist keine Löschung möglich.
3. `SUPABASE_URL` und `SUPABASE_SERVICE_ROLE_KEY` sind Standard-Secrets der
   gehosteten Edge-Umgebung. Den Service-Key niemals in Flutter oder GitHub-Code eintragen.
4. Erst danach die App veröffentlichen.

## Ablauf und Grenzen

- Ziel-ID ausschließlich aus verifiziertem JWT; fremde IDs im Request werden ignoriert.
- Löschmarker sperrt neue Dokument- und Bildschreibzugriffe, auch von anderen Geräten.
- Bilder werden stapelweise über die Storage-API gelöscht, einschließlich Unterordnern.
- Anschließend löscht die Admin-API das Auth-Konto. Fremdschlüssel löschen Dokumente,
  alte Versionen und Löschmarker automatisch.
- Teilfehler behalten den Löschmarker. Ein erneuter Versuch setzt die Löschung fort.
  Abbruch kann bereits gelöschte Bilder nicht wiederherstellen.
- Erfolgreiche Cloud-Löschung wird lokal markiert. Abmeldung, lokale Kontosicherungen,
  alte Migrationskopien und zugeordnete app-eigene Bilddateien werden bereinigt.
  Andere gespeicherte Konten bleiben bestehen. Gemeinsam referenzierte Bilddateien
  werden für diese Konten erhalten. Externe Originale und Exporte werden nicht gelöscht.
- Danach bleibt die App auch nach Neustart pausiert. Erst „Neu als Gast starten“
  erzeugt wieder ein Konto. Während eines offenen Löschvorgangs sind Änderungen gesperrt.
- Lokale Kopien auf anderen Geräten sowie Anbieter-Backups und Logs werden nicht
  fern-gelöscht. Die jeweiligen Aufbewahrungsfristen gelten weiterhin.
- Bei abgelaufener/verlorener Sitzung während einer unvollständigen Löschung ist
  gegebenenfalls eine administrative Fortsetzung nötig. Niemals lokale Daten vor
  einer bestätigten Cloud-Löschung als erfolgreich gelöscht behandeln.

## Prüfung nach Einrichtung

Mit einem separaten Testkonto mehrere Bikes/Bilder und Versionen anlegen, Export
speichern, dann löschen. Auth-User, Dokumente, Historie und alle Bilder im UID-Ordner
müssen fehlen. App neu laden: keine automatische Gastanmeldung. Danach explizit
neu starten. Ebenfalls Fehler/Wiederholung und zwei parallel geöffnete Geräte testen.

Lokal werden die Flutter-Tests und die Handler-Tests mit
`node --test supabase/functions/delete-account/handler.test.mjs` ausgeführt.
Diese ersetzen keinen Integrationstest der Migration und Storage-Löschung in Supabase.
