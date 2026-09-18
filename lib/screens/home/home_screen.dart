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
import '../../services/onboarding_tour_service.dart';
import '../bike_detail/bike_detail_screen.dart';
import '../../utils/app_route_observer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  bool _backupReminderShowing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    _checkBackupReminder();
  }

  Future<void> _checkBackupReminder() async {
    if (!mounted ||
        _tourPreparing ||
        _backupReminderShowing ||
        ModalRoute.of(context)?.isCurrent != true)
      return;
    _backupReminderShowing = true;
    try {
      final bikes = context.read<BikeProvider>();
      await bikes.ready;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted ||
          _tourPreparing ||
          ModalRoute.of(context)?.isCurrent != true ||
          prefs.getBool('hasCreatedOwnBike') != true ||
          prefs.getBool('hasSeenBackupReminder') == true ||
          !bikes.bikes.any((bike) => bike.id != '3'))
        return;
      final german = context.read<LanguageProvider>().currentLanguage == 'de';
      final openBackup = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.cloud_outlined),
          title: Text(
            german ? 'Datensicherung nicht vergessen' : 'Remember your backup',
          ),
          content: Text(
            german
                ? 'Dein erstes Bike ist angelegt! Prüfe unter „Konto & Datensicherung“ deine Sicherung und verknüpfe dein Konto für die Wiederherstellung nach Geräteverlust.'
                : 'Your first bike is ready! Check Account & backup and link your account so you can restore your data if you lose your device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(german ? 'Später' : 'Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                german ? 'Konto & Datensicherung' : 'Account & backup',
              ),
            ),
          ],
        ),
      );
      await prefs.setBool('hasSeenBackupReminder', true);
      if (mounted && openBackup == true) {
        await Navigator.of(
          context,
        ).push<void>(MaterialPageRoute(builder: (_) => const AccountScreen()));
      }
    } finally {
      _backupReminderShowing = false;
    }
  }

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _orderingBikes = false;
  final _tour = OnboardingTourService();
  final _demoBikeKey = GlobalKey(debugLabel: 'tour-bike');
  final _bikeScrollController = ScrollController();
  bool _tourPreparing = false;

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
    appRouteObserver.unsubscribe(this);
    _tour.cancelFor(context);
    _searchController.dispose();
    _bikeScrollController.dispose();
    super.dispose();
  }

  // --- NEU: ONBOARDING LOGIK ---
  Future<void> _checkFirstStart() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      if (mounted) _showOnboardingDialog(isFirstStart: true);
    } else if (await _tour.isFirstStart()) {
      if (mounted) await _startTour();
    } else {
      await _checkBackupReminder();
    }
  }

  Future<void> _startTour() => _tour.run(() async {
    try {
      final bikes = context.read<BikeProvider>();
      await bikes.ensureOnboardingDemo();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _searchController.clear();
        _searchQuery = '';
        _orderingBikes = false;
        _tourPreparing = true;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      if (_bikeScrollController.hasClients) _bikeScrollController.jumpTo(0);
      final german = context.read<LanguageProvider>().currentLanguage == 'de';
      final next = await _tour.showStep(
        context: context,
        target: _demoBikeKey,
        step: 1,
        event: 'bikeMenu',
        german: german,
        title: german ? 'Bikes verwalten' : 'Manage bikes',
        onNext: () =>
            _tourBikeMenu(bikes.bikes.firstWhere((bike) => bike.id == '3')),
        description: german
            ? '**Lange drücken** → Bike-Menü. Danach schließen. Wir üben am Demo-Bike.'
            : '**Press and hold** → bike menu. Then close it. Practice on the demo bike.',
      );
      if (!mounted || !next) return;
      setState(() => _orderingBikes = false);
      if (!await _tour.showStep(
        context: context,
        target: _demoBikeKey,
        step: 2,
        event: 'openBike',
        german: german,
        title: german ? 'Bike öffnen' : 'Open bike',
        description: german
            ? '**Bike antippen** → Setups öffnen.'
            : '**Tap the bike** → open its setups.',
      ))
        return;
      if (!mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => BikeDetailScreen(bikeId: '3', onboardingTour: _tour),
        ),
      );
      if (mounted && _tour.createOwnBikeRequested) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => const AddBikeScreen(configureAfterSave: true),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LanguageProvider>().currentLanguage == 'de'
                  ? 'Die Tour konnte nicht gestartet werden. Bitte erneut versuchen.'
                  : 'Could not start the tour. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _tourPreparing = false);
      if (mounted) await _checkBackupReminder();
    }
  });

  Future<void> _tourBikeMenu(Bike bike) async {
    _tour.suspend();
    await _showBikeMenu(bike, touring: true);
    if (mounted) _tour.complete('bikeMenu');
  }

  void _showOnboardingDialog({bool isFirstStart = false}) {
    showDialog(
      context: context,
      // Verhindert, dass der User beim ersten Start aus Versehen daneben klickt
      barrierDismissible: !isFirstStart,
      builder: (ctx) => Consumer<LanguageProvider>(
        builder: (_, language, __) {
          final lang = language.currentLanguage;
          return PopScope(
            canPop: !isFirstStart,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                Translations.get(lang, 'welcomeTitle'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        tooltip: 'Sprache / Language',
                        initialValue: lang,
                        onSelected: language.setLanguage,
                        itemBuilder: (_) => [
                          for (final code
                              in Translations.supportedLanguageCodes)
                            CheckedPopupMenuItem(
                              value: code,
                              checked: code == lang,
                              child: Text(code == 'de' ? 'Deutsch' : 'English'),
                            ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.language,
                                size: 16,
                                color: Theme.of(
                                  ctx,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                lang == 'de' ? 'Deutsch' : 'English',
                                style: Theme.of(ctx).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        ctx,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              Icon(
                                Icons.expand_more,
                                size: 16,
                                color: Theme.of(
                                  ctx,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Translations.get(lang, 'welcomeText1'),
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lang == 'de'
                          ? 'Nach „Los geht’s“ wird ein Gastkonto erstellt und deine Daten werden automatisch in einer privaten Cloud gespeichert. Verknüpfe unter „Konto & Datensicherung“ Google für die Wiederherstellung nach Geräteverlust.'
                          : 'After you tap “Let’s go”, a guest account is created and your data is saved automatically in a private cloud. Link Google under Account & backup to restore access after losing your device.',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                PrivacyPolicyLink(german: lang == 'de'),
                FilledButton(
                  onPressed: () async {
                    if (isFirstStart) {
                      // Status dauerhaft speichern!
                      final prefs = await SharedPreferences.getInstance();
                      if (!await prefs.setBool('is_first_start', true)) return;
                      final saved = await prefs.setBool(
                        'hasSeenOnboarding',
                        true,
                      );
                      if (!saved || !mounted) return;
                      context.read<CloudProvider>().startSync();
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (isFirstStart && mounted) await _startTour();
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
        },
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
                      _startTour();
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

  Future<void> _showBikeMenu(Bike bike, {bool touring = false}) async {
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
              onTap: touring
                  ? null
                  : () => Navigator.pop(sheetContext, 'delete'),
            ),
            if (touring) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  lang == 'de'
                      ? 'Bearbeiten öffnet auch den Namen. Löschen erklären wir nur; es ist während der Tour deaktiviert.'
                      : 'Edit also lets you rename the bike. Deletion is disabled during the tour.',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(lang == 'de' ? 'Zurück zur Tour' : 'Back to tour'),
              ),
            ],
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
    await Navigator.push(
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
    if (_tourPreparing) {
      final demoIndex = filteredBikes.indexWhere((bike) => bike.id == '3');
      if (demoIndex > 0) {
        filteredBikes.insert(0, filteredBikes.removeAt(demoIndex));
      }
    }

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
                    scrollController: _bikeScrollController,
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
                        key: filteredBikes[index].id == '3'
                            ? _demoBikeKey
                            : null,
                        bike: filteredBikes[index],
                        onTap: _tourPreparing && filteredBikes[index].id == '3'
                            ? () => _tour.complete('openBike')
                            : null,
                        onLongPress: () => _tour.waitingFor('bikeMenu')
                            ? _tourBikeMenu(filteredBikes[index])
                            : _showBikeMenu(filteredBikes[index]),
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
