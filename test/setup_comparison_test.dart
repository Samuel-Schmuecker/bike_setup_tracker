import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bike_setup_tracker/models/trail_setup.dart';
import 'package:bike_setup_tracker/models/bike_parameters.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/screens/bike_detail/bike_detail_screen.dart';
import 'package:bike_setup_tracker/screens/bike_detail/setup_comparison_screen.dart';
import 'package:bike_setup_tracker/utils/setup_comparison.dart';
import 'field_order_test.dart' show fixture, loadProvider;

void main() {
  test('deltas are B minus A, preserve units and omit missing values', () {
    final a = TrailSetup(
      id: 'a',
      name: 'A',
      forkPsi: 70,
      forkLsc: 5,
      frontPressure: 1.2,
    );
    final b = TrailSetup(
      id: 'b',
      name: 'B',
      forkPsi: 73,
      forkLsc: 3,
      frontPressure: 1.3,
      shockPsi: 180,
    );
    final rows = buildSetupComparison(fixture('x'), a, b, 'de');
    expect(rows.firstWhere((r) => r.id == 'forkPsi').delta, '▲ +3 PSI');
    expect(rows.firstWhere((r) => r.id == 'forkLsc').delta, '▼ −2 Klicks');
    expect(
      rows.firstWhere((r) => r.id == 'frontPressure').delta,
      '▲ +0.1 bar/PSI',
    );
    expect(rows.firstWhere((r) => r.id == 'shockPsi').delta, isNull);
    expect(rows.firstWhere((r) => r.id == 'forkLsr').changed, isFalse);
    final otherUnits = b.copyWith(
      customParameters: BikeParameters(unitOverrides: {'forkPsi': 'bar'}),
    );
    expect(
      buildSetupComparison(
        fixture('x'),
        a,
        otherUnits,
        'de',
      ).firstWhere((r) => r.id == 'forkPsi').delta,
      isNull,
    );
  });

  testWidgets('comparison filters unchanged rows and handles narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final a = TrailSetup(id: 'a', name: 'A', forkPsi: 70);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: SetupComparisonScreen(
            bike: fixture('x'),
            setupA: a,
            setupB: a.copyWith(id: 'b', forkPsi: 73),
          ),
        ),
      ),
    );
    expect(find.text('▲ +3'), findsOneWidget);
    expect(find.text('1 Unterschied'), findsOneWidget);
    await tester.tap(find.byTooltip('Setups tauschen'));
    await tester.pumpAndSettle();
    expect(find.text('▽ −3'), findsOneWidget);
    expect(find.text('▲ +3'), findsNothing);
    expect(find.text('1 Unterschied'), findsOneWidget);
    expect(find.text('LSC'), findsNothing);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('LSC'), findsWidgets);
    expect(find.text('1 Unterschied'), findsOneWidget);
    await tester.tap(find.byTooltip('Setups tauschen'));
    await tester.pumpAndSettle();
    expect(find.text('▲ +3'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'long press preselects setup and second selection opens comparison',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = await loadProvider(setups: 3);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BikeProvider>.value(value: provider),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(home: BikeDetailScreen(bikeId: 'a')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Setup 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Vergleichen'));
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsNWidgets(3));
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
        isTrue,
      );
      await tester.tap(find.text('Setup 1'));
      await tester.pumpAndSettle();
      expect(find.byType(SetupComparisonScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
