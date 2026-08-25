// lib/screens/add_bike/add_bike_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/bike_provider.dart';
import '../../providers/language_provider.dart'; 
import '../../utils/translations.dart';  
import '../../models/bike.dart';
import '../../models/bike_parameters.dart';
import '../../utils/image_helper.dart';
import '../../data/bike_presets.dart';

class AddBikeScreen extends StatefulWidget {
  const AddBikeScreen({Key? key}) : super(key: key);

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final _formKey = GlobalKey<FormState>();

  String _modelName = ''; 

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _travelFrontController = TextEditingController();
  final TextEditingController _travelRearController = TextEditingController();
  
  String _category = 'Enduro';
  String? _selectedImagePath;
  BikeParameters? _selectedParams;

  final List<String> _categories = [
    'Enduro', 'Trail', 'Downhill', 'All Mountain', 
    'Gravel', 'Cross Country', 'E-Bike'
  ];

  @override
  void dispose() {
    _brandController.dispose();
    _travelFrontController.dispose();
    _travelRearController.dispose();
    super.dispose();
  }

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

      final newBike = Bike(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brand: _brandController.text.trim(),
        model: _modelName.trim(), 
        category: _category,
        travelFront: int.tryParse(_travelFrontController.text) ?? 0,
        travelRear: int.tryParse(_travelRearController.text) ?? 0,
        imagePath: _selectedImagePath,
        availableParameters: _selectedParams, 
      );

      context.read<BikeProvider>().addBike(newBike);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>().currentLanguage;

    return Scaffold(
      // FIX 1: AppBar Titel übersetzt
      appBar: AppBar(title: Text(Translations.get(lang, 'newBike'))),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- BILD-AUSWAHL ---
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
                              Text(Translations.get(lang, 'addPhoto'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
                            ],
                          )
                        : ImageHelper.buildImage(_selectedImagePath!),
                  ),
                ),
                const SizedBox(height: 32),

                // --- MODELL (SMART AUTOCOMPLETE) ---
                Autocomplete<Bike>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Bike>.empty();
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return presetBikes.where((bike) => 
                      bike.model.toLowerCase().contains(query) || 
                      bike.brand.toLowerCase().contains(query)
                    );
                  },
                  displayStringForOption: (Bike option) => option.model,
                  onSelected: (Bike selection) {
                    setState(() {
                      _brandController.text = selection.brand; 
                      _travelFrontController.text = selection.travelFront.toString(); 
                      _travelRearController.text = selection.travelRear.toString();
                      if (_categories.contains(selection.category)) {
                        _category = selection.category; 
                      }
                      _selectedParams = presetBikeParameters[selection.id]; 
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        // FIX 2: Korrekten Suffix-Key für das Ausrufezeichen verwendet
                        content: Text('${Translations.get(lang, 'specsApplied')} ${selection.brand} ${selection.model} ${Translations.get(lang, 'specsAppliedSuffix')}'),
                        backgroundColor: Colors.teal,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    FocusScope.of(context).unfocus(); 
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.next, 
                      decoration: InputDecoration(
                        labelText: Translations.get(lang, 'model'), 
                        hintText: Translations.get(lang, 'modelHint'),
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.auto_awesome, size: 18),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? Translations.get(lang, 'required') : null,
                      onSaved: (val) => _modelName = val ?? '',
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8.0,
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceContainerHighest,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 250, 
                            maxWidth: MediaQuery.of(context).size.width - 32 
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(Icons.directions_bike, size: 20),
                                title: Text('${option.brand} ${option.model}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${option.travelFront}V / ${option.travelRear}H mm'),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // --- MARKE ---
                TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(labelText: Translations.get(lang, 'brand'), border: const OutlineInputBorder()),
                  validator: (val) => (val == null || val.trim().isEmpty) ? Translations.get(lang, 'required') : null,
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
                        controller: _travelFrontController,
                        decoration: InputDecoration(labelText: Translations.get(lang, 'travelFront'), border: const OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        // FIX 3: Übersetzung für 'Fehler' eingefügt
                        validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null) ? Translations.get(lang, 'error') : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _travelRearController,
                        decoration: InputDecoration(labelText: Translations.get(lang, 'travelRear'), border: const OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: (val) => (val == null || val.isEmpty || int.tryParse(val) == null) ? Translations.get(lang, 'error') : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                FilledButton.icon(
                  onPressed: _saveBike,
                  icon: const Icon(Icons.save),
                  label: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(Translations.get(lang, 'saveBike'), style: const TextStyle(fontSize: 16)),
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