// lib/main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'providers/bike_provider.dart';
import 'providers/language_provider.dart'; // NEU
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  runApp(
    // NEU: MultiProvider erlaubt uns beliebig viele Provider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(preferences)),
        ChangeNotifierProvider(create: (_) => BikeProvider()),
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
      theme: AppTheme.build(
        background: context.watch<ThemeProvider>().background,
        accent: context.watch<ThemeProvider>().accent,
      ),
      home: const HomeScreen(),
    );
  }
}
