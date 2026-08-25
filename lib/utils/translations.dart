      
      // lib/utils/translations.dart
// lib/utils/translations.dart

class Translations {
  static const Map<String, Map<String, String>> texts = {
    'de': {
      // HomeScreen & AddBike
      'myBikes': 'Meine Bikes',
      'tt_newBike': 'Neues Bike',
      'searchHint': 'Nach Marke oder Modell suchen...',
      'noBikes': 'Keine Bikes gefunden.',
      'addBike': 'Neues Bike hinzufügen',
      'addFromDB': 'Aus Datenbank wählen',
      'addFromDBSub': 'Vorkonfigurierte Top-Modelle inkl. Fahrwerks-Specs',
      'addManual': 'Manuell erstellen',
      'addManualSub': 'Marke, Modell und Federweg selbst eintragen',
      'newBike': 'Neues Bike',
      'addPhoto': 'Titelbild hinzufügen',
      'changePhoto': 'Titelbild ändern',
      'brand': 'Marke',
      'model': 'Modell (Tippen für Datenbank-Suche)',
      'modelHint': 'z.B. Megatower',
      'category': 'Kategorie',
      'travelFront': 'Federweg V (mm)',
      'travelRear': 'Federweg H (mm)',
      'saveBike': 'Bike speichern',
      'specsApplied': 'Specs für',
      'specsAppliedSuffix': 'übernommen!',

      // Bike Detail & Setup Card
      'newSetup': 'Neues Setup',
      'addnewSetup':'Neues Setup hinzufügen',
      'configSuspension': 'Fahrwerk konfigurieren',
      'rename': 'Umbenennen',
      'duplicate': 'Duplizieren',
      'deleteSetupTitle': 'Setup löschen?',
      'deleteSetupBody1': 'Möchtest du das Setup ',
      'deleteSetupBody2': ' wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
      'bikeNotFound' : 'Bike nicht gefunden',
      'newName': 'Neuer Name',
      'copySuffix': '(Kopie)',
      'front': 'Vorne',
      'rear': 'Hinten',
      'details': 'Details',

      // Setup Detail Screen & Dialogs
      'fork': 'Gabel',
      'shock': 'Dämpfer',
      'tires': 'Reifen',
      'frontTireModel' : 'Vorderreifen Model',
      'frontTirePresure' : 'Vorderreifen Druck',
      'rearTireModel': 'Hinterreifen Model',
      'rearTirePresure' : 'Hinterreifen Druck',
      'history': 'Änderungsverlauf',
      'notes': 'Notizen',
      'notesHint': 'Allgemeine Bemerkungen (z.B. Streckenbedingungen, Wetter...)',
      'noHistory': 'Bisher keine Anpassungen vorgenommen.',
      'newValue': 'Neuer Wert',
      'reasonOpt': 'Grund (Optional)',
      'reasonOptHint': 'z.B. Mehr Gegenhalt...',
      'whatIsThis': 'Was ist das?',
      'understood': 'Verstanden',
      'notSet': 'Nicht gesetzt',
      'air': 'Luftdruck',
      

      // add_setup_screen
      'setupName': 'Name des Setups',
      'setupNameHint': 'z.B. Bikepark Schladming',
      'noSetupName': 'Bitte Namen eingeben',
      'createSetup': 'Setup erstellen',

      // Setup Configurator Screen 
      'forkSettings': 'GABEL (FORK)',
      'shockType': 'DÄMPFER TYP',
      'shockSettings': 'DÄMPFER (SHOCK) EINSTELLUNGEN',
      'tireSettings': 'REIFEN (TIRES)',
      'mainAir': 'Haupt-Luftdruck (PSI)',
      'ottNeg': '2. Kammer / OTT (PSI/Klicks)',
      'hsc': 'High-Speed Comp. (HSC)',
      'lsc': 'Low-Speed Comp. (LSC)',
      'hsr': 'High-Speed Rebound (HSR)',
      'lsr': 'Low-Speed Rebound (LSR)',
      'tokens': 'Tokens (Spacers)',
      'hbo': 'Hydraulic Bottom-Out (HBO)',
      'airShock': 'Air (Luft)',
      'coilShock': 'Coil (Stahlfeder)',
      'shockAir': 'Luftdruck (PSI)',
      'springRate': 'Federrate (lbs/in)',
      'preload': 'Vorspannung (Preload)',
      'trackTires': 'Reifen & Druck tracken',
      'saveConfig': 'Konfiguration speichern',
      'saveChanges': 'Änderungen speichern',

      // Edit Bike Screen 
      'modelEdit': 'Modell',
      'editBike': 'Bike bearbeiten',
      'deleteBike': 'Bike löschen',
      'deleteBikeTitle': 'Bike löschen?',
      'deleteBikeBody': 'Möchtest du das Bike wirklich löschen? Alle Setups gehen unwiderruflich verloren.',

      // Allgemein
      'required': 'Pflichtfeld',
      'error': 'Fehler',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'delete': 'Löschen',


    },
    'en': {
      // HomeScreen & AddBike
      'myBikes': 'My Bikes',
      'tt_newBike': 'New Bike',
      'searchHint': 'Search brand or model...',
      'noBikes': 'No bikes found.',
      'addBike': 'Add new Bike',
      'addFromDB': 'Choose from Database',
      'addFromDBSub': 'Pre-configured top models with suspension specs',
      'addManual': 'Create manually',
      'addManualSub': 'Enter brand, model, and travel yourself',
      'newBike': 'New Bike',
      'addPhoto': 'Add Cover Photo',
      'changePhoto': 'Change Cover Photo',
      'brand': 'Brand',
      'model': 'Model (Tap to search database)',
      'modelHint': 'e.g. Megatower',
      'category': 'Category',
      'travelFront': 'Front Travel (mm)',
      'travelRear': 'Rear Travel (mm)',
      'saveBike': 'Save Bike',
      'specsApplied': 'Specs applied for',
      'specsAppliedSuffix': '!',

      // Bike Detail & Setup Card
      'newSetup': 'New Setup',
      'addnewSetup':'add new Setup',
      'configSuspension': 'Configure Suspension',
      'rename': 'Rename',
      'duplicate': 'Duplicate',
      'deleteSetupTitle': 'Delete Setup?',
      'deleteSetupBody1': 'Do you really want to delete the setup ',
      'deleteSetupBody2': '? This action cannot be undone.',
      'bikeNotFound' : 'Bike not found',
      'newName': 'New Name',
      'copySuffix': '(Copy)',
      'front': 'Front',
      'rear': 'Rear',
      'details': 'details',


      // Setup Detail Screen & Dialogs
      'fork': 'Fork',
      'shock': 'Shock',
      'tires': 'Tires',
      'frontTireModel' : 'Front tire model',
      'frontTirePresure' : 'Front tire pressure',
      'rearTireModel': 'Rear tire model',
      'rearTirePresure' : 'Rear tire pressure',
      'history': 'History',
      'notes': 'Notes',
      'notesHint': 'General remarks (e.g., trail conditions, weather...)',
      'noHistory': 'No adjustments recorded yet.',
      'newValue': 'New Value',
      'reasonOpt': 'Reason (Optional)',
      'reasonOptHint': 'e.g. more support...',
      'whatIsThis': 'What is this?',
      'understood': 'Got it',
      'notSet': 'Not set',
      'air': 'Air',

      // add_setup_screen
      'setupName': 'Setup name',
      'setupNameHint': 'e.g. Schladming',
      'noSetupName': 'Please enter a name.',
      'createSetup': 'Create setup',

      // Setup Configurator Screen 
      'forkSettings': 'FORK SETTINGS',
      'shockType': 'SHOCK TYPE',
      'shockSettings': 'SHOCK SETTINGS',
      'tireSettings': 'TIRES',
      'mainAir': 'Main Air Pressure (PSI)',
      'ottNeg': '2nd Chamber / OTT (PSI/Clicks)',
      'hsc': 'High-Speed Comp. (HSC)',
      'lsc': 'Low-Speed Comp. (LSC)',
      'hsr': 'High-Speed Rebound (HSR)',
      'lsr': 'Low-Speed Rebound (LSR)',
      'tokens': 'Tokens (Spacers)',
      'hbo': 'Hydraulic Bottom-Out (HBO)',
      'airShock': 'Air',
      'coilShock': 'Coil',
      'shockAir': 'Air Pressure (PSI)',
      'springRate': 'Spring Rate (lbs/in)',
      'preload': 'Preload (Turns)',
      'trackTires': 'Track Tires & Pressure',
      'saveConfig': 'Save Configuration',
      'saveChanges': 'Save Changes',

      // Edit Bike Screen (EN)
      'editBike': 'Edit Bike',
      'modelEdit': 'Model',
      'deleteBike': 'Delete Bike',
      'deleteBikeTitle': 'Delete Bike?',
      'deleteBikeBody': 'Do you really want to delete this bike? All setups will be lost permanently.',
      


      // Allgemein
      'required': 'Required',
      'error': 'Error',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
    },
  };

  static String get(String languageCode, String key) {
    return texts[languageCode]?[key] ?? texts['en']?[key] ?? key;
  }
}