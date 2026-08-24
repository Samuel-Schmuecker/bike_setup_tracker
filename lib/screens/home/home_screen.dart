// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../widgets/bike_card.dart';
import '../../widgets/add_bike_card.dart';
import '../add_bike/add_bike_screen.dart'; // NEU: Import hinzugefügt
import '../edit_bike/edit_bike_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // NEU: Navigation zum AddBikeScreen
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
    final allBikes = context.watch<BikeProvider>().bikes;

    final filteredBikes = allBikes.where((bike) {
      final query = _searchQuery.toLowerCase();
      final brandMatch = bike.brand.toLowerCase().contains(query);
      final modelMatch = bike.model.toLowerCase().contains(query);
      return brandMatch || modelMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Bikes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAddBikeTap,
            tooltip: 'Neues Bike',
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
                hintText: 'Nach Marke oder Modell suchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredBikes.length + 1,
              itemBuilder: (context, index) {
                if (index == filteredBikes.length) {
                  return AddBikeCard(onTap: _onAddBikeTap);
                }
                final bike = filteredBikes[index];
                return BikeCard(
                  bike: bike,
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditBikeScreen(bike: bike),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}