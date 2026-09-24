# Android-/iOS-Release-Prüfung

Stand: 24. September 2026. Ein erfolgreicher Build ist keine vollständige
Geräteabnahme und keine Store-Freigabe.

## Korrigiert

- iOS: `NSPhotoLibraryUsageDescription` ergänzt. Die App wählt Bilder aus der
  Mediathek; sie bietet keine Kameraaufnahme an. Eine Kameraberechtigung ist für
  diesen Ablauf nicht erforderlich. Bei einer späteren Kamerafunktion muss
  `NSCameraUsageDescription` ergänzt werden.
- Fotoauswahl: `requestFullMetadata: false`, Fehleranzeige auf Deutsch/Englisch
  und Schutz vor UI-Updates nach dem Verlassen der Seite.
- iOS: CocoaPods-Podfile für iOS 13 und die zugehörigen xcconfig-Includes ergänzt.
  Die tatsächlich installierten iOS-Plugins wurden auf Mindestversionen geprüft.
- Android: Ziel-API von 34 auf 36 angehoben; Mindestversion bleibt API 24
  (Android 7.0). AGP von 8.11.1 auf 8.12.1 angehoben, passend zu `share_plus`.
- Android: Release verwendet keine Debug-Signatur mehr. Optional wird
  `android/key.properties` geladen; ohne diese Datei ist das Ergebnis unsigniert.
  `android/key.properties.example` zeigt das Format. Schlüssel bleiben außerhalb
  des Repositorys; die vorhandenen Git-Ignore-Regeln schützen diese Dateien.
- Kotlin: inkrementelle Kompilierung deaktiviert, weil der tatsächliche Build
  Cachefehler bei Pluginpfaden auf C: und dem Projekt auf D: zeigte.
- Produktionsparameter aus dem bestehenden Main-Web-Workflow in
  `config/production.json` übernommen. Enthalten ist ausschließlich der öffentliche
  Publishable Key, kein administrativer Schlüssel.
- Auf diesem Rechner die fehlenden offiziellen Android Command-line Tools
  (15859902) ergänzt; Download gegen Googles SHA-256 geprüft. Vorher brach
  Flutters AAB-Abschlussprüfung wegen des fehlenden `apkanalyzer` mit einer
  irreführenden Meldung über native Debug-Symbole ab.

## Nachweise

- Flutter 3.38.9 / Dart 3.10.8.
- Vollständige Testsuite: **125 Tests erfolgreich**, einschließlich vier neuer
  Regressionstests für verweigerte Fotoauswahl und Navigation während des Dialogs.
- Statische Analyse: keine Fehler oder Warnungen, 58 bestehende Info-Hinweise
  (Stil, veraltete APIs). `flutter analyze --no-pub --no-fatal-infos` besteht.
- Android-Debug-APK erfolgreich gebaut.
- Android-Produktions-AAB nach Ergänzung der SDK-Werkzeuge erfolgreich mit
  `flutter build appbundle --release --no-pub --dart-define-from-file=config/production.json`
  gebaut (48,8 MB). Es ist **unsigniert** und wurde nicht hochgeladen.
- Manifest im gebauten APK geprüft: minSdk 24, targetSdk/compileSdk 36.
  Die ARM64-Bibliotheken im Produktions-AAB zeigen LOAD-Segment-Ausrichtungen
  von 16 oder 64 KB. Das prüft die ELF-Ausrichtung, ersetzt aber keinen Test auf
  einem Gerät mit 16-KB-Speicherseiten und keine Prüfung des Store-generierten APK.
- Debug-APK im vorhandenen Android-Emulator API 36.1 installiert: App-Prozess
  läuft, Begrüßungsdialog mit Sprachauswahl, Datenschutzerklärung und Startknopf
  erscheint. Keine AndroidRuntime-/Flutter-Fehler im abgefragten Startlog.
  Die Start-Warteabfrage meldete unter hoher Rechnerlast zunächst einen Timeout;
  anschließend wurde die Oberfläche über die UI-Hierarchie nachgewiesen.
  Das ist nur ein Starttest, keine vollständige Funktions- oder Performanceabnahme.
- iOS-Info.plist ist gültiges XML. Ein iOS-Build wurde auf diesem Windows-Rechner
  nicht ausgeführt; dafür sind macOS und Xcode erforderlich.
- Produktions-Auth-Einstellungen am Prüftag nur lesend abgefragt: Google und
  anonyme Anmeldung sind aktiv. Das aktualisiert den historischen Hinweis vom
  19. September in `environments.md`, prüft aber weder RLS noch OAuth-Rückleitungen.
- Im Code vorhanden: Android-INTERNET-Berechtigung, mobile OAuth-Rückleitung in
  Android und iOS, persistente lokale Datenbank, Backup-Import mit iOS-Dateityp,
  mobile Dateifreigabe mit iPad-Anker und Kontolöschungsablauf.

## Vor Veröffentlichung noch erforderlich

