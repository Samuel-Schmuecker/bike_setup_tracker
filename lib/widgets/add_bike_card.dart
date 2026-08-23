// lib/widgets/add_bike_card.dart

import 'package:flutter/material.dart';

class AddBikeCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddBikeCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      // Kein Schatten für einen "flacheren", dezenten Look
      elevation: 0, 
      // Dünner Rand und halbtransparente Füllung
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
      clipBehavior: Clip.antiAlias, // Sorgt dafür, dass der InkWell im Radius bleibt
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // Padding so gewählt, dass die Höhe in etwa der BikeCard entspricht
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 32,
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              Text(
                'add bike',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}