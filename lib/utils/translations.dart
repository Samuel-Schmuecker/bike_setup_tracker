// lib/utils/translations.dart

class Translations {
  static const Map<String, Map<String, String>> texts = {
    'de': {
      'languageName': 'Deutsch',
      'bikeCategoryEnduro': 'Enduro',
      'bikeCategoryTrail': 'Trail',
      'bikeCategoryDownhill': 'Downhill',
      'bikeCategoryAllMountain': 'All Mountain',
      'bikeCategoryGravel': 'Gravel',
      'bikeCategoryCrossCountry': 'Cross Country',
      'bikeCategoryEBike': 'E-Bike',
      'authReturnSuccessTitle': 'Anmeldung verarbeitet',
      'authReturnSuccessBody':
          'Du kannst dieses Fenster schließen und zur App zurückkehren.',
      'authReturnErrorTitle': 'Anmeldung nicht abgeschlossen',
      'authReturnErrorBody':
          'Bitte kehre zur App zurück und versuche es erneut.',
      'startupLoadError':
          'Die gespeicherten Daten konnten nicht sicher geladen werden. Sie wurden nicht überschrieben. Bitte die App-Daten nicht löschen und den Support kontaktieren.',
      'bikeTravelSummary': '{front}V / {rear}H mm',
      'backupBikeCount': '{count} Bikes',
      'backupFileType': 'Bike-Sicherung',
      'backupTooLarge': 'Die Sicherung ist größer als 50 MB.',
      'accountLogin': 'Login',
      'diagnosticCode': 'Code: {code}',
      'rangeInvalid': 'Gültige Grenzen und Schrittweite eingeben.',
      'rangeInvalidInteger':
          'Gültige Grenzen und Schrittweite eingeben. Nur ganze Zahlen.',
      'rangeMinimum': 'Minimum',
      'rangeMaximum': 'Maximum',
      // Onboarding, account/backup and adjustment ranges.
      'authProofHelp':
          'Der Anmeldenachweis fehlt, ist ungültig oder abgelaufen. Starte und beende die Anmeldung im selben Browser. Auf dem iPhone die App direkt in Safari öffnen und dort erneut anmelden. Vorhandene App-Daten nicht löschen.',
      'authAlreadyLinkedHelp':
          'Dieses Google-Konto ist bereits mit einem App-Konto verknüpft. Wähle „Login“, um dein bestehendes Konto zu öffnen. Deine Gastdaten bleiben bis zu deiner Entscheidung erhalten.',
      'authManualLinkingHelp':
          'Aktiviere „Allow manual linking“ in den Supabase-Auth-Einstellungen.',
      'authIncompleteHelp':
          'Google-Anmeldung nicht abgeschlossen. Bitte abbrechen und erneut versuchen. Bei erneutem Fehler den unten angezeigten Fehlercode mitteilen.',
      'tourAdvancedSection': 'Vertiefung',
      'tourBasicsSection': 'Grundtour',
      'tourClose': 'Tour schließen',
      'tourSkip': 'Überspringen',
      'tourNext': 'Weiter',
      'privacyPolicy': 'Datenschutzerklärung',
      'rangeStepSize': 'Schrittweite',

      'rangeRemove': 'Bereich entfernen',
      'rangeOutside': 'Außerhalb des Bereichs',
      'tourOwnBikeSection': 'Dein eigenes Bike',
      'tourDatabaseTitle': 'Datenbank oder manuell',
      'tourDatabaseBody':
          '**Modell suchen** → Vorschlag aus der Bike-Datenbank wählen. Nicht dabei? **Modell und Marke selbst eingeben.**',
      'tourSetupMenuHint':
          'Umbenennen ändert den Namen, Duplizieren erzeugt eine Kopie. Löschen ist während der Tour deaktiviert.',
      'tourBack': 'Zurück zur Tour',
      'tourSetupMenuTitle': 'Setup lange drücken',
      'tourSetupMenuBody':
          '**Lange drücken** → umbenennen oder duplizieren. Danach Menü schließen.',
      'tourOpenSetupTitle': 'Setup öffnen',
      'tourOpenSetupBody': '**Setup antippen** → Einstellwerte öffnen.',
      'tourFavoriteTitle': 'Favoriten markieren',
      'tourFavoriteBody':
          '**Stern antippen** → Favorit. Favoriten stehen zuerst. Erneut tippen zum Entfernen.',
      'tourCompleteTitle': 'Tour abgeschlossen',
      'tourCompleteBody':
          'Lege jetzt dein eigenes Bike an. Beim ersten Setup zeigen wir dir die Auswahl der Werte, eigene Felder und Kategorien.',
      'tourAddOwnBike': 'Eigenes Bike anlegen',

      'tourInterrupted': 'Die Tour wurde unterbrochen. Bitte erneut starten.',
      'tourSelectValuesTitle': 'Deine Werte auswählen',
      'tourSelectValuesBody':
          '**Nur tracken, was du brauchst.** Wähle hier PSI, Klicks, Tokens und mehr.',
      'tourRangesTitle': 'Einstellbereiche festlegen',
      'tourRangesBody':
          '**Minimum, Maximum und Schrittweite** passend zu deinem Bauteil einstellen.',
      'tourCustomFieldTitle': 'Eigenes Feld hinzufügen',
      'tourCustomFieldBody':
          '**Ein Wert fehlt?** Über + fügst du ein eigenes Feld hinzu.',
      'tourCustomCategoryTitle': 'Eigene Kategorie anlegen',
      'tourCustomCategoryBody':
          '**Mehr als Fahrwerk und Reifen.** Lege z. B. „Dropper Post“ als Kategorie an.',
      'tourFirstSetupSection': 'Dein erstes Setup',
      'rangeAdd': 'Einstellbereich hinzufügen',
      'rangeValueInvalid':
          'Wert muss im Bereich und auf einem Einstellschritt liegen',
      'tourSaveValueTitle': 'Wert ändern und speichern',
      'tourSaveValueBody':
          '**Wert antippen → ändern → Speichern.** Die Änderung bleibt am Demo-Bike.',
      'tourBasicsCompleteTitle': 'Grundtour geschafft',
      'tourBasicsCompleteBody':
          'Jetzt kannst du dein eigenes Bike anlegen. Beim ersten Setup zeigen wir dir kurz, wie du Werte und eigene Felder auswählst. Oder probiere erst die Vertiefung aus.',
      'tourStartAdvanced': 'Vertiefung starten',
      'tourSetupParametersTitle': 'Parameter pro Setup',
      'tourSetupParametersBody':
          '**Dieses Regler-Symbol** öffnet die Parameterauswahl. Wähle für **jedes Setup separat**, welche Werte du trackst.',
      'tourOpenOrderingTitle': 'Umsortieren öffnen',
      'tourOpenOrderingBody':
          '**Pfeile antippen** → Sortiermodus. Der Setup-Wechsel ist dabei gesperrt.',
      'tourMoveFieldTitle': 'Ein Feld verschieben',
      'tourMoveFieldBody': '**Feld halten, verschieben, loslassen.**',
      'tourFinishOrderingTitle': 'Sortierung abschließen',
      'tourFinishOrderingBody':
          '**Fertig antippen.** Reihenfolge nur hier oder für alle Demo-Setups übernehmen.',
      'tourHistoryTitle': 'Änderungen nachvollziehen',
      'tourHistoryBody':
          '**Vorher → Nachher** mit optionaler Notiz. Hier findest du deine Änderungen.',
      'tourSwipeTitle': 'Zwischen Setups wischen',
      'tourSwipeBody':
          '**Links oder rechts wischen.** Am PC: mit gedrückter linker Maustaste ziehen.',
      'tourStartError':
          'Die Tour konnte nicht gestartet werden. Bitte erneut versuchen.',
      'welcomeCloudConsent':
          'Nach „Los geht’s“ wird ein Gastkonto erstellt und deine Daten werden automatisch in einer privaten Cloud gespeichert. Verknüpfe unter „Konto & Datensicherung“ Google für die Wiederherstellung nach Geräteverlust.',
      'accountBackup': 'Konto & Datensicherung',
      'tourBikeMenuHint':
          'Bearbeiten öffnet auch den Namen. Löschen erklären wir nur; es ist während der Tour deaktiviert.',
      'backupNeedsAttention':
          'Die Datensicherung benötigt deine Aufmerksamkeit.',
      'view': 'Anzeigen',
      'backupReminderTitle': 'Datensicherung nicht vergessen',
      'backupReminderBody':
          'Dein erstes Bike ist angelegt! Prüfe unter „Konto & Datensicherung“ deine Sicherung und verknüpfe dein Konto für die Wiederherstellung nach Geräteverlust.',
      'later': 'Später',
      'tourBikeMenuTitle': 'Bikes verwalten',
      'tourBikeMenuBody':
          '**Lange drücken** → Bike-Menü. Danach schließen. Wir üben am Demo-Bike.',
      'tourOpenBikeTitle': 'Bike öffnen',
      'tourOpenBikeBody': '**Bike antippen** → Setups öffnen.',
      'guestDataChoiceTitle': 'Was soll mit deinen Gastdaten passieren?',
      'guestDataChoiceBody':
          'Nach erfolgreicher Google-Anmeldung wird das bisherige Gastkonto gelöscht. Übernommene Daten werden vorher vollständig synchronisiert.',
      'guestDataImportCopies': 'Daten als Kopien übernehmen',
      'backupExport': 'Sicherung exportieren',
      'guestDataDiscard': 'Gastdaten verwerfen',

      'guestDataDiscardTitle': 'Gastdaten wirklich verwerfen?',
      'guestDataDiscardBody':
          'Nach erfolgreicher Anmeldung werden das alte Gastkonto, seine Cloud-Daten und lokalen Sicherungen gelöscht. Exportierte Dateien bleiben erhalten.',
      'accountDeleteTitle': 'Konto endgültig löschen?',
      'accountDeleteBody':
          'Dein App-Konto, Cloud-Daten, Bilder und frühere Versionen sowie die lokalen Sicherungen dieses Kontos werden gelöscht. Dein Google-Konto bleibt bestehen. Exportierte Dateien und Kopien auf anderen Geräten bleiben erhalten. Anbieter-Backups unterliegen deren Aufbewahrungsfristen. Dieser Vorgang kann nicht rückgängig gemacht werden.',
      'accountDeleteConfirmationHint': 'Zur Bestätigung DELETE eingeben',
      'accountDeleteConfirm': 'Endgültig löschen',
      'accountOperationError':
          'Der Vorgang wurde nicht abgeschlossen. Bitte Verbindung und Eingaben prüfen. Details: {error}',
      'backupImportTitle': 'Sicherung importieren?',
      'backupImportBody':
          'Die Bikes werden als neue Kopien hinzugefügt. Vorhandene Bikes bleiben erhalten.',
      'confirm': 'Bestätigen',
      'backupCloudHistoryTitle': 'Frühere Cloud-Versionen',
      'backupCloudHistoryEmpty': 'Noch keine früheren Versionen vorhanden.',
      'close': 'Schließen',
      'backupRestoreTitle': 'Version wiederherstellen?',
      'backupRestoreBody':
          'Diese Fassung wird wieder zur aktuellen Fassung. Der aktuelle lokale Bestand wird vorher gesichert.',
      'backupLocalTitle': 'Lokale Sicherungen',
      'backupLocalEmpty': 'Noch keine Sicherungen vorhanden.',
      'backupSeparateAccount': 'Separat gespeicherter Kontobestand',
      'backupRestoreCopiesTitle': 'Als Kopien übernehmen?',
      'backupRestoreCopiesBody':
          'Diese Bikes werden dem aktuellen Bestand hinzugefügt.',
      'accountDocumentBikeOrder': 'Reihenfolge der Bikes',
      'accountDocumentFieldLibrary': 'Bibliothek eigener Felder',
      'accountDocumentDeletedBike': 'Gelöschtes Bike',
      'syncStatusGoogleWaiting':
          'Cloud synchronisiert; Google-Anmeldung noch offen.',
      'syncStatusGoogleError':
          'Google-Anmeldung konnte nicht zugeordnet werden oder ist abgelaufen. Bitte abbrechen und erneut anmelden.',
      'syncStatusSyncing': 'Daten werden synchronisiert …',
      'syncStatusSynced': 'Mit Cloud synchronisiert',
      'syncStatusConflict': 'Änderungskonflikt – Auswahl erforderlich',
      'syncStatusSetup':
          'Cloud-Einrichtung fehlt: SQL-Skript und Zugriffsregeln prüfen.',
      'syncStatusSession':
          'Anmeldung fehlt. Bitte erneut anmelden. Lokale Daten bleiben erhalten.',
      'syncStatusAuth':
          'Anmeldung nicht möglich. Verbindung und anonyme Anmeldung in Supabase prüfen.',
      'syncStatusLocal':
          'Lokales Speichern fehlgeschlagen. Bitte freien Speicher prüfen.',
      'syncStatusOffline':
          'Sicherung ausstehend. Verbindung oder Cloud-Dienst nicht verfügbar; automatischer Wiederholungsversuch folgt.',
      'syncStatusPending': 'Sicherung ausstehend',
      'syncStatusImages':
          'Räder geladen. Einige Fotos fehlen noch; sie werden erneut geladen.',
      'syncStatusCleanup':
          'Räder synchronisiert. Die Bildbereinigung wird erneut versucht.',
      'accountDelete': 'Konto löschen',
      'accountDeletedBody':
          'Dein Konto wurde gelöscht. Es wird kein neues Gastkonto angelegt, bis du die App erneut nutzt.',
      'accountDeletionPendingBody':
          'Die Kontolöschung wurde gestartet. Die Synchronisierung ist gesperrt. Bei einem Verbindungsfehler kannst du die Löschung erneut versuchen.',
      'backupExportLocal': 'Lokale Daten exportieren',
      'accountRestartGuest': 'Neu als Gast starten',
      'accountRetryDeletion': 'Löschung erneut versuchen',
      'accountGuestStatus': 'Du nutzt die App als Gast',
      'accountSessionExpiredBody':
          'Deine gespeicherte Anmeldung ist nicht mehr gültig. Das Konto wurde möglicherweise außerhalb der App gelöscht. Deine lokalen Daten sind noch vorhanden.',
      'accountReconnectTitle': 'Lokale Daten neu verbinden?',
      'accountReconnectBody':
          'Es wird ein neues Gastkonto erstellt. Deine vorhandenen lokalen Daten werden dorthin übertragen. Anschließend kannst du Google verbinden oder dich anmelden.',
      'accountReconnect': 'Lokale Daten neu verbinden',
      'accountLastSync': 'Letzte Synchronisierung',
      'accountStorageBody':
          'Bikes, Setups und Bilder werden lokal und automatisch in deiner privaten Cloud gespeichert.',
      'accountLinkGoogleBody':
          'Verknüpfe dein Google-Konto, um nach Geräteverlust oder gelöschten App-Daten wieder Zugriff zu erhalten. Die anonyme Anmeldung allein ermöglicht das nicht.',
      'accountSyncNow': 'Jetzt synchronisieren',
      'accountConflictsTitle': 'Konflikte',
      'accountConflictsBody':
          'Beide Fassungen bleiben bis zur Auswahl erhalten. Vor der Auflösung wird lokal eine Sicherung angelegt.',
      'accountConflictCopy': 'Konfliktkopie',
      'accountKeepBoth': 'Beide Fassungen behalten',
      'accountKeepLocal': 'Lokale Fassung behalten',
      'accountUseCloud': 'Cloud-Fassung übernehmen',
      'accountGoogleConnected': 'Google ist verbunden',
      'accountTitle': 'Dein Konto',
      'accountLoginSubtitle': 'Du hast bereits ein Konto?',
      'accountLoginBody':
          'Melde dich mit Google an, um auf deine gespeicherten Bikes und Setups zuzugreifen. Du entscheidest vorher, was mit deinen Gastdaten passiert.',
      'accountRegister': 'Registrieren',
      'accountRegisterSubtitle': 'Neu hier? Sichere deine Bikes.',
      'accountRegisterBody':
          'Erstelle dein App-Konto mit Google. Deine bisherigen Bikes und Setups bleiben erhalten und werden mit deinem Konto verknüpft. Du brauchst kein zusätzliches Passwort.',
      'accountGoogleLinkedBody':
          'Google ist verknüpft. Melde dich auf anderen Geräten mit demselben Google-Konto an.',
      'accountGoogleWaitingBody':
          'Schließe die Google-Anmeldung im Browser ab und kehre zur App zurück. Bei einer Verknüpfung mit einem bereits verwendeten Google-Konto bitte abbrechen und „Login“ wählen.',
      'accountCancelGoogle': 'Google-Anmeldung abbrechen',
      'accountSignOutTitle': 'Abmelden?',
      'accountSignOutBody':
          'Der lokale Kontobestand bleibt separat erhalten. Noch nicht synchronisierte Änderungen sind nur auf diesem Gerät vorhanden.',
      'accountSignOut': 'Abmelden',
      'accountGoogleOptionalBody':
          'Google ist optional. Du kannst die App weiter als Gast nutzen.',
      'guestCleanupTitle': 'Bisheriges Gastkonto bereinigen',
      'guestCleanupSyncingBody':
          'Die Gastdaten werden abgeglichen. Erst danach wird das alte Gastkonto gelöscht.',
      'guestCleanupErrorBody':
          'Das alte Gastkonto konnte noch nicht gelöscht werden. Deine Google-Daten bleiben erhalten. Bitte erneut versuchen. Wenn der Fehler bleibt, muss der Gastbestand geprüft werden.',
      'retry': 'Erneut versuchen',
      'backupFilesTitle': 'Sicherungsdateien',
      'backupFilesBody':
          'Eine exportierte Datei enthält deine Bikes, Setups und Bilder. Bewahre sie an einem sicheren Ort außerhalb dieses Geräts auf.',
      'backupExportAction': 'Exportieren',
      'backupImportAction': 'Importieren',
      'backupCloudVersions': 'Cloud-Versionen',
      'accountDeleteSummary':
          'Entfernt dein App-Konto und die zugehörigen Daten dauerhaft. Exportiere vorher eine Sicherung, wenn du deine Daten behalten möchtest.',
      'accountExportBeforeDelete': 'Vorher Sicherung exportieren',
      'accountDeleteAction': 'Konto und Daten löschen',
      'orderSetups': 'Setups ordnen',
      'favoritesStayFirst':
          'Ziehe die Setups in die gewünschte Reihenfolge. Favoriten bleiben oben.',
      // HomeScreen & AddBike
      'myBikes': 'Meine Bikes',
      'addFavorite': 'Als Favorit markieren',
      'removeFavorite': 'Favorit entfernen',
      'orderBikes': 'Bikes sortieren',
      'orderBikesHint':
          'Halte eine Bike-Kachel gedrückt und ziehe sie an die gewünschte Stelle. Favoriten bleiben oben. Änderungen werden automatisch gespeichert.',
      'finishOrdering': 'Fertig',
      'settings': 'Einstellungen',
      'appearance': 'Farben & Darstellung',
      'appearanceHint':
          'Wähle eine Farbe aus der Palette oder gib einen Hex-Wert ein. Gültige Eingaben werden direkt gespeichert. Der Haken zeigt deine aktuelle Farbe.',
      'applyColor': 'Farbe übernehmen',
      'chooseColor': 'Farbe auswählen',
      'paletteHint':
          'Tippe oder ziehe auf der Farbfläche, um deine Farbe auszuwählen.',
      'colorHue': 'Farbton',
      'colorSaturation': 'Sättigung',
      'colorBrightness': 'Helligkeit',
      'backgroundColor': 'Hintergrundfarbe',
      'accentColor': 'Akzentfarbe',
      'colorPreview': 'So sehen deine Farben aus',
      'resetColors': 'Farben zurücksetzen',
      'customColor': 'Eigene Farbe (Hex)',
      'invalidColor': 'Bitte 6 Hex-Zeichen eingeben, z. B. 009688.',
      'language': 'Sprache',
      'tt_newBike': 'Neues Bike',
      'searchHint': 'Nach Marke oder Modell suchen...',
      'tutorialInfo': 'Anleitung / Informationen',
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
      'clearHistory': 'Änderungsverlauf löschen',
      'clearHistoryTitle': 'Änderungsverlauf löschen?',
      'clearHistoryBody':
          'Möchtest du wirklich den gesamten Änderungsverlauf dieses Setups löschen? Dies kann nicht rückgängig gemacht werden. Die aktuellen Setup-Werte bleiben erhalten.',
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
      'deleteCategoryConfirmTitle': 'Kategorie wirklich löschen?',
      'deleteCategoryConfirmBody':
          'Die Kategorie mit allen Feldern und gespeicherten Werten wird auch aus allen anderen Rädern und Setups entfernt. Wenn du die Felder nur ausblenden möchtest, deaktiviere sie stattdessen im jeweiligen Rad oder Setup.',
      'renameCategory': 'Kategorie umbenennen',
      'editFieldOrder': 'Felder anordnen',
      'finishFieldOrder': 'Fertig',
      'dragField': 'Zum Verschieben kurz gedrückt halten und ziehen',
      'dragCategory': 'Kategorie gedrückt halten und verschieben',
      'fieldOrderHint':
          'Halte ein Feld kurz gedrückt und ziehe es innerhalb seiner Kategorie an die gewünschte Stelle. Ganze Kategorien verschiebst du, indem du ihre Überschrift oder den Griff daneben gedrückt hältst und ziehst.',
      'applyFieldOrderTitle': 'Anordnung übernehmen?',
      'applyFieldOrderBody':
          'Diese Anordnung auch für die anderen Setups dieses Rads übernehmen? Werte und aktivierte Felder bleiben unverändert.',
      'fieldOrderOnlyThis': 'Nur dieses Setup',
      'fieldOrderApplyAll': 'Für alle übernehmen',
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
          'Möchtest du das Bike mit seinen Setups löschen? Zugehörige Fotos werden nach der Synchronisierung ebenfalls gelöscht, sofern kein anderes Bike sie benötigt. Ältere Cloud-Versionen bleiben ohne diese Fotos wiederherstellbar.',

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
          'Halte auf der Startseite eine Bike-Kachel lange gedrückt. Im Menü kannst du das Bike bearbeiten, löschen oder die Bikes neu sortieren.',
      'gotIt': 'Los geht\'s!',
    },
    'en': {
      'languageName': 'English',
      'bikeCategoryEnduro': 'Enduro',
      'bikeCategoryTrail': 'Trail',
      'bikeCategoryDownhill': 'Downhill',
      'bikeCategoryAllMountain': 'All Mountain',
      'bikeCategoryGravel': 'Gravel',
      'bikeCategoryCrossCountry': 'Cross Country',
      'bikeCategoryEBike': 'E-Bike',
      'authReturnSuccessTitle': 'Sign-in processed',
      'authReturnSuccessBody':
          'You can close this window and return to the app.',
      'authReturnErrorTitle': 'Sign-in incomplete',
      'authReturnErrorBody': 'Please return to the app and try again.',
      'startupLoadError':
          'The saved data could not be loaded safely. It has not been overwritten. Do not clear the app data; please contact support.',
      'bikeTravelSummary': '{front}F / {rear}R mm',
      'backupBikeCount': '{count} bikes',
      'backupFileType': 'Bike backup',
      'backupTooLarge': 'The backup exceeds 50 MB.',
      'accountLogin': 'Login',
      'diagnosticCode': 'Code: {code}',
      'rangeInvalid': 'Enter valid limits and step size.',
      'rangeInvalidInteger':
          'Enter valid limits and step size. Whole numbers only.',
      'rangeMinimum': 'Minimum',
      'rangeMaximum': 'Maximum',
      // Onboarding, account/backup and adjustment ranges.
      'authProofHelp':
          'The sign-in proof is missing, invalid or expired. Start and finish in the same browser. On iPhone, open the app directly in Safari and retry there. Do not clear existing app data.',
      'authAlreadyLinkedHelp':
          'This Google account is already linked to an app account. Choose “Login” to open your existing account. Your guest data is kept until you decide what to do with it.',
      'authManualLinkingHelp':
          'Enable Allow manual linking in Supabase Auth settings.',
      'authIncompleteHelp':
          'Google sign-in did not complete. Cancel and retry. If it fails again, report the diagnostic code below.',
      'tourAdvancedSection': 'More features',
      'tourBasicsSection': 'Basics',
      'tourClose': 'Close tour',
      'tourSkip': 'Skip',
      'tourNext': 'Next',
      'privacyPolicy': 'Privacy policy',
      'rangeStepSize': 'Step size',

      'rangeRemove': 'Remove range',
      'rangeOutside': 'Outside range',
      'tourOwnBikeSection': 'Your own bike',
      'tourDatabaseTitle': 'Database or manual entry',
      'tourDatabaseBody':
          '**Search a model** → choose a bike database suggestion. Not listed? **Enter model and brand yourself.**',
      'tourSetupMenuHint':
          'Rename changes the name; Duplicate creates a copy. Deletion is disabled during the tour.',
      'tourBack': 'Back to tour',
      'tourSetupMenuTitle': 'Press and hold a setup',
      'tourSetupMenuBody':
          '**Press and hold** → rename or duplicate. Then close the menu.',
      'tourOpenSetupTitle': 'Open setup',
      'tourOpenSetupBody': '**Tap the setup** → open its settings.',
      'tourFavoriteTitle': 'Mark favorites',
      'tourFavoriteBody':
          '**Tap the star** → favorite. Favorites stay first. Tap again to remove.',
      'tourCompleteTitle': 'Tour complete',
      'tourCompleteBody':
          'Add your own bike next. Your first setup includes a short guide to tracking values, custom fields and categories.',
      'tourAddOwnBike': 'Add my bike',

      'tourInterrupted': 'Please restart the tour.',
      'tourSelectValuesTitle': 'Choose your values',
      'tourSelectValuesBody':
          '**Track only what you need.** Select PSI, clicks, tokens and more.',
      'tourRangesTitle': 'Set adjustment ranges',
      'tourRangesBody':
          'Set **minimum, maximum and step size** to match your component.',
      'tourCustomFieldTitle': 'Add a custom field',
      'tourCustomFieldBody':
          '**Missing a value?** Use + to add your own field.',
      'tourCustomCategoryTitle': 'Add a custom category',
      'tourCustomCategoryBody':
          '**Beyond suspension and tires.** Add a category such as “Dropper Post”.',
      'tourFirstSetupSection': 'Your first setup',
      'rangeAdd': 'Add adjustment range',
      'rangeValueInvalid': 'Value must match the range and step size',
      'tourSaveValueTitle': 'Change and save a value',
      'tourSaveValueBody':
          '**Tap value → change → Save.** The change stays on the demo bike.',
      'tourBasicsCompleteTitle': 'Basics complete',
      'tourBasicsCompleteBody':
          'You can now add your own bike. Your first setup includes a short guide to tracking values and custom fields. Or explore more features first.',
      'tourStartAdvanced': 'Explore more',
      'tourSetupParametersTitle': 'Parameters per setup',
      'tourSetupParametersBody':
          '**This sliders icon** opens parameter selection. Choose which values to track **separately for each setup**.',
      'tourOpenOrderingTitle': 'Open ordering',
      'tourOpenOrderingBody':
          '**Tap the arrows** → ordering mode. Switching setups is locked while ordering.',
      'tourMoveFieldTitle': 'Move a field',
      'tourMoveFieldBody': '**Hold, drag and release a field.**',
      'tourFinishOrderingTitle': 'Finish ordering',
      'tourFinishOrderingBody':
          '**Tap Done.** Apply the order here or to all demo setups.',
      'tourHistoryTitle': 'Review changes',
      'tourHistoryBody':
          '**Before → After** with an optional note. Find your changes here.',
      'tourSwipeTitle': 'Swipe between setups',
      'tourSwipeBody':
          '**Swipe left or right.** On a PC: drag with the left mouse button held.',
      'tourStartError': 'Could not start the tour. Please try again.',
      'welcomeCloudConsent':
          'After you tap “Let’s go”, a guest account is created and your data is saved automatically in a private cloud. Link Google under Account & backup to restore access after losing your device.',
      'accountBackup': 'Account & backup',
      'tourBikeMenuHint':
          'Edit also lets you rename the bike. Deletion is disabled during the tour.',
      'backupNeedsAttention': 'Your backup needs attention.',
      'view': 'View',
      'backupReminderTitle': 'Remember your backup',
      'backupReminderBody':
          'Your first bike is ready! Check Account & backup and link your account so you can restore your data if you lose your device.',
      'later': 'Later',
      'tourBikeMenuTitle': 'Manage bikes',
      'tourBikeMenuBody':
          '**Press and hold** → bike menu. Then close it. Practice on the demo bike.',
      'tourOpenBikeTitle': 'Open bike',
      'tourOpenBikeBody': '**Tap the bike** → open its setups.',
      'guestDataChoiceTitle': 'What should happen to your guest data?',
      'guestDataChoiceBody':
          'After successful Google sign-in, the old guest account is deleted. Imported data is fully synced first.',
      'guestDataImportCopies': 'Import data as copies',
      'backupExport': 'Export backup',
      'guestDataDiscard': 'Discard guest data',

      'guestDataDiscardTitle': 'Discard guest data?',
      'guestDataDiscardBody':
          'After successful sign-in, the old guest account, its cloud data and local backups are deleted. Exported files remain.',
      'accountDeleteTitle': 'Permanently delete account?',
      'accountDeleteBody':
          'Your app account, cloud data, images, previous versions and this account’s local backups will be deleted. Your Google account remains. Exported files and copies on other devices remain. Provider backups follow their retention periods. This cannot be undone.',
      'accountDeleteConfirmationHint': 'Type DELETE to confirm',
      'accountDeleteConfirm': 'Delete permanently',
      'accountOperationError':
          'The operation did not complete. Please check your connection and entries. Details: {error}',
      'backupImportTitle': 'Import backup?',
      'backupImportBody':
          'Bikes will be added as new copies. Existing bikes are retained.',
      'confirm': 'Confirm',
      'backupCloudHistoryTitle': 'Previous cloud versions',
      'backupCloudHistoryEmpty': 'No previous versions yet.',
      'close': 'Close',
      'backupRestoreTitle': 'Restore version?',
      'backupRestoreBody':
          'This version becomes current. The current local data is backed up first.',
      'backupLocalTitle': 'Local backups',
      'backupLocalEmpty': 'No backups yet.',
      'backupSeparateAccount': 'Separately saved account data',
      'backupRestoreCopiesTitle': 'Restore as copies?',
      'backupRestoreCopiesBody':
          'These bikes will be added to the current workspace.',
      'accountDocumentBikeOrder': 'Bike order',
      'accountDocumentFieldLibrary': 'Custom field library',
      'accountDocumentDeletedBike': 'Deleted bike',
      'syncStatusGoogleWaiting': 'Cloud synced; Google sign-in pending.',
      'syncStatusGoogleError':
          'Google sign-in could not be matched or expired. Please cancel and sign in again.',
      'syncStatusSyncing': 'Syncing data …',
      'syncStatusSynced': 'Synced with cloud',
      'syncStatusConflict': 'Conflicting changes – choose a version',
      'syncStatusSetup':
          'Cloud setup is incomplete: check SQL migration and access rules.',
      'syncStatusSession':
          'Session missing. Please sign in again. Local data is retained.',
      'syncStatusAuth':
          'Unable to authenticate. Check connection and anonymous sign-ins in Supabase.',
      'syncStatusLocal': 'Local save failed. Please check free storage.',
      'syncStatusOffline':
          'Backup pending. Connection or cloud service unavailable; retrying automatically.',
      'syncStatusPending': 'Backup pending',
      'syncStatusImages':
          'Bikes loaded. Some photos are still unavailable and will be retried.',
      'syncStatusCleanup': 'Bikes synced. Image cleanup will be retried.',
      'accountDelete': 'Delete account',
      'accountDeletedBody':
          'Your account has been deleted. No new guest account is created until you start again.',
      'accountDeletionPendingBody':
          'Account deletion has started. Sync is blocked. If the connection fails, retry deletion.',
      'backupExportLocal': 'Export local data',
      'accountRestartGuest': 'Start again as guest',
      'accountRetryDeletion': 'Retry deletion',
      'accountGuestStatus': 'You are using the app as a guest',
      'accountSessionExpiredBody':
          'Your saved session is no longer valid. The account may have been deleted outside the app. Your local data is still available.',
      'accountReconnectTitle': 'Reconnect local data?',
      'accountReconnectBody':
          'A new guest account will be created and your existing local data uploaded to it. You can then link Google or sign in.',
      'accountReconnect': 'Reconnect local data',
      'accountLastSync': 'Last sync',
      'accountStorageBody':
          'Bikes, setups and images are saved locally and automatically to your private cloud.',
      'accountLinkGoogleBody':
          'Link Google to regain access after losing a device or clearing app data. Anonymous sign-in alone cannot provide this.',
      'accountSyncNow': 'Sync now',
      'accountConflictsTitle': 'Conflicts',
      'accountConflictsBody':
          'Both versions are retained until you choose. A local backup is created before resolving.',
      'accountConflictCopy': 'Conflict copy',
      'accountKeepBoth': 'Keep both versions',
      'accountKeepLocal': 'Keep local version',
      'accountUseCloud': 'Use cloud version',
      'accountGoogleConnected': 'Google is connected',
      'accountTitle': 'Your account',
      'accountLoginSubtitle': 'Already have an account?',
      'accountLoginBody':
          'Sign in with Google to access your saved bikes and setups. First choose what happens to your guest data.',
      'accountRegister': 'Register',
      'accountRegisterSubtitle': 'New here? Keep your bikes safe.',
      'accountRegisterBody':
          'Create your app account with Google. Your existing bikes and setups are kept and linked to your account. No extra password needed.',
      'accountGoogleLinkedBody':
          'Google is linked. Sign in with the same Google account on other devices.',
      'accountGoogleWaitingBody':
          'Complete Google sign-in in the browser and return to the app. If this Google account is already linked elsewhere, cancel and choose Login.',
      'accountCancelGoogle': 'Cancel Google sign-in',
      'accountSignOutTitle': 'Sign out?',
      'accountSignOutBody':
          'Your local account data is retained separately. Unsynced changes exist only on this device.',
      'accountSignOut': 'Sign out',
      'accountGoogleOptionalBody':
          'Google is optional. You can keep using the app as a guest.',
      'guestCleanupTitle': 'Clean up previous guest account',
      'guestCleanupSyncingBody':
          'Guest data is being synced. The old guest account is deleted afterwards.',
      'guestCleanupErrorBody':
          'The old guest account could not be deleted yet. Your Google data remains. Retry; if this persists, the guest data needs review.',
      'retry': 'Retry',
      'backupFilesTitle': 'Backup files',
      'backupFilesBody':
          'An exported file contains your bikes, setups and images. Keep it somewhere safe outside this device.',
      'backupExportAction': 'Export',
      'backupImportAction': 'Import',
      'backupCloudVersions': 'Cloud versions',
      'accountDeleteSummary':
          'Permanently removes your app account and its data. Export a backup first if you want to keep your data.',
      'accountExportBeforeDelete': 'Export backup first',
      'accountDeleteAction': 'Delete account and data',
      'orderSetups': 'Reorder setups',
      'favoritesStayFirst':
          'Drag setups into your preferred order. Favorites stay at the top.',
      // HomeScreen & AddBike
      'myBikes': 'My Bikes',
      'addFavorite': 'Mark as favorite',
      'removeFavorite': 'Remove favorite',
      'orderBikes': 'Reorder bikes',
      'orderBikesHint':
          'Hold a bike card and drag it into position. Favorites stay at the top. Changes are saved automatically.',
      'finishOrdering': 'Done',
      'settings': 'Settings',
      'appearance': 'Colors & appearance',
      'appearanceHint':
          'Choose a palette color or enter a hex value. Valid entries are saved immediately. The checkmark shows your current color.',
      'applyColor': 'Apply color',
      'chooseColor': 'Choose color',
      'paletteHint': 'Tap or drag on the palette to choose your color.',
      'colorHue': 'Hue',
      'colorSaturation': 'Saturation',
      'colorBrightness': 'Brightness',
      'backgroundColor': 'Background color',
      'accentColor': 'Accent color',
      'colorPreview': 'Preview your colors',
      'resetColors': 'Reset colors',
      'customColor': 'Custom color (hex)',
      'invalidColor': 'Enter 6 hex characters, e.g. 009688.',
      'language': 'Language',
      'tt_newBike': 'New Bike',
      'searchHint': 'Search brand or model...',
      'tutorialInfo': 'Tutorial / Information',
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
      'clearHistory': 'Delete history',
      'clearHistoryTitle': 'Delete history?',
      'clearHistoryBody':
          'Do you really want to delete the entire history of this setup? This cannot be undone. The current setup values will be kept.',
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
      'deleteCategoryConfirmTitle': 'Delete category?',
      'deleteCategoryConfirmBody':
          'The category, including all fields and saved values, will also be removed from every other bike and setup. To only hide the fields, deactivate them in the respective bike or setup instead.',
      'renameCategory': 'Rename category',
      'editFieldOrder': 'Arrange fields',
      'finishFieldOrder': 'Done',
      'dragField': 'Briefly hold and drag to move',
      'dragCategory': 'Hold and drag to move the category',
      'fieldOrderHint':
          'Briefly hold a field and drag it to the desired position within its category. To move an entire category, hold and drag its heading or the handle next to it.',
      'applyFieldOrderTitle': 'Apply field order?',
      'applyFieldOrderBody':
          'Apply this order to the other setups of this bike as well? Values and enabled fields will stay unchanged.',
      'fieldOrderOnlyThis': 'Only this setup',
      'fieldOrderApplyAll': 'Apply to all',
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
          'Delete this bike and its setups? Its photos will also be deleted after syncing unless another bike needs them. Older cloud versions can still be restored without these photos.',

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
          'Long-press a bike card on the home screen to open the menu. Choose to edit or delete the bike, or reorder your bikes.',
      'gotIt': 'Let\'s go!',
    },
  };

  static String get(String languageCode, String key) {
    return texts[languageCode]?[key] ?? texts['en']?[key] ?? key;
  }

  static List<String> get supportedLanguageCodes =>
      List.unmodifiable(texts.keys);

  /// The language's native name, displayed by every language picker.
  static String languageName(String languageCode) =>
      texts[languageCode]?['languageName'] ?? languageCode;

  /// Localize labels without changing the stored category identifiers.
  static String bikeCategory(String languageCode, String category) {
    const keys = {
      'Enduro': 'bikeCategoryEnduro',
      'Trail': 'bikeCategoryTrail',
      'Downhill': 'bikeCategoryDownhill',
      'All Mountain': 'bikeCategoryAllMountain',
      'Gravel': 'bikeCategoryGravel',
      'Cross Country': 'bikeCategoryCrossCountry',
      'E-Bike': 'bikeCategoryEBike',
    };
    final key = keys[category];
    return key == null ? category : get(languageCode, key);
  }

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
