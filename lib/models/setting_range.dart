class SettingRange {
  final double min;
  final double max;
  final double step;
  final String reference;

  const SettingRange({
    required this.min,
    required this.max,
    this.step = 1,
    this.reference = 'none',
  });

  bool get isValid =>
      min.isFinite &&
      max.isFinite &&
      step.isFinite &&
      max > min &&
      step > 0 &&
      step <= max - min;
  bool contains(double value) => value.isFinite && value >= min && value <= max;
  double next(double? value, int direction) => double.parse(
    (value == null ? min : (value + direction * step).clamp(min, max))
        .toStringAsFixed(6),
  );
  static String format(double value) =>
      value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  Map<String, dynamic> toMap() => {
    'min': min,
    'max': max,
    'step': step,
    'reference': reference,
  };
  static SettingRange? fromMap(dynamic value) {
    if (value is! Map || value['min'] is! num || value['max'] is! num) {
      return null;
    }
    final range = SettingRange(
      min: (value['min'] as num).toDouble(),
      max: (value['max'] as num).toDouble(),
      step: (value['step'] as num? ?? 1).toDouble(),
      reference: value['reference'] as String? ?? 'none',
    );
    return range.isValid ? range : null;
  }
}
