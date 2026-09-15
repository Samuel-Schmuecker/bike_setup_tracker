// Required by newer Flutter versions; older SDKs export the builder via Material.
// ignore: unused_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Derives readable text and component colors from the user's two base colors.
class AppTheme {
  static ThemeData build({required Color background, required Color accent}) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    final generated = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    final scheme = generated.copyWith(
      surface: background,
      onSurface: brightness == Brightness.dark
          ? const Color(0xFFF5F5F5)
          : const Color(0xFF171717),
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: kIsWeb
              ? const FadeUpwardsPageTransitionsBuilder()
              : const CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
