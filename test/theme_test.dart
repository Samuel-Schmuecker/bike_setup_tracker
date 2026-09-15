import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_setup_tracker/providers/theme_provider.dart';
import 'package:bike_setup_tracker/theme/app_theme.dart';

void main() {
  test('Colors survive reload and can be reset', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider(prefs);
    await provider.setBackground(Colors.white);
    await provider.setAccent(Colors.purple);
    final restored = ThemeProvider(prefs);
    expect(restored.background, Colors.white);
    expect(restored.accent.toARGB32(), Colors.purple.toARGB32());
    await restored.reset();
    final defaults = ThemeProvider(prefs);
    expect(defaults.background, ThemeProvider.defaultBackground);
    expect(defaults.accent.toARGB32(), ThemeProvider.defaultAccent.toARGB32());
  });

  test('Light and dark backgrounds receive readable text', () {
    for (final background in [Colors.white, Colors.black]) {
      final theme = AppTheme.build(background: background, accent: Colors.teal);
      final luminances = [
        background.computeLuminance(),
        theme.colorScheme.onSurface.computeLuminance(),
      ]..sort();
      expect(
        (luminances.last + 0.05) / (luminances.first + 0.05),
        greaterThanOrEqualTo(4.5),
      );
      expect(theme.scaffoldBackgroundColor, background);
    }
  });
}
