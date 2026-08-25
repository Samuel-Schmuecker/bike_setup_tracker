// lib/screens/bike_detail/setup_configurator_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../providers/language_provider.dart'; // NEU
import '../../utils/translations.dart';          // NEU
import '../../models/bike_parameters.dart';
import 'add_setup_screen.dart';

class SetupConfiguratorScreen extends StatefulWidget {
  final String bikeId;
  final bool isEditing; 

  const SetupConfiguratorScreen({
    Key? key, 
    required this.bikeId, 
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<SetupConfiguratorScreen> createState() => _SetupConfiguratorScreenState();
}

class _SetupConfiguratorScreenState extends State<SetupConfiguratorScreen> {
  bool _forkPsi = true, _forkOtt = false, _forkHsc = false, _forkLsc = true;
  bool _forkHsr = false, _forkLsr = true, _forkTokens = false, _forkHbo = false;
  bool _shockIsCoil = false;
  bool _shockPsi = true, _shockTokens = false, _shockRate = false, _shockPreload = false;
  bool _shockHsc = false, _shockLsc = true, _shockHsr = false, _shockLsr = true, _shockHbo = false;
  bool _tires = true;

  @override
  void initState() {
    super.initState();
    final bike = context.read<BikeProvider>().bikes.firstWhere((b) => b.id == widget.bikeId);
    final p = bike.availableParameters;
    
    if (p != null) {
      _forkPsi = p.forkPsi; _forkOtt = p.forkOtt; _forkHsc = p.forkHsc; _forkLsc = p.forkLsc;
      _forkHsr = p.forkHsr; _forkLsr = p.forkLsr; _forkTokens = p.forkTokens; _forkHbo = p.forkHbo;
      _shockIsCoil = p.shockIsCoil;
      _shockPsi = p.shockPsi; _shockTokens = p.shockTokens; _shockRate = p.shockRate; _shockPreload = p.shockPreload;
      _shockHsc = p.shockHsc; _shockLsc = p.shockLsc; _shockHsr = p.shockHsr; _shockLsr = p.shockLsr; _shockHbo = p.shockHbo;
      _tires = p.tires;
    }
  }

  void _saveAndContinue() {
    final params = BikeParameters(
      forkPsi: _forkPsi, forkOtt: _forkOtt, forkHsc: _forkHsc, forkLsc: _forkLsc,
      forkHsr: _forkHsr, forkLsr: _forkLsr, forkTokens: _forkTokens, forkHbo: _forkHbo,
      shockIsCoil: _shockIsCoil,
      shockPsi: _shockPsi, shockTokens: _shockTokens, shockRate: _shockRate, shockPreload: _shockPreload,
      shockHsc: _shockHsc, shockLsc: _shockLsc, shockHsr: _shockHsr, shockLsr: _shockLsr, shockHbo: _shockHbo,
      tires: _tires,
    );

    context.read<BikeProvider>().updateBikeParameters(widget.bikeId, params);

    if (widget.isEditing) {
      Navigator.pop(context); 
    } else {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => AddSetupScreen(bikeId: widget.bikeId))
      );
    }
  }

  Widget buildHeader(String title) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sprache aus dem Provider holen
    final lang = context.watch<LanguageProvider>().currentLanguage;

    return Scaffold(
      appBar: AppBar(title: Text(Translations.get(lang, 'configSuspension'))),
      body: ListView(
        children: [
          buildHeader(Translations.get(lang, 'forkSettings')),
          SwitchListTile(title: Text(Translations.get(lang, 'mainAir')), value: _forkPsi, onChanged: (v) => setState(() => _forkPsi = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'ottNeg')), value: _forkOtt, onChanged: (v) => setState(() => _forkOtt = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'hsc')), value: _forkHsc, onChanged: (v) => setState(() => _forkHsc = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'lsc')), value: _forkLsc, onChanged: (v) => setState(() => _forkLsc = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'hsr')), value: _forkHsr, onChanged: (v) => setState(() => _forkHsr = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'lsr')), value: _forkLsr, onChanged: (v) => setState(() => _forkLsr = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'tokens')), value: _forkTokens, onChanged: (v) => setState(() => _forkTokens = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'hbo')), value: _forkHbo, onChanged: (v) => setState(() => _forkHbo = v)),

          buildHeader(Translations.get(lang, 'shockType')),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(Translations.get(lang, 'airShock'))),
                ButtonSegment(value: true, label: Text(Translations.get(lang, 'coilShock'))),
              ],
              selected: {_shockIsCoil},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() => _shockIsCoil = newSelection.first);
              },
            ),
          ),

          buildHeader(Translations.get(lang, 'shockSettings')),
          if (!_shockIsCoil) ...[
            SwitchListTile(title: Text(Translations.get(lang, 'shockAir')), value: _shockPsi, onChanged: (v) => setState(() => _shockPsi = v)),
            SwitchListTile(title: Text(Translations.get(lang, 'tokens')), value: _shockTokens, onChanged: (v) => setState(() => _shockTokens = v)),
          ] else ...[
            SwitchListTile(title: Text(Translations.get(lang, 'springRate')), value: _shockRate, onChanged: (v) => setState(() => _shockRate = v)),
            SwitchListTile(title: Text(Translations.get(lang, 'preload')), value: _shockPreload, onChanged: (v) => setState(() => _shockPreload = v)),
          ],
          SwitchListTile(title: Text(Translations.get(lang, 'hsc')), value: _shockHsc, onChanged: (v) => setState(() => _shockHsc = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'lsc')), value: _shockLsc, onChanged: (v) => setState(() => _shockLsc = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'hsr')), value: _shockHsr, onChanged: (v) => setState(() => _shockHsr = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'lsr')), value: _shockLsr, onChanged: (v) => setState(() => _shockLsr = v)),
          SwitchListTile(title: Text(Translations.get(lang, 'hbo')), value: _shockHbo, onChanged: (v) => setState(() => _shockHbo = v)),

          buildHeader(Translations.get(lang, 'tireSettings')),
          SwitchListTile(title: Text(Translations.get(lang, 'trackTires')), value: _tires, onChanged: (v) => setState(() => _tires = v)),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: FilledButton(
              onPressed: _saveAndContinue, 
              child: Text(widget.isEditing ? Translations.get(lang, 'saveChanges') : Translations.get(lang, 'saveConfig'))
            ),
          ),
        ],
      ),
    );
  }
}