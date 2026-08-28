// lib/models/bike.dart

import 'trail_setup.dart';
import 'bike_parameters.dart';

class Bike {
  final String id;
  final String brand;
  final String model;
  final String category;
  final int travelFront;
  final int travelRear;
  final String? imagePath;
  final BikeParameters? availableParameters; // NEU
  final List<TrailSetup> setups;

  Bike({
    required this.id,
    required this.brand,
    required this.model,
    required this.category,
    required this.travelFront,
    required this.travelRear,
    this.imagePath,
    this.availableParameters, // NEU
    this.setups = const [],
  });

  Bike copyWith({
    String? id,
    String? brand,
    String? model,
    String? category,
    int? travelFront,
    int? travelRear,
    String? imagePath,
    BikeParameters? availableParameters,
    List<TrailSetup>? setups,
  }) {
    return Bike(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      category: category ?? this.category,
      travelFront: travelFront ?? this.travelFront,
      travelRear: travelRear ?? this.travelRear,
      imagePath: imagePath ?? this.imagePath,
      availableParameters: availableParameters ?? this.availableParameters,
      setups: setups ?? this.setups,
    );
  }

  // Füge das in die Bike Klasse ein:
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'category': category,
      'travelFront': travelFront,
      'travelRear': travelRear,
      'imagePath': imagePath,
      'availableParameters': availableParameters?.toMap(),
      'setups': setups.map((x) => x.toMap()).toList(),
    };
  }

  factory Bike.fromMap(Map<String, dynamic> map) {
    return Bike(
      id: map['id'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      category: map['category'] ?? '',
      travelFront: map['travelFront'] ?? 0,
      travelRear: map['travelRear'] ?? 0,
      imagePath: map['imagePath'],
      availableParameters: map['availableParameters'] is Map
          ? BikeParameters.fromMap(
              Map<String, dynamic>.from(map['availableParameters']),
            )
          : null,
      setups: (map['setups'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((x) => TrailSetup.fromMap(Map<String, dynamic>.from(x)))
          .toList(),
    );
  }
}
