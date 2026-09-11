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

class BikeDetailScreen extends StatefulWidget {
  final String bikeId;

  const BikeDetailScreen({super.key, required this.bikeId});

  @override
  State<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  String get bikeId => widget.bikeId;
  List<TrailSetup>? _draftSetups;
  bool get _editing => _draftSetups != null;

  void _finishOrdering() {
    context.read<BikeProvider>().reorderSetups(
      bikeId,
      _draftSetups!.map((setup) => setup.id).toList(),
    );
    setState(() => _draftSetups = null);
  }

  void _onAddSetupTap(BuildContext context, Bike bike) {
    if (bike.availableParameters == null) {
      // Fall A: Noch nie konfiguriert -> Zeige Configurator
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetupConfiguratorScreen(bikeId: bike.id),
        ),
      );
    } else {
      // Fall B: Bereits konfiguriert -> Direkt zum Formular
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddSetupScreen(bikeId: bike.id),
        ),
      );
    }
  }

  // 1. Zeigt das BottomSheet mit den 3 Optionen an
  void _showSetupOptions(
    BuildContext context,
    Bike bike,
    TrailSetup setup,
    String lang,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  setup.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  Translations.get(lang, 'delete'),
                  style: TextStyle(color: Colors.redAccent),
                ),
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
  void _showRenameDialog(
    BuildContext context,
    Bike bike,
    TrailSetup setup,
    String lang,
  ) {
    final nameController = TextEditingController(text: setup.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translations.get(lang, 'rename')),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: Translations.get(lang, 'newName'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Translations.get(lang, 'cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                // Wir nutzen die bestehende updateSetup Methode
                final updatedSetup = setup.copyWith(
                  name: nameController.text.trim(),
                );
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
  void _showDeleteConfirmDialog(
    BuildContext context,
    Bike bike,
    TrailSetup setup,
    String lang,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translations.get(lang, 'deleteSetupTitle')),
        content: Text(
          '${Translations.get(lang, 'deleteSetupBody1')} "${setup.name}" ${Translations.get(lang, 'deleteSetupBody2')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Translations.get(lang, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              context.read<BikeProvider>().deleteSetup(bike.id, setup.id);
              Navigator.pop(ctx);
            },
            child: Text(
              Translations.get(lang, 'delete'),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
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
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
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

    final setups = _draftSetups ?? bike.orderedSetups;
    return PopScope(
      canPop: !_editing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _editing) _finishOrdering();
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240.0,
              pinned: true,
              centerTitle: false,
              actions: [
                if (_editing) ...[
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: Translations.get(lang, 'cancel'),
                    onPressed: () => setState(() => _draftSetups = null),
                  ),
                  TextButton(
                    onPressed: _finishOrdering,
                    child: Text(Translations.get(lang, 'finishFieldOrder')),
                  ),
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: Translations.get(lang, 'orderSetups'),
                    onPressed: () => setState(
                      () => _draftSetups = List.of(bike.orderedSetups),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _onAddSetupTap(context, bike),
                    tooltip: Translations.get(lang, 'newSetup'),
                  ),
                ],
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
                        buildTravelChip(
                          'assets/icons/fork.svg',
                          '${bike.travelFront} mm ${Translations.get(lang, 'front')}',
                        ),
                        buildTravelChip(
                          'assets/icons/shock.svg',
                          '${bike.travelRear} mm ${Translations.get(lang, 'rear')}',
                        ),
                      ],
                    ),
                  ],
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Hintergrundbild (NEU: Greift den DisplayPath ab)
                    ImageHelper.buildImage(
                      ImageHelper.getDisplayImagePath(
                        bike.imagePath,
                        bike.category,
                      ),
                    ),

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

            if (_editing)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            Translations.get(lang, 'favoritesStayFirst'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              sliver: SliverReorderableList(
                itemCount: setups.length,
                itemBuilder: (context, index) {
                  final setup = setups[index];
                  final card = SetupCard(
                    setup: setup,
                    bike: bike,
                    onTap: () {
                      if (_editing) return;
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
                    onLongPress: () {
                      if (!_editing) {
                        _showSetupOptions(context, bike, setup, lang);
                      }
                    },
                    onFavoriteToggle: () {
                      if (!_editing) {
                        context.read<BikeProvider>().toggleSetupFavorite(
                          bike.id,
                          setup.id,
                        );
                      }
                    },
                  );
                  return Container(
                    key: ValueKey('setup-${setup.id}'),
                    child: !_editing
                        ? card
                        : ReorderableDelayedDragStartListener(
                            index: index,
                            child: Row(
                              children: [
                                Expanded(child: IgnorePointer(child: card)),
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Icon(
                                    Icons.drag_indicator,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  if (!_editing) return;
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final setup = _draftSetups!.removeAt(oldIndex);
                    final favoriteCount = _draftSetups!
                        .where((s) => s.isFavorite)
                        .length;
                    final target = setup.isFavorite
                        ? newIndex.clamp(0, favoriteCount)
                        : newIndex.clamp(favoriteCount, _draftSetups!.length);
                    _draftSetups!.insert(target, setup);
                  });
                },
                proxyDecorator: (child, index, animation) => Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                ),
              ),
            ),
            if (!_editing)
              SliverToBoxAdapter(
                child: AddSetupCard(onTap: () => _onAddSetupTap(context, bike)),
              ),
          ],
        ),
      ),
    );
  }
}
