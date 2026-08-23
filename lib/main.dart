// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // <--- WICHTIG: Fehlt oft beim Web-Build!
import 'package:provider/provider.dart';

import 'providers/bike_provider.dart';
import 'screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 

  runApp(
    ChangeNotifierProvider(
      create: (context) => BikeProvider(),
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
        
        // HIER IST DER FIX: 
        // Erzwingt die iOS-Wischgeste (Zurück-Wischen) auf allen Geräten!
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}