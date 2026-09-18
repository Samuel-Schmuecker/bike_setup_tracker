# Texte und weitere Sprachen

Alle übersetzbaren App-Beschriftungen werden in
`lib/utils/translations.dart` gepflegt. Die Screens, Widgets und Touren verwenden
Sprachcodes und Übersetzungsschlüssel, keine Deutsch/Englisch-Abfragen.

## Eine Sprache hinzufügen

1. In `Translations.texts` den englischen Sprachblock kopieren und unter einem
   neuen Sprachcode ergänzen, beispielsweise `fr`.
2. Die Werte übersetzen; Schlüssel unverändert lassen. `languageName` enthält
   den Eigennamen der Sprache, beispielsweise `Français`.
3. Platzhalter wie `{error}`, `{count}` oder `{front}` unverändert übernehmen.
   In Tourtexten hebt `**Text**` wichtige Wörter hervor.
4. `flutter test test/translations_test.dart` ausführen. Der Test prüft gleiche
   Schlüssel und Platzhalter in allen Sprachen sowie verwendete Textschlüssel.

Die Sprachauswahl im Willkommen-Dialog und in den Einstellungen übernimmt neue
Sprachen automatisch aus dem Katalog. Unbekannte Sprachcodes bzw. fehlende Texte
fallen auf Englisch zurück.

## Texte im Code verwenden

```dart
Translations.get(languageCode, 'tourSetupParametersTitle');
Translations.format(languageCode, 'backupBikeCount', {'count': '$count'});
```

Neue Texte erhalten einen beschreibenden, von der Formulierung unabhängigen
Schlüssel und einen Eintrag in jedem Sprachblock. Themenpräfixe wie `tour`,
`account`, `backup`, `auth` und `range` helfen beim Auffinden. Gemeinsam verwendete
Aktionen wie `save` und `cancel` verwenden denselben Schlüssel.

Die sichtbaren Kategorienamen werden über `Translations.bikeCategory` übersetzt;
ihre gespeicherten IDs bleiben stabil. Eigene Bike-/Setup-Namen, eigene Felder,
Notizen und bereits gespeicherte Demo-Daten sind bearbeitbare Inhalte und werden
beim Sprachwechsel nicht verändert. Modell-/Markennamen, Einheiten, Dateinamen
und interne Diagnosemeldungen sind keine übersetzten UI-Beschriftungen.
