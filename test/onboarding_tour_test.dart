import 'package:bike_setup_tracker/widgets/bike_card.dart';
import 'package:bike_setup_tracker/widgets/setup_card.dart';
import 'dart:convert';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/home/home_screen.dart';
import 'package:bike_setup_tracker/services/onboarding_tour_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'first start migrates old welcome state and honors explicit flag',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingTourService();
      expect(await service.isFirstStart(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
      expect(await service.isFirstStart(), isFalse);
      await prefs.setBool('is_first_start', true);
      expect(await service.isFirstStart(), isTrue);
    },
  );

  test('demo restoration is idempotent and preserves user data', () async {
    SharedPreferences.setMockInitialValues({});
    final bikes = BikeProvider();
    await bikes.ready;
    final demo = bikes.bikes.single;
    final own = demo.copyWith(id: 'my-bike', model: 'My bike');
    bikes.addBike(own);
    bikes.deleteBike('3');
    await bikes.ensureOnboardingDemo();
    await bikes.ensureOnboardingDemo();
    expect(bikes.bikes, hasLength(2));
    expect(bikes.bikes.first.toMap(), own.toMap());
    final restored = bikes.bikes.last;
    bikes.updateBike(
      restored.copyWith(
        model: 'Renamed demo',
        setups: [
          restored.setups.first.copyWith(name: 'My setup', forkPsi: 123),
        ],
      ),
    );
    final repaired = await bikes.ensureOnboardingDemo();
    expect(repaired.model, 'Renamed demo');
    expect(repaired.setups, hasLength(2));
    expect(repaired.setups.first.name, 'My setup');
    expect(repaired.setups.first.forkPsi, 123);
    expect(repaired.setups.map((s) => s.id).toSet(), hasLength(2));
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('bikes_data')!), hasLength(2));
    bikes.dispose();
  });

  Future<BikeProvider> mountHome(
    WidgetTester tester, {
    bool first = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'hasSeenOnboarding': true,
      'is_first_start': first,
      'bikes_data': '[]',
    });
    final bikes = BikeProvider();
    await tester.runAsync(() => bikes.ready);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: bikes),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(theme: ThemeData.dark(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return bikes;
  }

  for (final advanced in [false, true]) {
    testWidgets('real actions advance the tour; advanced=$advanced', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bikes = await mountHome(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anleitung / Informationen'));
      await tester.pumpAndSettle();
      expect(find.text('Bikes verwalten'), findsOneWidget);
      await tester.longPress(find.byType(BikeCard).first);
      await tester.pumpAndSettle();
      expect(find.text('Bike bearbeiten'), findsOneWidget);
      await tester.tap(find.text('Zurück zur Tour'));
      await tester.pumpAndSettle();
      expect(find.text('Bike öffnen'), findsOneWidget);
      await tester.tap(find.byType(BikeCard).first);
      await tester.pumpAndSettle();
      expect(find.text('Setup lange drücken'), findsOneWidget);
      await tester.longPress(find.byType(SetupCard).first);
      await tester.pumpAndSettle();
      expect(find.text('Duplizieren'), findsOneWidget);
      await tester.tap(find.text('Zurück zur Tour'));
      await tester.pumpAndSettle();
      expect(find.text('Setup öffnen'), findsOneWidget);
      await tester.tap(find.byType(SetupCard).first);
      await tester.pumpAndSettle();
      expect(find.text('Zwischen Setups wischen'), findsOneWidget);
      await tester.dragFrom(const Offset(700, 250), const Offset(-650, 0));
      await tester.pumpAndSettle();
      expect(find.text('Wert ändern und speichern'), findsOneWidget);
      final before = bikes.bikes.single.setups[1].forkPsi;
      await tester.tap(find.byKey(const ValueKey('forkPsi')).hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(bikes.bikes.single.setups[1].forkPsi, isNot(before));
      expect(find.text('Grundtour geschafft'), findsOneWidget);
      if (!advanced) {
        await tester.tap(find.text('Fertig'));
        await tester.pumpAndSettle();
      } else {
        await tester.tap(find.text('Vertiefung starten'));
        await tester.pumpAndSettle();
        expect(find.text('Umsortieren öffnen'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.swap_vert).hitTestable());
        await tester.pumpAndSettle();
        expect(find.text('Ein Feld verschieben'), findsOneWidget);
        final source = find.byKey(const ValueKey('forkPsi')).last;
        final destination = tester.getRect(
          find.byKey(const ValueKey('forkOtt')).last,
        );
        final gesture = await tester.startGesture(tester.getCenter(source));
        await tester.pump(const Duration(milliseconds: 200));
        await gesture.moveTo(
          Offset(destination.right + 5, destination.center.dy),
        );
        await tester.pumpAndSettle();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text('Sortierung abschließen'), findsOneWidget);
        await tester.tap(find.text('Fertig').hitTestable());
        await tester.pumpAndSettle();
        // Keep the exercise scoped to this setup.
        final onlyThis = find.text('Nur dieses Setup');
        expect(onlyThis, findsOneWidget);
        await tester.tap(onlyThis);
        await tester.pumpAndSettle();
        expect(find.text('Änderungen nachvollziehen'), findsOneWidget);
        await tester.tap(find.text('Weiter'));
        await tester.pumpAndSettle();
        expect(find.text('Favoriten markieren'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.star_border).hitTestable().first);
        await tester.pumpAndSettle();
        expect(bikes.bikes.single.setups.any((s) => s.isFavorite), isTrue);
        expect(find.text('Tour abgeschlossen'), findsOneWidget);
        await tester.tap(find.text('Fertig'));
        await tester.pumpAndSettle();
      }
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      bikes.dispose();
    });
  }
  testWidgets(
    'Next is an alternative and skipping ordering discards the exercise',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bikes = await mountHome(tester, first: true);
      for (final label in [
        'Weiter',
        'Zurück zur Tour',
        'Weiter',
        'Weiter',
        'Zurück zur Tour',
        'Weiter',
        'Weiter',
        'Weiter',
        'Vertiefung starten',
        'Weiter',
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(find.text('Ein Feld verschieben'), findsOneWidget);
      await tester.tap(find.text('Überspringen'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(
        bikes.bikes.single.setups.every((s) => s.fieldOrders.isEmpty),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      bikes.dispose();
    },
  );

  testWidgets('automatic start can be skipped on a small display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bikes = await mountHome(tester, first: true);
    expect(find.text('Bikes verwalten'), findsOneWidget);
    await tester.ensureVisible(find.text('Überspringen'));
    await tester.tap(find.text('Überspringen'));
    await tester.pumpAndSettle();
    expect(find.text('Bikes verwalten'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('is_first_start'), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    bikes.dispose();
  });
}
