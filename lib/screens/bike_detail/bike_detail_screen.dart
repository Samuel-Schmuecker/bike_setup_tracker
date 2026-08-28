// lib/screens/bike_detail/bike_detail_screen.dart

import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/trail_setup.dart';
import 'package:bike_setup_tracker/screens/bike_detail/add_setup_screen.dart';
import 'package:bike_setup_tracker/screens/bike_detail/setup_configurator_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translations.dart';
import 'package:flutter_svg/flutter_svg.dart'; // NEU: Svg-Paket importiert
import '../../providers/bike_provider.dart';
import '../../widgets/setup_card.dart';
import '../../widgets/add_setup_card.dart';
import 'setup_detail_screen.dart'; 
import '../../utils/image_helper.dart';

class BikeDetailScreen extends StatelessWidget {
  final String bikeId;

  const BikeDetailScreen({super.key, required this.bikeId});

  void _onAddSetupTap(BuildContext context, Bike bike) {
    if (bike.availableParameters == null) {
      // Fall A: Noch nie konfiguriert -> Zeige Configurator
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SetupConfiguratorScreen(bikeId: bike.id)),
      );
    } else {
      // Fall B: Bereits konfiguriert -> Direkt zum Formular
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddSetupScreen(bikeId: bike.id)),
      );
    }
  }

  // 1. Zeigt das BottomSheet mit den 3 Optionen an
  void _showSetupOptions(BuildContext context, Bike bike, TrailSetup setup, String lang) {
  

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(setup.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(Translations.get(lang, 'rename')),
                onTap: () {
                  Navigator.pop(ctx); // BottomSheet schließen
                  _showRenameDialog(context, bike, setup, lang);
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: Text(Translations.get(lang, 'duplicate')),
                onTap: () {
                  context.read<BikeProvider>().duplicateSetup(
                    bike.id,
                    setup.id,
                    Translations.get(lang, 'copySuffix'),
                  );
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(Translations.get(lang, 'delete'), style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmDialog(context, bike, setup, lang);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // 2. Dialog zum Umbenennen
  void _showRenameDialog(BuildContext context, Bike bike, TrailSetup setup, String lang) {
    final nameController = TextEditingController(text: setup.name);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translations.get(lang, 'rename')),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(labelText: Translations.get(lang, 'newName'), border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(Translations.get(lang, 'cancel'))),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                // Wir nutzen die bestehende updateSetup Methode
                final updatedSetup = setup.copyWith(name: nameController.text.trim());
                context.read<BikeProvider>().updateSetup(bike.id, updatedSetup);
                Navigator.pop(ctx);
              }
            },
            child: Text(Translations.get(lang, 'save')),
          ),
        ],
      ),
    );
  }

  // 3. Sicherheits-Dialog vor dem Löschen
  void _showDeleteConfirmDialog(BuildContext context, Bike bike, TrailSetup setup, String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translations.get(lang, 'deleteSetupTitle')),
        content: Text('${Translations.get(lang, 'deleteSetupBody1')} "${setup.name}" ${Translations.get(lang, 'deleteSetupBody2')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(Translations.get(lang, 'cancel'))),
          TextButton(
            onPressed: () {
              context.read<BikeProvider>().deleteSetup(bike.id, setup.id);
              Navigator.pop(ctx);
            },
            child: Text(Translations.get(lang, 'delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final lang = context.watch<LanguageProvider>().currentLanguage;

    final bike = context.watch<BikeProvider>().bikes.firstWhere(
          (b) => b.id == bikeId,
          orElse: () => throw Exception(Translations.get(lang, 'bikeNotFound')),
        );

    

    // ANGEPASST: Nimmt nun einen svgPath statt IconData
    Widget buildTravelChip(String svgPath, String text) {
      return Container(
        margin: const EdgeInsets.only(right: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NEU: SvgPicture anstelle des Standard-Icons
            SvgPicture.asset(
              svgPath,
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            centerTitle: false,
            actions: [
                IconButton(
                icon: const Icon(Icons.tune),
                tooltip: Translations.get(lang, 'configSuspension'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // isEditing = true sorgt dafür, dass sich der Configurator danach einfach schließt
                      builder: (context) => SetupConfiguratorScreen(bikeId: bike.id, isEditing: true),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _onAddSetupTap(context, bike),
                tooltip: Translations.get(lang, 'newSetup'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.15,
              titlePadding: const EdgeInsets.only(left: 56.0, bottom: 16.0),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike.model,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ANGEPASST: Pfade zu den SVGs übergeben
                      buildTravelChip('assets/icons/fork.svg', '${bike.travelFront} mm ${Translations.get(lang, 'front')}'),
                      buildTravelChip('assets/icons/shock.svg', '${bike.travelRear} mm ${Translations.get(lang, 'rear')}'),
                    ],
                  ),
                ],
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Hintergrundbild (NEU: Greift den DisplayPath ab)
                  ImageHelper.buildImage(ImageHelper.getDisplayImagePath(bike.imagePath, bike.category)),
                  
                  // 2. Abdunkelndes Overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 2. ANPASSUNG DER SETUP-CARD
          SliverPadding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == bike.setups.length) {
                    return AddSetupCard(onTap: () => _onAddSetupTap(context, bike));
                  }

                  final setup = bike.setups[index];
                  return SetupCard(
                    setup: setup,
                    bike: bike, // NEU: Bike muss jetzt mit übergeben werden!
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetupDetailScreen(
                            bikeId: bike.id, 
                            setupId: setup.id,
                          ),
                        ),
                      );
                    },
                    onLongPress: () => _showSetupOptions(context, bike, setup, lang),
                    onFavoriteToggle: () {
                      context.read<BikeProvider>().toggleSetupFavorite(bike.id, setup.id);
                    },
                  );
                },
                childCount: bike.setups.length + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}