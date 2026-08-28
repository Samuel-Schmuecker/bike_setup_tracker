// lib/widgets/setup_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/trail_setup.dart';
import '../models/bike.dart'; // NEU
import 'package:provider/provider.dart';
import '../../utils/translations.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';

class SetupCard extends StatelessWidget {
  final TrailSetup setup;
  final Bike bike; // NEU: Bike Objekt, um Air/Coil abzufragen
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onFavoriteToggle;

  const SetupCard({
    super.key,
    required this.setup,
    required this.bike, // NEU
    required this.onTap,
    this.onLongPress,
    required this.onFavoriteToggle,
  });

  // Verhindert .0 bei runden Zahlen und gibt '-' bei null zurück
  String _formatNum(num? value) {
    if (value == null) return '-';
    return value == value.toInt() ? value.toInt().toString() : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>().currentLanguage;

    Widget buildValueBox(
      String svgPath,
      String label,
      String value,
      String unit,
    ) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  svgPath,
                  width: 12,
                  height: 12,
                  colorFilter: ColorFilter.mode(
                    colorScheme.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // A setup can override the bike-wide suspension configuration.
    final parameters = setup.customParameters ?? bike.availableParameters;
    final isCoil = parameters?.shockIsCoil == true;
    final shockValStr = isCoil
        ? _formatNum(setup.shockRate)
        : _formatNum(setup.shockPsi);
    final shockUnitStr = isCoil
        ? parameters?.unitOverrides['shockRate'] ?? 'lbs/in'
        : parameters?.unitOverrides['shockPsi'] ?? 'PSI';
    final forkUnitStr = parameters?.unitOverrides['forkPsi'] ?? 'PSI';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      setup.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      setup.isFavorite ? Icons.star : Icons.star_border,
                      color: setup.isFavorite
                          ? Colors.amber
                          : colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onFavoriteToggle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  buildValueBox(
                    'assets/icons/fork.svg',
                    'Gabel',
                    _formatNum(setup.forkPsi),
                    forkUnitStr,
                  ),
                  const SizedBox(width: 12),
                  // Setzt den korrekten String & Einheit ein
                  buildValueBox(
                    'assets/icons/shock.svg',
                    'Dämpfer',
                    shockValStr,
                    shockUnitStr,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        Translations.get(lang, 'details'),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
