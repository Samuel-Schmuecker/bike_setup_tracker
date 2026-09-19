// lib/providers/bike_provider.dart

import 'dart:collection';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';
import '../models/trail_setup.dart';
import '../models/bike_parameters.dart';
import '../data/demo_ohlins_ranges.dart';
import '../data/demo_bikes.dart';
import '../cloud/local_store.dart';
import '../cloud/sync_documents.dart';
import 'package:uuid/uuid.dart';

class BikeProvider extends ChangeNotifier {
  List<Bike> _bikes = [];
  List<CustomSetupCategory> _customFieldCatalog = [];
  Future<void> _pendingSave = Future.value();
  final LocalStore? localStore;
  late final Future<void> ready;
  String? storageError;

  UnmodifiableListView<Bike> get bikes => UnmodifiableListView(_bikes);
  UnmodifiableListView<CustomSetupCategory> get customFieldCatalog =>
      UnmodifiableListView(_customFieldCatalog);

  // KONSTRUKTOR: Lädt die Daten direkt beim App-Start
  BikeProvider({this.localStore}) {
    ready = loadFromDevice();
  }

  Json get exportPayload => {
    'bikes': _bikes.map((bike) => bike.toMap()).toList(),
    'catalog': _customFieldCatalog.map((item) => item.toMap()).toList(),
  };

