import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bike_setup_tracker/models/trail_setup.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/bike_detail/setup_detail_screen.dart';
import 'field_order_test.dart' show loadProvider;

void main() {
  testWidgets(
    'history deletion requires confirmation and persists only for this setup',
    (tester) async {
      final provider = await loadProvider();
      final log = SetupLog(
        parameters: 'Pressure changed',
        note: '',
        timestamp: DateTime(2026, 9, 11),
      );
      for (final setup in provider.bikes.first.setups) {
        provider.updateSetup('a', setup.copyWith(logs: [log]));
      }
      final original = provider.bikes.first.setups.first.toMap();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BikeProvider>.value(value: provider),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const SetupDetailScreen(bikeId: 'a', setupId: 'a-0'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final trash = find.byIcon(Icons.delete_outline);
      await tester.scrollUntilVisible(
        trash,
        300,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(trash);
      await tester.pumpAndSettle();
      expect(find.text('Änderungsverlauf löschen?'), findsOneWidget);
      expect(provider.bikes.first.setups.first.logs, hasLength(1));
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(provider.bikes.first.setups.first.logs, hasLength(1));

      await tester.tap(trash);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      expect(provider.bikes.first.setups.first.toMap(), {
        ...original,
        'logs': [],
      });
      expect(provider.bikes.first.setups[1].logs, hasLength(1));
      expect(
        find.text('Bisher keine Anpassungen vorgenommen.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.delete_outline), findsNothing);
      await tester.runAsync(() async {
        await provider.saveToDevice();
        final reloaded = BikeProvider();
        await reloaded.loadFromDevice();
        expect(reloaded.bikes.first.setups.first.logs, isEmpty);
        expect(reloaded.bikes.first.setups[1].logs, hasLength(1));
        reloaded.dispose();
      });
      expect(tester.takeException(), isNull);
    },
  );
}
