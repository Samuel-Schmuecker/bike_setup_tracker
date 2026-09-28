import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../models/trail_setup.dart';
import '../../providers/language_provider.dart';
import '../../utils/setup_comparison.dart';
import '../../utils/translations.dart';

class SetupComparisonScreen extends StatefulWidget {
  final Bike bike;
  final TrailSetup setupA, setupB;
  const SetupComparisonScreen({
    super.key,
    required this.bike,
    required this.setupA,
    required this.setupB,
  });
  @override
  State<SetupComparisonScreen> createState() => _SetupComparisonScreenState();
}

class _SetupComparisonScreenState extends State<SetupComparisonScreen> {
  bool _showAll = false;
  bool _swapped = false;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    String tr(String key) => Translations.get(lang, key);
    final setupA = _swapped ? widget.setupB : widget.setupA;
    final setupB = _swapped ? widget.setupA : widget.setupB;
    final allRows = buildSetupComparison(widget.bike, setupA, setupB, lang);
    final differenceCount = allRows.where((row) => row.changed).length;
    final rows = allRows.where((row) => _showAll || row.changed).toList();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = colors.primary;
    final divider = colors.outlineVariant.withValues(alpha: 0.6);

    Widget card(Widget child) => Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: divider),
      ),
      child: child,
    );

    Widget setupLabel(String letter, String name) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Setup $letter',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    Widget cell(String text, {bool header = false}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Text(
        text,
        style: header
            ? theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              )
            : theme.textTheme.bodyMedium,
      ),
    );

    Widget parameterCell(SetupComparisonRow row) {
      final label = switch (row.id) {
        'frontPressure' => tr('front'),
        'rearPressure' => tr('rear'),
        _ => row.label,
      };
      final unit = row.a.unit == row.b.unit ? row.a.unit : '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            if (unit.isNotEmpty)
              Text(
                '· $unit',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      );
    }

    String compactDelta(SetupComparisonRow row) {
      final delta = row.delta!.replaceFirst('▼', '▽');
      return row.b.unit.isEmpty
          ? delta
          : delta.substring(0, delta.length - row.b.unit.length - 1);
    }

    Widget valueCell(ComparisonValue value, {required bool sharedUnit}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Text(
          sharedUnit ? ComparisonValue(value.value, '').display : value.display,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Widget categoryIcon(String category) {
      final asset = switch (category) {
        'fork' => 'assets/icons/fork.svg',
        'shock' => 'assets/icons/shock.svg',
        _ => null,
      };
      return SizedBox(
        child: asset != null
            ? SvgPicture.asset(
                asset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
              )
            : Icon(
                category == 'tires' ? Icons.circle_outlined : Icons.tune,
                size: 20,
                color: accent,
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('compareSetups'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            card(
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          setupLabel('A', setupA.name),
                          IconButton(
                            tooltip: tr('comparisonSwap'),
                            icon: const Icon(Icons.swap_horiz),
                            color: accent,
                            onPressed: () =>
                                setState(() => _swapped = !_swapped),
                          ),
                          setupLabel('B', setupB.name),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        Translations.format(
                          lang,
                          differenceCount == 1
                              ? 'comparisonDifferenceOne'
                              : 'comparisonDifferenceCount',
                          {'count': '$differenceCount'},
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: divider),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      tr('comparisonAll'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    value: _showAll,
                    onChanged: (value) => setState(() => _showAll = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              card(
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, color: accent, size: 32),
                      const SizedBox(height: 12),
                      Text(tr('comparisonEmpty'), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            for (final category in rows.map((row) => row.category).toSet()) ...[
              card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          categoryIcon(category),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rows
                                  .firstWhere((row) => row.category == category)
                                  .categoryName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: divider),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.7),
                        1: FlexColumnWidth(0.75),
                        2: FlexColumnWidth(0.75),
                        3: FlexColumnWidth(1.15),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: TableBorder(
                        horizontalInside: BorderSide(color: divider),
                        verticalInside: BorderSide(
                          color: colors.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          children: [
                            cell(tr('comparisonParameter'), header: true),
                            cell('A', header: true),
                            cell('B', header: true),
                            Tooltip(
                              message: tr('comparisonDirection'),
                              child: cell('Δ', header: true),
                            ),
                          ],
                        ),
                        for (final row in rows.where(
                          (row) => row.category == category,
                        ))
                          TableRow(
                            decoration: BoxDecoration(
                              color: row.changed
                                  ? accent.withValues(alpha: 0.07)
                                  : null,
                              border: Border(
                                left: BorderSide(
                                  color: row.changed
                                      ? accent
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            children: [
                              parameterCell(row),
                              valueCell(
                                row.a,
                                sharedUnit: row.a.unit == row.b.unit,
                              ),
                              valueCell(
                                row.b,
                                sharedUnit: row.a.unit == row.b.unit,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: row.delta == null
                                      ? Text(
                                          '—',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            compactDelta(row),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: accent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
