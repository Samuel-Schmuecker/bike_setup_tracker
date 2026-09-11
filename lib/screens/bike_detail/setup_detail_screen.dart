import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translations.dart';
import 'setup_detail_page.dart';

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
  PageController? _controller;
  bool _editing = false;
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bikes = context.watch<BikeProvider>().bikes;
    final bikeIndex = bikes.indexWhere((bike) => bike.id == widget.bikeId);
    final lang = context.watch<LanguageProvider>().currentLanguage;
    if (bikeIndex == -1 || bikes[bikeIndex].setups.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(Translations.get(lang, 'setupNotFound'))),
      );
    }
    final setups = bikes[bikeIndex].orderedSetups;
    if (_controller == null) {
      var initialIndex = setups.indexWhere(
        (setup) => setup.id == widget.setupId,
      );
      if (initialIndex < 0) initialIndex = 0;
      _controller = PageController(initialPage: initialIndex);
    }
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: NotificationListener<ScrollStartNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis == Axis.horizontal) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  physics: _editing
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  itemCount: setups.length,
                  itemBuilder: (context, index) => Card(
                    margin: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    color: colors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: colors.outlineVariant.withValues(alpha: 0.45),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SetupDetailPage(
                      key: ValueKey(setups[index].id),
                      bikeId: widget.bikeId,
                      setupId: setups[index].id,
                      onEditingChanged: (editing) =>
                          setState(() => _editing = editing),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
