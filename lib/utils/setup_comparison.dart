import '../models/bike.dart';
import '../models/bike_parameters.dart';
import '../models/trail_setup.dart';
import 'translations.dart';

class ComparisonValue {
  final Object? value;
  final String unit;
  const ComparisonValue(this.value, this.unit);
  String get display => value == null || value == ''
      ? '—'
      : '${value is num ? formatComparisonNumber(value as num) : value}${unit.isEmpty ? '' : ' $unit'}';
}

String formatComparisonNumber(num value) =>
    value.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');

class SetupComparisonRow {
  final String id, category, categoryName, label;
  final ComparisonValue a, b;
  const SetupComparisonRow(
    this.id,
    this.category,
    this.categoryName,
    this.label,
    this.a,
    this.b,
  );
  bool get changed => a.value != b.value || a.unit != b.unit;
  String? get delta {
    if (!changed || a.value is! num || b.value is! num || a.unit != b.unit)
      return null;
    final difference = (b.value as num) - (a.value as num);
    if (difference == 0) return null;
    return '${difference > 0 ? '▲ +' : '▼ −'}${formatComparisonNumber(difference.abs())}${b.unit.isEmpty ? '' : ' ${b.unit}'}';
  }
}

List<SetupComparisonRow> buildSetupComparison(
  Bike bike,
  TrailSetup a,
  TrailSetup b,
  String lang,
) {
  String tr(String key) => Translations.get(lang, key);
  Map<
    String,
    ({
      String category,
      String categoryName,
      String label,
      ComparisonValue value,
    })
  >
  values(TrailSetup setup) {
    final params =
        setup.customParameters ?? bike.availableParameters ?? BikeParameters();
    final enabled = params.toMap();
    final stored = setup.toMap();
    final result =
        <
          String,
          ({
            String category,
            String categoryName,
            String label,
            ComparisonValue value,
          })
        >{};
    void add(
      String id,
      String category,
      String categoryName,
      String label,
      Object? value,
      String unit,
    ) {
      result[id] = (
        category: category,
        categoryName: categoryName,
        label: label,
        value: ComparisonValue(value == '' ? null : value, unit),
      );
    }

    for (final category in ['fork', 'shock']) {
      for (final suffix in [
        'Psi',
        'Ott',
        'Negative',
        'Rate',
        'Preload',
        'Hsc',
        'Lsc',
        'Hsr',
        'Lsr',
        'Tokens',
        'Hbo',
      ]) {
        final id = '$category$suffix';
        if (enabled[id] != true) continue;
        if (category == 'shock' &&
            (params.shockIsCoil
                ? ['Psi', 'Tokens'].contains(suffix)
                : ['Rate', 'Preload'].contains(suffix)))
          continue;
        final label = switch (suffix) {
          'Psi' => tr('mainShort'),
          'Ott' => tr(params.legacyFork ? 'legacyForkValue' : 'ott'),
          'Negative' => tr('negativeChamber'),
          'Rate' => tr('springRate'),
          'Preload' => tr('preload'),
          'Tokens' => tr('tokensShort'),
          _ => suffix.toUpperCase(),
        };
        final unit = switch (suffix) {
          'Psi' => 'PSI',
          'Ott' => tr('unitClicks'),
          'Negative' => 'PSI',
          'Rate' => 'lbs/in',
          'Preload' => tr('unitTurns'),
          'Tokens' => tr('unitPieces'),
          _ => tr('unitClicks'),
        };
        add(
          params.legacyFork && id == 'forkOtt' ? 'legacyFork' : id,
          category,
          tr(category),
          label,
          stored[id],
          params.legacyFork && id == 'forkOtt'
              ? ''
              : params.unitOverrides[id] ?? unit,
        );
      }
    }
    if (params.tires) {
      for (final side in ['front', 'rear']) {
        add(
          '${side}Tire',
          'tires',
          tr('tires'),
          '${tr(side)} · ${tr('tires')}',
          stored['${side}Tire'],
          '',
        );
        add(
          '${side}Pressure',
          'tires',
          tr('tires'),
          tr('${side}TirePressure'),
          stored['${side}Pressure'],
          params.legacyTires
              ? ''
              : params.unitOverrides['tirePressure'] ?? 'bar',
        );
      }
    }
    for (final category in params.customCategories) {
      for (final field in category.fields) {
        Object? value = field.value;
        if (field.type == CustomFieldType.number)
          value = num.tryParse(field.value.replaceAll(',', '.')) ?? field.value;
        if (field.type == CustomFieldType.boolean)
          value = field.value == 'true' ? tr('booleanYes') : tr('booleanNo');
        add(
          '${category.id}/custom:${field.id}',
          category.id,
          ['fork', 'shock', 'tires'].contains(category.id)
              ? tr(category.id)
              : category.name,
          field.name,
          value,
          field.unit,
        );
      }
    }
    return result;
  }

  final av = values(a), bv = values(b);
  final ids = {...av.keys, ...bv.keys};
  final categories = {
    ...a.categoryOrder,
    'fork',
    'shock',
    'tires',
    ...ids.map((id) => (av[id] ?? bv[id])!.category),
  };
  final rows = <SetupComparisonRow>[];
  for (final category in categories) {
    final categoryIds = ids
        .where((id) => (av[id] ?? bv[id])!.category == category)
        .toList();
    final order = a.fieldOrders[category] ?? const <String>[];
    int rank(String id) {
      final index = order.indexOf(
        id.contains('/custom:') ? id.split('/').last : id,
      );
      return index < 0 ? order.length + categoryIds.indexOf(id) : index;
    }

    final sorted = List<String>.of(categoryIds)
      ..sort((x, y) => rank(x).compareTo(rank(y)));
    for (final id in sorted) {
      final metadata = (av[id] ?? bv[id])!;
      rows.add(
        SetupComparisonRow(
          id,
          category,
          metadata.categoryName,
          metadata.label,
          av[id]?.value ?? const ComparisonValue(null, ''),
          bv[id]?.value ?? const ComparisonValue(null, ''),
        ),
      );
    }
  }
  return rows;
}
