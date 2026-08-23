// lib/screens/add_bike/preset_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../models/bike.dart';
import '../../data/bike_presets.dart';

class PresetListScreen extends StatefulWidget {
  const PresetListScreen({Key? key}) : super(key: key);

  @override
  State<PresetListScreen> createState() => _PresetListScreenState();
}

class _PresetListScreenState extends State<PresetListScreen> {
  String _searchQuery = '';

  void _addPresetBike(Bike preset) {
    // 1. Hole die spezifischen Parameter für dieses Bike aus der Map
    final params = presetBikeParameters[preset.id];

    // 2. Erstelle ein NEUES Bike-Objekt mit einer einzigartigen ID
    final newBike = Bike(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // WICHTIG: Neue ID!
      brand: preset.brand,
      model: preset.model,
      category: preset.category,
      travelFront: preset.travelFront,
      travelRear: preset.travelRear,
      imagePath: null, // Der Nutzer kann später selbst ein Bild hinzufügen
      availableParameters: params,
      setups: [], // Startet ohne Setups
    );

    // 3. Im Provider speichern
    context.read<BikeProvider>().addBike(newBike);

    // 4. Zurück zum HomeScreen
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${preset.brand} ${preset.model} wurde hinzugefügt!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Filterlogik für die Suche
    final filteredPresets = presetBikes.where((bike) {
      final query = _searchQuery.toLowerCase();
      return bike.brand.toLowerCase().contains(query) || 
             bike.model.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike aus Datenbank wählen'),
      ),
      body: Column(
        children: [
          // Suchleiste
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Nach Marke oder Modell suchen...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          
          // Liste der Vorlagen
          Expanded(
            child: ListView.builder(
              itemCount: filteredPresets.length,
              itemBuilder: (context, index) {
                final preset = filteredPresets[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.directions_bike),
                  ),
                  title: Text('${preset.brand} ${preset.model}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${preset.category} • ${preset.travelFront}V / ${preset.travelRear}H mm'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => _addPresetBike(preset),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}