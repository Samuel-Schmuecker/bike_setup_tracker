import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/home/home_screen.dart';
import 'package:bike_setup_tracker/widgets/bike_card.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'field_order_test.dart' show loadProvider;

void main() {
  test('Bike favorites persist without changing manual order', () async {
    final provider = await loadProvider();
    expect(Bike.fromMap({'id': 'legacy'}).isFavorite, isFalse);
    provider.toggleBikeFavorite('b');
    expect(provider.orderedBikes.map((b) => b.id), ['b', 'a']);
    expect(provider.bikes.map((b) => b.id), ['a', 'b']);
    expect(provider.bikes.last.copyWith(model: 'Edited').isFavorite, isTrue);
    await provider.saveToDevice();
    await provider.loadFromDevice();
    expect(provider.orderedBikes.map((b) => b.id), ['b', 'a']);
    provider.toggleBikeFavorite('b');
    expect(provider.orderedBikes.map((b) => b.id), ['a', 'b']);
    provider.toggleBikeFavorite('missing');
    expect(provider.bikes.any((b) => b.isFavorite), isFalse);
  });

  testWidgets('Home stars toggle favorites and ordering keeps them first', (
    tester,
  ) async {
    final provider = await loadProvider();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(theme: ThemeData.dark(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('bike-b')),
        matching: find.byIcon(Icons.star_border),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<BikeCard>(find.byType(BikeCard).first).bike.id, 'b');
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.longPress(find.byType(BikeCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bikes sortieren'));
    await tester.pumpAndSettle();
    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder(0, 2);
    await tester.pumpAndSettle();
    expect(provider.orderedBikes.first.id, 'b');
    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder(1, 0);
    await tester.pumpAndSettle();
    expect(provider.orderedBikes.first.id, 'b');
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Favorit entfernen'));
    await tester.pumpAndSettle();
    expect(provider.bikes.any((b) => b.isFavorite), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Delete from bike menu requires confirmation and persists', (
    tester,
  ) async {
    final provider = await loadProvider();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(theme: ThemeData.dark(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    for (final confirm in [false, true]) {
      await tester.longPress(find.byType(BikeCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bike löschen'));
      await tester.pumpAndSettle();
      expect(find.text('Bike löschen?'), findsOneWidget);
      expect(provider.bikes.length, 2);
      await tester.tap(find.text(confirm ? 'Löschen' : 'Abbrechen'));
      await tester.pumpAndSettle();
      expect(provider.bikes.length, confirm ? 1 : 2);
    }
    await provider.saveToDevice();
    await provider.loadFromDevice();
    expect(provider.bikes.map((bike) => bike.id), ['b']);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Bike order persists and invalid orders cannot remove bikes', () async {
    final provider = await loadProvider();
    provider.reorderBikes(['b', 'a']);
    await provider.saveToDevice();
    await provider.loadFromDevice();
    expect(provider.bikes.map((b) => b.id), ['b', 'a']);
    for (final ids in [
      ['a'],
      ['a', 'a'],
      ['a', 'missing'],
    ]) {
      provider.reorderBikes(ids);
      expect(provider.bikes.map((b) => b.id), ['b', 'a']);
    }
  });

  testWidgets('Long press opens menu and dragging reorders bikes', (
    tester,
  ) async {
    final provider = await loadProvider();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(theme: ThemeData.dark(), home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(BikeCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Bike bearbeiten'), findsOneWidget);
    await tester.tap(find.text('Bikes sortieren'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    final secondCard = find.byKey(const ValueKey('bike-b'));
    final beforeDrag = tester.getTopLeft(secondCard).dy;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(BikeCard).first),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getTopLeft(secondCard).dy, lessThan(beforeDrag));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(provider.bikes.map((b) => b.id), ['b', 'a']);
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    expect(tester.widget<BikeCard>(find.byType(BikeCard).first).bike.id, 'b');
    expect(tester.takeException(), isNull);
  });
}
