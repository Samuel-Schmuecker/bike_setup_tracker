import 'package:bike_setup_tracker/utils/translations.dart';
import 'package:flutter/material.dart';
import '../models/setting_range.dart';

class SettingRangeScale extends StatelessWidget {
  final SettingRange range;
  final double? value;
  final String languageCode;
  const SettingRangeScale({
    super.key,
    required this.range,
    required this.value,
    required this.languageCode,
  });
  @override
  Widget build(BuildContext context) {
    final outside = value != null && !range.contains(value!);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: value == null
              ? 0
              : ((value! - range.min) / (range.max - range.min)).clamp(0, 1),
          minHeight: 4,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(SettingRange.format(range.min)),
            Text(SettingRange.format(range.max)),
          ],
        ),
        if (outside)
          Text(
            Translations.get(languageCode, 'rangeOutside'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class SettingRangeEditor extends StatefulWidget {
  final SettingRange? initial;
  final String title;
  final String unit;
  final String languageCode;
  final bool integerOnly;
  final ValueChanged<SettingRange?> onSave;
  const SettingRangeEditor({
    super.key,
    this.initial,
    required this.title,
    required this.unit,
    required this.languageCode,
    this.integerOnly = false,
    required this.onSave,
  });
  @override
  State<SettingRangeEditor> createState() => _SettingRangeEditorState();
}

class _SettingRangeEditorState extends State<SettingRangeEditor> {
  late final min = TextEditingController(
    text: SettingRange.format(widget.initial?.min ?? 0),
  );
  late final max = TextEditingController(
    text: widget.initial == null
        ? ''
        : SettingRange.format(widget.initial!.max),
  );
  late final step = TextEditingController(
    text: SettingRange.format(widget.initial?.step ?? 1),
  );
  late String reference = widget.initial?.reference ?? 'none';
  String? error;
  @override
  void dispose() {
    min.dispose();
    max.dispose();
    step.dispose();
    super.dispose();
  }

  void save() {
    final a = double.tryParse(min.text.replaceAll(',', '.'));
    final b = double.tryParse(max.text.replaceAll(',', '.'));
    final s = double.tryParse(step.text.replaceAll(',', '.'));
    final range = a == null || b == null || s == null
        ? null
        : SettingRange(min: a, max: b, step: s, reference: reference);
    if (range == null ||
        !range.isValid ||
        (widget.integerOnly &&
            [a!, b!, s!].any((v) => v != v.roundToDouble()))) {
      setState(
        () => error = Translations.get(
          widget.languageCode,
          widget.integerOnly ? 'rangeInvalidInteger' : 'rangeInvalid',
        ),
      );
      return;
    }
    widget.onSave(range);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final entry in [
              (min, Translations.get(widget.languageCode, 'rangeMinimum')),
              (max, Translations.get(widget.languageCode, 'rangeMaximum')),
              (step, Translations.get(widget.languageCode, 'rangeStepSize')),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: entry.$1,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: entry.$2,
                    suffixText: widget.unit,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: save,
              child: Text(Translations.get(widget.languageCode, 'save')),
            ),
            TextButton(
              onPressed: () {
                widget.onSave(null);
                Navigator.pop(context);
              },
              child: Text(Translations.get(widget.languageCode, 'rangeRemove')),
            ),
          ],
        ),
      ),
    ),
  );
}
