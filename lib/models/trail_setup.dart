// lib/models/trail_setup.dart

class SetupLog {
  final String parameters;
  final String note;
  final DateTime timestamp;
  SetupLog({required this.parameters, required this.note, required this.timestamp});

  // Datenspeicherung
    Map<String, dynamic> toMap() => {
    'parameters': parameters,
    'note': note,
    'timestamp': timestamp.toIso8601String(), // Datum als String speichern
  };

  factory SetupLog.fromMap(Map<String, dynamic> map) => SetupLog(
    parameters: map['parameters'] ?? '',
    note: map['note'] ?? '',
    timestamp: DateTime.parse(map['timestamp']),
  );
}

class TrailSetup {
  final String id;
  final String name;
  
  // Fork
  final double? forkPsi;
  final double? forkOtt;
  final int? forkHsc;
  final int? forkLsc;
  final int? forkHsr;
  final int? forkLsr;
  final int? forkTokens;
  final int? forkHbo;
  
  // Shock
  final double? shockPsi;
  final int? shockTokens;
  final double? shockRate;
  final double? shockPreload;
  final int? shockHsc;
  final int? shockLsc;
  final int? shockHsr;
  final int? shockLsr;
  final int? shockHbo;
  
  // Tires
  final String? frontTire;
  final double? frontPressure;
  final String? rearTire;
  final double? rearPressure;
  
  final String notes;
  final bool isFavorite;
  final List<SetupLog> logs;

  TrailSetup({
    required this.id, required this.name,
    this.forkPsi, this.forkOtt, this.forkHsc, this.forkLsc, this.forkHsr, this.forkLsr, this.forkTokens, this.forkHbo,
    this.shockPsi, this.shockTokens, this.shockRate, this.shockPreload, this.shockHsc, this.shockLsc, this.shockHsr, this.shockLsr, this.shockHbo,
    this.frontTire, this.frontPressure, this.rearTire, this.rearPressure,
    this.notes = '', this.isFavorite = false, this.logs = const [],
  });

  TrailSetup copyWith({
    String? id, 
    String? name,
    double? forkPsi, double? forkOtt, int? forkHsc, int? forkLsc, int? forkHsr, int? forkLsr, int? forkTokens, int? forkHbo,
    double? shockPsi, int? shockTokens, double? shockRate, double? shockPreload, int? shockHsc, int? shockLsc, int? shockHsr, int? shockLsr, int? shockHbo,
    String? frontTire, double? frontPressure, String? rearTire, double? rearPressure,
    String? notes, bool? isFavorite, List<SetupLog>? logs,
  }) {
    return TrailSetup(
      id: id ?? this.id, 
      name: name ?? this.name, 
      forkPsi: forkPsi ?? this.forkPsi, forkOtt: forkOtt ?? this.forkOtt,
      forkHsc: forkHsc ?? this.forkHsc, forkLsc: forkLsc ?? this.forkLsc,
      forkHsr: forkHsr ?? this.forkHsr, forkLsr: forkLsr ?? this.forkLsr,
      forkTokens: forkTokens ?? this.forkTokens, forkHbo: forkHbo ?? this.forkHbo,
      shockPsi: shockPsi ?? this.shockPsi, shockTokens: shockTokens ?? this.shockTokens,
      shockRate: shockRate ?? this.shockRate, shockPreload: shockPreload ?? this.shockPreload,
      shockHsc: shockHsc ?? this.shockHsc, shockLsc: shockLsc ?? this.shockLsc,
      shockHsr: shockHsr ?? this.shockHsr, shockLsr: shockLsr ?? this.shockLsr,
      shockHbo: shockHbo ?? this.shockHbo,
      frontTire: frontTire ?? this.frontTire, frontPressure: frontPressure ?? this.frontPressure,
      rearTire: rearTire ?? this.rearTire, rearPressure: rearPressure ?? this.rearPressure,
      notes: notes ?? this.notes, isFavorite: isFavorite ?? this.isFavorite, logs: logs ?? this.logs,
    );
  }

  // Datenspeicherung 
  Map<String, dynamic> toMap() {
    return {
      'id': id, 'name': name,
      'forkPsi': forkPsi, 'forkOtt': forkOtt, 'forkHsc': forkHsc, 'forkLsc': forkLsc,
      'forkHsr': forkHsr, 'forkLsr': forkLsr, 'forkTokens': forkTokens, 'forkHbo': forkHbo,
      'shockPsi': shockPsi, 'shockTokens': shockTokens, 'shockRate': shockRate, 'shockPreload': shockPreload,
      'shockHsc': shockHsc, 'shockLsc': shockLsc, 'shockHsr': shockHsr, 'shockLsr': shockLsr, 'shockHbo': shockHbo,
      'frontTire': frontTire, 'frontPressure': frontPressure,
      'rearTire': rearTire, 'rearPressure': rearPressure,
      'notes': notes, 'isFavorite': isFavorite,
      'logs': logs.map((x) => x.toMap()).toList(), // Liste umwandeln
    };
  }

  factory TrailSetup.fromMap(Map<String, dynamic> map) {
    return TrailSetup(
      id: map['id'] ?? '', name: map['name'] ?? '',
      // Safe Parsing für Zahlen:
      forkPsi: (map['forkPsi'] as num?)?.toDouble(), forkOtt: (map['forkOtt'] as num?)?.toDouble(),
      forkHsc: map['forkHsc'] as int?, forkLsc: map['forkLsc'] as int?,
      forkHsr: map['forkHsr'] as int?, forkLsr: map['forkLsr'] as int?,
      forkTokens: map['forkTokens'] as int?, forkHbo: map['forkHbo'] as int?,
      shockPsi: (map['shockPsi'] as num?)?.toDouble(), shockTokens: map['shockTokens'] as int?,
      shockRate: (map['shockRate'] as num?)?.toDouble(), shockPreload: (map['shockPreload'] as num?)?.toDouble(),
      shockHsc: map['shockHsc'] as int?, shockLsc: map['shockLsc'] as int?,
      shockHsr: map['shockHsr'] as int?, shockLsr: map['shockLsr'] as int?,
      shockHbo: map['shockHbo'] as int?,
      frontTire: map['frontTire'] as String?, frontPressure: (map['frontPressure'] as num?)?.toDouble(),
      rearTire: map['rearTire'] as String?, rearPressure: (map['rearPressure'] as num?)?.toDouble(),
      notes: map['notes'] ?? '', isFavorite: map['isFavorite'] ?? false,
      logs: List<SetupLog>.from(map['logs']?.map((x) => SetupLog.fromMap(x)) ?? []),
    );
  }
}