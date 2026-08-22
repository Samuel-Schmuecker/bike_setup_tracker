// lib/utils/suspension_dictionary.dart

class SuspensionDictionary {
  // Zentrale Map für alle Erklärungen
  static const Map<String, String> parameterDescriptions = {
    'LSC': 'Low-Speed Compression: Kontrolliert das Einfedern bei langsamen Bewegungen (z. B. Wiegetritt, Bremsen, Anliegerkurven). Mehr LSC = mehr Gegenhalt, weniger LSC = mehr Traktion/Komfort.',
    'HSC': 'High-Speed Compression: Dämpft schnelle, harte Schläge (z. B. Wurzelfelder, dicke Steine, harten Landungen).',
    'LSR': 'Low-Speed Rebound: Regelt die Ausfedergeschwindigkeit nach normalen Bodenwellen und Kurven. Zu schnell = Bike springt, zu langsam = Fahrwerk versackt.',
    'HSR': 'High-Speed Rebound: Regelt das Ausfedern nach tiefen Kompressionen, damit das Heck bei Sprüngen nicht kickt.',
    'REBOUND': 'Regelt die Ausfedergeschwindigkeit. Zu schnell = Bike verhält sich wie ein Flummi, zu langsam = Fahrwerk erholt sich nicht.',
    //'PSI': 'Bestimmt die Grund-Härte (Sag) des Fahrwerks passend zum Fahrergewicht.',
    'AIR': 'Bestimmt die Grund-Härte (Sag) des Fahrwerks passend zum Fahrergewicht.',
    'MAIN': 'Bestimmt die Grund-Härte (Sag) des Fahrwerks passend zum Fahrergewicht.',
    'TOKENS': 'Volume Spacers: Verändern die Endprogression. Mehr Tokens = höherer Durchschlagschutz auf den letzten Millimetern des Federwegs.',
    'HBO': 'Hydraulic Bottom-Out: Ein hydraulischer Durchschlagschutz am Ende des Federwegs.',
    'OTT': 'Off The Top (Negativkammer): Reguliert die Sensibilität und das Ansprechverhalten auf den allerersten Zentimetern des Federwegs.',
    'SPRING RATE': 'Die Härte der Stahlfeder, passend zum Fahrergewicht gewählt.',
    'PRELOAD': 'Vorspannung der Stahlfeder. Achtung: Nicht zur Sag-Einstellung nutzen, maximal 2-3 Umdrehungen anspannen!',
  };

  // Hilfsfunktion: Sucht im übergebenen Titel (z. B. 'Fork LSC') nach dem passenden Schlüsselwort
  static String? getDescription(String title) {
    final titleUpper = title.toUpperCase();
    for (final entry in parameterDescriptions.entries) {
      if (titleUpper.contains(entry.key)) {
        return entry.value;
      }
    }
    return null; // Kein passender Text gefunden (z.B. bei Reifen)
  }
}