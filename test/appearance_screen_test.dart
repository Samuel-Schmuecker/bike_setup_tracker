import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_setup_tracker/providers/theme_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/settings/appearance_screen.dart';
import 'package:bike_setup_tracker/theme/app_theme.dart';

void main() {
  testWidgets(
    'Custom colors apply immediately, show a selected swatch and reject invalid input',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final theme = ThemeProvider(prefs);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: theme),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: Builder(
            builder: (context) {
              final colors = context.watch<ThemeProvider>();
              return MaterialApp(
                theme: AppTheme.build(
                  background: colors.background,
                  accent: colors.accent,
                ),
                home: const AppearanceScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final backgroundField = find.byType(TextFormField).first;
      await tester.enterText(backgroundField, ' #abcdef ');
      await tester.pumpAndSettle();
      expect(theme.background.toARGB32(), 0xFFABCDEF);
      expect(prefs.getInt('theme_background'), 0xFFABCDEF);
      expect(find.text('Farbe übernehmen'), findsNothing);
      final customSwatch = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Hintergrundfarbe #ABCDEF',
      );
      expect(customSwatch, findsOneWidget);
      expect(
        tester.widget<Semantics>(customSwatch).properties.selected,
        isTrue,
      );

      await tester.enterText(backgroundField, 'invalid');
      await tester.pumpAndSettle();
      expect(theme.background.toARGB32(), 0xFFABCDEF);
      expect(
        find.text('Bitte 6 Hex-Zeichen eingeben, z. B. 009688.'),
        findsOneWidget,
      );

      final accentField = find.byType(TextFormField).last;
      await tester.ensureVisible(accentField);
      await tester.enterText(accentField, '123456');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(theme.accent.toARGB32(), 0xFF123456);
      expect(prefs.getInt('theme_accent'), 0xFF123456);
      expect(tester.takeException(), isNull);
    },
  );
}
