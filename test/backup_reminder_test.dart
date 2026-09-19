import 'package:bike_setup_tracker/cloud/cloud_provider.dart';
import 'package:bike_setup_tracker/cloud/local_store.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/home/home_screen.dart';
import 'package:bike_setup_tracker/utils/app_route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestAccountCloud extends CloudProvider {
  TestAccountCloud(super.store, super.bikes)
    : super(startAutomatically: false, cloudEnabled: false);

  User? currentUser;
  @override
  User? get user => currentUser;

  void restoreUser({required bool guest, bool google = false}) {
    currentUser = User(
      id: 'account',
      aud: 'authenticated',
      appMetadata: {
        'providers': [if (google) 'google'],
      },
      userMetadata: {},
      createdAt: '2026-09-18T00:00:00Z',
      isAnonymous: guest,
    );
    notifyListeners();
  }
}

void main() {
  for (final scenario in ['connected', 'restored', 'guest', 'linking']) {
    testWidgets('backup reminder respects $scenario account state', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'hasSeenOnboarding': true,
        'is_first_start': false,
        'hasCreatedOwnBike': true,
      });
      final bikes = BikeProvider();
      late LocalStore store;
      late SharedPreferences prefs;
      await tester.runAsync(() async {
        prefs = await SharedPreferences.getInstance();
        await bikes.ready;
        bikes.addBike(bikes.bikes.single.copyWith(id: 'own'));
        await bikes.saveToDevice();
        store = LocalStore(
          await newDatabaseFactoryMemory().openDatabase(scenario),
        );
        await store.initialize(prefs);
      });
      final cloud = TestAccountCloud(store, bikes);
      if (scenario == 'connected') {
        cloud.restoreUser(guest: false, google: true);
      } else if (scenario == 'linking') {
        cloud.restoreUser(guest: true);
        cloud.accountOperation = true;
      }
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: bikes),
            ChangeNotifierProvider<CloudProvider>.value(value: cloud),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: MaterialApp(
            navigatorObservers: [appRouteObserver],
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Datensicherung nicht vergessen'), findsNothing);
      expect(prefs.getBool('hasSeenBackupReminder'), isNot(true));

      if (scenario != 'connected') {
        cloud.accountOperation = false;
        cloud.restoreUser(
          guest: scenario == 'guest',
          google: scenario != 'guest',
        );
        expect(cloud.shouldSuggestAccountBackup, scenario == 'guest');
        await tester.pump();
        await tester.pumpAndSettle();
      }
      if (scenario == 'guest') {
        expect(find.text('Datensicherung nicht vergessen'), findsOneWidget);
        await tester.tap(find.text('Später'));
        await tester.pumpAndSettle();
        expect(prefs.getBool('hasSeenBackupReminder'), isTrue);
      } else {
        expect(find.text('Datensicherung nicht vergessen'), findsNothing);
        // Returning Home must also honor the account, even with fresh local flags.
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        );
        await tester.pumpAndSettle();
        navigator.pop();
        await tester.pumpAndSettle();
        expect(find.text('Datensicherung nicht vergessen'), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      cloud.dispose();
      bikes.dispose();
      store.dispose();
      await tester.runAsync(() => store.database.close());
    });
  }
}
