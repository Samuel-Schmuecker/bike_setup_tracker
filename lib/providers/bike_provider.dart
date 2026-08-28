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
  List<CustomSetupCategory> _customFieldCatalog = [];
  Future<void> _pendingSave = Future.value();

  UnmodifiableListView<Bike> get bikes => UnmodifiableListView(_bikes);
  UnmodifiableListView<CustomSetupCategory> get customFieldCatalog =>
      UnmodifiableListView(_customFieldCatalog);

  // KONSTRUKTOR: Lädt die Daten direkt beim App-Start
  BikeProvider() {
    loadFromDevice();
  }

  // --- PERSISTENCE (SPEICHERN & LADEN) ---

  Future<void> saveToDevice() {
    // Capture the current state and serialize writes so an older async save can
    // never overwrite a newer one.
    final encodedData = jsonEncode(_bikes.map((b) => b.toMap()).toList());
    _pendingSave = _pendingSave
        .then((_) async {
          final prefs = await SharedPreferences.getInstance();
          final didSave = await prefs.setString('bikes_data', encodedData);
          if (!didSave) {
            debugPrint('Lokale Bike-Daten konnten nicht gespeichert werden.');
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Fehler beim Speichern der lokalen Bike-Daten: $error');
        });
    return _pendingSave;
  }

  Future<void> loadFromDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedCatalog = prefs.getString('custom_field_catalog');
    if (encodedCatalog != null) {
      try {
        final decodedCatalog = jsonDecode(encodedCatalog);
        if (decodedCatalog is List) {
          _customFieldCatalog = decodedCatalog
              .whereType<Map>()
              .map(
                (item) => CustomSetupCategory.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      } catch (error) {
        debugPrint('Fehler beim Laden der Feldbibliothek: $error');
      }
    }
    final String? encodedData = prefs.getString('bikes_data');

    if (encodedData != null && encodedData.isNotEmpty) {
      try {
        // VERSUCHT Daten zu laden
        final decodedData = jsonDecode(encodedData);
        if (decodedData is! List) {
          throw const FormatException('bikes_data ist keine Liste');
        }
        _bikes = decodedData
            .whereType<Map>()
            .map((map) => Bike.fromMap(Map<String, dynamic>.from(map)))
            .toList();
        _seedCatalogFromBikes();
        notifyListeners();
      } catch (e) {
        // WENN EIN DATEN-FEHLER AUFTRITT (z.B. altes Modell in Datenbank):
        // Bestehende Daten nicht automatisch löschen. So bleibt eine spätere
        // Migration oder manuelle Wiederherstellung möglich.
        debugPrint('Fehler beim Laden der lokalen Daten: $e');
        _loadDemoBikes();
      }
    } else {
      // Wenn KEINE Daten vorhanden sind (erster App-Start): Demo-Bikes laden
      _loadDemoBikes();
    }
  }

  void _seedCatalogFromBikes() {
    for (final bike in _bikes) {
      _mergeCategoriesIntoCatalog(
        bike.availableParameters?.customCategories ?? const [],
      );
      for (final setup in bike.setups) {
        _mergeCategoriesIntoCatalog(
          setup.customParameters?.customCategories ?? const [],
        );
      }
    }
    _saveCustomFieldCatalog();
  }

  void _mergeCategoriesIntoCatalog(List<CustomSetupCategory> categories) {
    for (final category in categories) {
      final categoryIndex = _customFieldCatalog.indexWhere(
        (item) => item.id == category.id,
      );
      if (categoryIndex == -1) {
        _customFieldCatalog.add(
          category.copyWith(
            fields: category.fields
                .map((field) => field.copyWith(value: ''))
                .toList(),
            notesEnabled: false,
            notes: '',
          ),
        );
        continue;
      }
      final current = _customFieldCatalog[categoryIndex];
      final fields = List<CustomSetupField>.from(current.fields);
      for (final field in category.fields) {
        if (!fields.any((item) => item.id == field.id)) {
          fields.add(field.copyWith(value: ''));
        }
      }
      _customFieldCatalog[categoryIndex] = current.copyWith(fields: fields);
    }
  }

  Future<void> _saveCustomFieldCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'custom_field_catalog',
      jsonEncode(
        _customFieldCatalog.map((category) => category.toMap()).toList(),
      ),
    );
  }

  void addCustomFieldTemplate(
    String categoryId,
    String categoryName,
    CustomSetupField field,
  ) {
    final categoryIndex = _customFieldCatalog.indexWhere(
      (item) => item.id == categoryId,
    );
    final template = field.copyWith(value: '');
    if (categoryIndex == -1) {
      _customFieldCatalog.add(
        CustomSetupCategory(
          id: categoryId,
          name: categoryName,
          fields: [template],
        ),
      );
    } else {
      final category = _customFieldCatalog[categoryIndex];
      _customFieldCatalog[categoryIndex] = category.copyWith(
        fields: [...category.fields, template],
      );
    }
    notifyListeners();
    _saveCustomFieldCatalog();
  }

  void updateCustomFieldTemplate(String categoryId, CustomSetupField field) {
    final categoryIndex = _customFieldCatalog.indexWhere(
      (item) => item.id == categoryId,
    );
    if (categoryIndex == -1) return;
    final category = _customFieldCatalog[categoryIndex];
    _customFieldCatalog[categoryIndex] = category.copyWith(
      fields: category.fields
          .map((item) => item.id == field.id ? field.copyWith(value: '') : item)
          .toList(),
    );
    _transformAllParameters((parameters) {
      return parameters.copyWith(
        customCategories: parameters.customCategories.map((category) {
          if (category.id != categoryId) return category;
          return category.copyWith(
            fields: category.fields.map((item) {
              return item.id == field.id
                  ? field.copyWith(value: item.value)
                  : item;
            }).toList(),
          );
        }).toList(),
      );
    });
    notifyListeners();
    saveToDevice();
    _saveCustomFieldCatalog();
  }

  void deleteCustomFieldTemplate(String categoryId, String fieldId) {
    final categoryIndex = _customFieldCatalog.indexWhere(
      (item) => item.id == categoryId,
    );
    if (categoryIndex == -1) return;
    final category = _customFieldCatalog[categoryIndex];
    _customFieldCatalog[categoryIndex] = category.copyWith(
      fields: category.fields.where((item) => item.id != fieldId).toList(),
    );
    _transformAllParameters((parameters) {
      return parameters.copyWith(
        customCategories: parameters.customCategories.map((category) {
          if (category.id != categoryId) return category;
          return category.copyWith(
            fields: category.fields
                .where((item) => item.id != fieldId)
                .toList(),
          );
        }).toList(),
      );
    });
    notifyListeners();
    saveToDevice();
    _saveCustomFieldCatalog();
  }

  void addCustomCategoryTemplate(CustomSetupCategory category) {
    if (_customFieldCatalog.any((item) => item.id == category.id)) return;
    _customFieldCatalog.add(category);
    notifyListeners();
    _saveCustomFieldCatalog();
  }

  void deleteCustomCategoryTemplate(String categoryId) {
    _customFieldCatalog.removeWhere((item) => item.id == categoryId);
    _transformAllParameters((parameters) {
      return parameters.copyWith(
        customCategories: parameters.customCategories
            .where((category) => category.id != categoryId)
            .toList(),
      );
    });
    notifyListeners();
    saveToDevice();
    _saveCustomFieldCatalog();
  }

  void _transformAllParameters(
    BikeParameters Function(BikeParameters parameters) transform,
  ) {
    _bikes = _bikes.map((bike) {
      final updatedSetups = bike.setups.map((setup) {
        final parameters = setup.customParameters;
        return parameters == null
            ? setup
            : setup.copyWith(customParameters: transform(parameters));
      }).toList();
      return bike.copyWith(
        availableParameters: bike.availableParameters == null
            ? null
            : transform(bike.availableParameters!),
        setups: updatedSetups,
      );
    }).toList();
  }

  void _loadDemoBikes() {
    _bikes = [
      Bike(
        id: '3',
        brand: 'Commencal',
        model: 'Supreme V5',
        category: 'Downhill',
        travelFront: 200,
        travelRear: 200,
        imagePath: 'assets/images/commencal_v5.png',
        availableParameters: BikeParameters(
          forkPsi: true,
          forkOtt: true,
          forkHsc: true,
          forkLsc: true,
          forkLsr: true,
          forkHsr: false,
          forkTokens: false,
          forkHbo: false,
          shockIsCoil: true,
          shockRate: true,
          shockPreload: true,
          shockHsc: true,
          shockLsc: true,
          shockLsr: true,
          shockHsr: false,
          shockHbo: true,
          tires: true,
        ),
        setups: [
          TrailSetup(
            id: 's4',
            name: 'Bikepark Setup',
            forkPsi: 110.0,
            forkOtt: 210.0,
            forkHsc: -3,
            forkLsc: -10,
            forkLsr: -8,
            shockRate: 450.0,
            shockPreload: 1.0,
            shockHsc: -2,
            shockLsc: -8,
            shockLsr: -6,
            shockHbo: 3,
            frontTire: 'Maxxis Assegai',
            frontPressure: 1.8,
            rearTire: 'Maxxis Minion DHR II',
            rearPressure: 2.0,
            notes:
                'Standard Setup für steile Parks. Öhlins DH38 und TTX22M Coil.',
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
      _bikes[index] = bike.copyWith(availableParameters: parameters);
      notifyListeners();
      saveToDevice(); // AUTO-SAVE
    }
  }

  void addSetupToBike(String bikeId, TrailSetup setup) {
    final bikeIndex = _bikes.indexWhere((bike) => bike.id == bikeId);
    if (bikeIndex != -1) {
      final bike = _bikes[bikeIndex];
      final updatedSetups = List<TrailSetup>.from(bike.setups)..add(setup);
      _bikes[bikeIndex] = bike.copyWith(setups: updatedSetups);
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
        _bikes[bikeIndex] = bike.copyWith(setups: updatedSetups);
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
      _bikes[bikeIndex] = bike.copyWith(setups: updatedSetups);
      notifyListeners();
      saveToDevice(); // AUTO-SAVE
    }
  }

  void duplicateSetup(String bikeId, String setupId, String copySuffix) {
    final bikeIndex = _bikes.indexWhere((b) => b.id == bikeId);
    if (bikeIndex != -1) {
      final bike = _bikes[bikeIndex];
      final originalSetup = bike.setups.firstWhere((s) => s.id == setupId);
      final duplicatedSetup = originalSetup.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${originalSetup.name} $copySuffix',
        isFavorite: false,
      );
      final updatedSetups = List<TrailSetup>.from(bike.setups)
        ..add(duplicatedSetup);
      _bikes[bikeIndex] = bike.copyWith(setups: updatedSetups);
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
        final updatedSetup = currentSetup.copyWith(
          isFavorite: !currentSetup.isFavorite,
        );
        final updatedSetups = List<TrailSetup>.from(bike.setups);
        updatedSetups[setupIndex] = updatedSetup;
        _bikes[bikeIndex] = bike.copyWith(setups: updatedSetups);
        notifyListeners();
        saveToDevice(); // AUTO-SAVE
      }
    }
  }
}
