// lib/utils/suspension_dictionary.dart

import 'translations.dart';

class SuspensionDictionary {
  static const Map<String, String> _descriptionKeys = {
    'LSC': 'descriptionLsc',
    'HSC': 'descriptionHsc',
    'LSR': 'descriptionLsr',
    'HSR': 'descriptionHsr',
    'PSI': 'descriptionAirPressure',
    'AIR': 'descriptionAirPressure',
    'MAIN': 'descriptionAirPressure',
    'TOKENS': 'descriptionTokens',
    'HBO': 'descriptionHbo',
    'OTT': 'descriptionOtt',
    'SPRING RATE': 'descriptionSpringRate',
    'PRELOAD': 'descriptionPreload',
  };

  // NEU: Nimmt jetzt auch den languageCode (z.B. 'de' oder 'en') entgegen
  static String? getDescription(String title, String languageCode) {
    final titleUpper = title.toUpperCase();
    for (final entry in _descriptionKeys.entries) {
      if (titleUpper.contains(entry.key)) {
        return Translations.get(languageCode, entry.value);
      }
    }
    return null;
  }
}