1. **Eigene App-IDs und Signierung:** Android verwendet noch
   `com.example.bike_setup_tracker`, iOS `com.example.bikeSetupTracker`.
   Endgültige IDs festlegen, bevor echte Installationen verteilt werden.
   Bei Android auch Namespace und MainActivity-Package/Pfad anpassen;
   bei iOS Runner/Tests und Developer-Team konfigurieren. Upload-Keystore,
   Apple-Zertifikate und Provisioning fehlen hier. Keine Schlüssel wurden erzeugt.
2. **iOS-Anmeldung:** Die reguläre Anmeldung ist Google-basiert. Apple verlangt
   nach Richtlinie 4.8 normalerweise eine gleichwertige Alternative mit privater
   E-Mail-Adresse und begrenzter Datennutzung, beispielsweise Sign in with Apple.
   Diese Integration einschließlich Supabase-Provider, Kontoverknüpfung und
   Löschung fehlt noch. Ein Gastmodus allein belegt die Erfüllung nicht.
3. **Backend-Rückleitung:** `bikesetuptracker://auth/callback` im gewünschten
   Supabase-Projekt erlauben. Google-Anmeldung und Gastübernahme auf einem echten
   Android-Gerät und iPhone testen, auch bei zuvor geschlossener App.
   Die lokalen URI-Handler sind vorhanden; die Dashboard-Allowlist wurde nicht
   eingesehen. Dev und Produktion verwenden dieselbe App-ID und dasselbe Scheme;
   für parallele Installationen sind getrennte Varianten nötig.
4. **Bilder und Prozessneustart:** Android kann die App während der Fotoauswahl
   beenden. `ImagePicker.retrieveLostData()` ist noch nicht integriert; in diesem
   Fall kann eine gerade laufende Auswahl verloren gehen und muss wiederholt
   werden. Die Zuordnung zu einem ungespeicherten Bike braucht dafür einen
   persistierten Entwurf. Bereits gespeicherte lokale Fotos verwenden absolute
   Dokumentenpfade: Wiederherstellung/Containerwechsel auf iOS gesondert prüfen
   und vor breiter Verteilung auf stabile relative Referenzen migrieren.
5. **Geräteabnahme:** Fotos (JPEG/HEIC), Abbrechen/Verweigern, Neustart offline,
   Bearbeiten/Löschen, Google-Rückkehr, Sync mit zwei Geräten, Konflikte,
   Backup exportieren/importieren und Kontolöschung vollständig durchspielen.
   Android 7 und aktuelle Version, Gesten-/Dreiknopfnavigation, große Schrift,
   Tastatur sowie iPhone und iPad abdecken. API 36 verändert unter anderem das
   Verhalten bei Bildschirmrändern; Layout deshalb auf Geräten prüfen.
6. **Store-Unterlagen:** Datenschutz-/Datensicherheitsangaben müssen die echte
   Supabase-Nutzung, Fotos und Kontodaten abbilden. iOS-Archiv auf Privacy-Manifeste,
   Icons und Export-Compliance prüfen. Screenshots, Support-/Datenschutz-URL,
   Kontolöschungsinformationen, Altersfreigabe und Review-Zugang vorbereiten.
7. **Build-Rechner:** Die Command-line Tools sind jetzt installiert.
   `flutter doctor` meldet noch nicht akzeptierte Android-Lizenzen;
   mit `flutter doctor --android-licenses` prüfen und akzeptieren.
   Für den App Store Xcode 26 oder neuer
   mit iOS-26-SDK verwenden; die App kann weiterhin iOS 13 als Minimum haben.

## Build-Befehle

Ohne Defines startet das Projekt in **Dev**, auch bei `--release`.
Aus dem Projektverzeichnis, mit Flutter im PATH:

```sh
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build appbundle --release --dart-define-from-file=config/production.json
```

Das AAB liegt unter `build/app/outputs/bundle/release/app-release.aab`.
Es ist nur mit eingerichtetem Upload-Key für die Store-Abgabe vorgesehen.

Auf macOS zunächst `flutter pub get`, anschließend `pod install` im Ordner
`ios` ausführen. `ios/Runner.xcworkspace` in Xcode öffnen, Bundle-ID und Team
einrichten. Danach vom Projektverzeichnis:

```sh
flutter build ios --release --no-codesign --dart-define-from-file=config/production.json
flutter build ipa --release --dart-define-from-file=config/production.json
```

Den erzeugten Podfile.lock nach dem ersten erfolgreichen macOS-Build prüfen und
für reproduzierbare Builds versionieren. Alle Geräteprüfungen zunächst mit Dev
und eigenen Testkonten durchführen; Produktionsdaten nicht als Testdaten löschen.

## Quellen

- [image_picker: iOS-Konfiguration und Android-Prozessverlust](https://pub.dev/packages/image_picker)
- [share_plus: Build-Anforderungen](https://pub.dev/packages/share_plus)
- [Google Play: Ziel-API 36 ab August 2026](https://support.google.com/googleplay/android-developer/answer/11926878?hl=de)
- [Apple: Anmeldung, Richtlinie 4.8](https://developer.apple.com/app-store/review/guidelines/#login-services)
- [Apple: aktuelle SDK-/Einreichungsanforderungen](https://developer.apple.com/news/upcoming-requirements/)
