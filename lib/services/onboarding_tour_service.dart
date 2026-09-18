import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/translations.dart';

/// Shows a spotlight while leaving the real target available for input.
/// Screens report successful actions; Next can bypass an exercise, Skip ends it.
class OnboardingTourService {
  OnboardingTourService({
    this.preferenceKey = 'is_first_start',
    this.preferenceValue = false,
  });
  final String preferenceKey;
  final bool preferenceValue;
  bool createOwnBikeRequested = false;
  static const accent = Color(0xFFC4F000);
  static const surface = Color(0xFF1C1C1C);
  bool _running = false;
  bool _cancelled = false;
  bool _visible = true;
  String? _event;
  BuildContext? _owner;
  OverlayEntry? _overlay;
  Completer<bool>? _step;

  bool waitingFor(String event) => _event == event && _step != null;
  bool complete(String event) {
    if (!waitingFor(event)) return false;
    _resolve(true);
    return true;
  }

  void _resolve(bool result) {
    final pending = _step;
    _step = null;
    _event = null;
    _overlay?.remove();
    _overlay?.dispose();
    _overlay = null;
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  void cancel() {
    _cancelled = true;
    _resolve(false);
  }

  void cancelFor(BuildContext context) {
    if (identical(_owner, context)) cancel();
  }

  void suspend() {
    _visible = false;
    _overlay?.markNeedsBuild();
  }

  void resume() {
    _visible = true;
    _overlay?.markNeedsBuild();
  }

  Future<bool> isFirstStart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_first_start') ??
        !(prefs.getBool('hasSeenOnboarding') ?? false);
  }

  Future<void> run(Future<void> Function() tour) async {
    if (_running) return;
    _running = true;
    _cancelled = false;
    createOwnBikeRequested = false;
    try {
      await tour();
    } finally {
      _resolve(false);
      _owner = null;
      _running = false;
    }
  }

  Future<bool> showStep({
    required BuildContext context,
    required GlobalKey target,
    required int step,
    int total = 6,
    bool advanced = false,
    String? sectionLabel,
    bool allowTargetInteraction = true,
    required String event,
    required String title,
    required String description,
    required String languageCode,
    Future<void> Function()? onNext,
  }) async {
    if (_cancelled || !context.mounted) return false;
    _owner = context;
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted || _cancelled) return false;
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (animation != null && animation.status == AnimationStatus.forward) {
      final done = Completer<void>();
      void listener(AnimationStatus status) {
        if (status != AnimationStatus.forward && !done.isCompleted)
          done.complete();
      }

      animation.addStatusListener(listener);
      try {
        await done.future;
      } finally {
        animation.removeStatusListener(listener);
      }
    }
    if (!context.mounted || _cancelled || route?.isCurrent == false)
      return false;
    final targetContext = target.currentContext;
    if (targetContext == null)
      throw StateError('Tour target not mounted: $event');
    await Scrollable.ensureVisible(targetContext, alignment: 0.2);
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted || _cancelled) return false;
    final pending = Completer<bool>();
    _step = pending;
    _event = event;
    _visible = true;
    bool busy = false;
    _overlay = OverlayEntry(
      builder: (_) => !_visible
          ? const SizedBox.shrink()
          : _Spotlight(
              target: target,
              title: title,
              description: description,
              languageCode: languageCode,
              allowTargetInteraction: allowTargetInteraction,
              progress:
                  '${sectionLabel ?? Translations.get(languageCode, advanced ? 'tourAdvancedSection' : 'tourBasicsSection')} · $step / $total',
              onSkip: cancel,
              onNext: () async {
                if (busy) return;
                busy = true;
                try {
                  if (onNext != null) {
                    await onNext();
                  } else {
                    complete(event);
                  }
                } catch (_) {
                  cancel();
                } finally {
                  busy = false;
                }
              },
            ),
    );
    Overlay.of(context).insert(_overlay!);
    final result = await pending.future;
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool(preferenceKey, preferenceValue)) {
      throw StateError('Could not save onboarding status');
    }
    return result && !_cancelled && context.mounted;
  }
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({
    required this.target,
    required this.title,
    required this.description,
    required this.progress,
    required this.languageCode,
    required this.onSkip,
    required this.onNext,
    required this.allowTargetInteraction,
  });
  final GlobalKey target;
  final String title, description, progress;
  final String languageCode;
  final VoidCallback onSkip, onNext;
  final bool allowTargetInteraction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final box = target.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            child: TextButton(
              onPressed: onSkip,
              child: Text(Translations.get(languageCode, 'tourClose')),
            ),
          ),
        );
      }
      final overlayBox = context.findRenderObject() as RenderBox;
      final origin = overlayBox.globalToLocal(box.localToGlobal(Offset.zero));
      final rect = (origin & box.size)
          .inflate(4)
          .intersect(Offset.zero & constraints.biggest);
      final bottom =
          rect.center.dy < constraints.maxHeight / 2 ||
          rect.height > constraints.maxHeight / 2;
      return Stack(
        children: [
          // The painter rejects hit tests inside the hole, so the actual app gets
          // taps, long presses, mouse/touch swipes and drag-and-drop unchanged.
          Positioned.fill(
            child: GestureDetector(
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightPainter(rect, allowTargetInteraction),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: bottom ? Alignment.bottomCenter : Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440,
                    maxHeight: constraints.maxHeight * .42,
                  ),
                  child: Card(
                    color: OnboardingTourService.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                        color: OnboardingTourService.accent,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    progress,
                                    style: const TextStyle(
                                      color: OnboardingTourService.accent,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        for (final (index, part)
                                            in description.split('**').indexed)
                                          TextSpan(
                                            text: part,
                                            style: index.isOdd
                                                ? const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                      ],
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: onSkip,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                ),
                                child: Text(
                                  Translations.get(languageCode, 'tourSkip'),
                                ),
                              ),
                              FilledButton(
                                onPressed: onNext,
                                style: FilledButton.styleFrom(
                                  backgroundColor: OnboardingTourService.accent,
                                  foregroundColor: Colors.black,
                                ),
                                child: Text(
                                  Translations.get(languageCode, 'tourNext'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.rect, this.allowTargetInteraction);
  final Rect rect;
  final bool allowTargetInteraction;
  @override
  bool hitTest(Offset position) =>
      !allowTargetInteraction || !rect.contains(position);
  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .72));
    canvas.drawRRect(
      hole,
      Paint()
        ..color = OnboardingTourService.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      rect != oldDelegate.rect ||
      allowTargetInteraction != oldDelegate.allowTargetInteraction;
}
