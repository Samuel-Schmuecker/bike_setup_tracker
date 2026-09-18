import 'package:bike_setup_tracker/models/bike_parameters.dart';
import 'package:bike_setup_tracker/models/setting_range.dart';
import 'package:bike_setup_tracker/models/trail_setup.dart';
import 'package:bike_setup_tracker/widgets/setting_range_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/bike_detail/setup_detail_screen.dart';
import 'field_order_test.dart' show loadProvider;

void main() {
  testWidgets('setup steps log changes and inherits updated bike limits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await loadProvider();
    provider.updateBikeParameters(
      'a',
      BikeParameters(
        ranges: {
          'forkLsc': const SettingRange(min: 0, max: 10, reference: 'closed'),
        },
      ),
    );
    provider.updateSetup(
      'a',
      provider.bikes.first.setups.first.copyWith(forkLsc: 4),
    );
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
    expect(find.text('4'), findsOneWidget);
    final tile = find.byKey(const ValueKey('forkLsc'));
    expect(tester.getSize(tile), const Size(85, 85));
    expect(
      find.descendant(of: tile, matching: find.byIcon(Icons.add)),
      findsNothing,
    );
    expect(find.text('ab geschlossen'), findsNothing);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byIcon(Icons.add),
      ),
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(provider.bikes.first.setups.first.forkLsc, 5);
    expect(
      provider.bikes.first.setups.first.logs.single.parameters,
      contains('4 ➔ 5'),
    );
    provider.updateBikeParameters(
      'a',
      BikeParameters(ranges: {'forkLsc': const SettingRange(min: 0, max: 3)}),
    );
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
    expect(tester.getSize(tile), const Size(85, 85));
    expect(find.descendant(of: tile, matching: find.text('0')), findsOneWidget);
    expect(find.descendant(of: tile, matching: find.text('3')), findsOneWidget);
    final marker = tester.widget<Align>(
      find.byKey(const ValueKey('forkLsc-range-position')),
    );
    expect(marker.alignment, Alignment.centerRight);
    expect(provider.bikes.first.setups.first.forkLsc, 5);
    expect(tester.takeException(), isNull);
  });
  test(
    'ranges round trip, preserve old values and support explicit removal',
    () {
      final parameters = BikeParameters(
        ranges: {
          'forkLsc': const SettingRange(min: 0, max: 10, reference: 'closed'),
          'shockPreload': const SettingRange(min: 0, max: 3, step: 0.5),
          'custom:test': null,
        },
      );
      final setup = TrailSetup(
        id: 's',
        name: 'Old setup',
        forkLsc: -12,
        customParameters: parameters,
      );
      final restored = TrailSetup.fromMap(setup.toMap());
      expect(restored.forkLsc, -12);
      expect(restored.customParameters!.ranges['forkLsc']!.reference, 'closed');
      expect(
        restored.customParameters!.copyWith().ranges['shockPreload']!.step,
        0.5,
      );
      expect(
        restored.customParameters!.ranges.containsKey('custom:test'),
        isTrue,
      );
      expect(restored.customParameters!.ranges['custom:test'], isNull);
      expect(BikeParameters.fromMap({}).ranges, isEmpty);
      expect(SettingRange.fromMap({'min': 10, 'max': 0}), isNull);
    },
  );

  test('decimal stepping is precise, bounded and initializes at minimum', () {
    const range = SettingRange(min: 0, max: 3, step: 0.1);
    expect(range.next(0.2, 1), 0.3);
    expect(range.next(3, 1), 3);
    expect(range.next(-10, 1), 0);
    expect(range.next(null, -1), 0);
    expect(SettingRange.format(0), '0');
    expect(SettingRange.format(10), '10');
  });

  testWidgets('editor validates boundaries and accepts comma decimal steps', (
    tester,
  ) async {
    SettingRange? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => SettingRangeEditor(
                  title: 'Vorspannung',
                  unit: 'Umdr.',
                  languageCode: 'de',
                  onSave: (value) => saved = value,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gültige Grenzen'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '3');
    await tester.enterText(find.byType(TextField).at(2), '0,5');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(saved!.step, 0.5);
    expect(saved!.max, 3);
  });

  testWidgets('compact range warns about preserved out of range value', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 126,
            child: SettingRangeScale(
              range: SettingRange(min: 0, max: 10, reference: 'closed'),
              value: -12,
              languageCode: 'de',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Außerhalb des Bereichs'), findsOneWidget);
    expect(find.text('ab geschlossen'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
