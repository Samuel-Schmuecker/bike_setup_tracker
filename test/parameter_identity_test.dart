import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/bike_detail/setup_configurator_screen.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_setup_tracker/models/bike_parameters.dart';
import 'package:bike_setup_tracker/models/setting_range.dart';
import 'package:bike_setup_tracker/models/trail_setup.dart';
import 'package:bike_setup_tracker/utils/setup_comparison.dart';
import 'package:flutter_test/flutter_test.dart';
import 'field_order_test.dart' show fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'unit picker offers suitable presets and preserves custom units',
    (tester) async {
      final bike = fixture(
        'b',
        setups: 1,
      ).copyWith(availableParameters: BikeParameters(forkHsc: true));
      SharedPreferences.setMockInitialValues({
        'bikes_data': jsonEncode([bike.toMap()]),
        'app_lang': 'de',
        'hasSeenConfiguratorTour': true,
      });
      final provider = BikeProvider();
      await tester.runAsync(() => provider.ready);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: MaterialApp(
            home: SetupConfiguratorScreen(bikeId: 'b', isEditing: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> openUnit(Finder tile) async {
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: tile, matching: find.byType(IconButton)),
        );
        await tester.pumpAndSettle();
      }

      final hsc = find.widgetWithText(SwitchListTile, 'HSC').first;
      await openUnit(hsc);
      final options = tester
          .widget<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          )
          .items!;
      expect(options.map((item) => item.value), contains('Klicks'));
      expect(options.map((item) => item.value), isNot(contains('Umdr.')));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eigene Einheit').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Speichern'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), '  Stufen  ');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      await openUnit(hsc);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Stufen',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      await openUnit(find.byType(SwitchListTile).first);
      final pressureOptions = tester
          .widget<DropdownButton<String>>(
            find.byType(DropdownButton<String>),
          )
          .items!;
      expect(
        pressureOptions.map((item) => item.value),
        containsAll(['bar', 'PSI', '__custom_unit__']),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('bar').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Änderungen speichern'));
      await tester.tap(find.text('Änderungen speichern'));
      await tester.pumpAndSettle();
      expect(
        provider.bikes.single.availableParameters!.unitOverrides,
        containsPair('forkHsc', 'Stufen'),
      );
      expect(
        provider.bikes.single.availableParameters!.unitOverrides,
        containsPair('forkPsi', 'bar'),
      );
      final saved = provider.bikes.single;
      final rows = buildSetupComparison(
        saved,
        saved.setups.first,
        saved.setups.first,
        'de',
      );
      expect(rows.firstWhere((row) => row.id == 'forkHsc').a.unit, 'Stufen');
      expect(rows.firstWhere((row) => row.id == 'forkPsi').a.unit, 'bar');
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => provider.saveToDevice());
      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    },
  );
  testWidgets('configuration assigns legacy values and selects one tire unit', (
    tester,
  ) async {
    final bike = fixture('b', setups: 1).copyWith(
      availableParameters: BikeParameters.fromMap({'forkOtt': true}),
      setups: [TrailSetup(id: 's', name: 'S', forkOtt: 210, frontPressure: 22)],
    );
    SharedPreferences.setMockInitialValues({
      'bikes_data': jsonEncode([bike.toMap()]),
      'app_lang': 'de',
      'hasSeenConfiguratorTour': true,
    });
    final provider = BikeProvider();
    await tester.runAsync(() => provider.ready);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          home: SetupConfiguratorScreen(bikeId: 'b', isEditing: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neg.-Kammer').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('REIFEN'));
    await tester.tap(find.text('REIFEN'));
    await tester.pumpAndSettle();
    final tire = find.widgetWithText(
      SwitchListTile,
      'Reifendruck: Einheit auswählen',
    );
    await tester.ensureVisible(tire);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: tire, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PSI').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();
    final save = find.text('Änderungen speichern');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final result = provider.bikes.single;
    expect(result.availableParameters!.legacyFork, isFalse);
    expect(result.availableParameters!.legacyTires, isFalse);
    expect(result.availableParameters!.forkNegative, isTrue);
    expect(result.availableParameters!.forkOtt, isFalse);
    expect(result.availableParameters!.unitOverrides['tirePressure'], 'PSI');
    expect(result.setups.single.forkNegative, 210);
    expect(result.setups.single.frontPressure, 22);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => provider.saveToDevice());
    await tester.pumpWidget(const SizedBox());
    provider.dispose();
  });
  test('new parameters and both independent values survive serialization', () {
    final params = BikeParameters(forkOtt: true, forkNegative: true);
    final setup = TrailSetup(
      id: 's',
      name: 'S',
      forkOtt: 8,
      forkNegative: 90,
      customParameters: params,
    );
    final restored = TrailSetup.fromMap(setup.toMap());
    expect(restored.forkOtt, 8);
    expect(restored.forkNegative, 90);
    expect(restored.customParameters!.forkNegative, isTrue);
    expect(restored.customParameters!.legacyFork, isFalse);
    expect(restored.customParameters!.legacyTires, isFalse);
    final rows = buildSetupComparison(fixture('b'), restored, restored, 'de');
    expect(rows.firstWhere((r) => r.id == 'forkOtt').label, 'OTT');
    expect(rows.firstWhere((r) => r.id == 'forkOtt').a.display, '8 Klicks');
    expect(
      rows.firstWhere((r) => r.id == 'forkNegative').label,
      'Neg.-Kammer',
    );
    expect(rows.firstWhere((r) => r.id == 'forkNegative').a.display, '90 PSI');
  });

  test(
    'old ambiguous fields stay marked until assigned, including round trip',
    () {
      final old = BikeParameters.fromMap({'forkOtt': true});
      final restored = BikeParameters.fromMap(old.copyWith().toMap());
      expect(restored.legacyFork, isTrue);
      expect(restored.legacyTires, isTrue);
      final setup = TrailSetup(
        id: 's',
        name: 'S',
        forkOtt: 210,
        frontPressure: 1.5,
        customParameters: restored,
      );
      final rows = buildSetupComparison(fixture('b'), setup, setup, 'de');
      expect(rows.firstWhere((r) => r.id == 'legacyFork').a.display, '210');
      expect(rows.firstWhere((r) => r.id == 'frontPressure').a.unit, isEmpty);
      expect(rows.any((r) => r.id == 'forkOtt'), isFalse);
      expect(
        BikeParameters.fromMap({
          'unitOverrides': {'tirePressure': 'PSI'},
        }).legacyTires,
        isFalse,
      );
    },
  );

  test(
    'assignment moves the value and field order without losing other data',
    () {
      final setup = TrailSetup(
        id: 's',
        name: 'S',
        forkOtt: 210,
        forkPsi: 80,
        notes: 'Keep',
        fieldOrders: {
          'fork': ['forkOtt', 'forkPsi'],
        },
      );
      final resolved = setup.resolveLegacyFork(true);
      expect(resolved.forkNegative, 210);
      expect(resolved.forkOtt, isNull);
      expect(resolved.forkPsi, 80);
      expect(resolved.notes, 'Keep');
      expect(resolved.fieldOrders['fork'], ['forkNegative', 'forkPsi']);
      expect(setup.resolveLegacyFork(false).forkOtt, 210);
    },
  );

  test(
    'bike assignment migrates only setups inheriting its parameters',
    () async {
      final legacy = BikeParameters.fromMap({'forkOtt': true});
      final bike = Bike(
        id: 'b',
        brand: 'B',
        model: 'M',
        category: 'Enduro',
        travelFront: 160,
        travelRear: 160,
        availableParameters: legacy,
        setups: [
          TrailSetup(id: 'inherited', name: 'I', forkOtt: 210),
          TrailSetup(
            id: 'custom',
            name: 'C',
            forkOtt: 5,
            customParameters: BikeParameters(forkOtt: true),
          ),
        ],
      );
      SharedPreferences.setMockInitialValues({
        'bikes_data': jsonEncode([bike.toMap()]),
      });
      final provider = BikeProvider();
      await provider.ready;
      provider.updateBikeParameters(
        'b',
        BikeParameters(
          forkNegative: true,
          ranges: {'forkNegative': const SettingRange(min: 0, max: 300)},
        ),
        legacyToNegative: true,
      );
      final setups = provider.bikes.single.setups;
      expect(setups.first.forkNegative, 210);
      expect(setups.first.forkOtt, isNull);
      expect(setups.last.forkOtt, 5);
      expect(setups.last.forkNegative, isNull);
      await provider.saveToDevice();
    },
  );
}
