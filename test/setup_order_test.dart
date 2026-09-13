import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/bike_detail/bike_detail_screen.dart';
import 'package:bike_setup_tracker/utils/translations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'field_order_test.dart' show loadProvider;

void main() {
  testWidgets('long press on card body reorders setups', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await loadProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BikeProvider>.value(value: provider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const BikeDetailScreen(bikeId: 'a'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    final source = tester.getCenter(find.text('Setup 0'));
    final target = tester.getCenter(find.byKey(const ValueKey('setup-a-1')));
    final gesture = await tester.startGesture(source);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveTo(target + const Offset(0, 150));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text(Translations.get('de', 'finishFieldOrder')));
    await tester.pumpAndSettle();
    expect(provider.bikes.first.setups.map((s) => s.id), ['a-1', 'a-0']);
    expect(tester.takeException(), isNull);
  });

  test('favorites lead while manual order persists after reload', () async {
    final provider = await loadProvider(setups: 3);
    provider.reorderSetups('a', ['a-2', 'a-0', 'a-1']);
    provider.toggleSetupFavorite('a', 'a-1');
    expect(provider.bikes.first.orderedSetups.map((s) => s.id), [
      'a-1',
      'a-2',
      'a-0',
    ]);
    await provider.saveToDevice();
    await provider.loadFromDevice();
    expect(provider.bikes.first.orderedSetups.map((s) => s.id), [
      'a-1',
      'a-2',
      'a-0',
    ]);
    provider.toggleSetupFavorite('a', 'a-1');
    expect(provider.bikes.first.orderedSetups.map((s) => s.id), [
      'a-2',
      'a-0',
      'a-1',
    ]);
    provider.reorderSetups('a', ['a-0', 'a-0', 'a-1']);
    expect(provider.bikes.first.setups.map((s) => s.id), ['a-2', 'a-0', 'a-1']);
  });
}

