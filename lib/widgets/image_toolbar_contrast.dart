import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/image_helper.dart';

/// Matches the cover crop, bottom gradient and parallax of the bike header.
class ImageToolbarContrast extends StatefulWidget {
  const ImageToolbarContrast({
    super.key,
    required this.imagePath,
    required this.expandedHeight,
    required this.builder,
  }) : _bikeCard = false;

  /// Samples the favorite button on a bike card, including its horizontal shade.
  const ImageToolbarContrast.bikeCard({
    super.key,
    required this.imagePath,
    required this.builder,
  }) : expandedHeight = 140,
       _bikeCard = true;

  final bool _bikeCard;
  final String imagePath;
  final double expandedHeight;
  final Widget Function(BuildContext context, Color iconColor) builder;

  @override
  State<ImageToolbarContrast> createState() => _ImageToolbarContrastState();
}

class _ImageToolbarContrastState extends State<ImageToolbarContrast> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ByteData? _pixels;
  Size _imageSize = Size.zero;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(ImageToolbarContrast oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) _resolveImage();
  }

  void _resolveImage() {
    _detach();
    final generation = ++_generation;
    _pixels = null;
    try {
      _stream = ImageHelper.getImageProvider(
        widget.imagePath,
      ).resolve(createLocalImageConfiguration(context));
      _listener = ImageStreamListener((info, _) async {
        try {
          final pixels = await info.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (!mounted || generation != _generation) return;
          setState(() {
            _pixels = pixels;
            _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        } catch (_) {
          // Keep the light fallback on the dark missing-image placeholder.
        } finally {
          info.dispose();
        }
      }, onError: (Object error, StackTrace? stackTrace) {});
      _stream!.addListener(_listener!);
    } catch (_) {
      // Invalid custom image paths use the same fallback.
    }
  }

  void _detach() {
    if (_listener != null) _stream?.removeListener(_listener!);
  }

  @override
  void dispose() {
    _generation++;
    _detach();
    super.dispose();
  }

  Color _iconColor(double width, double shrink, double topPadding) {
    final theme = Theme.of(context);
    final surface =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;
    final collapseRange = widget.expandedHeight - kToolbarHeight;
    final progress = (shrink / collapseRange).clamp(0.0, 1.0);
    final fadeStart = (1 - kToolbarHeight / collapseRange).clamp(0.0, 1.0);
    final opacity = 1 - Interval(fadeStart, 1).transform(progress);
    if (_pixels == null && opacity > 0) return Colors.white;

    var luminance = surface.computeLuminance();
    if (_pixels != null && opacity > 0) {
      final height = widget.expandedHeight + topPadding;
      final fitted = applyBoxFit(BoxFit.cover, _imageSize, Size(width, height));
      final crop = Alignment.center.inscribe(
        fitted.source,
        Offset.zero & _imageSize,
      );
      var total = 0.0;
      // Sample the toolbar rather than the bike or the dark title area below it.
      for (var row = 0; row < 6; row++) {
        final y = topPadding + (row + 0.5) * kToolbarHeight / 6 + shrink / 4;
        for (var column = 0; column < 32; column++) {
          final x = (column + 0.5) / 32;
          final px = (crop.left + crop.width * x).floor().clamp(
            0,
            _imageSize.width.toInt() - 1,
          );
          final py = (crop.top + crop.height * y / height).floor().clamp(
            0,
            _imageSize.height.toInt() - 1,
          );
          final offset = (py * _imageSize.width.toInt() + px) * 4;
          final pixel = Color.fromARGB(
            _pixels!.getUint8(offset + 3),
            _pixels!.getUint8(offset),
            _pixels!.getUint8(offset + 1),
            _pixels!.getUint8(offset + 2),
          );
          final shaded = Color.alphaBlend(
            Colors.black.withValues(alpha: 0.87 * (y / height).clamp(0.0, 1.0)),
            Color.alphaBlend(pixel, surface),
          );
          total += Color.alphaBlend(
            shaded.withValues(alpha: opacity),
            surface,
          ).computeLuminance();
        }
      }
      luminance = total / (6 * 32);
    }
    // The crossover at which black and white have equal contrast.
    return luminance > 0.179 ? Colors.black : Colors.white;
  }

  Color _cardIconColor(Size size) {
    if (_pixels == null || size.isEmpty) return Colors.white;
    final fitted = applyBoxFit(BoxFit.cover, _imageSize, size);
    final crop = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & _imageSize,
    );
    final surface = Theme.of(context).colorScheme.surface;
    var total = 0.0;
    // Match the 24px icon centered in the top-right 48px button (8px inset).
    for (var row = 0; row < 6; row++) {
      for (var column = 0; column < 6; column++) {
        final x = (size.width - 44 + (column + 0.5) * 4) / size.width;
        final y = (20 + (row + 0.5) * 4) / size.height;
        final px = (crop.left + crop.width * x).floor().clamp(
          0,
          _imageSize.width.toInt() - 1,
        );
        final py = (crop.top + crop.height * y).floor().clamp(
          0,
          _imageSize.height.toInt() - 1,
        );
        final offset = (py * _imageSize.width.toInt() + px) * 4;
        final pixel = Color.fromARGB(
          _pixels!.getUint8(offset + 3),
          _pixels!.getUint8(offset),
          _pixels!.getUint8(offset + 1),
          _pixels!.getUint8(offset + 2),
        );
        total += Color.alphaBlend(
          Colors.black.withValues(alpha: 0.87 * (1 - x).clamp(0.0, 1.0)),
          Color.alphaBlend(pixel, surface),
        ).computeLuminance();
      }
    }
    return total / 36 > 0.179 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) => widget._bikeCard
      ? LayoutBuilder(
          builder: (context, constraints) =>
              widget.builder(context, _cardIconColor(constraints.biggest)),
        )
      : SliverLayoutBuilder(
          builder: (context, constraints) => widget.builder(
            context,
            _iconColor(
              constraints.crossAxisExtent,
              constraints.scrollOffset,
              MediaQuery.paddingOf(context).top,
            ),
          ),
        );
}
