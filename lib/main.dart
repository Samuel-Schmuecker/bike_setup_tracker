import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bike_provider.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BikeProvider()),
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
      title: 'MTB Setup',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal, // Deine Hauptfarbe
          brightness: Brightness.dark, // Dark Mode für die MTB-App
        ),
        useMaterial3: true,

        //Aktiviert die Back-Swipe-Geste für iOS und Android
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(), // Startet den Home Screen, den wir jetzt bauen
    );
  }
}