// lib/screens/bike_detail/setup_configurator_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../models/bike_parameters.dart';
import 'add_setup_screen.dart';

class SetupConfiguratorScreen extends StatefulWidget {
  final String bikeId;
  final bool isEditing; // NEU: Unterscheidet zwischen Neuanlage und Bearbeitung

  const SetupConfiguratorScreen({
    Key? key, 
    required this.bikeId, 
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<SetupConfiguratorScreen> createState() => _SetupConfiguratorScreenState();
}

class _SetupConfiguratorScreenState extends State<SetupConfiguratorScreen> {
  // Lokale Variablen mit Standardwerten
  bool _forkPsi = true, _forkOtt = false, _forkHsc = false, _forkLsc = true;
  bool _forkHsr = false, _forkLsr = true, _forkTokens = false, _forkHbo = false;
  bool _shockIsCoil = false;
  bool _shockPsi = true, _shockTokens = false, _shockRate = false, _shockPreload = false;
  bool _shockHsc = false, _shockLsc = true, _shockHsr = false, _shockLsr = true, _shockHbo = false;
  bool _tires = true;

  @override
  void initState() {
    super.initState();
    // Vorhandene Parameter laden, falls das Bike schon konfiguriert wurde
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

    // NEU: Navigation abhängig vom Modus
    if (widget.isEditing) {
      Navigator.pop(context); // Einfach zurück zur Detailansicht
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
    return Scaffold(
      appBar: AppBar(title: const Text('Fahrwerk Konfigurieren')),
      body: ListView(
        children: [
          buildHeader('GABEL (FORK)'),
          SwitchListTile(title: const Text('Haupt-Luftdruck (PSI)'), value: _forkPsi, onChanged: (v) => setState(() => _forkPsi = v)),
          SwitchListTile(title: const Text('2. Kammer / OTT (PSI/Klicks)'), value: _forkOtt, onChanged: (v) => setState(() => _forkOtt = v)),
          SwitchListTile(title: const Text('High-Speed Comp. (HSC)'), value: _forkHsc, onChanged: (v) => setState(() => _forkHsc = v)),
          SwitchListTile(title: const Text('Low-Speed Comp. (LSC)'), value: _forkLsc, onChanged: (v) => setState(() => _forkLsc = v)),
          SwitchListTile(title: const Text('High-Speed Rebound (HSR)'), value: _forkHsr, onChanged: (v) => setState(() => _forkHsr = v)),
          SwitchListTile(title: const Text('Low-Speed Rebound (LSR)'), value: _forkLsr, onChanged: (v) => setState(() => _forkLsr = v)),
          SwitchListTile(title: const Text('Tokens (Spacers)'), value: _forkTokens, onChanged: (v) => setState(() => _forkTokens = v)),
          SwitchListTile(title: const Text('Hydraulic Bottom-Out (HBO)'), value: _forkHbo, onChanged: (v) => setState(() => _forkHbo = v)),

          buildHeader('DÄMPFER TYP'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Air (Luft)')),
                ButtonSegment(value: true, label: Text('Coil (Stahlfeder)')),
              ],
              selected: {_shockIsCoil},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() => _shockIsCoil = newSelection.first);
              },
            ),
          ),

          buildHeader('DÄMPFER (SHOCK) EINSTELLUNGEN'),
          if (!_shockIsCoil) ...[
            SwitchListTile(title: const Text('Luftdruck (PSI)'), value: _shockPsi, onChanged: (v) => setState(() => _shockPsi = v)),
            SwitchListTile(title: const Text('Tokens (Spacers)'), value: _shockTokens, onChanged: (v) => setState(() => _shockTokens = v)),
          ] else ...[
            SwitchListTile(title: const Text('Federrate (lbs/in)'), value: _shockRate, onChanged: (v) => setState(() => _shockRate = v)),
            SwitchListTile(title: const Text('Vorspannung (Preload)'), value: _shockPreload, onChanged: (v) => setState(() => _shockPreload = v)),
          ],
          SwitchListTile(title: const Text('High-Speed Comp. (HSC)'), value: _shockHsc, onChanged: (v) => setState(() => _shockHsc = v)),
          SwitchListTile(title: const Text('Low-Speed Comp. (LSC)'), value: _shockLsc, onChanged: (v) => setState(() => _shockLsc = v)),
          SwitchListTile(title: const Text('High-Speed Rebound (HSR)'), value: _shockHsr, onChanged: (v) => setState(() => _shockHsr = v)),
          SwitchListTile(title: const Text('Low-Speed Rebound (LSR)'), value: _shockLsr, onChanged: (v) => setState(() => _shockLsr = v)),
          SwitchListTile(title: const Text('Hydraulic Bottom-Out (HBO)'), value: _shockHbo, onChanged: (v) => setState(() => _shockHbo = v)),

          buildHeader('REIFEN (TIRES)'),
          SwitchListTile(title: const Text('Reifen & Druck tracken'), value: _tires, onChanged: (v) => setState(() => _tires = v)),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: FilledButton(
              onPressed: _saveAndContinue, 
              child: Text(widget.isEditing ? 'Änderungen speichern' : 'Konfiguration speichern')
            ),
          ),
        ],
      ),
    );
  }
}