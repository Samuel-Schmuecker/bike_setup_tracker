// lib/main.dart

import 'package:flutter/material.dart';
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
        
        // Den problematischen "pageTransitionsTheme"-Block haben wir hier 
        // komplett entfernt. Flutter erledigt das jetzt automatisch und 
        // 100% kompatibel für das Web!
      ),
      home: const HomeScreen(),
    );
  }
}