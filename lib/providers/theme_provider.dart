import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._preferences) {
    _background = _readColor('theme_background', defaultBackground);
    _accent = _readColor('theme_accent', defaultAccent);
  }

  static const defaultBackground = Color(0xFF101D1B);
  static const defaultAccent = Colors.teal;
  final SharedPreferences _preferences;
  late Color _background;
  late Color _accent;

  Color get background => _background;
  Color get accent => _accent;

  Color _readColor(String key, Color fallback) {
    final value = _preferences.get(key);
    return value is int && value >= 0 && value <= 0xFFFFFFFF
        ? Color(value).withValues(alpha: 1)
        : fallback;
  }

  Future<void> setBackground(Color color) async {
    _background = color.withValues(alpha: 1);
    notifyListeners();
    await _preferences.setInt('theme_background', _background.toARGB32());
  }

  Future<void> setAccent(Color color) async {
    _accent = color.withValues(alpha: 1);
    notifyListeners();
    await _preferences.setInt('theme_accent', _accent.toARGB32());
  }

  Future<void> reset() async {
    await setBackground(defaultBackground);
    await setAccent(defaultAccent);
  }
}
