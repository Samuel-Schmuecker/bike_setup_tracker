// lib/screens/edit_bike/edit_bike_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/bike.dart';
import '../../providers/bike_provider.dart';

class EditBikeScreen extends StatefulWidget {
  final Bike bike;

  const EditBikeScreen({Key? key, required this.bike}) : super(key: key);

  @override
  State<EditBikeScreen> createState() => _EditBikeScreenState();
}

class _EditBikeScreenState extends State<EditBikeScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _brand;
  late String _model;
  late String _category;
  late int _travelFront;
  late int _travelRear;
  String? _selectedImagePath;

  final List<String> _categories = [
    'Enduro', 'Trail', 'Downhill', 'All Mountain', 
    'Gravel', 'Cross Country', 'E-Bike'
  ];

  @override
  void initState() {
    super.initState();
    // Mit den bestehenden Daten des Bikes befüllen
    _brand = widget.bike.brand;
    _model = widget.bike.model;
    
    // Fallback, falls mal eine Kategorie aus der DB kommt, die nicht in der Liste ist
    _category = _categories.contains(widget.bike.category) 
        ? widget.bike.category 
        : _categories.first;
        
    _travelFront = widget.bike.travelFront;
    _travelRear = widget.bike.travelRear;
    _selectedImagePath = widget.bike.imagePath;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    }
  }

  void _saveBike() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedBike = Bike(
        id: widget.bike.id, // ID bleibt gleich!
        brand: _brand.trim(),
        model: _model.trim(),
        category: _category,
        travelFront: _travelFront,
        travelRear: _travelRear,
        imagePath: _selectedImagePath,
        setups: widget.bike.setups, // Wichtig: Die Setups übernehmen!
      );

      context.read<BikeProvider>().updateBike(updatedBike);
      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bike löschen?'),
        content: Text('Möchtest du das Bike "${widget.bike.brand} ${widget.bike.model}" wirklich löschen? Alle Setups gehen verloren.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Dialog schließen
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              // Bike aus dem Provider löschen
              context.read<BikeProvider>().deleteBike(widget.bike.id);
              Navigator.pop(ctx); // Dialog schließen
              Navigator.pop(context); // Edit Screen schließen (zurück zur Liste)
            },
            child: const Text(
              'Löschen', 
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bike bearbeiten'),
        actions: [
          // Löschen-Icon oben rechts
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _confirmDelete,
            tooltip: 'Bike löschen',
          ),
        ],
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
                // Bildauswahl
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16.0),
                      border: _selectedImagePath == null 
                          ? Border.all(color: colorScheme.outlineVariant)
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32, color: colorScheme.primary),
                              const SizedBox(height: 8),
                              Text('Titelbild ändern', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            ],
                          )
                        : (kIsWeb
                            ? Image.network(_selectedImagePath!, fit: BoxFit.cover)
                            : Image.file(File(_selectedImagePath!), fit: BoxFit.cover)),
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  initialValue: _brand, // NEU: Initialer Wert
                  decoration: const InputDecoration(labelText: 'Marke', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Pflichtfeld' : null,
                  onSaved: (value) => _brand = value!,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: _model,
                  decoration: const InputDecoration(labelText: 'Modell', border: OutlineInputBorder()),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Pflichtfeld' : null,
                  onSaved: (value) => _model = value!,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Kategorie', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) { if (val != null) setState(() => _category = val); },
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _travelFront.toString(),
                        decoration: const InputDecoration(labelText: 'Federweg V (mm)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Fehler' : null,
                        onSaved: (value) => _travelFront = int.parse(value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _travelRear.toString(),
                        decoration: const InputDecoration(labelText: 'Federweg H (mm)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.isEmpty || int.tryParse(value) == null) ? 'Fehler' : null,
                        onSaved: (value) => _travelRear = int.parse(value!),
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
                    child: Text('Änderungen speichern', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Roter Delete-Button unten als Alternative/Zusatz zum AppBar-Icon
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete),
                  label: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Bike löschen', style: TextStyle(fontSize: 16)),
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