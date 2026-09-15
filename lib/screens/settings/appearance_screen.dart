import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/translations.dart';
import '../../widgets/color_picker_dialog.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final lang = context.watch<LanguageProvider>().currentLanguage;
    String tr(String key) => Translations.get(lang, key);
    return Scaffold(
      appBar: AppBar(title: Text(tr('appearance'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(tr('appearanceHint')),
          const SizedBox(height: 24),
          _ColorSection(
            label: tr('backgroundColor'),
            color: theme.background,
            colors: const [
              ThemeProvider.defaultBackground,
              Color(0xFF121212),
              Color(0xFF172033),
              Color(0xFF302638),
              Color(0xFFF5F5F5),
              Color(0xFFFFF8EC),
            ],
            onChanged: theme.setBackground,
          ),
          const SizedBox(height: 24),
          _ColorSection(
            label: tr('accentColor'),
            color: theme.accent,
            colors: const [
              Colors.teal,
              Colors.blue,
              Colors.purple,
              Colors.pink,
              Colors.orange,
              Colors.green,
            ],
            onChanged: theme.setAccent,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_bike,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tr('colorPreview'))),
                  Switch(value: true, onChanged: (_) {}),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: theme.reset,
            icon: const Icon(Icons.restore),
            label: Text(tr('resetColors')),
          ),
        ],
      ),
    );
  }
}

class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.label,
    required this.color,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final List<Color> colors;
  final ValueChanged<Color> onChanged;

  String _hex(Color value) =>
      value.toARGB32().toRadixString(16).substring(2).toUpperCase();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final palette = [
      ...colors,
      if (!colors.any((entry) => entry.toARGB32() == color.toARGB32())) color,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: palette.map((candidate) {
            final selected = candidate.toARGB32() == color.toARGB32();
            return Semantics(
              selected: selected,
              label: '$label #${_hex(candidate)}',
              child: Tooltip(
                message: '#${_hex(candidate)}',
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: candidate,
                      foregroundColor:
                          ThemeData.estimateBrightnessForColor(candidate) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      shape: const CircleBorder(),
                    ),
                    onPressed: () => onChanged(candidate),
                    child: selected ? const Icon(Icons.check) : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.color_lens_outlined),
          label: Text(Translations.get(lang, 'chooseColor')),
          onPressed: () async {
            final selected = await showDialog<Color>(
              context: context,
              builder: (_) => ColorPickerDialog(color: color, lang: lang),
            );
            if (selected != null && context.mounted) onChanged(selected);
          },
        ),
        const SizedBox(height: 16),
        _CustomColorInput(color: color, onChanged: onChanged, lang: lang),
      ],
    );
  }
}

class _CustomColorInput extends StatefulWidget {
  const _CustomColorInput({
    required this.color,
    required this.onChanged,
    required this.lang,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final String lang;

  @override
  State<_CustomColorInput> createState() => _CustomColorInputState();
}

class _CustomColorInputState extends State<_CustomColorInput> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  String _hex(Color color) =>
      color.toARGB32().toRadixString(16).substring(2).toUpperCase();

  String _normalize(String value) =>
      value.trim().replaceFirst(RegExp(r'^#'), '');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _hex(widget.color));
  }

  @override
  void didUpdateWidget(covariant _CustomColorInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color.toARGB32() != widget.color.toARGB32() &&
        _normalize(_controller.text).toUpperCase() != _hex(widget.color)) {
      _controller.text = _hex(widget.color);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    final color = Color(
      0xFF000000 | int.parse(_normalize(_controller.text), radix: 16),
    );
    _controller.text = _hex(color);
    widget.onChanged(color);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controller,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: Translations.get(widget.lang, 'customColor'),
              hintText: '#009688',
              border: const OutlineInputBorder(),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(_normalize(value ?? ''))
                ? null
                : Translations.get(widget.lang, 'invalidColor'),
            onFieldSubmitted: (_) => _apply(),
            onChanged: (value) {
              final hex = _normalize(value);
              if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
                widget.onChanged(Color(0xFF000000 | int.parse(hex, radix: 16)));
              }
            },
          ),
        ],
      ),
    );
  }
}
