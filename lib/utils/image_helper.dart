// lib/utils/image_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageHelper {
  
  static String getDefaultImageForCategory(String category) {
    final cat = category.toLowerCase();
    
    if (cat.contains('downhill') || cat.contains('dh')) {
      return 'assets/images/downhill.png';
    } else if (cat.contains('enduro')) {
      return 'assets/images/enduro.png';
    } else if (cat.contains('trail') || cat.contains('all mountain') || cat.contains('am')) {
      return 'assets/images/trail.png';
    } else if (cat.contains('gravel')) {
      return 'assets/images/gravel.png';
    } else if (cat.contains('cross country') || cat.contains('xc')) {
      return 'assets/images/xc.png';
    } else if (cat.contains('e-bike')) {
      return 'assets/images/ebike.png';
    }
    
    return 'assets/images/default.png';
  }

  static String getDisplayImagePath(String? customPath, String category) {
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }
    return getDefaultImageForCategory(category);
  }

  // --- SAUBERE FEHLER-WIDGET LÖSUNG ---
  
  // 1. Die reine UI-Komponente (braucht gar keinen Context)
  static Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
      ),
    );
  }

  // 2. Der Wrapper, der von Flutters Image.* errorBuilder erwartet wird
  static Widget _flutterErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    return _buildErrorPlaceholder();
  }

  // Gibt das fertige Image-Widget zurück
  static Widget buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    try {
      if (path.startsWith('data:image')) {
        final base64Str = path.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: fit, errorBuilder: _flutterErrorBuilder);
      } else if (path.startsWith('assets/')) {
        return Image.asset(path, fit: fit, errorBuilder: _flutterErrorBuilder);
      } else if (kIsWeb) {
        return Image.network(path, fit: fit, errorBuilder: _flutterErrorBuilder);
      } else {
        return Image.file(File(path), fit: fit, errorBuilder: _flutterErrorBuilder);
      }
    } catch (e) {
      // Wenn das Parsen (z.B. Base64 Decode) fehlschlägt, rufen wir einfach direkt das UI-Widget auf!
      return _buildErrorPlaceholder(); 
    }
  }

  // Gibt den ImageProvider zurück
  static ImageProvider getImageProvider(String path) {
    if (path.startsWith('data:image')) {
      final base64Str = path.split(',').last;
      return MemoryImage(base64Decode(base64Str));
    } else if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else if (kIsWeb) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }
}