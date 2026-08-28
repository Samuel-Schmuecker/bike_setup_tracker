// lib/providers/language_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/translations.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'de'; // Standard ist Deutsch

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('app_lang');
    if (savedLanguage != null &&
        Translations.supportedLanguageCodes.contains(savedLanguage)) {
      _currentLanguage = savedLanguage;
    }
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (!Translations.supportedLanguageCodes.contains(langCode)) {
      return;
    }
    if (_currentLanguage != langCode) {
      _currentLanguage = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_lang', langCode);
      notifyListeners();
    }
  }
}
