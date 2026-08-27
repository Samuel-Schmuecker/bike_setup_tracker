// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEU: Für Onboarding Status
import '../../providers/bike_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translations.dart';
import '../../widgets/bike_card.dart';
import '../../widgets/add_bike_card.dart';
import '../add_bike/add_bike_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.get(lang, 'welcomeText1'),
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Translations.get(lang, 'welcomeText2'),
                      style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(Translations.get(lang, 'gotIt'), style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _onAddBikeTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBikeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;
    final allBikes = context.watch<BikeProvider>().bikes;

    final filteredBikes = allBikes.where((bike) {
      final query = _searchQuery.toLowerCase();
      return bike.brand.toLowerCase().contains(query) || bike.model.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.get(lang, 'myBikes')),
        actions: [
          // NEU: Info-Button, um das Tutorial manuell aufzurufen
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tutorial / Info',
            onPressed: () => _showOnboardingDialog(isFirstStart: false),
          ),
          // SPRACH-UMSCHALTER
          TextButton(
            onPressed: () {
              final newLang = lang == 'de' ? 'en' : 'de';
              context.read<LanguageProvider>().setLanguage(newLang);
            },
            child: Text(
              lang.toUpperCase(),
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAddBikeTap,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        })
                    : null,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.0), borderSide: BorderSide.none),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: filteredBikes.isEmpty && _searchQuery.isNotEmpty
                ? Center(child: Text(Translations.get(lang, 'noBikes')))
                : ListView.builder(
                    itemCount: filteredBikes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filteredBikes.length) {
                        return AddBikeCard(onTap: _onAddBikeTap);
                      }
                      return BikeCard(bike: filteredBikes[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}