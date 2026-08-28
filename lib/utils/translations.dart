// lib/utils/translations.dart

class Translations {
  static const Map<String, Map<String, String>> texts = {
    'de': {
      // HomeScreen & AddBike
      'myBikes': 'Meine Bikes',
      'tt_newBike': 'Neues Bike',
      'searchHint': 'Nach Marke oder Modell suchen...',
      'tutorialInfo': 'Tutorial / Info',
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
      'addnewSetup': 'Neues Setup hinzufügen',
      'configSuspension': 'Fahrwerk konfigurieren',
      'rename': 'Umbenennen',
      'duplicate': 'Duplizieren',
      'deleteSetupTitle': 'Setup löschen?',
      'deleteSetupBody1': 'Möchtest du das Setup ',
      'deleteSetupBody2':
          ' wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
      'bikeNotFound': 'Bike nicht gefunden',
      'newName': 'Neuer Name',
      'copySuffix': '(Kopie)',
      'front': 'Vorne',
      'rear': 'Hinten',
      'details': 'Details',

      // Setup Detail Screen & Dialogs
      'fork': 'Gabel',
      'shock': 'Dämpfer',
      'tires': 'Reifen',
      'frontTireModel': 'Vorderreifen Model',
      'frontTirePressure': 'Vorderreifen-Druck',
      'rearTireModel': 'Hinterreifen Model',
      'rearTirePressure': 'Hinterreifen-Druck',
      'history': 'Änderungsverlauf',
      'notes': 'Notizen',
      'notesHint':
          'Allgemeine Bemerkungen (z.B. Streckenbedingungen, Wetter...)',
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
      'mainAir': 'Haupt-Luftdruck',
      'ottNeg': '2. Kammer / OTT',
      'hsc': 'High-Speed Comp. (HSC)',
      'lsc': 'Low-Speed Comp. (LSC)',
      'hsr': 'High-Speed Rebound (HSR)',
      'lsr': 'Low-Speed Rebound (LSR)',
      'tokens': 'Tokens (Spacers)',
      'hbo': 'Hydraulic Bottom-Out (HBO)',
      'airShock': 'Air (Luft)',
      'coilShock': 'Coil (Stahlfeder)',
      'shockAir': 'Luftdruck',
      'springRate': 'Federrate',
      'preload': 'Vorspannung (Preload)',
      'mainShort': 'Hauptkammer',
      'negativeChamberShort': 'Neg/OTT',
      'tokensShort': 'Tokens',
      'springShort': 'Feder',
      'preloadShort': 'Vorspannung',
      'componentField': '{component}: {field}',
      'unitClicks': 'Klicks',
      'unitPieces': 'Stück',
      'unitTurns': 'Umdr.',
      'unitPsiClicks': 'PSI/Klicks',
      'descriptionLsc':
          'Low-Speed Compression: Kontrolliert das Einfedern bei langsamen Bewegungen (z. B. Wiegetritt, Bremsen, Anliegerkurven). Mehr LSC = mehr Gegenhalt, weniger = mehr Traktion.',
      'descriptionHsc':
          'High-Speed Compression: Dämpft schnelle, harte Schläge (z. B. Wurzelfelder, dicke Steine, harte Landungen).',
      'descriptionLsr':
          'Low-Speed Rebound: Regelt die Ausfedergeschwindigkeit nach normalen Bodenwellen. Zu schnell = Bike springt, zu langsam = Fahrwerk versackt.',
      'descriptionHsr':
          'High-Speed Rebound: Regelt das Ausfedern nach tiefen Kompressionen, damit das Heck bei Sprüngen nicht kickt.',
      'descriptionAirPressure':
          'Bestimmt die Grund-Härte (Sag) des Fahrwerks passend zum Fahrergewicht.',
      'descriptionTokens':
          'Volume Spacers: Verändern die Endprogression. Mehr = höherer Durchschlagschutz.',
      'descriptionHbo':
          'Hydraulic Bottom-Out: Ein hydraulischer Durchschlagschutz am Ende des Federwegs.',
      'descriptionOtt':
          'Off The Top: Reguliert die Sensibilität auf den allerersten Zentimetern des Federwegs.',
      'descriptionSpringRate':
          'Die Härte der Stahlfeder, passend zum Fahrergewicht gewählt.',
      'descriptionPreload':
          'Vorspannung der Stahlfeder. Achtung: Nicht zur Sag-Einstellung nutzen (max. 2–3 Umdrehungen)!',
      'trackTires': 'Reifen & Druck tracken',
      'saveConfig': 'Konfiguration speichern',
      'saveChanges': 'Änderungen speichern',

      'setupConfig': 'Setup Konfiguration',
      'shockTypeSetup': 'Dämpfer für dieses Setup',
      'unsavedChangesTitle': 'Änderungen noch nicht gespeichert',
      'unsavedChangesBody':
          'Du hast die Konfiguration geändert. Speichere sie, bevor du den Bildschirm verlässt.',
      'keepEditing': 'Weiter bearbeiten',
      'discard': 'Verwerfen',
      'showNotesField': 'Notizfeld anzeigen',
      'editCustomField': 'Feld bearbeiten',
      'deleteFieldFromLibrary': 'Feld aus Bibliothek löschen',
      'deleteFieldConfirmTitle': 'Feld wirklich löschen?',
      'deleteFieldConfirmBody':
          'Das Feld und seine gespeicherten Werte werden aus allen Bikes und Setups entfernt.',
      'numberType': 'Zahl',
      'textType': 'Text',
      'booleanType': 'Ja / Nein',
      'booleanYes': 'Ja',
      'booleanNo': 'Nein',
      'customField': 'Eigenes Feld',
      'deleteCategory': 'Kategorie löschen',
      'addCategory': 'Neue Kategorie hinzufügen',
      'changeUnit': 'Einheit ändern',
      'unit': 'Einheit',
      'defaultValue': 'Standard',
      'newCategory': 'Neue Kategorie',
      'categoryName': 'Kategoriename',
      'create': 'Erstellen',
      'addCustomField': 'Eigenes Feld hinzufügen',
      'fieldName': 'Feldname',
      'valueType': 'Werttyp',
      'none': 'Keine',
      'customUnit': 'Eigene Einheit',
      'add': 'Hinzufügen',
      'categoryNotesHint': 'Notizen zu {category} …',
      'setupNotFound': 'Setup nicht gefunden',

      // Edit Bike Screen
      'modelEdit': 'Modell',
      'editBike': 'Bike bearbeiten',
      'deleteBike': 'Bike löschen',
      'deleteBikeTitle': 'Bike löschen?',
      'deleteBikeBody':
          'Möchtest du das Bike wirklich löschen? Alle Setups gehen unwiderruflich verloren.',

      // Allgemein
      'required': 'Pflichtfeld',
      'error': 'Fehler',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'delete': 'Löschen',

      // Erster start / info
      'welcomeTitle': 'Willkommen beim Bike Setup Tracker! 🚲',
      'welcomeText1':
          'Ich habe dir ein Beispiel-Fahrrad angelegt, damit du die Funktionen direkt ausprobieren kannst.',
      'welcomeText2':
          'WICHTIG: Du kannst dieses Beispiel (und jedes andere Rad) jederzeit bearbeiten oder löschen, indem du auf der Startseite LANGE auf die Kachel gedrückt hältst!',
      'gotIt': 'Los geht\'s!',
    },
    'en': {
      // HomeScreen & AddBike
      'myBikes': 'My Bikes',
      'tt_newBike': 'New Bike',
      'searchHint': 'Search brand or model...',
      'tutorialInfo': 'Tutorial / Info',
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
      'addnewSetup': 'add new Setup',
      'configSuspension': 'Configure Suspension',
      'rename': 'Rename',
      'duplicate': 'Duplicate',
      'deleteSetupTitle': 'Delete Setup?',
      'deleteSetupBody1': 'Do you really want to delete the setup ',
      'deleteSetupBody2': '? This action cannot be undone.',
      'bikeNotFound': 'Bike not found',
      'newName': 'New Name',
      'copySuffix': '(Copy)',
      'front': 'Front',
      'rear': 'Rear',
      'details': 'details',

      // Setup Detail Screen & Dialogs
      'fork': 'Fork',
      'shock': 'Shock',
      'tires': 'Tires',
      'frontTireModel': 'Front tire model',
      'frontTirePressure': 'Front tire pressure',
      'rearTireModel': 'Rear tire model',
      'rearTirePressure': 'Rear tire pressure',
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
      'mainAir': 'Main Air Pressure',
      'ottNeg': '2nd Chamber / OTT',
      'hsc': 'High-Speed Comp. (HSC)',
      'lsc': 'Low-Speed Comp. (LSC)',
      'hsr': 'High-Speed Rebound (HSR)',
      'lsr': 'Low-Speed Rebound (LSR)',
      'tokens': 'Tokens (Spacers)',
      'hbo': 'Hydraulic Bottom-Out (HBO)',
      'airShock': 'Air',
      'coilShock': 'Coil',
      'shockAir': 'Air Pressure',
      'springRate': 'Spring Rate',
      'preload': 'Preload',
      'mainShort': 'Main',
      'negativeChamberShort': 'Neg/OTT',
      'tokensShort': 'Tokens',
      'springShort': 'Spring',
      'preloadShort': 'Preload',
      'componentField': '{component}: {field}',
      'unitClicks': 'Clicks',
      'unitPieces': 'Pieces',
      'unitTurns': 'Turns',
      'unitPsiClicks': 'PSI/Clicks',
      'descriptionLsc':
          'Low-Speed Compression: Controls compression during slow suspension movements (e.g. pedaling, braking, berms). More LSC = more support, less = more traction.',
      'descriptionHsc':
          'High-Speed Compression: Absorbs fast, harsh impacts (e.g. root sections, big rocks, hard landings).',
      'descriptionLsr':
          'Low-Speed Rebound: Controls the extension speed after normal bumps. Too fast = bike bounces, too slow = suspension packs down.',
      'descriptionHsr':
          'High-Speed Rebound: Controls extension after deep compressions to prevent the rear end from bucking on jumps.',
      'descriptionAirPressure':
          'Determines the baseline stiffness (sag) of the suspension based on rider weight.',
      'descriptionTokens':
          'Volume Spacers: Alter bottom-out resistance. More tokens = harder to bottom out.',
      'descriptionHbo':
          'Hydraulic Bottom-Out: Extra hydraulic resistance at the very end of the stroke.',
      'descriptionOtt':
          'Off The Top: Regulates initial stroke sensitivity without affecting mid/end stroke.',
      'descriptionSpringRate':
          'The stiffness of the coil spring, chosen based on rider weight.',
      'descriptionPreload':
          'Coil spring preload. Warning: Do not use it to adjust sag (max. 2–3 turns)!',
      'trackTires': 'Track Tires & Pressure',
      'saveConfig': 'Save Configuration',
      'saveChanges': 'Save Changes',

      'setupConfig': 'Setup Configuration',
      'shockTypeSetup': 'Shock type for this setup',
      'unsavedChangesTitle': 'Unsaved changes',
      'unsavedChangesBody':
          'You changed the configuration. Save it before leaving this screen.',
      'keepEditing': 'Keep editing',
      'discard': 'Discard',
      'showNotesField': 'Show notes field',
      'editCustomField': 'Edit field',
      'deleteFieldFromLibrary': 'Delete field from library',
      'deleteFieldConfirmTitle': 'Delete field?',
      'deleteFieldConfirmBody':
          'The field and its saved values will be removed from every bike and setup.',
      'numberType': 'Number',
      'textType': 'Text',
      'booleanType': 'Yes / No',
      'booleanYes': 'Yes',
      'booleanNo': 'No',
      'customField': 'Custom field',
      'deleteCategory': 'Delete category',
      'addCategory': 'Add new category',
      'changeUnit': 'Change unit',
      'unit': 'Unit',
      'defaultValue': 'Default',
      'newCategory': 'New category',
      'categoryName': 'Category name',
      'create': 'Create',
      'addCustomField': 'Add custom field',
      'fieldName': 'Field name',
      'valueType': 'Value type',
      'none': 'None',
      'customUnit': 'Custom unit',
      'add': 'Add',
      'categoryNotesHint': 'Notes about {category} …',
      'setupNotFound': 'Setup not found',

      // Edit Bike Screen (EN)
      'editBike': 'Edit Bike',
      'modelEdit': 'Model',
      'deleteBike': 'Delete Bike',
      'deleteBikeTitle': 'Delete Bike?',
      'deleteBikeBody':
          'Do you really want to delete this bike? All setups will be lost permanently.',

      // Allgemein
      'required': 'Required',
      'error': 'Error',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',

      // First start / info
      'welcomeTitle': 'Welcome to Bike Setup Tracker! 🚲',
      'welcomeText1':
          'I have created a demo bike for you so you can try out the features right away.',
      'welcomeText2':
          'IMPORTANT: You can edit or delete this demo (and any other bike) at any time by LONG-PRESSING the bike card on the home screen!',
      'gotIt': 'Let\'s go!',
    },
  };

  static String get(String languageCode, String key) {
    return texts[languageCode]?[key] ?? texts['en']?[key] ?? key;
  }

  static List<String> get supportedLanguageCodes =>
      List.unmodifiable(texts.keys);

  static String nextLanguageCode(String currentLanguageCode) {
    final languages = supportedLanguageCodes;
    if (languages.isEmpty) {
      return currentLanguageCode;
    }

    final currentIndex = languages.indexOf(currentLanguageCode);
    return languages[(currentIndex + 1) % languages.length];
  }

  static String format(
    String languageCode,
    String key,
    Map<String, String> parameters,
  ) {
    var value = get(languageCode, key);
    for (final entry in parameters.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }
}
