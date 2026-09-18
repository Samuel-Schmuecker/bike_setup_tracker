import 'dart:io';

import 'package:bike_setup_tracker/utils/translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all supported languages expose the same translation keys', () {
    final languages = Translations.supportedLanguageCodes;
    expect(languages, isNotEmpty);

    final referenceKeys = Translations.texts[languages.first]!.keys.toSet();
    for (final language in languages.skip(1)) {
      expect(
        Translations.texts[language]!.keys.toSet(),
        referenceKeys,
        reason: 'Translation keys differ for $language',
      );
    }
  });

  test('translation placeholders are replaced', () {
    expect(
      Translations.format('en', 'categoryNotesHint', {'category': 'Geometry'}),
      'Notes about Geometry …',
    );
  });

  test('all translations preserve the same named placeholders', () {
    final placeholder = RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}');
    Set<String> names(String text) =>
        placeholder.allMatches(text).map((match) => match.group(1)!).toSet();
    for (final entry in Translations.texts['en']!.entries) {
      for (final language in Translations.supportedLanguageCodes) {
        expect(
          names(Translations.get(language, entry.key)),
          names(entry.value),
          reason: 'Placeholder mismatch: $language / ${entry.key}',
        );
      }
    }
  });

  test('literal translation references exist in the catalog', () {
    final reference = RegExp(
      r"Translations\.(?:get|format)\(\s*[^,]+,\s*'([^']+)'",
    );
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final match in reference.allMatches(file.readAsStringSync())) {
        final key = match.group(1)!;
        expect(
          Translations.texts['en']!.containsKey(key),
          isTrue,
          reason: 'Missing translation $key in ${file.path}',
        );
      }
    }
  });

  test('language pickers use native names from the catalog', () {
    for (final code in Translations.supportedLanguageCodes) {
      expect(Translations.texts[code]!['languageName'], isNotEmpty);
      expect(
        Translations.languageName(code),
        Translations.texts[code]!['languageName'],
      );
    }
    expect(Translations.languageName('unknown'), 'unknown');
  });

  test('new UI messages fall back to English and format dynamic values', () {
    expect(
      Translations.get('unknown', 'tourSetupParametersTitle'),
      'Parameters per setup',
    );
    expect(
      Translations.format('en', 'accountOperationError', {'error': 'offline'}),
      'The operation did not complete. Please check your connection and entries. Details: offline',
    );
    expect(
      Translations.bikeCategory('en', 'Custom category'),
      'Custom category',
    );
  });
}
