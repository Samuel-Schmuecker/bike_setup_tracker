// lib/models/bike_parameters.dart

enum CustomFieldType { number, text, boolean }

class CustomSetupField {
  final String id;
  final String name;
  final CustomFieldType type;
  final String unit;
  final String value;

  const CustomSetupField({
    required this.id,
    required this.name,
    required this.type,
    this.unit = '',
    this.value = '',
  });

  CustomSetupField copyWith({
    String? name,
    CustomFieldType? type,
    String? unit,
    String? value,
  }) {
    return CustomSetupField(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'unit': unit,
    'value': value,
  };

  factory CustomSetupField.fromMap(Map<String, dynamic> map) {
    return CustomSetupField(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: CustomFieldType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => CustomFieldType.text,
      ),
      unit: map['unit']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
    );
  }
}

class CustomSetupCategory {
  final String id;
  final String name;
  final List<CustomSetupField> fields;
  final bool notesEnabled;
  final String notes;

  const CustomSetupCategory({
    required this.id,
    required this.name,
    this.fields = const [],
    this.notesEnabled = false,
    this.notes = '',
  });

  CustomSetupCategory copyWith({
    String? name,
    List<CustomSetupField>? fields,
    bool? notesEnabled,
    String? notes,
  }) {
    return CustomSetupCategory(
      id: id,
      name: name ?? this.name,
      fields: fields ?? this.fields,
      notesEnabled: notesEnabled ?? this.notesEnabled,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'fields': fields.map((field) => field.toMap()).toList(),
    'notesEnabled': notesEnabled,
    'notes': notes,
  };

  factory CustomSetupCategory.fromMap(Map<String, dynamic> map) {
    return CustomSetupCategory(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      fields: (map['fields'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (field) =>
                CustomSetupField.fromMap(Map<String, dynamic>.from(field)),
          )
          .toList(),
      notesEnabled: map['notesEnabled'] == true,
      notes: map['notes']?.toString() ?? '',
    );
  }
}

class BikeParameters {
  // Fork
  final bool forkPsi;
  final bool forkOtt; // Negative Chamber / OTT
  final bool forkHsc;
  final bool forkLsc;
  final bool forkHsr; // High-Speed Rebound
  final bool forkLsr; // Low-Speed Rebound
  final bool forkTokens;
  final bool forkHbo; // Hydraulic Bottom Out

  // Shock Type
  final bool shockIsCoil; // false = Air, true = Coil

  // Shock
  final bool shockPsi; // Air Pressure (Air)
  final bool shockTokens; // Volume Spacer (Air)
  final bool shockRate; // Spring Rate (Coil)
  final bool shockPreload; // Preload (Coil)

  final bool shockHsc;
  final bool shockLsc;
  final bool shockHsr;
  final bool shockLsr;
  final bool shockHbo;

  // Tires
  final bool tires;
  final List<CustomSetupCategory> customCategories;
  final Map<String, String> unitOverrides;

  BikeParameters({
    this.forkPsi = true,
    this.forkOtt = false,
    this.forkHsc = false,
    this.forkLsc = true,
    this.forkHsr = false,
    this.forkLsr = true,
    this.forkTokens = false,
    this.forkHbo = false,
    this.shockIsCoil = false,
    this.shockPsi = true,
    this.shockTokens = false,
    this.shockRate = false,
    this.shockPreload = false,
    this.shockHsc = false,
    this.shockLsc = true,
    this.shockHsr = false,
    this.shockLsr = true,
    this.shockHbo = false,
    this.tires = true,
    this.customCategories = const [],
    this.unitOverrides = const {},
  });

  BikeParameters copyWith({
    List<CustomSetupCategory>? customCategories,
    Map<String, String>? unitOverrides,
  }) {
    return BikeParameters(
      forkPsi: forkPsi,
      forkOtt: forkOtt,
      forkHsc: forkHsc,
      forkLsc: forkLsc,
      forkHsr: forkHsr,
      forkLsr: forkLsr,
      forkTokens: forkTokens,
      forkHbo: forkHbo,
      shockIsCoil: shockIsCoil,
      shockPsi: shockPsi,
      shockTokens: shockTokens,
      shockRate: shockRate,
      shockPreload: shockPreload,
      shockHsc: shockHsc,
      shockLsc: shockLsc,
      shockHsr: shockHsr,
      shockLsr: shockLsr,
      shockHbo: shockHbo,
      tires: tires,
      customCategories: customCategories ?? this.customCategories,
      unitOverrides: unitOverrides ?? this.unitOverrides,
    );
  }

  // (Optional: toMap / fromMap für SQLite hier ergänzen analog zu den Feldern oben)

  Map<String, dynamic> toMap() {
    return {
      'forkPsi': forkPsi,
      'forkOtt': forkOtt,
      'forkHsc': forkHsc,
      'forkLsc': forkLsc,
      'forkHsr': forkHsr,
      'forkLsr': forkLsr,
      'forkTokens': forkTokens,
      'forkHbo': forkHbo,
      'shockIsCoil': shockIsCoil,
      'shockPsi': shockPsi,
      'shockTokens': shockTokens,
      'shockRate': shockRate,
      'shockPreload': shockPreload,
      'shockHsc': shockHsc,
      'shockLsc': shockLsc,
      'shockHsr': shockHsr,
      'shockLsr': shockLsr,
      'shockHbo': shockHbo,
      'tires': tires,
      'customCategories': customCategories
          .map((category) => category.toMap())
          .toList(),
      'unitOverrides': unitOverrides,
    };
  }

  factory BikeParameters.fromMap(Map<String, dynamic> map) {
    return BikeParameters(
      forkPsi: map['forkPsi'] ?? true,
      forkOtt: map['forkOtt'] ?? false,
      forkHsc: map['forkHsc'] ?? false,
      forkLsc: map['forkLsc'] ?? true,
      forkHsr: map['forkHsr'] ?? false,
      forkLsr: map['forkLsr'] ?? true,
      forkTokens: map['forkTokens'] ?? false,
      forkHbo: map['forkHbo'] ?? false,
      shockIsCoil: map['shockIsCoil'] ?? false,
      shockPsi: map['shockPsi'] ?? true,
      shockTokens: map['shockTokens'] ?? false,
      shockRate: map['shockRate'] ?? false,
      shockPreload: map['shockPreload'] ?? false,
      shockHsc: map['shockHsc'] ?? false,
      shockLsc: map['shockLsc'] ?? true,
      shockHsr: map['shockHsr'] ?? false,
      shockLsr: map['shockLsr'] ?? true,
      shockHbo: map['shockHbo'] ?? false,
      tires: map['tires'] ?? true,
      customCategories: (map['customCategories'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (category) => CustomSetupCategory.fromMap(
              Map<String, dynamic>.from(category),
            ),
          )
          .toList(),
      unitOverrides: map['unitOverrides'] is Map
          ? Map<String, String>.from(map['unitOverrides'])
          : const {},
    );
  }
}
