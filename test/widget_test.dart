import 'package:bike_setup_tracker/cloud/cloud_provider.dart';
import 'package:bike_setup_tracker/cloud/local_store.dart';
import 'package:bike_setup_tracker/main.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/providers/theme_provider.dart';
import 'package:bike_setup_tracker/screens/settings/account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App works without registration and opens account settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'hasSeenOnboarding': true,
      'bikes_data': '[]',
    });
    late SharedPreferences prefs;
    late LocalStore store;
    late BikeProvider bikes;
    await tester.runAsync(() async {
      prefs = await SharedPreferences.getInstance();
      store = LocalStore(
        await newDatabaseFactoryMemory().openDatabase('widget'),
      );
      await store.initialize(prefs);
      bikes = BikeProvider(localStore: store);
      await bikes.ready;
    });
    final cloud = CloudProvider(store, bikes, startAutomatically: false);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: bikes),
          ChangeNotifierProvider.value(value: cloud),
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.search), findsOneWidget);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konto & Datensicherung'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(find.text('Du nutzt die App als Gast'), findsOneWidget);
    expect(find.text('Registrieren'), findsNWidgets(2));
    expect(find.text('Login'), findsNWidgets(2));
    expect(find.text('E-Mail-Code anfordern'), findsNothing);
    expect(find.textContaining('Die anonyme Anmeldung allein'), findsOneWidget);
    cloud.googleIssue = 'identity_already_exists';
    tester.element(find.byType(AccountScreen)).markNeedsBuild();
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Dieses Google-Konto ist bereits'),
      findsWidgets,
    );
    final recoveryLogin = find.ancestor(
      of: find.byIcon(Icons.login),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(recoveryLogin, findsOneWidget);
    expect(tester.widget<FilledButton>(recoveryLogin).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    cloud.dispose();
    bikes.dispose();
    store.dispose();
    await tester.runAsync(() => store.database.close());
  });
}
