// lib/models/bike_parameters.dart

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

  BikeParameters({
    this.forkPsi = true, this.forkOtt = false,
    this.forkHsc = false, this.forkLsc = true,
    this.forkHsr = false, this.forkLsr = true,
    this.forkTokens = false, this.forkHbo = false,
    this.shockIsCoil = false,
    this.shockPsi = true, this.shockTokens = false,
    this.shockRate = false, this.shockPreload = false,
    this.shockHsc = false, this.shockLsc = true,
    this.shockHsr = false, this.shockLsr = true,
    this.shockHbo = false,
    this.tires = true,
  });

  // (Optional: toMap / fromMap für SQLite hier ergänzen analog zu den Feldern oben)

  Map<String, dynamic> toMap() {
    return {
      'forkPsi': forkPsi, 'forkOtt': forkOtt, 'forkHsc': forkHsc, 'forkLsc': forkLsc,
      'forkHsr': forkHsr, 'forkLsr': forkLsr, 'forkTokens': forkTokens, 'forkHbo': forkHbo,
      'shockIsCoil': shockIsCoil,
      'shockPsi': shockPsi, 'shockTokens': shockTokens, 'shockRate': shockRate, 'shockPreload': shockPreload,
      'shockHsc': shockHsc, 'shockLsc': shockLsc, 'shockHsr': shockHsr, 'shockLsr': shockLsr, 'shockHbo': shockHbo,
      'tires': tires,
    };
  }

  factory BikeParameters.fromMap(Map<String, dynamic> map) {
    return BikeParameters(
      forkPsi: map['forkPsi'] ?? true, forkOtt: map['forkOtt'] ?? false,
      forkHsc: map['forkHsc'] ?? false, forkLsc: map['forkLsc'] ?? true,
      forkHsr: map['forkHsr'] ?? false, forkLsr: map['forkLsr'] ?? true,
      forkTokens: map['forkTokens'] ?? false, forkHbo: map['forkHbo'] ?? false,
      shockIsCoil: map['shockIsCoil'] ?? false,
      shockPsi: map['shockPsi'] ?? true, shockTokens: map['shockTokens'] ?? false,
      shockRate: map['shockRate'] ?? false, shockPreload: map['shockPreload'] ?? false,
      shockHsc: map['shockHsc'] ?? false, shockLsc: map['shockLsc'] ?? true,
      shockHsr: map['shockHsr'] ?? false, shockLsr: map['shockLsr'] ?? true,
      shockHbo: map['shockHbo'] ?? false,
      tires: map['tires'] ?? true,
    );
  }
}