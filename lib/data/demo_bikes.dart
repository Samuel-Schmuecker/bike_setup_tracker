import '../models/bike.dart';
import '../models/bike_parameters.dart';
import '../models/trail_setup.dart';
import 'demo_ohlins_ranges.dart';

List<Bike> createDemoBikes() => [
  Bike(
    id: '3',
    brand: 'Commencal',
    model: 'Supreme V5',
    category: 'Downhill',
    travelFront: 200,
    travelRear: 200,
    imagePath: 'assets/images/commencal_v5.png',
    availableParameters: BikeParameters(
      ranges: demoOhlinsRanges,
      unitOverrides: const {'shockHsc': 'Stufe'},
      forkPsi: true,
      forkOtt: true,
      forkHsc: true,
      forkLsc: true,
      forkLsr: true,
      forkHsr: false,
      forkTokens: false,
      forkHbo: false,
      shockIsCoil: true,
      shockPsi: false,
      shockTokens: false,
      shockRate: true,
      shockPreload: true,
      shockHsc: true,
      shockLsc: true,
      shockLsr: true,
      shockHsr: false,
      shockHbo: false,
      tires: true,
    ),
    setups: [
      TrailSetup(
        id: 's4',
        name: 'Bikepark Setup',
        forkPsi: 110.0,
        forkOtt: 210.0,
        forkHsc: 3,
        forkLsc: 10,
        forkLsr: 8,
        shockRate: 450.0,
        shockPreload: 1.0,
        shockHsc: 2,
        shockLsc: 8,
        shockLsr: 6,
        frontTire: 'Maxxis Assegai',
        frontPressure: 1.8,
        rearTire: 'Maxxis Minion DHR II',
        rearPressure: 2.0,
        notes:
            'Standard Setup für steile Parks. Öhlins DH38 m.1 Air und TTX22m.2 Coil.',
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
      TrailSetup(
        id: 's5',
        name: 'Nass & Wurzeln',
        forkPsi: 100.0,
        forkOtt: 210.0,
        forkHsc: 2,
        forkLsc: 7,
        forkLsr: 9,
        shockRate: 450.0,
        shockPreload: 1.0,
        shockHsc: 2,
        shockLsc: 6,
        shockLsr: 5,
        frontTire: 'Maxxis Assegai',
        frontPressure: 1.6,
        rearTire: 'Maxxis Minion DHR II',
        rearPressure: 1.8,
        notes: 'Weicheres Demo-Setup für nasse, wurzelige Strecken.',
      ),
    ],
  ),
];
