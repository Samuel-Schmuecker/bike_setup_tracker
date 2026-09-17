// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'providers/bike_provider.dart';
import 'providers/language_provider.dart'; // NEU
import 'screens/home/home_screen.dart';
import 'cloud/local_database.dart';
import 'cloud/local_store.dart';
import 'cloud/cloud_provider.dart';
import 'screens/settings/account_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  late final LocalStore store;
  late final BikeProvider bikes;
  try {
    store = LocalStore(await openBikeDatabase());
    await store.initialize(preferences);
    bikes = BikeProvider(localStore: store);
    await bikes.ready;
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SelectableText(
                'Die gespeicherten Daten konnten nicht sicher geladen werden. '
                'Sie wurden nicht überschrieben. Bitte die App-Daten nicht löschen und den Support kontaktieren.',
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    // NEU: MultiProvider erlaubt uns beliebig viele Provider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(preferences)),
        ChangeNotifierProvider.value(value: bikes),
        ChangeNotifierProvider(
          create: (_) => CloudProvider(
            store,
            bikes,
            cloudEnabled: preferences.getBool('hasSeenOnboarding') ?? false,
          ),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => LanguageProvider()), // NEU
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike Setup Tracker',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final cloud = context.watch<CloudProvider?>();
        if (cloud != null && (cloud.cloudPaused || cloud.deletionPending)) {
          return const AccountScreen();
        }
        final switching =
            context.watch<CloudProvider?>()?.accountOperation ?? false;
        return PopScope(
          canPop: !switching,
          child: Stack(
            children: [
              AbsorbPointer(absorbing: switching, child: child!),
              if (switching)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x55000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
      theme: AppTheme.build(
        background: context.watch<ThemeProvider>().background,
        accent: context.watch<ThemeProvider>().accent,
      ),
      home: const HomeScreen(),
    );
  }
}
