// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importiere deinen Provider und den HomeScreen
import 'providers/bike_provider.dart';
import 'screens/home/home_screen.dart';

void main() {
  // Wichtig für Web und SharedPreferences, bevor die App startet
  WidgetsFlutterBinding.ensureInitialized(); 

  runApp(
    // Provider an der obersten Stelle der App registrieren
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
      debugShowCheckedModeBanner: false, // Entfernt das rote Debug-Banner
      theme: ThemeData(
        // Wir haben die App optisch eher dunkel/hochwertig gestaltet,
        // daher setzen wir das Grund-Theme auf dunkel.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, // Deine Akzentfarbe (kannst du anpassen)
          brightness: Brightness.dark, 
        ),
        useMaterial3: true,
        
        // Hier lag der Fehler! Die saubere Einbindung der PageTransitions:
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}