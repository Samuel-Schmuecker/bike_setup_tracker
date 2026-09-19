# Login- und Bildbereinigung

## Supabase aktivieren

Im aktuellen Projekt ist die Funktion unter dem URL-Slug `super-function`
bereitgestellt; der Dashboard-Anzeigename lautet `cleanup-bike-images`.
Die App verwendet deshalb standardmäßig `super-function`. Entscheidend ist
die tatsächliche URL, nicht der Anzeigename. Für eine Bereitstellung unter
`cleanup-bike-images` die App mit
`--dart-define=SUPABASE_IMAGE_CLEANUP_FUNCTION=cleanup-bike-images` bauen.
Die folgenden Schritte beschreiben eine neue Bereitstellung unter diesem Namen.

Vor Veröffentlichung der aktualisierten App:

1. Die bisherigen drei Migrationen müssen eingerichtet sein. Danach
   `supabase/migrations/202609180001_bike_image_cleanup.sql` im Supabase SQL Editor
   ausführen.
2. Die Edge Function bereitstellen:

   ```sh
   supabase functions deploy cleanup-bike-images --project-ref dcrkfiooddkbzljibomo --no-verify-jwt
   ```

   Alternativ im Dashboard die Funktion `cleanup-bike-images` mit den Dateien
   `index.ts` und `handler.mjs` aus `supabase/functions/cleanup-bike-images/`
   anlegen. Gateway-JWT-Prüfung ausschalten; der Handler prüft Signatur, Issuer,
   Ablauf und den aktuellen Nutzer selbst. Die standardmäßigen Edge-Secrets
   `SUPABASE_URL` und `SUPABASE_SERVICE_ROLE_KEY` werden ausschließlich dort verwendet.
3. Danach die aktualisierte App verteilen. Ohne Funktion bleibt die App lokal
   nutzbar und synchronisiert Dokumente, meldet aber die ausstehende Bildbereinigung.

Diese Einrichtung wurde im Repository vorbereitet; sie ist kein Nachweis eines
Deployments in das gehostete Supabase-Projekt.

## Verhalten

- Beim Gastimport wird nur das vollständig unveränderte mitgelieferte Demo-Rad
  ausgelassen. Änderungen an Setups, Fotos, Notizen oder am Rad bleiben erhalten.
  Datumswerte der automatisch erzeugten Demo-Historie werden beim Vergleich ignoriert.
- Fehlende oder beschädigte Cloud-Fotos verhindern das Laden der Räder und Setups
  nicht mehr. Die Bildreferenz bleibt lokal erhalten, ein Ersatzbild wird angezeigt,
  und der nächste Sync versucht den Download erneut. Ein Export mit noch fehlendem
  Foto meldet einen Fehler, statt unbemerkt eine unvollständige Sicherung zu erzeugen.
- Nur explizite Cloud-Löschmarkierungen dürfen ein synchronisiertes lokales Rad
  entfernen. Eine unerwartet fehlende Datenbankzeile löscht keine lokalen Daten.
- Nach bestätigter Cloud-Löschung eines Rads werden dessen historische Cloud-Foto-
  Referenzen entfernt. Rad und Setups bleiben aus der Cloud-Historie ohne diese Fotos
  wiederherstellbar. Lokale Sicherungen und vom Nutzer exportierte Dateien bleiben bestehen.
- Fotos, die noch zu anderen Rädern oder deren Wiederherstellungsversionen gehören,
  bleiben erhalten. Unreferenzierte Uploads, beispielsweise nach abgebrochenem Speichern,
  werden nach einer Stunde beim nächsten abgeschlossenen Dokument-Sync bereinigt.
  Bei geschlossener App gibt es keinen zeitgesteuerten Bereinigungsdienst.
- Löschungen erfolgen über die Storage-API, nicht durch SQL-Löschen von Dateimetadaten.
  Siehe [Supabase: Delete Objects](https://supabase.com/docs/guides/storage/management/delete-objects).
- Die Datenbank markiert Dateinamen vor der Löschung dauerhaft als ausgemustert und
  verhindert neue Referenzen auf diese Dateien. Parallel laufende Geräte und wiederholte
  Löschversuche können dadurch kein neu hochgeladenes Foto entfernen. Neue Dateien
  liegen unter `UID/Zufalls-ID/Inhalts-Hash`; bisherige `UID/Inhalts-Hash`-Dateien bleiben lesbar.
- Fehlgeschlagene Bereinigungen bleiben serverseitig offen und werden beim nächsten
  Sync erneut versucht, auch nach einem App-Neustart. Ohne Netz wird zuerst lokal
  gelöscht; die Storage-Löschung folgt erst nach erfolgreicher Synchronisierung.

## Tests

```sh
flutter test test/cloud_sync_test.dart test/guest_import_test.dart test/translations_test.dart
node --test supabase/functions/cleanup-bike-images/handler.test.mjs supabase/functions/delete-account/handler.test.mjs
npm install --prefix .tmp/image-cleanup-tests --cache .tmp/npm-cache --no-save --ignore-scripts @electric-sql/pglite@0.5.8
node --test supabase/tests/bike_image_cleanup.test.mjs
```

Die SQL-Tests führen alle Migrationen in einem isolierten PostgreSQL-WASM-System
aus und prüfen Referenzen, geteilte Fotos, Wiederholungen, Upload-Schutz und Rechte.
Storage-API und Flutter-Netzwerkzugriffe werden in den jeweiligen Tests simuliert.
Ein abschließender Test gegen das gehostete Projekt bleibt nach Deployment nötig.
