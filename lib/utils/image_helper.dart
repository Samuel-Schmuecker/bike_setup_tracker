// lib/utils/image_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageHelper {
  
  // --- NEU: Zuweisung des Standard-Bildes basierend auf der Kategorie ---
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
      return 'assets/images/e_bike.png';
    }
    
    // Fallback für alle anderen Kategorien
    return 'assets/images/default.png';
  }

  // --- NEU: Entscheidet, ob Nutzerbild oder Fallback genutzt wird ---
  static String getDisplayImagePath(String? customPath, String category) {
    if (customPath != null && customPath.isNotEmpty) {
      return customPath;
    }
    return getDefaultImageForCategory(category);
  }

  // Fallback-Widget bei Ladefehlern
  static Widget _errorFallback(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
      ),
    );
  }

  // Gibt das fertige Image-Widget zurück
  static Widget buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    try {
      if (path.startsWith('data:image')) {
        final base64Str = path.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: fit, errorBuilder: _errorFallback);
      } else if (path.startsWith('assets/')) {
        return Image.asset(path, fit: fit, errorBuilder: _errorFallback);
      } else if (kIsWeb) {
        return Image.network(path, fit: fit, errorBuilder: _errorFallback);
      } else {
        return Image.file(File(path), fit: fit, errorBuilder: _errorFallback);
      }
    } catch (e) {
      return _errorFallback(null as dynamic, e, null); 
    }
  }

  // Gibt den ImageProvider zurück (für Hintergrundbilder)
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