# Google-Anmeldung aktivieren

Für diesen Einstieg brauchst du weder eine eigene Domain noch SMTP.
Die Anmeldung läuft über Google und die vorhandene Supabase-Projektadresse.
Google Client Secret nur in Supabase eintragen, niemals in die Flutter-App.

## 1. Google-Projekt und Zustimmung einrichten

1. https://console.cloud.google.com/ öffnen und ein Projekt anlegen oder auswählen,
   beispielsweise **Bike Setup Tracker**.
2. **Google Auth Platform** öffnen. Falls noch nicht eingerichtet, **Get started**
   wählen. App-Name, Support-E-Mail und Entwickler-Kontaktadresse hinterlegen.
3. Zielgruppe **External / Extern** auswählen. Für den Anfang im Testmodus bleiben
   und unter **Audience → Test users** die Google-Adressen deiner Tester hinzufügen.
4. Nur die Anmeldedaten `openid`, E-Mail und Profil verwenden. Keine Drive-,
   Kalender- oder sonstigen zusätzlichen Berechtigungen anfordern.

## 2. OAuth-Client erstellen

Unter **Clients → Create client**:

- Typ: **Web application**. Auch die native App verwendet in dieser Umsetzung
  den Browser und Supabase als Vermittler.
- Name: beispielsweise **Bike Tracker Supabase**.
- Unter **Authorized redirect URIs** exakt eintragen:

```text
https://dcrkfiooddkbzljibomo.supabase.co/auth/v1/callback
```

- Für lokale Web-Tests als **Authorized JavaScript origin** eintragen:

```text
http://localhost:5173
```

Client erstellen. **Client ID** und **Client secret** werden im nächsten Schritt
direkt in Supabase eingetragen. Das Secret nicht hier im Chat veröffentlichen.

## 3. Google in Supabase aktivieren

1. **Authentication → Sign In / Providers → Google** öffnen.
2. Google aktivieren, Client ID und Client Secret aus Schritt 2 eintragen, speichern.
3. Unter den Auth-Einstellungen **Allow manual linking / Manual identity linking**
   einschalten. Das ist für **Mit Google absichern** erforderlich, damit die
   anonyme Nutzer-ID und ihre Daten erhalten bleiben.
4. Anonyme Anmeldung eingeschaltet lassen.

## 4. Rückkehr zur App erlauben

In **Authentication → URL Configuration → Redirect URLs**:

```text
http://localhost:5173/
bikesetuptracker://auth/callback
http://127.0.0.1:43827/auth/callback**
```

- Erste Adresse: Web-Test. App mit `flutter run -d chrome --web-port 5173` starten.
  Wichtig: immer denselben Host und Port verwenden, damit Browser-Daten und der
  Sicherheitsnachweis der begonnenen Anmeldung wiedergefunden werden.
- Zweite Adresse: Android/iOS. Die Rückleitung ist im App-Projekt registriert.
- Dritte Adresse: Windows/macOS/Linux. Die App öffnet für maximal 15 Minuten
  einen lokalen Listener, ausschließlich auf `127.0.0.1`. Ein einmaliger
  Versuchscode in der Rückleitung wird zusätzlich zu PKCE geprüft. Bei belegtem
  Port meldet die Anmeldung einen Fehler; keine Firewall-Öffnung nach außen nötig.

Die **Site URL** für diesen Web-Test auf `http://localhost:5173/` setzen.
Bei einer späteren Veröffentlichung die tatsächliche Web-Adresse ergänzen
und als Site URL setzen. Die App sendet ihre konkrete Rückleitungsadresse mit;
eine fehlende Freigabe kann trotzdem wieder zur falschen Site URL führen.

Die Google-Redirect-URI aus Schritt 2 und die App-Rückleitungen aus Schritt 4
haben unterschiedliche Aufgaben und müssen in den jeweiligen Diensten stehen.

## 5. Prüfen

App wegen der nativen Rückleitung vollständig neu bauen/starten.

1. Mit vorhandenem Gastbestand **Konto & Datensicherung → Mit Google absichern**
   wählen. Im Browser Google-Konto auswählen und zur App zurückkehren.
2. In Supabase Authentication prüfen: dieselbe Nutzer-ID, jetzt mit Google.
   Die bestehenden Bikes und Bilder müssen erhalten bleiben.
3. In einem zweiten Browserprofil/einem zweiten Gerät **Mit Google anmelden**
   wählen. Mit demselben Google-Konto anmelden, Daten und Bilder prüfen.
4. Wenn auf diesem zweiten Gerät schon Gastdaten vorhanden waren, liegen diese
   unter **Lokale Sicherungen** zur ausdrücklichen Übernahme als Kopien bereit.
5. Abbruch, Browser-Zurück und Neuladen während der Anmeldung testen.
6. Wird bei der Verknüpfung ein bereits zu einem anderen Account gehörendes
   Google-Konto gewählt, Anmeldung abbrechen und **Mit Google anmelden** verwenden.
   Die App hängt die Gastdaten niemals ungeprüft an eine andere Identität um.

## Typische Meldungen

- `redirect_uri_mismatch`: Google muss die Supabase-Callback-Adresse aus Schritt 2 kennen.
- Rückkehr zu `localhost:3000`: Supabase-Rückleitungen und Site URL aus Schritt 4 prüfen.
- Provider deaktiviert: Google in Supabase aktivieren und Zugangsdaten speichern.
- Manual linking deaktiviert: Schritt 3.3 aktivieren.
- Zugriff verweigert im Testmodus: verwendete Google-Adresse als Testnutzer hinzufügen.
- Anmeldung abgelaufen: in der App abbrechen und erneut starten.

Die E-Mail-Code-Oberfläche wurde durch Google ersetzt. Vorhandene
E-Mail-Accounts können, solange sie angemeldet sind, Google verknüpfen.
E-Mail-API-Methoden bleiben zur Kompatibilität erhalten, sind aber kein
öffentlicher Registrierungsweg dieser Version.

Die Tests simulieren Supabase-Antworten. Echte Google-Anmeldung kann erst nach
Konfiguration der Client-Zugangsdaten geprüft werden. Android/iOS/macOS sind
hier nicht auf echten Geräten geprüft. Vor öffentlichem Betrieb Google-Zielgruppe
und gegebenenfalls erforderliche Branding-Prüfung abschließen; Testmodus ist
kein öffentlicher Release.

Quellen:
- https://supabase.com/docs/guides/auth/social-login/auth-google
- https://supabase.com/docs/guides/auth/auth-identity-linking
- https://supabase.com/docs/guides/auth/redirect-urls
