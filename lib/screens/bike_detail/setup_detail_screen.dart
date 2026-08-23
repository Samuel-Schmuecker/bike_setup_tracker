// lib/screens/bike_detail/setup_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/bike_provider.dart';
import '../../models/trail_setup.dart';
import '../../models/bike_parameters.dart';
import '../../utils/suspension_dictionary.dart';

class SetupDetailScreen extends StatefulWidget {
  final String bikeId;
  final String setupId;

  const SetupDetailScreen({
    super.key,
    required this.bikeId,
    required this.setupId,
  });

  @override
  State<SetupDetailScreen> createState() => _SetupDetailScreenState();
}

class _SetupDetailScreenState extends State<SetupDetailScreen> {
  late TextEditingController _notesController;
  late FocusNode _notesFocusNode;
  late BikeProvider _bikeProvider;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _notesFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bike = context.read<BikeProvider>().bikes.firstWhere((b) => b.id == widget.bikeId);
      final setup = bike.setups.firstWhere((s) => s.id == widget.setupId);
      _notesController.text = setup.notes;
    });

    _notesFocusNode.addListener(() {
      if (!_notesFocusNode.hasFocus) {
        _saveNotes();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bikeProvider = context.read<BikeProvider>();
  }

  void _saveNotes() {
    try {
      final bike = _bikeProvider.bikes.firstWhere((b) => b.id == widget.bikeId);
      final setup = bike.setups.firstWhere((s) => s.id == widget.setupId);
      
      if (setup.notes != _notesController.text) {
        _bikeProvider.updateSetup(widget.bikeId, setup.copyWith(notes: _notesController.text));
      }
    } catch (e) {
      // Ignorieren, falls Widget bereits disposed ist
    }
  }

  @override
  void dispose() {
    _saveNotes();
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  double? _parseDouble(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  String? _formatNum(num? value) {
    if (value == null) return null;
    return value == value.toInt() ? value.toInt().toString() : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bike = context.watch<BikeProvider>().bikes.firstWhere((b) => b.id == widget.bikeId);
    final setup = bike.setups.firstWhere((s) => s.id == widget.setupId);
    final params = bike.availableParameters ?? BikeParameters();
    final colorScheme = Theme.of(context).colorScheme;

    void handleSave(String label, String? oldValStr, String newValStr, String note, TrailSetup updatedSetup) {
      if (oldValStr == null || oldValStr.trim().isEmpty || oldValStr == '-') {
        context.read<BikeProvider>().updateSetup(widget.bikeId, updatedSetup);
        return;
      }
      if (oldValStr == newValStr) {
        context.read<BikeProvider>().updateSetup(widget.bikeId, updatedSetup);
        return;
      }

      String diffStr = '';
      final oldNum = _parseDouble(oldValStr);
      final newNum = _parseDouble(newValStr);

      if (oldNum != null && newNum != null) {
        final diff = newNum - oldNum;
        if (diff != 0) {
          String diffFormatted = diff == diff.toInt() ? diff.toInt().toString() : diff.toStringAsFixed(1);
          diffStr = diff > 0 ? ' (+$diffFormatted)' : ' ($diffFormatted)';
        }
      }

      final logMsg = '$label: $oldValStr ➔ $newValStr$diffStr';
      final newLog = SetupLog(parameters: logMsg, note: note, timestamp: DateTime.now());
      context.read<BikeProvider>().updateSetup(widget.bikeId, updatedSetup.copyWith(logs: [newLog, ...updatedSetup.logs]));
    }

    void showStepperModal(String title, String unit, String? currentValue, bool isText, double stepSize, Function(String, String) onSave) {
      showDialog(
        context: context,
        builder: (ctx) => _EditValueDialog(
          title: title, unit: unit, initialValue: currentValue,
          isText: isText, stepSize: stepSize, onSave: onSave,
        ),
      );
    }

    // --- 1. NEUER HEADER MIT TRENNLINIE ---
    Widget buildSectionHeader(String title, {IconData? icon, String? svgPath}) {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 32.0, bottom: 16.0),
        child: Row(
          children: [
            if (svgPath != null)
              SvgPicture.asset(
                svgPath,
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: Colors.white70, // Etwas heller als vorher
              ),
            ),
            const SizedBox(width: 16),
            // Subtile Linie nach dem Text für den Tech-Look
            Expanded(
              child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
            ),
          ],
        ),
      );
    }

    // --- 2. VEREDELTE KACHELN ---
    Widget buildTile(String label, String? value, String unit, VoidCallback onTap, {double? width = 85}) {
      final isSet = value != null && value != '-';
      
      return InkWell(
        onTap: onTap, 
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: width, 
          height: width, // Quadratisch
          decoration: BoxDecoration(
            // Gleicher dunkler Background wie auf Bild 1
            color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Text(
                label, 
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value ?? '-', 
                  style: TextStyle(
                    fontSize: 24, // Etwas größer
                    fontWeight: FontWeight.bold, 
                    // Wenn nicht gesetzt, machen wir den Strich etwas dunkler
                    color: isSet ? Colors.white : Colors.white38,
                  )
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit, 
                // Einheit in Accent-Farbe (Primary) sieht sehr hochwertig aus
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSet ? colorScheme.primary : Colors.white38, letterSpacing: 0.5)
              ),
            ],
          ),
        ),
      );
    }

    // --- 3. NEUES HORIZONTALES REIFEN-LAYOUT (MIT FESTER HÖHE) ---
    Widget buildTireCard(String position, String? model, String? pressure, VoidCallback onModelTap, VoidCallback onPressureTap) {
      final hasModel = model != null && model.isNotEmpty;
      final hasPressure = pressure != null && pressure != '-';

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        // Eine feste Mindesthöhe verhindert, dass die Box bei '-' zusammenfällt
        height: 85, 
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Zwingt Kinder auf volle Höhe
          children: [
            // Linke Seite: Model
            Expanded(
              flex: 3, // Nimmt etwas mehr Platz ein für lange Namen
              child: InkWell(
                onTap: onModelTap,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // Vertikal zentriert
                    children: [
                      Text('$position Model', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 4),
                      Text(
                        hasModel ? model : 'Nicht gesetzt', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hasModel ? Colors.white : Colors.white38),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Trennlinie in der Mitte
            VerticalDivider(color: Colors.white.withOpacity(0.1), width: 1, thickness: 1),
            // Rechte Seite: Luftdruck
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onPressureTap,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Vertikal zentriert
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Air', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            hasPressure ? pressure : '-', 
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: hasPressure ? Colors.white : Colors.white38)
                          ),
                          const SizedBox(width: 4),
                          // Zeigt nun pauschal bar/psi, der User weiß, was er eingetragen hat
                          Text(
                            'bar/psi', 
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: hasPressure ? colorScheme.primary : Colors.white38)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      // --- SLIVER APP BAR FÜR DEN PREMIUM LOOK ---
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 48.0, bottom: 16.0),
                title: Text(
                  setup.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.surface.withOpacity(0.8),
                        colorScheme.surface,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- FORK ---
                  buildSectionHeader('Gabel', svgPath: 'assets/icons/fork.svg'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(spacing: 12.0, runSpacing: 12.0, children: [
                      if (params.forkPsi) buildTile('Main', _formatNum(setup.forkPsi), 'PSI', () => showStepperModal('Fork Main', 'psi', _formatNum(setup.forkPsi), false, 5, (v, n) => handleSave('Fork PSI', _formatNum(setup.forkPsi), v, n, setup.copyWith(forkPsi: _parseDouble(v))))),
                      if (params.forkOtt) buildTile('Neg/OTT', _formatNum(setup.forkOtt), 'PSI', () => showStepperModal('Fork OTT/Negative', 'psi/clk', _formatNum(setup.forkOtt), false, 5, (v, n) => handleSave('Fork OTT', _formatNum(setup.forkOtt), v, n, setup.copyWith(forkOtt: _parseDouble(v))))),
                      if (params.forkHsc) buildTile('HSC', _formatNum(setup.forkHsc), 'CLK', () => showStepperModal('Fork HSC', 'click', _formatNum(setup.forkHsc), false, 1, (v, n) => handleSave('Fork HSC', _formatNum(setup.forkHsc), v, n, setup.copyWith(forkHsc: int.tryParse(v))))),
                      if (params.forkLsc) buildTile('LSC', _formatNum(setup.forkLsc), 'CLK', () => showStepperModal('Fork LSC', 'click', _formatNum(setup.forkLsc), false, 1, (v, n) => handleSave('Fork LSC', _formatNum(setup.forkLsc), v, n, setup.copyWith(forkLsc: int.tryParse(v))))),
                      if (params.forkHsr) buildTile('HSR', _formatNum(setup.forkHsr), 'CLK', () => showStepperModal('Fork HSR', 'click', _formatNum(setup.forkHsr), false, 1, (v, n) => handleSave('Fork HSR', _formatNum(setup.forkHsr), v, n, setup.copyWith(forkHsr: int.tryParse(v))))),
                      if (params.forkLsr) buildTile('LSR', _formatNum(setup.forkLsr), 'CLK', () => showStepperModal('Fork LSR', 'click', _formatNum(setup.forkLsr), false, 1, (v, n) => handleSave('Fork LSR', _formatNum(setup.forkLsr), v, n, setup.copyWith(forkLsr: int.tryParse(v))))),
                      if (params.forkTokens) buildTile('Tokens', _formatNum(setup.forkTokens), 'PCS', () => showStepperModal('Fork Tokens', 'pcs', _formatNum(setup.forkTokens), false, 1, (v, n) => handleSave('Fork Tokens', _formatNum(setup.forkTokens), v, n, setup.copyWith(forkTokens: int.tryParse(v))))),
                      if (params.forkHbo) buildTile('HBO', _formatNum(setup.forkHbo), 'CLK', () => showStepperModal('Fork HBO', 'click', _formatNum(setup.forkHbo), false, 1, (v, n) => handleSave('Fork HBO', _formatNum(setup.forkHbo), v, n, setup.copyWith(forkHbo: int.tryParse(v))))),
                    ]),
                  ),

                  // --- SHOCK ---
                  buildSectionHeader('Dämpfer', svgPath: 'assets/icons/shock.svg'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(spacing: 12.0, runSpacing: 12.0, children: [
                      if (!params.shockIsCoil) ...[
                        if (params.shockPsi) buildTile('Air', _formatNum(setup.shockPsi), 'PSI', () => showStepperModal('Shock Air Pressure', 'psi', _formatNum(setup.shockPsi), false, 5, (v, n) => handleSave('Shock Air', _formatNum(setup.shockPsi), v, n, setup.copyWith(shockPsi: _parseDouble(v))))),
                        if (params.shockTokens) buildTile('Tokens', _formatNum(setup.shockTokens), 'PCS', () => showStepperModal('Shock Tokens', 'pcs', _formatNum(setup.shockTokens), false, 1, (v, n) => handleSave('Shock Tokens', _formatNum(setup.shockTokens), v, n, setup.copyWith(shockTokens: int.tryParse(v))))),
                      ] else ...[
                        if (params.shockRate) buildTile('Spring', _formatNum(setup.shockRate), 'LBS', () => showStepperModal('Shock Spring Rate', 'lbs/in', _formatNum(setup.shockRate), false, 25, (v, n) => handleSave('Shock Rate', _formatNum(setup.shockRate), v, n, setup.copyWith(shockRate: _parseDouble(v))))),
                        if (params.shockPreload) buildTile('Preload', _formatNum(setup.shockPreload), 'TRN', () => showStepperModal('Shock Preload', 'turns', _formatNum(setup.shockPreload), false, 0.25, (v, n) => handleSave('Shock Preload', _formatNum(setup.shockPreload), v, n, setup.copyWith(shockPreload: _parseDouble(v))))),
                      ],
                      if (params.shockHsc) buildTile('HSC', _formatNum(setup.shockHsc), 'CLK', () => showStepperModal('Shock HSC', 'click', _formatNum(setup.shockHsc), false, 1, (v, n) => handleSave('Shock HSC', _formatNum(setup.shockHsc), v, n, setup.copyWith(shockHsc: int.tryParse(v))))),
                      if (params.shockLsc) buildTile('LSC', _formatNum(setup.shockLsc), 'CLK', () => showStepperModal('Shock LSC', 'click', _formatNum(setup.shockLsc), false, 1, (v, n) => handleSave('Shock LSC', _formatNum(setup.shockLsc), v, n, setup.copyWith(shockLsc: int.tryParse(v))))),
                      if (params.shockHsr) buildTile('HSR', _formatNum(setup.shockHsr), 'CLK', () => showStepperModal('Shock HSR', 'click', _formatNum(setup.shockHsr), false, 1, (v, n) => handleSave('Shock HSR', _formatNum(setup.shockHsr), v, n, setup.copyWith(shockHsr: int.tryParse(v))))),
                      if (params.shockLsr) buildTile('LSR', _formatNum(setup.shockLsr), 'CLK', () => showStepperModal('Shock LSR', 'click', _formatNum(setup.shockLsr), false, 1, (v, n) => handleSave('Shock LSR', _formatNum(setup.shockLsr), v, n, setup.copyWith(shockLsr: int.tryParse(v))))),
                      if (params.shockHbo) buildTile('HBO', _formatNum(setup.shockHbo), 'CLK', () => showStepperModal('Shock HBO', 'click', _formatNum(setup.shockHbo), false, 1, (v, n) => handleSave('Shock HBO', _formatNum(setup.shockHbo), v, n, setup.copyWith(shockHbo: int.tryParse(v))))),
                    ]),
                  ),

                  // --- TIRES (EDLE HORIZONTALE KARTEN) ---
                  if (params.tires) ...[
                    buildSectionHeader('Reifen', svgPath: 'assets/icons/tire.svg'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          buildTireCard(
                            'Front', setup.frontTire, _formatNum(setup.frontPressure),
                            () => showStepperModal('Vorderreifen Model', '', setup.frontTire, true, 1, (v, n) => handleSave('Front Model', setup.frontTire, v, n, setup.copyWith(frontTire: v))),
                            // Änderung: 'bar/psi' statt nur 'bar' übergeben
                            () => showStepperModal('Vorderreifen Druck', 'bar/psi', _formatNum(setup.frontPressure), false, 0.1, (v, n) => handleSave('Front Pressure', _formatNum(setup.frontPressure), v, n, setup.copyWith(frontPressure: _parseDouble(v)))),
                          ),
                          buildTireCard(
                            'Rear', setup.rearTire, _formatNum(setup.rearPressure),
                            () => showStepperModal('Hinterreifen Model', '', setup.rearTire, true, 1, (v, n) => handleSave('Rear Model', setup.rearTire, v, n, setup.copyWith(rearTire: v))),
                            // Änderung: 'bar/psi' statt nur 'bar' übergeben
                            () => showStepperModal('Hinterreifen Druck', 'bar/psi', _formatNum(setup.rearPressure), false, 0.1, (v, n) => handleSave('Rear Pressure', _formatNum(setup.rearPressure), v, n, setup.copyWith(rearPressure: _parseDouble(v)))),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- LOG ---
                  buildSectionHeader('Verlauf', icon: Icons.history),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: setup.logs.isEmpty 
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Bisher keine Anpassungen vorgenommen.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.5))),
                    )
                  : ConstrainedBox(
                      // NEU: Begrenzt die Höhe auf max. ~3,5 Einträge (ca. 240px), 
                      // schrumpft aber zusammen, wenn es weniger Einträge sind.
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.white, Colors.transparent],
                            stops: [0.0, 0.75, 1.0], // Fade-Out etwas später ansetzen
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: ListView.builder(
                          // NEU: Zieht sich zusammen und scrollt "bouncy" (iOS-Style)
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: setup.logs.length,
                          itemBuilder: (context, index) {
                            final log = setup.logs[index];
                            final isLast = index == setup.logs.length - 1;

                            String mainText = log.parameters;
                            String diffBadge = '';
                            final regex = RegExp(r'(.*)\s\((.*)\)$');
                            final match = regex.firstMatch(log.parameters);
                            if (match != null) {
                              mainText = match.group(1) ?? log.parameters;
                              diffBadge = match.group(2) ?? '';
                            }

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 10, height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: colorScheme.primary, width: 2),
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                        ),
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 1.5,
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        )
                                      else
                                        // BUGFIX: Unsichtbarer Platzhalter verhindert den 1-Pixel Overflow
                                        const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Expanded(child: Text(mainText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white))),
                                              if (diffBadge.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(color: colorScheme.primaryContainer.withOpacity(0.8), borderRadius: BorderRadius.circular(12)),
                                                  child: Text(diffBadge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                                                ),
                                            ],
                                          ),
                                          if (log.note.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(log.note, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.5), fontSize: 13)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
              ),

                  // --- NOTIZEN ---
                  buildSectionHeader('Notizen', icon: Icons.edit_note),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _notesController,
                      focusNode: _notesFocusNode,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Allgemeine Bemerkungen...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- DIALOG WIDGET BLEIBT WIE ZUVOR ---
