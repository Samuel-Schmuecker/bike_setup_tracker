import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/home/home_screen.dart';
import 'package:bike_setup_tracker/widgets/bike_card.dart';
import 'field_order_test.dart' show loadProvider;

void main() {
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
