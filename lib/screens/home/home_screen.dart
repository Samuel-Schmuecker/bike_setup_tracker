// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEU: Für Onboarding Status
import '../../providers/bike_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translations.dart';
import '../../widgets/bike_card.dart';
import '../../widgets/add_bike_card.dart';
import '../../widgets/privacy_policy_link.dart';
import '../add_bike/add_bike_screen.dart';
import '../settings/appearance_screen.dart';
import '../settings/account_screen.dart';
import '../../cloud/cloud_provider.dart';
import '../../models/bike.dart';
import '../edit_bike/edit_bike_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _orderingBikes = false;

  @override
  void initState() {
    super.initState();
    // Prüft beim Start, ob das Onboarding schon gezeigt wurde
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstStart();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- NEU: ONBOARDING LOGIK ---
  Future<void> _checkFirstStart() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      if (mounted) _showOnboardingDialog(isFirstStart: true);
    }
  }

  void _showOnboardingDialog({bool isFirstStart = false}) {
    final lang = context.read<LanguageProvider>().currentLanguage;

    showDialog(
      context: context,
      // Verhindert, dass der User beim ersten Start aus Versehen daneben klickt
      barrierDismissible: !isFirstStart,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          Translations.get(lang, 'welcomeTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translations.get(lang, 'welcomeText1'),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'de'
                    ? 'Deine Daten werden automatisch in einer privaten Cloud gespeichert. Verknüpfe unter „Konto & Datensicherung“ Google für die Wiederherstellung nach Geräteverlust.'
                    : 'Your data is saved automatically in a private cloud. Link Google under Account & backup to restore access after losing your device.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Translations.get(lang, 'welcomeText2'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PrivacyPolicyLink(german: lang == 'de'),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (isFirstStart) {
                // Status dauerhaft speichern!
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasSeenOnboarding', true);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                Translations.get(lang, 'gotIt'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onAddBikeTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBikeScreen()),
    );
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          final lang = languageProvider.currentLanguage;
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Translations.get(lang, 'settings'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: Text(
                      lang == 'de'
                          ? 'Konto & Datensicherung'
                          : 'Account & backup',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        this.context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AccountScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(Translations.get(lang, 'language')),
                    trailing: DropdownButton<String>(
                      value: lang,
                      items: Translations.supportedLanguageCodes
                          .map(
                            (code) => DropdownMenuItem(
                              value: code,
                              child: Text(code == 'de' ? 'Deutsch' : 'English'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) languageProvider.setLanguage(value);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(Translations.get(lang, 'appearance')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        this.context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AppearanceScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(Translations.get(lang, 'tutorialInfo')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showOnboardingDialog();
                    },
                  ),
                  PrivacyPolicyLink(german: lang == 'de'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBikeMenu(Bike bike) async {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${bike.brand} ${bike.model}',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(Translations.get(lang, 'editBike')),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.swap_vert),
              title: Text(Translations.get(lang, 'orderBikes')),
              onTap: () => Navigator.pop(sheetContext, 'order'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              iconColor: Theme.of(sheetContext).colorScheme.error,
              textColor: Theme.of(sheetContext).colorScheme.error,
              title: Text(Translations.get(lang, 'deleteBike')),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(Translations.get(lang, 'deleteBikeTitle')),
          content: Text(
            '${Translations.get(lang, 'deleteBikeBody')}\n\n"${bike.brand} ${bike.model}"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(Translations.get(lang, 'cancel')),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(Translations.get(lang, 'delete')),
            ),
          ],
        ),
      );
      if (mounted && confirmed == true) {
        context.read<BikeProvider>().deleteBike(bike.id);
      }
      return;
    }
    if (action == 'order') {
      FocusScope.of(context).unfocus();
      setState(() {
        _searchController.clear();
        _searchQuery = '';
        _orderingBikes = true;
      });
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => EditBikeScreen(bike: bike)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cloud = context.watch<CloudProvider?>();
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final allBikes = context.watch<BikeProvider>().bikes;

    final filteredBikes = allBikes.where((bike) {
      final query = _searchQuery.toLowerCase();
      return bike.brand.toLowerCase().contains(query) ||
          bike.model.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        actionsIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(Translations.get(lang, 'myBikes')),
        actions: [
          if (_orderingBikes)
            TextButton(
              onPressed: () => setState(() => _orderingBikes = false),
              child: Text(Translations.get(lang, 'finishOrdering')),
            )
          else
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: Translations.get(lang, 'settings'),
              onPressed: _showSettings,
            ),
        ],
      ),
      body: Column(
        children: [
          if (cloud != null &&
              (cloud.status == 'conflict' ||
                  cloud.status == 'local' ||
                  cloud.status == 'session'))
            MaterialBanner(
              content: Text(
                lang == 'de'
                    ? 'Die Datensicherung benötigt deine Aufmerksamkeit.'
                    : 'Your backup needs attention.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountScreen(),
                    ),
                  ),
                  child: Text(lang == 'de' ? 'Anzeigen' : 'View'),
                ),
              ],
            ),
          if (_orderingBikes)
            Padding(
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
                      child: Text(Translations.get(lang, 'orderBikesHint')),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: Translations.get(lang, 'searchHint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          Expanded(
            child: filteredBikes.isEmpty && _searchQuery.isNotEmpty
                ? Center(child: Text(Translations.get(lang, 'noBikes')))
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: filteredBikes.length,
                    footer: _orderingBikes
                        ? null
                        : AddBikeCard(onTap: _onAddBikeTap),
                    onReorder: (oldIndex, newIndex) {
                      if (!_orderingBikes) return;
                      final ids = allBikes.map((bike) => bike.id).toList();
                      if (newIndex > oldIndex) newIndex--;
                      ids.insert(newIndex, ids.removeAt(oldIndex));
                      context.read<BikeProvider>().reorderBikes(ids);
                    },
                    proxyDecorator: (child, index, animation) => Material(
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                    itemBuilder: (context, index) {
                      final card = BikeCard(
                        bike: filteredBikes[index],
                        onLongPress: () => _showBikeMenu(filteredBikes[index]),
                      );
                      return Container(
                        key: ValueKey('bike-${filteredBikes[index].id}'),
                        child: !_orderingBikes
                            ? card
                            : ReorderableDelayedDragStartListener(
                                index: index,
                                child: Row(
                                  children: [
                                    Expanded(child: AbsorbPointer(child: card)),
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
                  ),
          ),
        ],
      ),
    );
  }
}