class _EditValueDialog extends StatefulWidget {
  final String title;
  final String unit;
  final String? initialValue;
  final bool isText;
  final double stepSize;
  final Function(String, String) onSave;

  const _EditValueDialog({
    required this.title, required this.unit, this.initialValue,
    required this.isText, required this.stepSize, required this.onSave,
  });

  @override
  State<_EditValueDialog> createState() => _EditValueDialogState();
}

class _EditValueDialogState extends State<_EditValueDialog> {
  late TextEditingController _valCtrl;
  late TextEditingController _noteCtrl;
  late FocusNode _valFocusNode;
  bool _manualEdit = false;
  double? _currentNum;

  @override
  void initState() {
    super.initState();
    _valCtrl = TextEditingController(text: widget.initialValue ?? '');
    _noteCtrl = TextEditingController();
    _valFocusNode = FocusNode();

    if (!widget.isText) {
      if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
        _currentNum = double.tryParse(widget.initialValue!.replaceAll(',', '.'));
      }
    }
  }

  @override
  void dispose() {
    _valCtrl.dispose();
    _noteCtrl.dispose();
    _valFocusNode.dispose();
    super.dispose();
  }

  void _changeValue(double delta) {
    setState(() {
      _currentNum = (_currentNum ?? 0) + delta;
      _valCtrl.text = _currentNum == _currentNum!.toInt() ? _currentNum!.toInt().toString() : _currentNum!.toStringAsFixed(1);
    });
  }

 @override
  Widget build(BuildContext context) {
    final titleString = widget.unit.isNotEmpty ? '${widget.title} (${widget.unit})' : widget.title;
    
    // Wir suchen die passende Beschreibung anhand des Titels
    final description = SuspensionDictionary.getDescription(widget.title);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      
      // NEU: Extrem sauberes Header-Layout mit perfektem Ripple-Effekt
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Platzhalter links, damit der Text optisch exakt zentriert bleibt
          if (description != null) 
            const SizedBox(width: 24),
          
          Expanded(
            child: Text(
              titleString, 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Info-Button rechts
          if (description != null)
            IconButton(
              // Entfernt überschüssiges Padding für einen perfekten Touch-Radius
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24, // Feste Icon-Größe
              splashRadius: 20, // Begrenzt den Ripple-Effekt schön auf das Icon
              icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Was ist das?', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    content: Text(description, style: const TextStyle(height: 1.5)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Verstanden'),
                      ),
                    ],
                  ),
                );
              },
            )
          // Fallback, wenn kein Info-Icon da ist, damit der Text mittig bleibt
          else if (description == null)
             const SizedBox(width: 24),
        ],
      ),
      
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isText) 
              TextField(
                controller: _valCtrl, 
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Wert'), 
                autofocus: true,
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(icon: const Icon(Icons.remove), onPressed: () => _changeValue(-widget.stepSize), padding: const EdgeInsets.all(12)),
                  _manualEdit 
                    ? SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _valCtrl, focusNode: _valFocusNode, textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(isDense: true),
                          onSubmitted: (val) {
                            setState(() {
                              _currentNum = double.tryParse(val.replaceAll(',', '.'));
                              _manualEdit = false;
                            });
                          },
                        ),
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          setState(() => _manualEdit = true);
                          _valFocusNode.requestFocus();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Text(_valCtrl.text.isEmpty ? '0' : _valCtrl.text, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  IconButton.filledTonal(icon: const Icon(Icons.add), onPressed: () => _changeValue(widget.stepSize), padding: const EdgeInsets.all(12)),
                ],
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteCtrl, 
              decoration: const InputDecoration(labelText: 'Grund (Optional)', hintText: 'z.B. Mehr Gegenhalt...', border: OutlineInputBorder(), isDense: true),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            if (_valCtrl.text.isNotEmpty) widget.onSave(_valCtrl.text, _noteCtrl.text);
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}