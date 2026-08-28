// lib/screens/bike_detail/setup_configurator_screen.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translations.dart';
import '../../models/bike_parameters.dart';
import 'add_setup_screen.dart';

Widget _webKeyboardSafeDialog(BuildContext context, Widget dialog) {
  if (!kIsWeb) return dialog;

  // Mobile browsers already resize their visual viewport for the keyboard.
  // Removing Flutter's additional inset prevents dialogs from moving twice.
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
    child: dialog,
  );
}

class SetupConfiguratorScreen extends StatefulWidget {
  final String bikeId;
  final bool isEditing;

  // NEU: Wenn eine setupId übergeben wird, konfigurieren wir nur DIESES Setup!
  final String? setupId;

  const SetupConfiguratorScreen({
    super.key,
    required this.bikeId,
    this.isEditing = false,
    this.setupId, // NEU
  });

  @override
  State<SetupConfiguratorScreen> createState() =>
      _SetupConfiguratorScreenState();
}

class _SetupConfiguratorScreenState extends State<SetupConfiguratorScreen> {
  bool _forkPsi = true, _forkOtt = false, _forkHsc = false, _forkLsc = true;
  bool _forkHsr = false, _forkLsr = true, _forkTokens = false, _forkHbo = false;
  bool _shockIsCoil = false;
  bool _shockPsi = true,
      _shockTokens = false,
      _shockRate = false,
      _shockPreload = false;
  bool _shockHsc = false,
      _shockLsc = true,
      _shockHsr = false,
      _shockLsr = true,
      _shockHbo = false;
  bool _tires = true;
  List<CustomSetupCategory> _customCategories = [];
  Map<String, String> _unitOverrides = {};
  late String _initialStateJson;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    final bike = context.read<BikeProvider>().bikes.firstWhere(
      (b) => b.id == widget.bikeId,
    );

    BikeParameters? p;

    // NEU: Wenn wir ein spezifisches Setup bearbeiten, schauen wir ZUERST, ob es schon
    // Custom-Parameter hat. Wenn nicht, holen wir als Startwert den Standard des Bikes.
    if (widget.setupId != null) {
      final setup = bike.setups.firstWhere((s) => s.id == widget.setupId);
      p = setup.customParameters ?? bike.availableParameters;
    } else {
      p = bike.availableParameters;
    }

