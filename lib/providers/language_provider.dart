// lib/providers/language_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'de'; // Standard ist Deutsch

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_lang') ?? 'de';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (_currentLanguage != langCode) {
      _currentLanguage = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_lang', langCode);
      notifyListeners();
    }
  }
}