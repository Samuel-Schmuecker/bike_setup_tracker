// lib/screens/bike_detail/setup_detail_screen.dart

import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/bike_provider.dart';
import '../../models/trail_setup.dart';
import '../../models/bike_parameters.dart';
import '../../utils/suspension_dictionary.dart';
import '../../utils/translations.dart';
import 'setup_configurator_screen.dart';
import '../../widgets/reorderable_field_wrap.dart';

class SetupDetailScreen extends StatefulWidget {
  final String bikeId;
  final String setupId;

  const SetupDetailScreen({
    super.key,
    required this.bikeId,
    required this.setupId,
  });

  @override
  State<SetupDetailScreen> createState() => _SetupDetailScreenState();
}

class _SetupDetailScreenState extends State<SetupDetailScreen> {
  late TextEditingController _notesController;
  late FocusNode _notesFocusNode;
  late BikeProvider _bikeProvider;
  bool _editingOrder = false;
  final Map<String, List<String>> _draftOrders = {};
  final Map<String, List<String>> _initialOrders = {};
  List<String>? _draftCategoryOrder;
  List<String> _initialCategoryOrder = [];

  Future<void> _finishOrdering() async {
    final changed = <String, List<String>>{
      for (final entry in _draftOrders.entries)
        if (!listEquals(entry.value, _initialOrders[entry.key]))
          entry.key: entry.value,
    };
    final categoriesChanged =
        _draftCategoryOrder != null &&
        !listEquals(_draftCategoryOrder, _initialCategoryOrder);
    if (changed.isEmpty && !categoriesChanged) {
      setState(() => _editingOrder = false);
      return;
    }
    final bike = _bikeProvider.bikes.firstWhere(
      (bike) => bike.id == widget.bikeId,
    );
    var applyToAll = false;
    if (bike.setups.length > 1) {
      final lang = context.read<LanguageProvider>().currentLanguage;
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(Translations.get(lang, 'applyFieldOrderTitle')),
          content: Text(Translations.get(lang, 'applyFieldOrderBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(Translations.get(lang, 'fieldOrderOnlyThis')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(Translations.get(lang, 'fieldOrderApplyAll')),
            ),
          ],
        ),
      );
      if (!mounted || result == null) return;
      applyToAll = result;
    }
    _bikeProvider.updateFieldOrders(
      widget.bikeId,
      widget.setupId,
      changed,
      applyToAll: applyToAll,
      categoryOrder: categoriesChanged ? _draftCategoryOrder : null,
    );
    setState(() => _editingOrder = false);
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _notesFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final bike = context.read<BikeProvider>().bikes.firstWhere(
          (b) => b.id == widget.bikeId,
        );
        final setup = bike.setups.firstWhere((s) => s.id == widget.setupId);
        _notesController.text = setup.notes;
      } catch (e) {
        // Falls Bike/Setup nicht existiert
      }
    });

    _notesFocusNode.addListener(() {
      if (!_notesFocusNode.hasFocus) {
        _saveNotes();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bikeProvider = context.read<BikeProvider>();
  }

  void _saveNotes() {
    try {
      final bike = _bikeProvider.bikes.firstWhere((b) => b.id == widget.bikeId);
      final setup = bike.setups.firstWhere((s) => s.id == widget.setupId);

      if (setup.notes != _notesController.text) {
        _bikeProvider.updateSetup(
          widget.bikeId,
          setup.copyWith(notes: _notesController.text),
        );
      }
    } catch (e) {
      // Ignorieren
    }
  }

  @override
  void dispose() {
    // Provider nicht während des Widget-Abbaus benachrichtigen. Das kann bei
    // InheritedWidget/Provider zu `_dependents.isEmpty` führen.
    final notes = _notesController.text;
    final bikeProvider = _bikeProvider;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final bike = bikeProvider.bikes.firstWhere(
          (b) => b.id == widget.bikeId,
        );
        final setup = bike.setups.firstWhere((s) => s.id == widget.setupId);
        if (setup.notes != notes) {
          bikeProvider.updateSetup(widget.bikeId, setup.copyWith(notes: notes));
        }
      } catch (_) {
        // Bike oder Setup wurde inzwischen entfernt.
      }
    });
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  double? _parseDouble(String value) {
    if (value.trim().isEmpty || value == '-') return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  String? _formatNum(num? value) {
    if (value == null) return null;
    return value == value.toInt() ? value.toInt().toString() : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bikes = context.watch<BikeProvider>().bikes;
    final bikeIndex = bikes.indexWhere((b) => b.id == widget.bikeId);
    if (bikeIndex == -1) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final bike = bikes[bikeIndex];
    final setupIndex = bike.setups.indexWhere((s) => s.id == widget.setupId);
    if (setupIndex == -1) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            Translations.get(
              context.watch<LanguageProvider>().currentLanguage,
              'setupNotFound',
            ),
          ),
        ),
      );
    }
    final setup = bike.setups[setupIndex];

    // FIX 2: Absolut sicherer Fallback, auch für sehr alte Demo-Bikes
    final params =
        setup.customParameters ?? bike.availableParameters ?? BikeParameters();
    String unitFor(String key, String fallback) =>
        params.unitOverrides[key] ?? fallback;

    final colorScheme = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final availableCategoryIds = <String>[
      'fork',
      'shock',
      if (params.tires ||
          params.customCategories.any(
            (category) =>
                category.id == 'tires' &&
                (category.fields.isNotEmpty || category.notesEnabled),
          ))
        'tires',
      for (final category in params.customCategories)
        if (!const {'fork', 'shock', 'tires'}.contains(category.id) &&
            (category.fields.isNotEmpty || category.notesEnabled))
          category.id,
    ];
    final categoryOrder = <String>{
      ...(_editingOrder
          ? _draftCategoryOrder ?? setup.categoryOrder
          : setup.categoryOrder),
      ...availableCategoryIds,
    }.toList();
    final visibleCategoryIds = categoryOrder
        .where(availableCategoryIds.contains)
        .toList();

    Widget orderedFields(String categoryId, List<Widget> children) {
      final original = <String>{
        ...?setup.fieldOrders[categoryId],
        for (final child in children) (child.key! as ValueKey<String>).value,
      }.toList();
      if (_editingOrder) {
        _initialOrders.putIfAbsent(categoryId, () => original);
      }
      return ReorderableFieldWrap(
        categoryId: categoryId,
        order: _editingOrder
            ? (_draftOrders[categoryId] ?? original)
            : original,
        editing: _editingOrder,
        dragLabel: Translations.get(lang, 'dragField'),
        onReorder: (order) => setState(() => _draftOrders[categoryId] = order),
        children: children,
      );
    }

    String componentField(String componentKey, String fieldKey) {
      return Translations.format(lang, 'componentField', {
        'component': Translations.get(lang, componentKey),
        'field': Translations.get(lang, fieldKey),
      });
    }

    // FIX 1: Extrem robuster Speichervorgang, der leere Strings und "-" sicher verarbeitet!
    void handleSave(
      String label,
      String? oldValStr,
      String newValStr,
      String note,
      TrailSetup updatedSetup,
    ) {
      final cleanOldVal =
          (oldValStr == null || oldValStr.trim().isEmpty || oldValStr == '-')
          ? null
          : oldValStr;
      final cleanNewVal = (newValStr.trim().isEmpty || newValStr == '-')
          ? null
          : newValStr;

      // Wenn sich der sichtbare String nicht ändert, nichts tun
      if (cleanOldVal == cleanNewVal) return;

      // Wenn es eine Ersteingabe ist (vorher gab es keinen Wert),
      // speichern wir nur das Setup ohne einen Log-Eintrag zu erzeugen.
      if (cleanOldVal == null) {
        context.read<BikeProvider>().updateSetup(widget.bikeId, updatedSetup);
        return;
      }

      // Wenn wir hier ankommen, gab es eine echte Änderung eines bestehenden Wertes
      String diffStr = '';
      final oldNum = _parseDouble(cleanOldVal);
      final newNum = _parseDouble(cleanNewVal ?? '');

      if (oldNum != null && newNum != null) {
        final diff = newNum - oldNum;
        if (diff != 0) {
          String diffFormatted = diff == diff.toInt()
              ? diff.toInt().toString()
              : diff.toStringAsFixed(1);
          diffStr = diff > 0 ? ' (+$diffFormatted)' : ' ($diffFormatted)';
        }
      }

      final displayOld = cleanOldVal;
      final displayNew = cleanNewVal ?? '-'; // Falls gelöscht
      final logMsg = '$label: $displayOld ➔ $displayNew$diffStr';
      final newLog = SetupLog(
        parameters: logMsg,
        note: note,
        timestamp: DateTime.now(),
      );

      context.read<BikeProvider>().updateSetup(
        widget.bikeId,
        updatedSetup.copyWith(logs: [newLog, ...updatedSetup.logs]),
      );
    }

    void showStepperModal(
      String title,
      String unit,
      String? currentValue,
      bool isText,
      double stepSize,
      Function(String, String) onSave,
    ) {
      showDialog(
        context: context,
        builder: (ctx) => _EditValueDialog(
          title: title,
          unit: unit,
          initialValue: currentValue,
          isText: isText,
          stepSize: stepSize,
          onSave: onSave,
        ),
      );
    }

    Widget buildSectionHeader(String title, {IconData? icon, String? svgPath}) {
      return Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 32.0,
          bottom: 16.0,
        ),
        child: Row(
          children: [
            if (svgPath != null)
              SvgPicture.asset(
                svgPath,
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Colors.white70,
                  BlendMode.srcIn,
                ),
              )
            else if (icon != null)
              Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Divider(
                color: Colors.white.withOpacity(0.1),
                thickness: 1,
              ),
            ),
          ],
        ),
      );
    }

    Widget categoryHeader(
      String id,
      String title, {
      IconData? icon,
      String? svgPath,
    }) {
      final header = buildSectionHeader(title, icon: icon, svgPath: svgPath);
      if (!_editingOrder) return header;
      return ReorderableDelayedDragStartListener(
        key: ValueKey('category-handle-$id'),
        index: visibleCategoryIds.indexOf(id),
        child: ColoredBox(
          color: Colors.transparent,
          child: Row(
            children: [
              Expanded(child: header),
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 16),
                child: Tooltip(
                  message: Translations.get(lang, 'dragCategory'),
                  child: Icon(Icons.drag_indicator, color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildTile(
      String fieldId,
      String label,
      String? value,
      String unit,
      VoidCallback onTap, {
      double? width = 85,
    }) {
      final isSet = value != null && value != '-';

      return InkWell(
        key: ValueKey(fieldId),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: width,
          height: width,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value ?? '-',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSet ? Colors.white : Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSet ? colorScheme.primary : Colors.white38,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildTireCard(
      String fieldId,
      String position,
      String? model,
      String? pressure,
      VoidCallback onModelTap,
      VoidCallback onPressureTap,
    ) {
      final hasModel = model != null && model.isNotEmpty && model != '-';
      final hasPressure = pressure != null && pressure != '-';

      return Container(
        key: ValueKey(fieldId),
        width: MediaQuery.sizeOf(context).width - 36,
        margin: const EdgeInsets.only(bottom: 12),
        height: 85,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: onModelTap,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$position ${Translations.get(lang, 'modelEdit')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasModel ? model : Translations.get(lang, 'notSet'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasModel ? Colors.white : Colors.white38,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            VerticalDivider(
              color: Colors.white.withOpacity(0.1),
              width: 1,
              thickness: 1,
            ),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onPressureTap,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        Translations.get(lang, 'air'),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            hasPressure ? pressure : '-',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: hasPressure
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unitFor('tirePressure', 'bar/PSI'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasPressure
                                  ? colorScheme.primary
                                  : Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    TrailSetup setupWithCustomValue(
      String categoryId,
      String fieldId,
      String value,
    ) {
      final categories = params.customCategories.map((category) {
        if (category.id != categoryId) return category;
        return category.copyWith(
          fields: category.fields
              .map(
                (field) =>
                    field.id == fieldId ? field.copyWith(value: value) : field,
              )
              .toList(),
        );
      }).toList();
      return setup.copyWith(
        customParameters: params.copyWith(customCategories: categories),
      );
    }

    List<Widget> buildCustomFieldTiles(CustomSetupCategory? category) {
      if (category == null) return const [];
      return category.fields.map((field) {
        if (field.type == CustomFieldType.boolean) {
          final enabled = field.value == 'true';
          return SizedBox(
            key: ValueKey('custom:${field.id}'),
            width: 182,
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              tileColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                field.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: enabled,
              onChanged: (value) => handleSave(
                field.name,
                Translations.get(lang, enabled ? 'booleanYes' : 'booleanNo'),
                Translations.get(lang, value ? 'booleanYes' : 'booleanNo'),
                '',
                setupWithCustomValue(category.id, field.id, value.toString()),
              ),
            ),
          );
        }

        return buildTile(
          'custom:${field.id}',
          field.name,
          field.value.isEmpty ? null : field.value,
          field.unit,
          () => showStepperModal(
            field.name,
            field.unit,
            field.value.isEmpty ? null : field.value,
            field.type == CustomFieldType.text,
            1,
            (value, note) => handleSave(
              field.name,
              field.value,
              value,
              note,
              setupWithCustomValue(category.id, field.id, value),
            ),
          ),
        );
      }).toList();
    }

    Widget buildCustomFields(CustomSetupCategory category) {
      if (category.fields.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: orderedFields(category.id, buildCustomFieldTiles(category)),
      );
    }

    CustomSetupCategory? customCategory(String id) {
      final index = params.customCategories.indexWhere(
        (category) => category.id == id,
      );
      return index == -1 ? null : params.customCategories[index];
    }

    void saveCategoryNotes(String categoryId, String notes) {
      final provider = context.read<BikeProvider>();
      final currentBike = provider.bikes.firstWhere(
        (bike) => bike.id == widget.bikeId,
      );
      final currentSetup = currentBike.setups.firstWhere(
        (setup) => setup.id == widget.setupId,
      );
      final currentParameters =
          currentSetup.customParameters ??
          currentBike.availableParameters ??
          BikeParameters();
      final categories = currentParameters.customCategories.map((category) {
        return category.id == categoryId
            ? category.copyWith(notes: notes)
            : category;
      }).toList();
      provider.updateSetup(
        widget.bikeId,
        currentSetup.copyWith(
          customParameters: currentParameters.copyWith(
            customCategories: categories,
          ),
        ),
      );
    }

    Widget buildCategoryNotes(CustomSetupCategory? category) {
      if (category == null || !category.notesEnabled) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: _CategoryNotesField(
          key: ValueKey('category-notes-${setup.id}-${category.id}'),
          initialValue: category.notes,
          hintText: Translations.format(lang, 'categoryNotesHint', {
            'category': category.name,
          }),
          onSave: (notes) => saveCategoryNotes(category.id, notes),
        ),
      );
    }

    final categorySections = <String, Widget>{
      'fork': Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- FORK ---
          categoryHeader(
            'fork',
            Translations.get(lang, 'fork'),
            svgPath: 'assets/icons/fork.svg',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: orderedFields('fork', [
              if (params.forkPsi)
                buildTile(
                  'forkPsi',
                  Translations.get(lang, 'mainShort'),
                  _formatNum(setup.forkPsi),
                  unitFor('forkPsi', 'PSI'),
                  () => showStepperModal(
                    componentField('fork', 'mainShort'),
                    unitFor('forkPsi', 'PSI'),
                    _formatNum(setup.forkPsi),
                    false,
                    5,
                    (v, n) => handleSave(
                      componentField('fork', 'mainShort'),
                      _formatNum(setup.forkPsi),
                      v,
                      n,
                      setup.copyWith(forkPsi: _parseDouble(v)),
                    ),
                  ),
                ),
              if (params.forkOtt)
                buildTile(
                  'forkOtt',
                  Translations.get(lang, 'negativeChamberShort'),
                  _formatNum(setup.forkOtt),
                  unitFor('forkOtt', Translations.get(lang, 'unitPsiClicks')),
                  () => showStepperModal(
                    componentField('fork', 'negativeChamberShort'),
                    unitFor('forkOtt', Translations.get(lang, 'unitPsiClicks')),
                    _formatNum(setup.forkOtt),
                    false,
                    5,
                    (v, n) => handleSave(
                      componentField('fork', 'negativeChamberShort'),
                      _formatNum(setup.forkOtt),
                      v,
                      n,
                      setup.copyWith(forkOtt: _parseDouble(v)),
                    ),
                  ),
                ),
              if (params.forkHsc)
                buildTile(
                  'forkHsc',
                  'HSC',
                  _formatNum(setup.forkHsc),
                  unitFor('forkHsc', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('fork', 'hsc'),
                    unitFor('forkHsc', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.forkHsc),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('fork', 'hsc'),
                      _formatNum(setup.forkHsc),
                      v,
                      n,
                      setup.copyWith(forkHsc: int.tryParse(v)),
                    ),
                  ),
                ),
              if (params.forkLsc)
                buildTile(
                  'forkLsc',
                  'LSC',
                  _formatNum(setup.forkLsc),
                  unitFor('forkLsc', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('fork', 'lsc'),
                    unitFor('forkLsc', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.forkLsc),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('fork', 'lsc'),
                      _formatNum(setup.forkLsc),
                      v,
                      n,
                      setup.copyWith(forkLsc: int.tryParse(v)),
                    ),
                  ),
                ),
              if (params.forkHsr)
                buildTile(
                  'forkHsr',
                  'HSR',
                  _formatNum(setup.forkHsr),
                  unitFor('forkHsr', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('fork', 'hsr'),
                    unitFor('forkHsr', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.forkHsr),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('fork', 'hsr'),
                      _formatNum(setup.forkHsr),
                      v,
                      n,
                      setup.copyWith(forkHsr: int.tryParse(v)),
                    ),
                  ),
                ),
              if (params.forkLsr)
                buildTile(
                  'forkLsr',
                  'LSR',
                  _formatNum(setup.forkLsr),
                  unitFor('forkLsr', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('fork', 'lsr'),
                    unitFor('forkLsr', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.forkLsr),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('fork', 'lsr'),
                      _formatNum(setup.forkLsr),
                      v,
                      n,
                      setup.copyWith(forkLsr: int.tryParse(v)),
                    ),
                  ),
                ),
              if (params.forkTokens)
                buildTile(
                  'forkTokens',
                  Translations.get(lang, 'tokensShort'),
                  _formatNum(setup.forkTokens),
                  unitFor('forkTokens', Translations.get(lang, 'unitPieces')),
                  () => showStepperModal(
                    componentField('fork', 'tokensShort'),
                    unitFor('forkTokens', Translations.get(lang, 'unitPieces')),
                    _formatNum(setup.forkTokens),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('fork', 'tokensShort'),
                      _formatNum(setup.forkTokens),
                      v,
                      n,
                      setup.copyWith(forkTokens: int.tryParse(v)),
                    ),
                  ),
                ),
              if (params.forkHbo)
                buildTile(
                  'forkHbo',
                  'HBO',
                  _formatNum(setup.forkHbo),
                  unitFor('forkHbo', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('fork', 'hbo'),
                    unitFor('forkHbo', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.forkHbo),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('fork', 'hbo'),
                      _formatNum(setup.forkHbo),
                      v,
                      n,
                      setup.copyWith(forkHbo: int.tryParse(v)),
                    ),
                  ),
                ),
              ...buildCustomFieldTiles(customCategory('fork')),
            ]),
          ),
          buildCategoryNotes(customCategory('fork')),
        ],
      ),
      'shock': Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SHOCK ---
          categoryHeader(
            'shock',
            Translations.get(lang, 'shock'),
            svgPath: 'assets/icons/shock.svg',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: orderedFields('shock', [
              if (!params.shockIsCoil) ...[
                if (params.shockPsi)
                  buildTile(
                    'shockPsi',
                    Translations.get(lang, 'airShock'),
                    _formatNum(setup.shockPsi),
                    unitFor('shockPsi', 'PSI'),
                    () => showStepperModal(
                      Translations.get(lang, 'shockAir'),
                      unitFor('shockPsi', 'PSI'),
                      _formatNum(setup.shockPsi),
                      false,
                      5,
                      (v, n) => handleSave(
                        Translations.get(lang, 'shockAir'),
                        _formatNum(setup.shockPsi),
                        v,
                        n,
                        setup.copyWith(shockPsi: _parseDouble(v)),
                      ),
                    ),
                  ),
                if (params.shockTokens)
                  buildTile(
                    'shockTokens',
                    Translations.get(lang, 'tokensShort'),
                    _formatNum(setup.shockTokens),
                    unitFor(
                      'shockTokens',
                      Translations.get(lang, 'unitPieces'),
                    ),
                    () => showStepperModal(
                      componentField('shock', 'tokensShort'),
                      unitFor(
                        'shockTokens',
                        Translations.get(lang, 'unitPieces'),
                      ),
                      _formatNum(setup.shockTokens),
                      false,
                      1,
                      (v, n) => handleSave(
                        componentField('shock', 'tokensShort'),
                        _formatNum(setup.shockTokens),
                        v,
                        n,
                        setup.copyWith(shockTokens: int.tryParse(v)),
                      ),
                    ),
                  ),
              ] else ...[
                if (params.shockRate)
                  buildTile(
                    'shockRate',
                    Translations.get(lang, 'springShort'),
                    _formatNum(setup.shockRate),
                    unitFor('shockRate', 'lbs/in'),
                    () => showStepperModal(
                      componentField('shock', 'springRate'),
                      unitFor('shockRate', 'lbs/in'),
                      _formatNum(setup.shockRate),
                      false,
                      25,
                      (v, n) => handleSave(
                        componentField('shock', 'springRate'),
                        _formatNum(setup.shockRate),
                        v,
                        n,
                        setup.copyWith(shockRate: _parseDouble(v)),
                      ),
                    ),
                  ),
                if (params.shockPreload)
                  buildTile(
                    'shockPreload',
                    Translations.get(lang, 'preloadShort'),
                    _formatNum(setup.shockPreload),
                    unitFor(
                      'shockPreload',
                      Translations.get(lang, 'unitTurns'),
                    ),
                    () => showStepperModal(
                      componentField('shock', 'preload'),
                      unitFor(
                        'shockPreload',
                        Translations.get(lang, 'unitTurns'),
                      ),
                      _formatNum(setup.shockPreload),
                      false,
                      0.25,
                      (v, n) => handleSave(
                        componentField('shock', 'preload'),
                        _formatNum(setup.shockPreload),
                        v,
                        n,
                        setup.copyWith(shockPreload: _parseDouble(v)),
                      ),
                    ),
                  ),
              ],
              if (params.shockHsc)
                buildTile(
                  'shockHsc',
                  'HSC',
                  _formatNum(setup.shockHsc),
                  unitFor('shockHsc', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('shock', 'hsc'),
                    unitFor('shockHsc', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.shockHsc),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('shock', 'hsc'),
                      _formatNum(setup.shockHsc),
                      v,
                      n,
                      setup.copyWith(shockHsc: int.tryParse(v)),
                    ),
                  ),
                ),
              if (params.shockLsc)
                buildTile(
                  'shockLsc',
                  'LSC',
                  _formatNum(setup.shockLsc),
                  unitFor('shockLsc', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('shock', 'lsc'),
                    unitFor('shockLsc', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.shockLsc),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('shock', 'lsc'),
                      _formatNum(setup.shockLsc),
                      v,
                      n,
                      setup.copyWith(shockLsc: int.tryParse(v)),
                    ),
                  ),
                ),
              if (params.shockHsr)
                buildTile(
                  'shockHsr',
                  'HSR',
                  _formatNum(setup.shockHsr),
                  unitFor('shockHsr', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('shock', 'hsr'),
                    unitFor('shockHsr', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.shockHsr),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('shock', 'hsr'),
                      _formatNum(setup.shockHsr),
                      v,
                      n,
                      setup.copyWith(shockHsr: int.tryParse(v)),
                    ),
                  ),
                ),
              if (params.shockLsr)
                buildTile(
                  'shockLsr',
                  'LSR',
                  _formatNum(setup.shockLsr),
                  unitFor('shockLsr', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('shock', 'lsr'),
                    unitFor('shockLsr', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.shockLsr),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('shock', 'lsr'),
                      _formatNum(setup.shockLsr),
                      v,
                      n,
                      setup.copyWith(shockLsr: int.tryParse(v)),
                    ),
                  ),
                ),
              if (params.shockHbo)
                buildTile(
                  'shockHbo',
                  'HBO',
                  _formatNum(setup.shockHbo),
                  unitFor('shockHbo', Translations.get(lang, 'unitClicks')),
                  () => showStepperModal(
                    componentField('shock', 'hbo'),
                    unitFor('shockHbo', Translations.get(lang, 'unitClicks')),
                    _formatNum(setup.shockHbo),
                    false,
                    1,
                    (v, n) => handleSave(
                      componentField('shock', 'hbo'),
                      _formatNum(setup.shockHbo),
                      v,
                      n,
                      setup.copyWith(shockHbo: int.tryParse(v)),
                    ),
                  ),
                ),
              ...buildCustomFieldTiles(customCategory('shock')),
            ]),
          ),
          buildCategoryNotes(customCategory('shock')),
        ],
      ),
      if (availableCategoryIds.contains('tires'))
        'tires': Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            categoryHeader(
              'tires',
              Translations.get(lang, 'tires'),
              svgPath: 'assets/icons/tire.svg',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: orderedFields('tires', [
                if (params.tires) ...[
                  buildTireCard(
                    'frontTire',
                    Translations.get(lang, 'front'),
                    setup.frontTire,
                    _formatNum(setup.frontPressure),
                    () => showStepperModal(
                      Translations.get(lang, 'frontTireModel'),
                      '',
                      setup.frontTire,
                      true,
                      1,
                      (v, n) => handleSave(
                        Translations.get(lang, 'frontTireModel'),
                        setup.frontTire,
                        v,
                        n,
                        setup.copyWith(frontTire: v),
                      ),
                    ),
                    () => showStepperModal(
                      Translations.get(lang, 'frontTirePressure'),
                      unitFor('tirePressure', 'bar/PSI'),
                      _formatNum(setup.frontPressure),
                      false,
                      0.1,
                      (v, n) => handleSave(
                        Translations.get(lang, 'frontTirePressure'),
                        _formatNum(setup.frontPressure),
                        v,
                        n,
                        setup.copyWith(frontPressure: _parseDouble(v)),
                      ),
                    ),
                  ),
                  buildTireCard(
                    'rearTire',
                    Translations.get(lang, 'rear'),
                    setup.rearTire,
                    _formatNum(setup.rearPressure),
                    () => showStepperModal(
                      Translations.get(lang, 'rearTireModel'),
                      '',
                      setup.rearTire,
                      true,
                      1,
                      (v, n) => handleSave(
                        Translations.get(lang, 'rearTireModel'),
                        setup.rearTire,
                        v,
                        n,
                        setup.copyWith(rearTire: v),
                      ),
                    ),
                    () => showStepperModal(
                      Translations.get(lang, 'rearTirePressure'),
                      unitFor('tirePressure', 'bar/PSI'),
                      _formatNum(setup.rearPressure),
                      false,
                      0.1,
                      (v, n) => handleSave(
                        Translations.get(lang, 'rearTirePressure'),
                        _formatNum(setup.rearPressure),
                        v,
                        n,
                        setup.copyWith(rearPressure: _parseDouble(v)),
                      ),
                    ),
                  ),
                ],
                ...buildCustomFieldTiles(customCategory('tires')),
              ]),
            ),
            buildCategoryNotes(customCategory('tires')),
          ],
        ),
      for (final category in params.customCategories)
        if (!const {'fork', 'shock', 'tires'}.contains(category.id) &&
            availableCategoryIds.contains(category.id))
          category.id: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              categoryHeader(
                category.id,
                category.name,
                icon: Icons.category_outlined,
              ),
              buildCustomFields(category),
              buildCategoryNotes(category),
            ],
          ),
    };
    return PopScope(
      canPop: !_editingOrder,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _editingOrder) _finishOrdering();
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                pinned: true,
                actions: [
                  if (_editingOrder)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: Translations.get(lang, 'cancel'),
                      onPressed: () => setState(() => _editingOrder = false),
                    ),
                  if (_editingOrder)
                    TextButton(
                      onPressed: _finishOrdering,
                      child: Text(Translations.get(lang, 'finishFieldOrder')),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: Translations.get(lang, 'editFieldOrder'),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _draftOrders.clear();
                          _initialOrders.clear();
                          _draftCategoryOrder = null;
                          _initialCategoryOrder = List.of(categoryOrder);
                          _editingOrder = true;
                        });
                      },
                    ),
                  if (!_editingOrder)
                    IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: Translations.get(lang, 'setupConfig'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SetupConfiguratorScreen(
                              bikeId: bike.id,
                              setupId: setup.id,
                              isEditing: true,
                            ),
                          ),
                        );
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 48.0, bottom: 16.0),
                  title: Text(
                    setup.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.surface.withOpacity(0.8),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (_editingOrder)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              Translations.get(lang, 'fieldOrderHint'),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverReorderableList(
                itemCount: visibleCategoryIds.length,
                itemBuilder: (context, index) {
                  final id = visibleCategoryIds[index];
                  return Container(
                    key: ValueKey('category-$id'),
                    child: categorySections[id],
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (!_editingOrder) return;
                  final visible = List<String>.of(visibleCategoryIds);
                  if (newIndex > oldIndex) newIndex--;
                  visible.insert(newIndex, visible.removeAt(oldIndex));
                  var index = 0;
                  setState(() {
                    _draftCategoryOrder = categoryOrder
                        .map(
                          (id) => availableCategoryIds.contains(id)
                              ? visible[index++]
                              : id,
                        )
                        .toList();
                  });
                },
                proxyDecorator: (child, index, animation) => Material(
                  color: colorScheme.surface,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LOG ---
                    buildSectionHeader(
                      Translations.get(lang, 'history'),
                      icon: Icons.history,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: setup.logs.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                Translations.get(lang, 'noHistory'),
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 240),
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white,
                                      Colors.white,
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.75, 1.0],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.dstIn,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: setup.logs.length,
                                  itemBuilder: (context, index) {
                                    final log = setup.logs[index];
                                    final isLast =
                                        index == setup.logs.length - 1;

                                    String mainText = log.parameters;
                                    String diffBadge = '';
                                    final regex = RegExp(r'(.*)\s\((.*)\)$');
                                    final match = regex.firstMatch(
                                      log.parameters,
                                    );
                                    if (match != null) {
                                      mainText =
                                          match.group(1) ?? log.parameters;
                                      diffBadge = match.group(2) ?? '';
                                    }

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(
                                                top: 6,
                                              ),
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: colorScheme.primary,
                                                  width: 2,
                                                ),
                                                color: Theme.of(
                                                  context,
                                                ).scaffoldBackgroundColor,
                                              ),
                                            ),
                                            if (!isLast)
                                              Container(
                                                width: 1.5,
                                                height: 50,
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                              )
                                            else
                                              const SizedBox(height: 10),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 24.0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        mainText,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    if (diffBadge.isNotEmpty)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: colorScheme
                                                              .primaryContainer
                                                              .withOpacity(0.8),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          diffBadge,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: colorScheme
                                                                .onPrimaryContainer,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                if (log.note.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    log.note,
                                                    style: TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.white
                                                          .withOpacity(0.5),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                    ),

                    // --- NOTIZEN ---
                    buildSectionHeader(
                      Translations.get(lang, 'notes'),
                      icon: Icons.edit_note,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _notesController,
                        focusNode: _notesFocusNode,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: Translations.get(lang, 'notesHint'),
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ZENTRALER DIALOG MIT STEPPER ---
class _CategoryNotesField extends StatefulWidget {
  const _CategoryNotesField({
    super.key,
    required this.initialValue,
    required this.hintText,
    required this.onSave,
  });

  final String initialValue;
  final String hintText;
  final ValueChanged<String> onSave;

  @override
  State<_CategoryNotesField> createState() => _CategoryNotesFieldState();
}

class _CategoryNotesFieldState extends State<_CategoryNotesField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late String _lastSavedValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    _lastSavedValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant _CategoryNotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      _lastSavedValue = widget.initialValue;
    }
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _save();
  }

  void _save() {
    final value = _controller.text;
    if (value == _lastSavedValue) return;
    _lastSavedValue = value;
    widget.onSave(value);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.notes_outlined),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.35)),
        ),
      ),
    );
  }
}

