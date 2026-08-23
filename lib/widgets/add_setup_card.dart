// lib/widgets/add_setup_card.dart

import 'package:flutter/material.dart';

class AddSetupCard extends StatelessWidget {
  final VoidCallback onTap;
  const AddSetupCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
      ),
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text('Neues Setup hinzufügen', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}