    if (p != null) {
      _forkPsi = p.forkPsi;
      _forkOtt = p.forkOtt;
      _forkHsc = p.forkHsc;
      _forkLsc = p.forkLsc;
      _forkHsr = p.forkHsr;
      _forkLsr = p.forkLsr;
      _forkTokens = p.forkTokens;
      _forkHbo = p.forkHbo;
      _shockIsCoil = p.shockIsCoil;
      _shockPsi = p.shockPsi;
      _shockTokens = p.shockTokens;
      _shockRate = p.shockRate;
      _shockPreload = p.shockPreload;
      _shockHsc = p.shockHsc;
      _shockLsc = p.shockLsc;
      _shockHsr = p.shockHsr;
      _shockLsr = p.shockLsr;
      _shockHbo = p.shockHbo;
      _tires = p.tires;
      _customCategories = p.customCategories
          .map(
            (category) => category.copyWith(fields: List.of(category.fields)),
          )
          .toList();
      _unitOverrides = Map.of(p.unitOverrides);
    }
    _initialStateJson = jsonEncode(_currentParameters().toMap());
  }

  BikeParameters _currentParameters() {
    return BikeParameters(
      forkPsi: _forkPsi,
      forkOtt: _forkOtt,
      forkHsc: _forkHsc,
      forkLsc: _forkLsc,
      forkHsr: _forkHsr,
      forkLsr: _forkLsr,
      forkTokens: _forkTokens,
      forkHbo: _forkHbo,
      shockIsCoil: _shockIsCoil,
      shockPsi: _shockPsi,
      shockTokens: _shockTokens,
      shockRate: _shockRate,
      shockPreload: _shockPreload,
      shockHsc: _shockHsc,
      shockLsc: _shockLsc,
      shockHsr: _shockHsr,
      shockLsr: _shockLsr,
      shockHbo: _shockHbo,
      tires: _tires,
      customCategories: _customCategories,
      unitOverrides: _unitOverrides,
    );
  }

  bool get _hasUnsavedChanges =>
      jsonEncode(_currentParameters().toMap()) != _initialStateJson;

  void _popScreen() {
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  void _saveAndContinue() {
    final params = _currentParameters();

    final provider = context.read<BikeProvider>();

    if (widget.setupId != null) {
      // --- MODUS A: Setup-spezifisch überschreiben ---
      final bike = provider.bikes.firstWhere((b) => b.id == widget.bikeId);
      final setup = bike.setups.firstWhere((s) => s.id == widget.setupId);
      provider.updateSetup(
        widget.bikeId,
        setup.copyWith(customParameters: params),
      );
    } else {
      // --- MODUS B: Das gesamte Bike anpassen ---
      provider.updateBikeParameters(widget.bikeId, params);
    }

    if (widget.isEditing) {
      _popScreen();
    } else {
      _allowPop = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddSetupScreen(bikeId: widget.bikeId),
        ),
      );
    }
  }

  Future<void> _handleBackNavigation() async {
    if (_allowPop || !_hasUnsavedChanges) {
      _popScreen();
      return;
    }

    final lang = context.read<LanguageProvider>().currentLanguage;
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(Translations.get(lang, 'unsavedChangesTitle')),
        content: Text(Translations.get(lang, 'unsavedChangesBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'continue'),
            child: Text(Translations.get(lang, 'keepEditing')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: Text(Translations.get(lang, 'discard')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'save'),
            child: Text(Translations.get(lang, 'save')),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (action == 'save') {
      _saveAndContinue();
    } else if (action == 'discard') {
      _popScreen();
    }
  }

  String _sectionName(String categoryId, String lang) {
    switch (categoryId) {
      case 'fork':
        return Translations.get(lang, 'fork');
      case 'shock':
        return Translations.get(lang, 'shock');
      case 'tires':
        return Translations.get(lang, 'tires');
      default:
        return categoryId;
    }
  }

  Future<void> _addCustomField(String categoryId, String categoryName) async {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final field = await showDialog<CustomSetupField>(
      context: context,
      requestFocus: false,
      builder: (_) => _CustomFieldDialog(lang: lang),
    );

    if (field == null || !mounted) return;

    context.read<BikeProvider>().addCustomFieldTemplate(
      categoryId,
      categoryName,
      field,
    );

    setState(() {
      final index = _customCategories.indexWhere(
        (category) => category.id == categoryId,
      );
      if (index == -1) {
        _customCategories.add(
          CustomSetupCategory(
            id: categoryId,
            name: categoryName,
            fields: [field],
          ),
        );
      } else {
        final category = _customCategories[index];
        _customCategories[index] = category.copyWith(
          fields: [...category.fields, field],
        );
      }
    });
  }

  Future<void> _addCustomCategory() async {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final name = await showDialog<String>(
      context: context,
      requestFocus: false,
      builder: (_) => _CustomCategoryDialog(lang: lang),
    );
    if (name == null || name.isEmpty || !mounted) return;
    final category = CustomSetupCategory(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
    );
    context.read<BikeProvider>().addCustomCategoryTemplate(category);
    setState(() => _customCategories.add(category));
  }

  void _removeCustomField(String categoryId, String fieldId) {
    setState(() {
      final index = _customCategories.indexWhere(
        (category) => category.id == categoryId,
      );
      if (index == -1) return;
      final category = _customCategories[index];
      _customCategories[index] = category.copyWith(
        fields: category.fields.where((field) => field.id != fieldId).toList(),
      );
    });
  }

  void _toggleCategoryNotes(
    String categoryId,
    String categoryName,
    bool enabled,
  ) {
    setState(() {
      final index = _customCategories.indexWhere(
        (category) => category.id == categoryId,
      );
      if (index == -1) {
        _customCategories.add(
          CustomSetupCategory(
            id: categoryId,
            name: categoryName,
            notesEnabled: enabled,
          ),
        );
      } else {
        final category = _customCategories[index];
        _customCategories[index] = category.copyWith(notesEnabled: enabled);
      }
    });
  }

  Widget _categoryNotesControl(
    String categoryId,
    String categoryName,
    String lang,
  ) {
    final index = _customCategories.indexWhere(
      (category) => category.id == categoryId,
    );
    final enabled = index != -1 && _customCategories[index].notesEnabled;
    return SwitchListTile(
      secondary: const Icon(Icons.notes_outlined),
      title: Text(Translations.get(lang, 'showNotesField')),
      value: enabled,
      onChanged: (value) =>
          _toggleCategoryNotes(categoryId, categoryName, value),
    );
  }

  void _toggleCustomField(
    String categoryId,
    String categoryName,
    CustomSetupField template,
    bool selected,
  ) {
    if (!selected) {
      _removeCustomField(categoryId, template.id);
      return;
    }
    setState(() {
      final index = _customCategories.indexWhere(
        (category) => category.id == categoryId,
      );
      if (index == -1) {
        _customCategories.add(
          CustomSetupCategory(
            id: categoryId,
            name: categoryName,
            fields: [template.copyWith(value: '')],
          ),
        );
      } else {
        final category = _customCategories[index];
        if (category.fields.any((field) => field.id == template.id)) return;
        _customCategories[index] = category.copyWith(
          fields: [
            ...category.fields,
            template.copyWith(value: ''),
          ],
        );
      }
    });
  }

  Future<void> _manageCustomField(
    String categoryId,
    CustomSetupField field,
  ) async {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(Translations.get(lang, 'editCustomField')),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(Translations.get(lang, 'deleteFieldFromLibrary')),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(Translations.get(lang, 'deleteFieldConfirmTitle')),
          content: Text(Translations.get(lang, 'deleteFieldConfirmBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(Translations.get(lang, 'cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(Translations.get(lang, 'delete')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      context.read<BikeProvider>().deleteCustomFieldTemplate(
        categoryId,
        field.id,
      );
      _removeCustomField(categoryId, field.id);
    } else if (action == 'edit') {
      final updated = await showDialog<CustomSetupField>(
        context: context,
        builder: (_) => _CustomFieldDialog(lang: lang, initialField: field),
      );
      if (updated == null || !mounted) return;
      context.read<BikeProvider>().updateCustomFieldTemplate(
        categoryId,
        updated,
      );
      setState(() {
        final index = _customCategories.indexWhere(
          (category) => category.id == categoryId,
        );
        if (index == -1) return;
        final category = _customCategories[index];
        _customCategories[index] = category.copyWith(
          fields: category.fields
              .map(
                (item) => item.id == updated.id
                    ? updated.copyWith(value: item.value)
                    : item,
              )
              .toList(),
        );
      });
    }
  }

  List<Widget> _customFieldControls(
    String categoryId,
    String categoryName,
    String lang,
  ) {
    final selectedIndex = _customCategories.indexWhere(
      (category) => category.id == categoryId,
    );
    final selectedFields = selectedIndex == -1
        ? const <CustomSetupField>[]
        : _customCategories[selectedIndex].fields;
    final catalog = context.watch<BikeProvider>().customFieldCatalog;
    final catalogIndex = catalog.indexWhere(
      (category) => category.id == categoryId,
    );
    final catalogFields = catalogIndex == -1
        ? const <CustomSetupField>[]
        : catalog[catalogIndex].fields;
    final fields = <CustomSetupField>[
      ...catalogFields,
      ...selectedFields.where(
        (field) => !catalogFields.any((item) => item.id == field.id),
      ),
    ];
    return [
      for (final field in fields)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => _manageCustomField(categoryId, field),
          child: SwitchListTile(
            secondary: const Icon(Icons.tune),
            title: Text(field.name),
            subtitle: Text(
              [
                switch (field.type) {
                  CustomFieldType.number => Translations.get(
                    lang,
                    'numberType',
                  ),
                  CustomFieldType.text => Translations.get(lang, 'textType'),
                  CustomFieldType.boolean => Translations.get(
                    lang,
                    'booleanType',
                  ),
                },
                if (field.unit.isNotEmpty) field.unit,
              ].join(' · '),
            ),
            value: selectedFields.any((item) => item.id == field.id),
            onChanged: (selected) =>
                _toggleCustomField(categoryId, categoryName, field, selected),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: OutlinedButton.icon(
            onPressed: () => _addCustomField(categoryId, categoryName),
            icon: const Icon(Icons.add),
            label: Text(Translations.get(lang, 'customField')),
          ),
        ),
      ),
    ];
  }

  Future<void> _editUnit(String key, String defaultUnit) async {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final unit = await showDialog<String>(
      context: context,
      requestFocus: false,
      builder: (_) => _UnitEditDialog(
        lang: lang,
        initialUnit: _unitOverrides[key] ?? defaultUnit,
        defaultUnit: defaultUnit,
      ),
    );
    if (unit == null || unit.isEmpty || !mounted) return;
    setState(() => _unitOverrides[key] = unit);
  }

  Widget _parameterSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String unitKey,
    required String defaultUnit,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _editUnit(unitKey, defaultUnit),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(_unitOverrides[unitKey] ?? defaultUnit),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget buildSection({
    required String storageKey,
    required String title,
    IconData? icon,
    String? svgPath,
    required List<Widget> children,
    bool initiallyExpanded = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey(storageKey),
        initiallyExpanded: initiallyExpanded,
        leading: svgPath != null
            ? SvgPicture.asset(
                svgPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colorScheme.primary,
                  BlendMode.srcIn,
                ),
              )
            : Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final catalogCategories = context.watch<BikeProvider>().customFieldCatalog;
    final visibleCustomCategories = <CustomSetupCategory>[
      ...catalogCategories.where(
        (category) => !const {'fork', 'shock', 'tires'}.contains(category.id),
      ),
      ..._customCategories.where(
        (category) =>
            !const {'fork', 'shock', 'tires'}.contains(category.id) &&
            !catalogCategories.any((item) => item.id == category.id),
      ),
    ];

    return PopScope(
      canPop: _allowPop || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBackNavigation();
      },
      child: Scaffold(
        // Titel dynamisch anpassen
        appBar: AppBar(
          title: Text(
            widget.setupId != null
                ? Translations.get(lang, 'setupConfig')
                : Translations.get(lang, 'configSuspension'),
          ),
        ),
        body: ListView(
          children: [
            buildSection(
              storageKey: 'fork-section',
              title: Translations.get(lang, 'forkSettings'),
              svgPath: 'assets/icons/fork.svg',
              children: [
                _parameterSwitch(
                  title: Translations.get(lang, 'mainAir'),
                  value: _forkPsi,
                  onChanged: (v) => setState(() => _forkPsi = v),
                  unitKey: 'forkPsi',
                  defaultUnit: 'PSI',
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'ottNeg'),
                  value: _forkOtt,
                  onChanged: (v) => setState(() => _forkOtt = v),
                  unitKey: 'forkOtt',
                  defaultUnit: Translations.get(lang, 'unitPsiClicks'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'hsc'),
                  value: _forkHsc,
                  onChanged: (v) => setState(() => _forkHsc = v),
                  unitKey: 'forkHsc',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'lsc'),
                  value: _forkLsc,
                  onChanged: (v) => setState(() => _forkLsc = v),
                  unitKey: 'forkLsc',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'hsr'),
                  value: _forkHsr,
                  onChanged: (v) => setState(() => _forkHsr = v),
                  unitKey: 'forkHsr',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'lsr'),
                  value: _forkLsr,
                  onChanged: (v) => setState(() => _forkLsr = v),
                  unitKey: 'forkLsr',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'tokens'),
                  value: _forkTokens,
                  onChanged: (v) => setState(() => _forkTokens = v),
                  unitKey: 'forkTokens',
                  defaultUnit: Translations.get(lang, 'unitPieces'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'hbo'),
                  value: _forkHbo,
                  onChanged: (v) => setState(() => _forkHbo = v),
                  unitKey: 'forkHbo',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _categoryNotesControl('fork', _sectionName('fork', lang), lang),
                ..._customFieldControls(
                  'fork',
                  _sectionName('fork', lang),
                  lang,
                ),
              ],
            ),
            buildSection(
              storageKey: 'shock-section',
              title: Translations.get(lang, 'shockSettings'),
              svgPath: 'assets/icons/shock.svg',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        Translations.get(lang, 'shockType'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(
                            value: false,
                            label: Text(Translations.get(lang, 'airShock')),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text(Translations.get(lang, 'coilShock')),
                          ),
                        ],
                        selected: {_shockIsCoil},
                        onSelectionChanged: (selection) =>
                            setState(() => _shockIsCoil = selection.first),
                      ),
                    ],
                  ),
                ),
                if (!_shockIsCoil) ...[
                  _parameterSwitch(
                    title: Translations.get(lang, 'shockAir'),
                    value: _shockPsi,
                    onChanged: (v) => setState(() => _shockPsi = v),
                    unitKey: 'shockPsi',
                    defaultUnit: 'PSI',
                  ),
                  _parameterSwitch(
                    title: Translations.get(lang, 'tokens'),
                    value: _shockTokens,
                    onChanged: (v) => setState(() => _shockTokens = v),
                    unitKey: 'shockTokens',
                    defaultUnit: Translations.get(lang, 'unitPieces'),
                  ),
                ] else ...[
                  _parameterSwitch(
                    title: Translations.get(lang, 'springRate'),
                    value: _shockRate,
                    onChanged: (v) => setState(() => _shockRate = v),
                    unitKey: 'shockRate',
                    defaultUnit: 'lbs/in',
                  ),
                  _parameterSwitch(
                    title: Translations.get(lang, 'preload'),
                    value: _shockPreload,
                    onChanged: (v) => setState(() => _shockPreload = v),
                    unitKey: 'shockPreload',
                    defaultUnit: Translations.get(lang, 'unitTurns'),
                  ),
                ],
                _parameterSwitch(
                  title: Translations.get(lang, 'hsc'),
                  value: _shockHsc,
                  onChanged: (v) => setState(() => _shockHsc = v),
                  unitKey: 'shockHsc',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'lsc'),
                  value: _shockLsc,
                  onChanged: (v) => setState(() => _shockLsc = v),
                  unitKey: 'shockLsc',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'hsr'),
                  value: _shockHsr,
                  onChanged: (v) => setState(() => _shockHsr = v),
                  unitKey: 'shockHsr',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'lsr'),
                  value: _shockLsr,
                  onChanged: (v) => setState(() => _shockLsr = v),
                  unitKey: 'shockLsr',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _parameterSwitch(
                  title: Translations.get(lang, 'hbo'),
                  value: _shockHbo,
                  onChanged: (v) => setState(() => _shockHbo = v),
                  unitKey: 'shockHbo',
                  defaultUnit: Translations.get(lang, 'unitClicks'),
                ),
                _categoryNotesControl(
                  'shock',
                  _sectionName('shock', lang),
                  lang,
                ),
                ..._customFieldControls(
                  'shock',
                  _sectionName('shock', lang),
                  lang,
                ),
              ],
            ),
            buildSection(
              storageKey: 'tires-section',
              title: Translations.get(lang, 'tireSettings'),
              icon: Icons.tire_repair,
              initiallyExpanded: false,
              children: [
                _parameterSwitch(
                  title: Translations.get(lang, 'trackTires'),
                  value: _tires,
                  onChanged: (v) => setState(() => _tires = v),
                  unitKey: 'tirePressure',
                  defaultUnit: 'bar/PSI',
                ),
                _categoryNotesControl(
                  'tires',
                  _sectionName('tires', lang),
                  lang,
                ),
                ..._customFieldControls(
                  'tires',
                  _sectionName('tires', lang),
                  lang,
                ),
              ],
            ),
            for (final category in visibleCustomCategories)
              buildSection(
                storageKey: '${category.id}-section',
                title: category.name,
                icon: Icons.category_outlined,
                initiallyExpanded: false,
                children: [
                  _categoryNotesControl(category.id, category.name, lang),
                  ..._customFieldControls(category.id, category.name, lang),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        context
                            .read<BikeProvider>()
                            .deleteCustomCategoryTemplate(category.id);
                        setState(
                          () => _customCategories.removeWhere(
                            (item) => item.id == category.id,
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(Translations.get(lang, 'deleteCategory')),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: OutlinedButton.icon(
                onPressed: _addCustomCategory,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: Text(Translations.get(lang, 'addCategory')),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FilledButton(
                onPressed: _saveAndContinue,
                child: Text(
                  widget.isEditing
                      ? Translations.get(lang, 'saveChanges')
                      : Translations.get(lang, 'saveConfig'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitEditDialog extends StatefulWidget {
  const _UnitEditDialog({
    required this.lang,
    required this.initialUnit,
    required this.defaultUnit,
  });

  final String lang;
  final String initialUnit;
  final String defaultUnit;

  @override
  State<_UnitEditDialog> createState() => _UnitEditDialogState();
}

class _UnitEditDialogState extends State<_UnitEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUnit);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final unit = _controller.text.trim();
    if (unit.isEmpty) return;
    Navigator.pop(context, unit);
  }

  @override
  Widget build(BuildContext context) {
    final dialog = AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      scrollable: true,
      title: Text(Translations.get(widget.lang, 'changeUnit')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: Translations.get(widget.lang, 'unit'),
          hintText: widget.defaultUnit,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, widget.defaultUnit),
          child: Text(Translations.get(widget.lang, 'defaultValue')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(Translations.get(widget.lang, 'save')),
        ),
      ],
    );
    return _webKeyboardSafeDialog(context, dialog);
  }
}

class _CustomCategoryDialog extends StatefulWidget {
  const _CustomCategoryDialog({required this.lang});

  final String lang;

  @override
  State<_CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<_CustomCategoryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final dialog = AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      scrollable: true,
      title: Text(Translations.get(widget.lang, 'newCategory')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: Translations.get(widget.lang, 'categoryName'),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(Translations.get(widget.lang, 'cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(Translations.get(widget.lang, 'create')),
        ),
      ],
    );
    return _webKeyboardSafeDialog(context, dialog);
  }
}

class _CustomFieldDialog extends StatefulWidget {
  const _CustomFieldDialog({required this.lang, this.initialField});

  final String lang;
  final CustomSetupField? initialField;

  @override
  State<_CustomFieldDialog> createState() => _CustomFieldDialogState();
}

class _CustomFieldDialogState extends State<_CustomFieldDialog> {
  static const _customUnitValue = '__custom_unit__';
  List<String> get _units => [
    '',
    'PSI',
    'bar',
    'mm',
    '%',
    Translations.get(widget.lang, 'unitClicks'),
    Translations.get(widget.lang, 'unitTurns'),
    'Nm',
    '°',
    _customUnitValue,
  ];

  late final TextEditingController _nameController;
  final _customUnitController = TextEditingController();
  CustomFieldType _type = CustomFieldType.number;
  String _selectedUnit = '';

  @override
  void initState() {
    super.initState();
    final field = widget.initialField;
    _nameController = TextEditingController(text: field?.name ?? '');
    _type = field?.type ?? CustomFieldType.number;
    if (field != null &&
        field.unit.isNotEmpty &&
        !_units.contains(field.unit)) {
      _selectedUnit = _customUnitValue;
      _customUnitController.text = field.unit;
    } else {
      _selectedUnit = field?.unit ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(
      context,
      CustomSetupField(
        id:
            widget.initialField?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        type: _type,
        unit: _selectedUnit == _customUnitValue
            ? _customUnitController.text.trim()
            : _selectedUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialog = AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(
        widget.initialField == null
            ? Translations.get(widget.lang, 'addCustomField')
            : Translations.get(widget.lang, 'editCustomField'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: Translations.get(widget.lang, 'fieldName'),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CustomFieldType>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: Translations.get(widget.lang, 'valueType'),
              ),
              items: [
                DropdownMenuItem(
                  value: CustomFieldType.number,
                  child: Text(Translations.get(widget.lang, 'numberType')),
                ),
                DropdownMenuItem(
                  value: CustomFieldType.text,
                  child: Text(Translations.get(widget.lang, 'textType')),
                ),
                DropdownMenuItem(
                  value: CustomFieldType.boolean,
                  child: Text(Translations.get(widget.lang, 'booleanType')),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            if (_type != CustomFieldType.boolean) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: InputDecoration(
                  labelText: Translations.get(widget.lang, 'unit'),
                ),
                items: _units
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(
                          unit.isEmpty
                              ? Translations.get(widget.lang, 'none')
                              : unit == _customUnitValue
                              ? Translations.get(widget.lang, 'customUnit')
                              : unit,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedUnit = value ?? ''),
              ),
              if (_selectedUnit == _customUnitValue) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customUnitController,
                  decoration: InputDecoration(
                    labelText: Translations.get(widget.lang, 'customUnit'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(Translations.get(widget.lang, 'cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.initialField == null
                ? Translations.get(widget.lang, 'add')
                : Translations.get(widget.lang, 'save'),
          ),
        ),
      ],
    );
    return _webKeyboardSafeDialog(context, dialog);
  }
}