class _EditValueDialog extends StatefulWidget {
  final String title;
  final String unit;
  final String? initialValue;
  final bool isText;
  final double stepSize;
  final Function(String, String) onSave;

  const _EditValueDialog({
    required this.title,
    required this.unit,
    this.initialValue,
    required this.isText,
    required this.stepSize,
    required this.onSave,
  });

  @override
  State<_EditValueDialog> createState() => _EditValueDialogState();
}

class _EditValueDialogState extends State<_EditValueDialog> {
  late TextEditingController _valCtrl;
  late TextEditingController _noteCtrl;
  late FocusNode _valFocusNode;
  bool _manualEdit = false;
  double? _currentNum;

  @override
  void initState() {
    super.initState();
    _valCtrl = TextEditingController(text: widget.initialValue ?? '');
    _noteCtrl = TextEditingController();
    _valFocusNode = FocusNode();

    if (!widget.isText) {
      if (widget.initialValue != null &&
          widget.initialValue!.isNotEmpty &&
          widget.initialValue != '-') {
        _currentNum = double.tryParse(
          widget.initialValue!.replaceAll(',', '.'),
        );
      }
    }
  }

  @override
  void dispose() {
    _valCtrl.dispose();
    _noteCtrl.dispose();
    _valFocusNode.dispose();
    super.dispose();
  }