  void applyStoredPayload() {
    final payload = localStore!.payload;
    final bikes = (payload['bikes'] as List)
        .map((value) => Bike.fromMap(Map<String, dynamic>.from(value as Map)))
        .toList();
    final catalog = (payload['catalog'] as List)
        .map(
          (value) => CustomSetupCategory.fromMap(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList();
    _bikes = bikes;
    _customFieldCatalog = catalog;
    notifyListeners();
  }

  Future<void> _saveLocalStore() async {
    try {
      await localStore!.savePayload(exportPayload);
      storageError = null;
    } catch (_) {
      storageError = 'local_save_failed';
    }
    notifyListeners();
  }

  // --- PERSISTENCE (SPEICHERN & LADEN) ---

  Future<void> saveToDevice() {
    if (localStore != null) return _saveLocalStore();
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
    if (localStore != null) {
      if (localStore!.initialized) {
        applyStoredPayload();
      } else {
        _loadDemoBikes();
      }
      // Also recover the field library for older installations.
      _seedCatalogFromBikes();
      await saveToDevice();
      return;
    }
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
        if (prefs.getBool('demo_ohlins_ranges_v1') != true) {
          _bikes = _bikes.map((bike) {
            if (bike.id != '3' ||
                bike.brand != 'Commencal' ||
                bike.model != 'Supreme V5')
              return bike;
            final parameters = bike.availableParameters ?? BikeParameters();
            return bike.copyWith(
              availableParameters: parameters.copyWith(
                ranges: {...demoOhlinsRanges, ...parameters.ranges},
              ),
            );
          }).toList();
          await saveToDevice();
          await prefs.setBool('demo_ohlins_ranges_v1', true);
        }
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
    if (localStore != null) {
      await _saveLocalStore();
      return;
    }
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

  void renameCustomCategoryTemplate(String categoryId, String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty ||
        const {'fork', 'shock', 'tires'}.contains(categoryId)) {
      return;
    }
    _customFieldCatalog = _customFieldCatalog
        .map(
          (category) => category.id == categoryId
              ? category.copyWith(name: trimmedName)
              : category,
        )
        .toList();
    _transformAllParameters(
      (parameters) => parameters.copyWith(
        customCategories: parameters.customCategories
            .map(
              (category) => category.id == categoryId
                  ? category.copyWith(name: trimmedName)
                  : category,
            )
            .toList(),
      ),
    );
    notifyListeners();
    saveToDevice();
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

  Future<void> restoreDemoAfterDeletion() async {
    if (localStore?.state['cloudPaused'] != true || localStore?.owner != null) {
      throw StateError('Demo reset requires a deleted account');
    }
    _customFieldCatalog = [];
    _loadDemoBikes();
    _seedCatalogFromBikes();
    await saveToDevice();
    if (storageError != null) throw StateError('LOCAL_SAVE_FAILED');
  }

  /// Restores only missing demo data, preserving the user's bikes and edits.
  Future<Bike> ensureOnboardingDemo() async {
    await ready;
    final index = _bikes.indexWhere((bike) => bike.id == '3');
    final template = createDemoBikes().single;
    if (index < 0) {
      _bikes.add(template);
    } else if (_bikes[index].setups.length < 2) {
      final bike = _bikes[index];
      _bikes[index] = bike.copyWith(
        setups: [
          ...bike.setups,
          for (final setup in template.setups.take(2 - bike.setups.length))
            setup.copyWith(id: const Uuid().v4()),
        ],
      );
    }
    notifyListeners();
    await saveToDevice();
    if (storageError != null) throw StateError('LOCAL_SAVE_FAILED');
    return _bikes.firstWhere((bike) => bike.id == '3');
  }

  void _loadDemoBikes() {
    _bikes = createDemoBikes();
    notifyListeners();
    saveToDevice();
  }

  // --- CRUD AKTIONEN (Mit Auto-Save) ---

  void addBike(Bike bike) {
    _bikes.add(bike);
    notifyListeners();
    saveToDevice(); // AUTO-SAVE
  }

  void reorderBikes(List<String> bikeIds) {
    final byId = {for (final bike in _bikes) bike.id: bike};
    if (bikeIds.length != _bikes.length ||
        bikeIds.toSet().length != byId.length ||
        bikeIds.any((id) => !byId.containsKey(id))) {
      return;
    }
    _bikes = bikeIds.map((id) => byId[id]!).toList();
    notifyListeners();
    saveToDevice();
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

  void clearSetupHistory(String bikeId, String setupId) {
    final bikeIndex = _bikes.indexWhere((bike) => bike.id == bikeId);
    if (bikeIndex == -1) return;
    final setupIndex = _bikes[bikeIndex].setups.indexWhere(
      (setup) => setup.id == setupId,
    );
    if (setupIndex == -1) return;
    final setup = _bikes[bikeIndex].setups[setupIndex];
    if (setup.logs.isEmpty) return;
    updateSetup(bikeId, setup.copyWith(logs: []));
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

  void updateFieldOrders(
    String bikeId,
    String setupId,
    Map<String, List<String>> orders, {
    bool applyToAll = false,
    List<String>? categoryOrder,
  }) {
    final index = _bikes.indexWhere((bike) => bike.id == bikeId);
    if (index == -1) return;
    final bike = _bikes[index];
    if (!bike.setups.any((setup) => setup.id == setupId)) return;
    _bikes[index] = bike.copyWith(
      setups: bike.setups.map((setup) {
        if (!applyToAll && setup.id != setupId) return setup;
        return setup.copyWith(
          categoryOrder: categoryOrder == null
              ? null
              : List<String>.of(categoryOrder),
          fieldOrders: {
            ...setup.fieldOrders,
            for (final entry in orders.entries)
              entry.key: List<String>.of(entry.value),
          },
        );
      }).toList(),
    );
    notifyListeners();
    saveToDevice();
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
        id: const Uuid().v4(),
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

  void reorderSetups(String bikeId, List<String> setupIds) {
    final index = _bikes.indexWhere((bike) => bike.id == bikeId);
    if (index == -1) return;
    final bike = _bikes[index];
    final byId = {for (final setup in bike.setups) setup.id: setup};
    if (setupIds.length != byId.length ||
        setupIds.toSet().length != byId.length ||
        setupIds.any((id) => !byId.containsKey(id))) {
      return;
    }
    _bikes[index] = bike.copyWith(
      setups: setupIds.map((id) => byId[id]!).toList(),
    );
    notifyListeners();
    saveToDevice();
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
