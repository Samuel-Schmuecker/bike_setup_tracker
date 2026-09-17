import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../providers/bike_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/translations.dart';
import 'setup_detail_page.dart';
import '../../services/onboarding_tour_service.dart';

class SetupDetailScreen extends StatefulWidget {
  final String bikeId;
  final String setupId;
  final OnboardingTourService? onboardingTour;
  const SetupDetailScreen({
    super.key,
    required this.bikeId,
    required this.setupId,
    this.onboardingTour,
  });
  @override
  State<SetupDetailScreen> createState() => _SetupDetailScreenState();
}

class _SetupDetailScreenState extends State<SetupDetailScreen> {
  PageController? _controller;
  bool _editing = false;
  bool _tourDetailActive = false;
  final _swipeTourKey = GlobalKey(debugLabel: 'tour-setup-pager');

  @override
  void initState() {
    super.initState();
    if (widget.onboardingTour != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTour());
    }
  }

  final _pageKeys = <String, GlobalKey<SetupDetailPageState>>{};
  int? _tourStartPage;

  Future<void> _showTour() async {
    if (!mounted) return;
    final tour = widget.onboardingTour!;
    final german = context.read<LanguageProvider>().currentLanguage == 'de';
    var advanced = false;
    try {
      _tourStartPage = _controller!.page!.round();
      final next = await tour.showStep(
        context: context,
        target: _swipeTourKey,
        step: 5,
        event: 'swipe',
        german: german,
        title: german ? 'Zwischen Setups wischen' : 'Swipe between setups',
        description: german
            ? 'Wische nach links oder rechts. Am PC: linke Maustaste gedrückt halten und ziehen. Nach einem Seitenwechsel geht es automatisch weiter.'
            : 'Swipe left or right. On a PC, drag while holding the left mouse button. A successful page change advances the tour.',
      );
      if (!mounted || !next) return;
      setState(() => _tourDetailActive = true);
      final bike = context.read<BikeProvider>().bikes.firstWhere(
        (b) => b.id == widget.bikeId,
      );
      final id = bike.orderedSetups[_controller!.page!.round()].id;
      advanced = await _pageKeys[id]!.currentState!.runTour(tour);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              german
                  ? 'Die Tour wurde unterbrochen. Bitte erneut starten.'
                  : 'Please restart the tour.',
            ),
          ),
        );
    } finally {
      if (mounted && ModalRoute.of(context)?.isCurrent == true)
        Navigator.pop(context, advanced);
    }
  }

  @override
  void dispose() {
    widget.onboardingTour?.cancelFor(context);
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
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis == Axis.horizontal) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                  if (notification is ScrollEndNotification &&
                      notification.metrics.axis == Axis.horizontal &&
                      _controller!.page!.round() != _tourStartPage) {
                    widget.onboardingTour?.complete('swipe');
                  }
                  return false;
                },
                child: PageView.builder(
                  key: _swipeTourKey,
                  controller: _controller,
                  scrollBehavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                    dragDevices: {
                      ...ScrollConfiguration.of(context).dragDevices,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  physics: _editing || _tourDetailActive
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
                      key: _pageKeys.putIfAbsent(
                        setups[index].id,
                        () => GlobalKey<SetupDetailPageState>(),
                      ),
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