  void _changeValue(double delta) {
    setState(() {
      _currentNum = (_currentNum ?? 0) + delta;
      _valCtrl.text = _currentNum == _currentNum!.toInt()
          ? _currentNum!.toInt().toString()
          : _currentNum!.toStringAsFixed(1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final titleString = widget.unit.isNotEmpty
        ? '${widget.title} (${widget.unit})'
        : widget.title;
    final description = SuspensionDictionary.getDescription(widget.title, lang);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (description != null) const SizedBox(width: 24),
          Expanded(
            child: Text(
              titleString,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (description != null)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
              splashRadius: 20,
              icon: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Translations.get(lang, 'whatIsThis'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    content: Text(
                      description,
                      style: const TextStyle(height: 1.5),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(Translations.get(lang, 'understood')),
                      ),
                    ],
                  ),
                );
              },
            )
          else if (description == null)
            const SizedBox(width: 24),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isText)
              TextField(
                controller: _valCtrl,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: Translations.get(lang, 'newValue'),
                ),
                autofocus: true,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove),
                    onPressed: () => _changeValue(-widget.stepSize),
                    padding: const EdgeInsets.all(12),
                  ),
                  _manualEdit
                      ? SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _valCtrl,
                            focusNode: _valFocusNode,
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(
                              signed: true,
                              decimal: true,
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(isDense: true),
                            onSubmitted: (val) {
                              setState(() {
                                _currentNum = double.tryParse(
                                  val.replaceAll(',', '.'),
                                );
                                _manualEdit = false;
                              });
                            },
                          ),
                        )
                      : InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() => _manualEdit = true);
                            _valFocusNode.requestFocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              _valCtrl.text.isEmpty ? '0' : _valCtrl.text,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: () => _changeValue(widget.stepSize),
                    padding: const EdgeInsets.all(12),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: Translations.get(lang, 'reasonOpt'),
                hintText: Translations.get(lang, 'reasonOptHint'),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(Translations.get(lang, 'cancel')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            if (_valCtrl.text.isNotEmpty) {
              widget.onSave(_valCtrl.text, _noteCtrl.text);
            }
          },
          child: Text(Translations.get(lang, 'save')),
        ),
      ],
    );
  }
}
