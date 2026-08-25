// lib/utils/suspension_dictionary.dart

class SuspensionDictionary {
  static const Map<String, Map<String, String>> parameterDescriptions = {
    'de': {
      'LSC': 'Low-Speed Compression: Kontrolliert das Einfedern bei langsamen Bewegungen (z. B. Wiegetritt, Bremsen, Anliegerkurven). Mehr LSC = mehr Gegenhalt, weniger = mehr Traktion.',
      'HSC': 'High-Speed Compression: Dämpft schnelle, harte Schläge (z. B. Wurzelfelder, dicke Steine, harte Landungen).',
      'LSR': 'Low-Speed Rebound: Regelt die Ausfedergeschwindigkeit nach normalen Bodenwellen. Zu schnell = Bike springt, zu langsam = Fahrwerk versackt.',
      'HSR': 'High-Speed Rebound: Regelt das Ausfedern nach tiefen Kompressionen, damit das Heck bei Sprüngen nicht kickt.',
      'PSI': 'Bestimmt die Grund-Härte (Sag) des Fahrwerks passend zum Fahrergewicht.',
      'AIR': 'Bestimmt die Grund-Härte (Sag) des Fahrwerks passend zum Fahrergewicht.',
      'MAIN': 'Bestimmt die Grund-Härte (Sag) des Fahrwerks passend zum Fahrergewicht.',
      'TOKENS': 'Volume Spacers: Verändern die Endprogression. Mehr = höherer Durchschlagschutz.',
      'HBO': 'Hydraulic Bottom-Out: Ein hydraulischer Durchschlagschutz am Ende des Federwegs.',
      'OTT': 'Off The Top: Reguliert die Sensibilität auf den allerersten Zentimetern des Federwegs.',
      'SPRING RATE': 'Die Härte der Stahlfeder, passend zum Fahrergewicht gewählt.',
      'PRELOAD': 'Vorspannung der Stahlfeder. Achtung: Nicht zur Sag-Einstellung nutzen (max. 2-3 Umdrehungen)!',
    },
    'en': {
      'LSC': 'Low-Speed Compression: Controls compression during slow suspension movements (e.g. pedaling, braking, berms). More LSC = more support, less = more traction.',
      'HSC': 'High-Speed Compression: Absorbs fast, harsh impacts (e.g. root sections, big rocks, hard landings).',
      'LSR': 'Low-Speed Rebound: Controls the extension speed after normal bumps. Too fast = bike bounces, too slow = suspension packs down.',
      'HSR': 'High-Speed Rebound: Controls extension after deep compressions to prevent the rear end from bucking on jumps.',
      'PSI': 'Determines the baseline stiffness (Sag) of the suspension based on rider weight.',
      'AIR': 'Determines the baseline stiffness (Sag) of the suspension based on rider weight.',
      'MAIN': 'Determines the baseline stiffness (Sag) of the suspension based on rider weight.',
      'TOKENS': 'Volume Spacers: Alter bottom-out resistance. More tokens = harder to bottom out.',
      'HBO': 'Hydraulic Bottom-Out: Extra hydraulic resistance at the very end of the stroke.',
      'OTT': 'Off The Top: Regulates initial stroke sensitivity without affecting mid/end stroke.',
      'SPRING RATE': 'The stiffness of the coil spring, chosen based on rider weight.',
      'PRELOAD': 'Coil spring preload. Warning: Do not use to adjust sag (max 2-3 turns)!',
    }
  };

  // NEU: Nimmt jetzt auch den languageCode (z.B. 'de' oder 'en') entgegen
  static String? getDescription(String title, String languageCode) {
    final titleUpper = title.toUpperCase();
    final dict = parameterDescriptions[languageCode] ?? parameterDescriptions['en']!;
    
    for (final entry in dict.entries) {
      if (titleUpper.contains(entry.key)) {
        return entry.value;
      }
    }
    return null; 
  }
}