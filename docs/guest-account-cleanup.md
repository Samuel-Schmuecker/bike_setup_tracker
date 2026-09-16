# Gastkonto nach Google-Anmeldung bereinigen

## Verhalten

- **Mit Google absichern:** gleiche Nutzer-ID, daher keine Gastkonto-Löschung.
- **Mit Google anmelden:** vor dem Wechsel Auswahl zwischen Übernahme als Kopien
  und ausdrücklich bestätigtem Verwerfen. Ein Export wird vorher angeboten.
- Vor Beginn wird der Gastbestand vollständig synchronisiert. Konflikte oder
  Offline-Zustand verhindern den Wechsel, damit keine unbekannten Cloud-Daten verloren gehen.
- Eine serverseitige Berechtigung mit sieben Tagen Gültigkeit wird unter der noch
  aktiven Gastsitzung erstellt. Sie enthält keine Google- oder Gast-Zugangstokens.
- Nach dem Google-Login werden neue IDs für übernommene Bikes und zugehörige Daten
  vergeben. Übernahme und Kontowechsel erfolgen lokal in einer Transaktion.
- Erst nach erfolgreichem Abgleich des Zielkontos werden Gastbilder, Gastkonto und
  dessen Daten und Versionen gelöscht. Lokale Gastarchive werden anschließend entfernt.
- Fehler oder Verbindungsabbrüche lassen den Vorgang für erneute Versuche erhalten;
  beim Neuladen werden keine doppelten Kopien angelegt. Die Kontoseite zeigt offene
  Bereinigungen mit einem Retry-Button. Auch automatische Synchronisierung versucht erneut.
- Wird das alte Gastkonto zwischenzeitlich geändert oder in ein registriertes Konto
  umgewandelt, verweigert der Server die Löschung. Der Gastbestand bleibt für eine
  manuelle Prüfung erhalten. Nach Ablauf der Berechtigung ist ebenfalls eine manuelle
  Klärung erforderlich. Das Zielkonto wird niemals anstelle des Gastkontos gelöscht.
- Abbruch oder fehlgeschlagene Google-Anmeldung löschen kein Konto.

## Aktivierung

1. Die Kontolöschung aus `docs/account-deletion-setup.md` muss eingerichtet sein.
2. `supabase/migrations/202609170001_guest_transfer.sql` im Supabase SQL Editor ausführen.
3. Die bestehende Edge Function `delete-account` mit **index.ts und handler.mjs**
   erneut deployen. Gateway-Konfiguration bleibt unverändert.
4. Erst danach die neue App-Version veröffentlichen.

Die nicht öffentlich lesbare Tabelle `guest_transfers` enthält zeitlich begrenzte
Berechtigungen, Nutzer-IDs und Revisionsnummern. Abgelaufene Einträge werden bei
der nächsten Vorbereitung eines Gastwechsels entfernt. Ohne weitere Nutzung können
sie administrativ mit `delete from public.guest_transfers where expires_at < now();`
bereinigt werden. Sie enthalten keine Bike-Inhalte oder Auth-Refresh-Tokens.

## Live-Test nach Deployment

Zwei eigene Testkonten nutzen: Gast mit Bild und ein bestehendes Google-Konto.
Übernahme prüfen (neue IDs, bestehende Google-Bikes erhalten, Bilder verfügbar),
anschließend Gast-ID in Auth, Tabellen und Storage prüfen. Verwerfen, OAuth-Abbruch,
Offline-Fehler und Neuladen während der Übernahme separat testen. Gastdaten während
des Logins in einem zweiten Browser ändern: Die Bereinigung muss blockieren.
Supabase-Migration und echte Storage-Löschung können lokale Mock-Tests nicht ersetzen.
