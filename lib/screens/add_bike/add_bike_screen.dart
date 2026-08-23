// lib/screens/add_bike/add_bike_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../providers/bike_provider.dart';
import 'dart:convert';
import '../../utils/image_helper.dart';

class AddBikeScreen extends StatefulWidget {
  const AddBikeScreen({super.key});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();

  String _brand = '';
  String _model = '';
  String _category = 'Enduro';
  int _travelFront = 0;
  int _travelRear = 0;
  
  String? _selectedImagePath;

  final List<String> _categories = [
    'Enduro', 'Trail', 'Downhill', 'All Mountain', 
    'Gravel', 'Cross Country', 'E-Bike'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      // WICHTIG FÜR WEB: Komprimierung, damit der LocalStorage nicht platzt!
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70, 
    );
    
    if (pickedFile != null) {
      // Bild als Bytes einlesen (funktioniert auf Web und Mobile)
      final bytes = await pickedFile.readAsBytes();
      // In Text (Base64) umwandeln
      final base64Image = base64Encode(bytes);
      
      setState(() {
        // Speichern mit Daten-Präfix
        _selectedImagePath = 'data:image/jpeg;base64,$base64Image';
      });
    }
  }

  void _saveBike() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newBike = Bike(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brand: _brand.trim(),
        model: _model.trim(),
        category: _category,
        travelFront: _travelFront,
        travelRear: _travelRear,
        imagePath: _selectedImagePath,
      );

      context.read<BikeProvider>().addBike(newBike);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neues Bike anlegen'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kompaktere Bildauswahl (Höhe 120)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16.0),
                      border: _selectedImagePath == null 
                          ? Border.all(color: colorScheme.outlineVariant)
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    //
                    child: _selectedImagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32, color: colorScheme.primary),
                              const SizedBox(height: 8),
                              Text('Titelbild hinzufügen', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            ],
                          )
                        : ImageHelper.buildImage(_selectedImagePath!),
                        //
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Marke (z. B. Santa Cruz)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Pflichtfeld' : null,
                  onSaved: (value) => _brand = value!,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Modell (z. B. Megatower)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Pflichtfeld' : null,
                  onSaved: (value) => _model = value!,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) { if (val != null) setState(() => _category = val); },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Federweg V (mm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Fehler' : null,
                        onSaved: (value) => _travelFront = int.parse(value!),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Federweg H (mm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Fehler' : null,
                        onSaved: (value) => _travelRear = int.parse(value!),
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                FilledButton.icon(
                  onPressed: _saveBike,
                  icon: const Icon(Icons.save),
                  label: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Speichern', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}