// lib/screens/bike_detail/add_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../models/trail_setup.dart';
import 'setup_detail_screen.dart';

class AddSetupScreen extends StatefulWidget {
  final String bikeId;
  const AddSetupScreen({super.key, required this.bikeId});

  @override
  State<AddSetupScreen> createState() => _AddSetupScreenState();
}

class _AddSetupScreenState extends State<AddSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';

  void _createEmptySetup() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Neues Setup erstellen (alles außer Name ist null/-)
      final newSetup = TrailSetup(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name.trim(),
      );

      // Speichern
      context.read<BikeProvider>().addSetupToBike(widget.bikeId, newSetup);

      // Bildschirm austauschen, direkt zu den Details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SetupDetailScreen(
            bikeId: widget.bikeId, 
            setupId: newSetup.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neues Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name des Setups',
                  hintText: 'z.B. Bikepark Schladming',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Bitte Namen eingeben' : null,
                onSaved: (val) => _name = val!,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _createEmptySetup,
                child: const Text('Setup erstellen'),
              )
            ],
          ),
        ),
      ),
    );
  }
}