import 'dart:async';

import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/add_bike/add_bike_screen.dart';
import 'package:bike_setup_tracker/screens/edit_bike/edit_bike_screen.dart';
import 'package:bike_setup_tracker/utils/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const channel = MethodChannel('plugins.flutter.io/image_picker');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mount(WidgetTester tester, bool editing) async {
    SharedPreferences.setMockInitialValues({
      'hasCreatedOwnBike': true,
      'hasSeenBikeCreationTour': true,
    });
    final bikes = BikeProvider();
    await tester.runAsync(() => bikes.ready);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: bikes),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          home: editing
              ? EditBikeScreen(
                  bike: Bike(
                    id: 'test',
                    brand: 'Test',
                    model: 'Bike',
                    category: 'Trail',
                    travelFront: 140,
                    travelRear: 130,
                  ),
                )
              : const AddBikeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(bikes.dispose);
  }

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  for (final editing in [false, true]) {
    testWidgets('photo permission failure is handled; editing=$editing', (
      tester,
    ) async {
      var called = false;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        called = true;
        expect(call.arguments['requestFullMetadata'], false);
        throw PlatformException(code: 'photo_access_denied');
      });
      await mount(tester, editing);
      await tester.tap(find.byIcon(Icons.add_a_photo));
      await tester.pumpAndSettle();
      expect(called, isTrue);
      expect(
        find.text(Translations.get('de', 'photoSelectionError')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'leaving photo screen before failure is safe; editing=$editing',
      (tester) async {
        final result = Completer<String?>();
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (_) => result.future,
        );
        await mount(tester, editing);
        await tester.tap(find.byIcon(Icons.add_a_photo));
        await tester.pump();
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        result.completeError(PlatformException(code: 'photo_access_denied'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
