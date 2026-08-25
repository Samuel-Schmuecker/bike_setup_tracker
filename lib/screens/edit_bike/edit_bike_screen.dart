// lib/screens/edit_bike/edit_bike_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/bike_provider.dart';
import '../../providers/language_provider.dart'; // NEU
import '../../utils/translations.dart';          // NEU
import '../../models/bike.dart';
import '../../utils/image_helper.dart';

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
    _brand = widget.bike.brand;
    _model = widget.bike.model;
    
    _category = _categories.contains(widget.bike.category) 
        ? widget.bike.category 
        : _categories.first;
        
    _travelFront = widget.bike.travelFront;
    _travelRear = widget.bike.travelRear;
    _selectedImagePath = widget.bike.imagePath;
  }

  // --- NEUE HYBRID-BILD-LOGIK (Wie im AddBikeScreen) ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() {
          _selectedImagePath = 'data:image/jpeg;base64,$base64Image';
        });
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImagePath = '${directory.path}/$fileName';
        await File(pickedFile.path).copy(savedImagePath);
        setState(() {
          _selectedImagePath = savedImagePath;
        });
      }
    }
  }

  void _saveBike() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final updatedBike = Bike(
        id: widget.bike.id, 
        brand: _brand.trim(),
        model: _model.trim(),
        category: _category,
        travelFront: _travelFront,
        travelRear: _travelRear,
        imagePath: _selectedImagePath,
        availableParameters: widget.bike.availableParameters, // Behalte die Specs bei!
        setups: widget.bike.setups, // Behalte alle Setups bei!
      );

      context.read<BikeProvider>().updateBike(updatedBike);
      Navigator.pop(context);
    }
  }

  void _confirmDelete(String lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Translations.get(lang, 'deleteBikeTitle')),
        // Nutzt den übersetzten Text und bindet den Namen des Bikes dynamisch ein
        content: Text('${Translations.get(lang, 'deleteBikeBody')}\n\n"${widget.bike.brand} ${widget.bike.model}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text(Translations.get(lang, 'cancel')),
          ),
          TextButton(
            onPressed: () {
              context.read<BikeProvider>().deleteBike(widget.bike.id);
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            child: Text(
              Translations.get(lang, 'delete'), 
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>().currentLanguage;

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.get(lang, 'editBike')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(lang),
            tooltip: Translations.get(lang, 'deleteBike'),
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
                
                // --- BILD ---
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16.0),
                      border: _selectedImagePath == null 
                          ? Border.all(color: colorScheme.outlineVariant.withOpacity(0.5))
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32, color: colorScheme.primary),
                              const SizedBox(height: 8),
                              Text(Translations.get(lang, 'changePhoto'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            ],
                          )
                        : ImageHelper.buildImage(_selectedImagePath!),
                  ),
                ),
                const SizedBox(height: 24),

                // --- MARKE & MODELL ---
                TextFormField(
                  initialValue: _brand, 
                  decoration: InputDecoration(labelText: Translations.get(lang, 'brand'), border: const OutlineInputBorder()),
                  validator: (val) => (val == null || val.trim().isEmpty) ? Translations.get(lang, 'required') : null,
                  onSaved: (val) => _brand = val!,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  initialValue: _model,
                  decoration: InputDecoration(labelText: Translations.get(lang, 'modelEdit'), hintText: Translations.get(lang, 'modelHint'), border: const OutlineInputBorder()),
                  validator: (val) => (val == null || val.trim().isEmpty) ? Translations.get(lang, 'required') : null,
                  onSaved: (val) => _model = val!,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                
                // --- KATEGORIE ---
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: InputDecoration(labelText: Translations.get(lang, 'category'), border: const OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) { if (val != null) setState(() => _category = val); },
                ),
                const SizedBox(height: 16),
                
                // --- FEDERWEG ---
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _travelFront.toString(),
                        decoration: InputDecoration(labelText: Translations.get(lang, 'travelFront'), border: const OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null) ? Translations.get(lang, 'error') : null,
                        onSaved: (val) => _travelFront = int.parse(val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: _travelRear.toString(),
                        decoration: InputDecoration(labelText: Translations.get(lang, 'travelRear'), border: const OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null) ? Translations.get(lang, 'error') : null,
                        onSaved: (val) => _travelRear = int.parse(val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // --- BUTTONS ---
                FilledButton.icon(
                  onPressed: _saveBike,
                  icon: const Icon(Icons.save),
                  label: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(Translations.get(lang, 'saveChanges'), style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () => _confirmDelete(lang),
                  icon: const Icon(Icons.delete),
                  label: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(Translations.get(lang, 'deleteBike'), style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}