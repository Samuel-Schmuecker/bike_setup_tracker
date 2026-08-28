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
}
