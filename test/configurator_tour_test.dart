import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/screens/add_bike/add_bike_screen.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/bike_detail/setup_configurator_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<BikeProvider> mount(
    WidgetTester tester, {
    String bikeId = 'own',
    bool editing = false,
    bool existingSetup = false,
    bool seen = false,
    bool fromCreation = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      'is_first_start': true,
      'hasSeenConfiguratorTour': seen,
    });
    final bikes = BikeProvider();
    await tester.runAsync(() => bikes.ready);
    final demo = bikes.bikes.single;
    if (bikeId != '3') {
      bikes.addBike(
        demo.copyWith(id: bikeId, setups: existingSetup ? demo.setups : []),
      );
    }
    await tester.runAsync(() => bikes.saveToDevice());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: bikes),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: SetupConfiguratorScreen(
            bikeId: bikeId,
            showFirstBikeTour: fromCreation,
            isEditing: editing,
            setupId: existingSetup ? demo.setups.first.id : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bikes;
  }

  testWidgets(
    'four informational steps use independent flag and do not change data',
    (tester) async {
      final bikes = await mount(tester);
      final before = bikes.exportPayload.toString();
      expect(find.text('Deine Werte auswählen'), findsOneWidget);
      expect(find.text('Dein erstes Setup · 1 / 4'), findsOneWidget);
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(find.text('Einstellbereiche festlegen'), findsOneWidget);
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(find.text('Eigenes Feld hinzufügen'), findsOneWidget);
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(find.text('Eigene Kategorie anlegen'), findsOneWidget);
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
      expect(find.text('Dein erstes Setup · 4 / 4'), findsNothing);
      expect(bikes.exportPayload.toString(), before);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasSeenConfiguratorTour'), isTrue);
      expect(prefs.getBool('is_first_start'), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      bikes.dispose();
    },
  );

  testWidgets('skip remembers dismissal without changing main tour flag', (
    tester,
  ) async {
    final bikes = await mount(tester);
    await tester.tap(find.text('Überspringen'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('hasSeenConfiguratorTour'), isTrue);
    expect(prefs.getBool('is_first_start'), isTrue);
    expect(find.text('Deine Werte auswählen'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    bikes.dispose();
  });

  for (final mode in ['demo', 'editing', 'existing', 'seen', 'regular']) {
    testWidgets('does not launch for $mode', (tester) async {
      final bikes = await mount(
        tester,
        bikeId: mode == 'demo' ? '3' : 'own',
        editing: mode == 'editing',
        existingSetup: mode == 'existing',
        seen: mode == 'seen',
        fromCreation: mode != 'regular',
      );
      expect(find.text('Deine Werte auswählen'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasSeenConfiguratorTour'), mode == 'seen');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      bikes.dispose();
    });
  }

  testWidgets(
    'first own bike offers database hint and starts configuration after manual save',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final bikes = BikeProvider();
      await tester.runAsync(() => bikes.ready);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: bikes),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const AddBikeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Datenbank oder manuell'), findsOneWidget);
      await tester.tap(find.byType(TextFormField).first);
      await tester.pumpAndSettle();
      expect(find.text('Datenbank oder manuell'), findsNothing);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .hasFocus,
        isTrue,
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Mein eigenes Modell');
      await tester.enterText(fields.at(1), 'Meine Marke');
      await tester.enterText(fields.at(2), '160');
      await tester.enterText(fields.at(3), '150');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.ensureVisible(find.text('Bike speichern'));
      await tester.tap(find.text('Bike speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Deine Werte auswählen'), findsOneWidget);
      expect(bikes.bikes.last.model, 'Mein eigenes Modell');
      expect(
        (await SharedPreferences.getInstance()).getBool('hasCreatedOwnBike'),
        isTrue,
      );
      await tester.tap(find.text('Überspringen'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      bikes.dispose();
    },
  );
}
