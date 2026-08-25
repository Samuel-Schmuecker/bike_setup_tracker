// lib/widgets/add_setup_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/translations.dart'; 
import 'package:bike_setup_tracker/providers/language_provider.dart';


class AddSetupCard extends StatelessWidget {
  final VoidCallback onTap;
  const AddSetupCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>().currentLanguage;

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
                Text(Translations.get(lang, 'addnewSetup'), style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}