import 'package:flutter/material.dart';
import '../utils/translations.dart';

/// A reusable opaque HSV picker. Changes are returned only on confirmation.
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key, required this.color, required this.lang});

  final Color color;
  final String lang;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late HSVColor _color;

  @override
  void initState() {
    super.initState();
    _color = HSVColor.fromColor(widget.color);
  }

  String tr(String key) => Translations.get(widget.lang, key);

  @override
  Widget build(BuildContext context) {
    final selected = _color.toColor();
    return AlertDialog(
      title: Text(tr('chooseColor')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('paletteHint')),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const height = 190.0;
                  void update(Offset position) {
                    setState(() {
                      _color = _color
                          .withSaturation((position.dx / width).clamp(0.0, 1.0))
                          .withValue(
                            (1 - position.dy / height).clamp(0.0, 1.0),
                          );
                    });
                  }

                  return Semantics(
                    label: tr('paletteHint'),
                    child: GestureDetector(
                      key: const ValueKey('color-palette'),
                      onTapDown: (details) => update(details.localPosition),
                      onPanStart: (details) => update(details.localPosition),
                      onPanUpdate: (details) => update(details.localPosition),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: height,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        HSVColor.fromAHSV(
                                          1,
                                          _color.hue,
                                          1,
                                          1,
                                        ).toColor(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: (_color.saturation * width - 10).clamp(
                                  0.0,
                                  width - 20,
                                ),
                                top: ((1 - _color.value) * height - 10).clamp(
                                  0.0,
                                  height - 20,
                                ),
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(tr('colorHue')),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                  ),
                ),
                child: Slider(
                  value: _color.hue,
                  max: 360,
                  activeColor: Colors.transparent,
                  inactiveColor: Colors.transparent,
                  thumbColor: Colors.white,
                  semanticFormatterCallback: (value) =>
                      '${tr('colorHue')} ${value.round()}°',
                  onChanged: (value) =>
                      setState(() => _color = _color.withHue(value)),
                ),
              ),
              const SizedBox(height: 12),
              // Sliders also make the color plane accessible by keyboard.
              Text(tr('colorSaturation')),
              Slider(
                value: _color.saturation,
                semanticFormatterCallback: (value) =>
                    '${tr('colorSaturation')} ${(value * 100).round()}%',
                onChanged: (value) =>
                    setState(() => _color = _color.withSaturation(value)),
              ),
              Text(tr('colorBrightness')),
              Slider(
                value: _color.value,
                semanticFormatterCallback: (value) =>
                    '${tr('colorBrightness')} ${(value * 100).round()}%',
                onChanged: (value) =>
                    setState(() => _color = _color.withValue(value)),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        ThemeData.estimateBrightnessForColor(selected) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, selected),
          child: Text(tr('applyColor')),
        ),
      ],
    );
  }
}
