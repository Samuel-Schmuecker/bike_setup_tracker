// lib/providers/bike_provider.dart

import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';
import '../models/trail_setup.dart';
import '../models/bike_parameters.dart';

class BikeProvider extends ChangeNotifier {
  List<Bike> _bikes = [];

  UnmodifiableListView<Bike> get bikes => UnmodifiableListView(_bikes);

  // KONSTRUKTOR: Lädt die Daten direkt beim App-Start
  BikeProvider() {
    loadFromDevice();
  }

  // --- PERSISTENCE (SPEICHERN & LADEN) ---

  Future<void> saveToDevice() async {
    final prefs = await SharedPreferences.getInstance();
    // Konvertiert alle Bikes in Maps, dann die ganze Liste in einen JSON-String
    final String encodedData = jsonEncode(_bikes.map((b) => b.toMap()).toList());
    await prefs.setString('bikes_data', encodedData);
  }

  Future<void> loadFromDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('bikes_data');

    if (encodedData != null && encodedData.isNotEmpty) {
      // Wenn Daten vorhanden sind: Decodieren und in Bike-Objekte umwandeln
      final List<dynamic> decodedList = jsonDecode(encodedData);
      _bikes = decodedList.map((map) => Bike.fromMap(map)).toList();
      notifyListeners();
    } else {
      // Wenn KEINE Daten vorhanden sind (erster App-Start): Demo-Bikes laden
      _loadDemoBikes();
    }
  }

  void _loadDemoBikes() {
    _bikes = [
      Bike(
        id: '3', brand: 'Commencal', model: 'Supreme V5', category: 'Downhill',
        travelFront: 200, travelRear: 200, imagePath: 'assets/images/commencal_v5.png',
        availableParameters: BikeParameters(
          forkPsi: true, forkOtt: true, forkHsc: true, forkLsc: true, forkLsr: true, forkHsr: false, forkTokens: false, forkHbo: false,
          shockIsCoil: true, shockRate: true, shockPreload: true, shockHsc: true, shockLsc: true, shockLsr: true, shockHsr: false, shockHbo: true, tires: true,
        ),
        setups: [
          TrailSetup(
            id: 's4', 
            name: 'Bikepark Setup', 
            forkPsi: 110.0, forkOtt: 210.0, forkHsc: -3, forkLsc: -10, forkLsr: -8,
            shockRate: 450.0, shockPreload: 1.0, shockHsc: -2, shockLsc: -8, shockLsr: -6, shockHbo: 3,
            frontTire: 'Maxxis Assegai', frontPressure: 1.8, rearTire: 'Maxxis Minion DHR II', rearPressure: 2.0,
            notes: 'Standard Setup für steile Parks. Öhlins DH38 und TTX22M Coil.',
            // --- NEU: Realistische Demo-Logs ---
            logs: [
              SetupLog(
                parameters: 'Fork PSI: 105 ➔ 110 (+5)', 
                note: 'Gabel tauchte im steilen Gelände zu tief weg.', 
                timestamp: DateTime.now().subtract(const Duration(days: 2)),
              ),
              SetupLog(
                parameters: 'Shock LSC: -10 ➔ -8 (+2)', 
                note: 'Brauche mehr Pop an den Absprüngen auf der Jumpline.', 
                timestamp: DateTime.now().subtract(const Duration(days: 5)),
              ),
              SetupLog(
                parameters: 'Front Pressure: 1.6 ➔ 1.8 (+0.2)', 
                note: '', // Log ohne Notiz
                timestamp: DateTime.now().subtract(const Duration(days: 12)),
              ),
            ],
          ),
        ],
      ),

    ];
    notifyListeners();
    saveToDevice(); // Demo-Daten direkt speichern
  }


  // --- CRUD AKTIONEN (Mit Auto-Save) ---

  void addBike(Bike bike) {
    _bikes.add(bike);
    notifyListeners();
    saveToDevice(); // AUTO-SAVE
  }

  void updateBike(Bike updatedBike) {
    final index = _bikes.indexWhere((bike) => bike.id == updatedBike.id);
    if (index != -1) {
      _bikes[index] = updatedBike;
      notifyListeners();
      saveToDevice(); // AUTO-SAVE
    }
  }

  void deleteBike(String bikeId) {
    _bikes.removeWhere((bike) => bike.id == bikeId);
    notifyListeners();
    saveToDevice(); // AUTO-SAVE
  }

  void updateBikeParameters(String bikeId, BikeParameters parameters) {
    final index = _bikes.indexWhere((bike) => bike.id == bikeId);
    if (index != -1) {
      final bike = _bikes[index];
      _bikes[index] = Bike(
        id: bike.id, brand: bike.brand, model: bike.model, category: bike.category,
        travelFront: bike.travelFront, travelRear: bike.travelRear, imagePath: bike.imagePath,
        setups: bike.setups,
        availableParameters: parameters, 
      );
      notifyListeners();
      saveToDevice(); // AUTO-SAVE
    }
  }

  void addSetupToBike(String bikeId, TrailSetup setup) {
    final bikeIndex = _bikes.indexWhere((bike) => bike.id == bikeId);
    if (bikeIndex != -1) {
      final bike = _bikes[bikeIndex];
      final updatedSetups = List<TrailSetup>.from(bike.setups)..add(setup);
      _bikes[bikeIndex] = Bike(
        id: bike.id, brand: bike.brand, model: bike.model, category: bike.category,
        travelFront: bike.travelFront, travelRear: bike.travelRear, imagePath: bike.imagePath,
        availableParameters: bike.availableParameters, 
        setups: updatedSetups,
      );
      notifyListeners();
      saveToDevice(); // AUTO-SAVE
    }
  }

  void updateSetup(String bikeId, TrailSetup updatedSetup) {
    final bikeIndex = _bikes.indexWhere((b) => b.id == bikeId);
    if (bikeIndex != -1) {
      final bike = _bikes[bikeIndex];
      final setupIndex = bike.setups.indexWhere((s) => s.id == updatedSetup.id);
      if (setupIndex != -1) {
        final updatedSetups = List<TrailSetup>.from(bike.setups);
        updatedSetups[setupIndex] = updatedSetup;
        _bikes[bikeIndex] = Bike(
          id: bike.id, brand: bike.brand, model: bike.model, category: bike.category,
          travelFront: bike.travelFront, travelRear: bike.travelRear, imagePath: bike.imagePath,
          availableParameters: bike.availableParameters,
          setups: updatedSetups,
        );
        notifyListeners();
        saveToDevice(); // AUTO-SAVE
      }
    }
  }

  void deleteSetup(String bikeId, String setupId) {
    final bikeIndex = _bikes.indexWhere((b) => b.id == bikeId);
    if (bikeIndex != -1) {
      final bike = _bikes[bikeIndex];
      final updatedSetups = bike.setups.where((s) => s.id != setupId).toList();
      _bikes[bikeIndex] = Bike(
        id: bike.id, brand: bike.brand, model: bike.model, category: bike.category,
        travelFront: bike.travelFront, travelRear: bike.travelRear, imagePath: bike.imagePath,
        availableParameters: bike.availableParameters,
        setups: updatedSetups,
      );
      notifyListeners();
      saveToDevice(); // AUTO-SAVE
    }
  }

  void duplicateSetup(String bikeId, String setupId) {
    final bikeIndex = _bikes.indexWhere((b) => b.id == bikeId);
    if (bikeIndex != -1) {
      final bike = _bikes[bikeIndex];
      final originalSetup = bike.setups.firstWhere((s) => s.id == setupId);
      final duplicatedSetup = originalSetup.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${originalSetup.name} (Kopie)',
        isFavorite: false,
      );
      final updatedSetups = List<TrailSetup>.from(bike.setups)..add(duplicatedSetup);
      _bikes[bikeIndex] = Bike(
        id: bike.id, brand: bike.brand, model: bike.model, category: bike.category,
        travelFront: bike.travelFront, travelRear: bike.travelRear, imagePath: bike.imagePath,
        availableParameters: bike.availableParameters,
        setups: updatedSetups,
      );
      notifyListeners();
      saveToDevice(); // AUTO-SAVE
    }
  }

  void toggleSetupFavorite(String bikeId, String setupId) {
    final bikeIndex = _bikes.indexWhere((b) => b.id == bikeId);
    if (bikeIndex != -1) {
      final bike = _bikes[bikeIndex];
      final setupIndex = bike.setups.indexWhere((s) => s.id == setupId);
      if (setupIndex != -1) {
        final currentSetup = bike.setups[setupIndex];
        final updatedSetup = currentSetup.copyWith(isFavorite: !currentSetup.isFavorite);
        final updatedSetups = List<TrailSetup>.from(bike.setups);
        updatedSetups[setupIndex] = updatedSetup;
        _bikes[bikeIndex] = Bike(
          id: bike.id, brand: bike.brand, model: bike.model, category: bike.category,
          travelFront: bike.travelFront, travelRear: bike.travelRear, imagePath: bike.imagePath,
          availableParameters: bike.availableParameters,
          setups: updatedSetups,
        );
        notifyListeners();
        saveToDevice(); // AUTO-SAVE
      }
    }
  }
}