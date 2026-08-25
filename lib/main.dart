// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'providers/bike_provider.dart';
import 'providers/language_provider.dart'; // NEU
import 'screens/home/home_screen.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // NEU: MultiProvider erlaubt uns beliebig viele Provider
    MultiProvider(
      providers: [
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: kIsWeb
                ? const FadeUpwardsPageTransitionsBuilder()
                : const CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}