// lib/screens/bike_detail/setup_configurator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translations.dart';
import '../../models/bike_parameters.dart';
import 'add_setup_screen.dart';

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
  }

  void _saveAndContinue() {
    final params = BikeParameters(
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
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddSetupScreen(bikeId: widget.bikeId),
        ),
      );
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
              title: Text(lang == 'de' ? 'Feld bearbeiten' : 'Edit field'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(
                lang == 'de'
                    ? 'Feld aus Bibliothek löschen'
                    : 'Delete field from library',
              ),
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
          title: Text(
            lang == 'de' ? 'Feld wirklich löschen?' : 'Delete field?',
          ),
          content: Text(
            lang == 'de'
                ? 'Das Feld und seine gespeicherten Werte werden aus allen Bikes und Setups entfernt.'
                : 'The field and its saved values will be removed from every bike and setup.',
          ),
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
                  CustomFieldType.number => lang == 'de' ? 'Zahl' : 'Number',
                  CustomFieldType.text => 'Text',
                  CustomFieldType.boolean =>
                    lang == 'de' ? 'Ja / Nein' : 'Yes / No',
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
            label: Text(lang == 'de' ? 'Eigenes Feld' : 'Custom field'),
          ),
        ),
      ),
    ];
  }

  Future<void> _editUnit(String key, String defaultUnit) async {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final controller = TextEditingController(
      text: _unitOverrides[key] ?? defaultUnit,
    );
    final unit = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang == 'de' ? 'Einheit ändern' : 'Change unit'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: lang == 'de' ? 'Einheit' : 'Unit',
            hintText: defaultUnit,
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, defaultUnit),
            child: Text(lang == 'de' ? 'Standard' : 'Default'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(Translations.get(lang, 'save')),
          ),
        ],
      ),
    );
    controller.dispose();
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

    return Scaffold(
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
                defaultUnit: 'PSI/Klicks',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'hsc'),
                value: _forkHsc,
                onChanged: (v) => setState(() => _forkHsc = v),
                unitKey: 'forkHsc',
                defaultUnit: 'Klicks',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'lsc'),
                value: _forkLsc,
                onChanged: (v) => setState(() => _forkLsc = v),
                unitKey: 'forkLsc',
                defaultUnit: 'Klicks',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'hsr'),
                value: _forkHsr,
                onChanged: (v) => setState(() => _forkHsr = v),
                unitKey: 'forkHsr',
                defaultUnit: 'Klicks',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'lsr'),
                value: _forkLsr,
                onChanged: (v) => setState(() => _forkLsr = v),
                unitKey: 'forkLsr',
                defaultUnit: 'Klicks',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'tokens'),
                value: _forkTokens,
                onChanged: (v) => setState(() => _forkTokens = v),
                unitKey: 'forkTokens',
                defaultUnit: 'Stück',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'hbo'),
                value: _forkHbo,
                onChanged: (v) => setState(() => _forkHbo = v),
                unitKey: 'forkHbo',
                defaultUnit: 'Klicks',
              ),
              ..._customFieldControls('fork', _sectionName('fork', lang), lang),
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
                  defaultUnit: 'Stück',
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
                  defaultUnit: 'Umdr.',
                ),
              ],
              _parameterSwitch(
                title: Translations.get(lang, 'hsc'),
                value: _shockHsc,
                onChanged: (v) => setState(() => _shockHsc = v),
                unitKey: 'shockHsc',
                defaultUnit: 'Klicks',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'lsc'),
                value: _shockLsc,
                onChanged: (v) => setState(() => _shockLsc = v),
                unitKey: 'shockLsc',
                defaultUnit: 'Klicks',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'hsr'),
                value: _shockHsr,
                onChanged: (v) => setState(() => _shockHsr = v),
                unitKey: 'shockHsr',
                defaultUnit: 'Klicks',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'lsr'),
                value: _shockLsr,
                onChanged: (v) => setState(() => _shockLsr = v),
                unitKey: 'shockLsr',
                defaultUnit: 'Klicks',
              ),
              _parameterSwitch(
                title: Translations.get(lang, 'hbo'),
                value: _shockHbo,
                onChanged: (v) => setState(() => _shockHbo = v),
                unitKey: 'shockHbo',
                defaultUnit: 'Klicks',
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
                ..._customFieldControls(category.id, category.name, lang),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      context.read<BikeProvider>().deleteCustomCategoryTemplate(
                        category.id,
                      );
                      setState(
                        () => _customCategories.removeWhere(
                          (item) => item.id == category.id,
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      lang == 'de' ? 'Kategorie löschen' : 'Delete category',
                    ),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: OutlinedButton.icon(
              onPressed: _addCustomCategory,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(
                lang == 'de' ? 'Neue Kategorie hinzufügen' : 'Add new category',
              ),
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
    );
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
    final isGerman = widget.lang == 'de';
    return AlertDialog(
      title: Text(isGerman ? 'Neue Kategorie' : 'New category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: isGerman ? 'Kategoriename' : 'Category name',
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
          child: Text(isGerman ? 'Erstellen' : 'Create'),
        ),
      ],
    );
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
  static const _units = [
    '',
    'PSI',
    'bar',
    'mm',
    '%',
    'Klicks',
    'Umdr.',
    'Nm',
    '°',
    'Eigene…',
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
      _selectedUnit = 'Eigene…';
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
        unit: _selectedUnit == 'Eigene…'
            ? _customUnitController.text.trim()
            : _selectedUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGerman = widget.lang == 'de';
    return AlertDialog(
      title: Text(
        widget.initialField == null
            ? (isGerman ? 'Eigenes Feld hinzufügen' : 'Add custom field')
            : (isGerman ? 'Feld bearbeiten' : 'Edit field'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: isGerman ? 'Feldname' : 'Field name',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CustomFieldType>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: isGerman ? 'Werttyp' : 'Value type',
              ),
              items: [
                DropdownMenuItem(
                  value: CustomFieldType.number,
                  child: Text(isGerman ? 'Zahl' : 'Number'),
                ),
                const DropdownMenuItem(
                  value: CustomFieldType.text,
                  child: Text('Text'),
                ),
                DropdownMenuItem(
                  value: CustomFieldType.boolean,
                  child: Text(isGerman ? 'Ja / Nein' : 'Yes / No'),
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
                  labelText: isGerman ? 'Einheit' : 'Unit',
                ),
                items: _units
                    .map(
                      (unit) => DropdownMenuItem(
                        value: unit,
                        child: Text(
                          unit.isEmpty ? (isGerman ? 'Keine' : 'None') : unit,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedUnit = value ?? ''),
              ),
              if (_selectedUnit == 'Eigene…') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customUnitController,
                  decoration: InputDecoration(
                    labelText: isGerman ? 'Eigene Einheit' : 'Custom unit',
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
                ? (isGerman ? 'Hinzufügen' : 'Add')
                : Translations.get(widget.lang, 'save'),
          ),
        ),
      ],
    );
  }
}
