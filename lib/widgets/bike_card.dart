// lib/widgets/bike_card.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../screens/bike_detail/bike_detail_screen.dart';
import '../../utils/image_helper.dart';

class BikeCard extends StatelessWidget {
  final Bike bike;
  final VoidCallback? onLongPress; // NEU: Optionale Callback-Funktion

  const BikeCard({
    Key? key,
    required this.bike,
    this.onLongPress, // NEU
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasImage = bike.imagePath != null;

    // --- NEU: Sehr saubere ImageProvider Logik durch unseren Helfer ---
    ImageProvider? imageProvider;
    if (hasImage) {
      imageProvider = ImageHelper.getImageProvider(bike.imagePath!);
    }

    // Dynamische Text- und Chip-Farben (Weiß bei Bildern, Theme-Farben ohne Bild)
    final textColor = hasImage ? Colors.white : colorScheme.onSurface;
    final subtitleColor = hasImage ? Colors.white70 : colorScheme.onSurfaceVariant;
    final chipBgColor = hasImage 
        ? Colors.black54 
        : colorScheme.surfaceContainerHighest.withOpacity(0.6);
    final chipTextColor = hasImage ? Colors.white : colorScheme.onSurfaceVariant;

    // Hilfs-Widget für die nebeneinanderliegenden Chips
    Widget buildChip(Widget child) {
      return Container(
        margin: const EdgeInsets.only(right: 8.0, top: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(12.0),
          border: hasImage ? Border.all(color: Colors.white24, width: 0.5) : null,
        ),
        child: child,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias, // Wichtig für abgerundete Ecken trotz Stack/Bild
      elevation: hasImage ? 3 : 1,
      child: SizedBox(
        height: 140, // Feste Höhe wie gefordert
        child: Stack(
          children: [
            // 1. Hintergrundbild (ganz unten im Stack)
            if (hasImage)
              Positioned.fill(
                child: bike.imagePath!.startsWith('assets/')
                    // Wenn es ein Testbild aus unseren Ordnern ist:
                    ? Image.asset(bike.imagePath!, fit: BoxFit.cover) 
                    // Sonst wie gewohnt Web oder lokales Handy-File:
                    : (kIsWeb
                        ? Image.network(bike.imagePath!, fit: BoxFit.cover)
                        : Image.file(File(bike.imagePath!), fit: BoxFit.cover)),
              ),

            // 2. Dunkles Gradient-Overlay (Links nach Rechts)
            if (hasImage)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black87, // Sehr dunkel links (für Text)
                        Colors.transparent, // Transparent rechts (Bild bleibt sichtbar)
                      ],
                    ),
                  ),
                ),
              ),

            // 3. Klickbarer Bereich und Text (liegt ganz oben)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BikeDetailScreen(bikeId: bike.id),
                      ),
                    );
                  },
                  onLongPress: onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 4. Fall-Back Icon (nur wenn KEIN Bild existiert)
                        if (!hasImage) ...[
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            child: const Icon(Icons.directions_bike, size: 30),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // 5. Texte und Chips (Marke, Modell, Reihe mit Chips)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Marke
                              Text(
                                bike.brand.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: subtitleColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Modell
                              Text(
                                bike.model,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Chips (Kategorie & Setups nebeneinander)
                              Row(
                                children: [
                                  buildChip(
                                    Text(
                                      bike.category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: chipTextColor,
                                      ),
                                    ),
                                  ),
                                  buildChip(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.tune,
                                          size: 14,
                                          color: chipTextColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${bike.setups.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: chipTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}