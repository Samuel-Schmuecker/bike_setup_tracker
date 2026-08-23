// lib/widgets/bike_card.dart

import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../utils/image_helper.dart';
import '../screens/bike_detail/bike_detail_screen.dart';
import '../screens/edit_bike/edit_bike_screen.dart';

class BikeCard extends StatelessWidget {
  final Bike bike;
  final VoidCallback? onLongPress;

  const BikeCard({
    super.key,
    required this.bike,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Holt IMMER einen Bildpfad (Nutzer oder Kategorie-Fallback)
    final displayPath = ImageHelper.getDisplayImagePath(bike.imagePath, bike.category);

    // Hilfs-Widget für die nebeneinanderliegenden Chips (jetzt immer im dunklen Look)
    Widget buildChip(Widget child) {
      return Container(
        margin: const EdgeInsets.only(right: 8.0, top: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.black54, // Halbtransparenter, dunkler Hintergrund
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.white24, width: 0.5), // Feiner Rand
        ),
        child: child,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias, // Wichtig für abgerundete Ecken trotz Stack/Bild
      elevation: 3, // Schatten, da es ein Bild ist
      child: SizedBox(
        height: 140, // Feste Höhe
        child: Stack(
          children: [
            // 1. Hintergrundbild (es gibt jetzt IMMER eins)
            Positioned.fill(
              child: ImageHelper.buildImage(displayPath),
            ),

            // 2. Dunkles Gradient-Overlay (Links nach Rechts) für Lesbarkeit
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
                  onLongPress: onLongPress ?? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditBikeScreen(bike: bike),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Texte und Chips
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Marke
                              Text(
                                bike.brand.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: Colors.white70, // Fest auf hellgrau
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              // Modell
                              Text(
                                bike.model,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // Fest auf weiß
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
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  buildChip(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.tune,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${bike.setups.length}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
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