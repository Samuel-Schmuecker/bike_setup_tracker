// lib/utils/image_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageHelper {
  // Das Fallback-Widget, falls ein Bild nicht geladen werden kann
  static Widget _errorFallback(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      color: Colors.grey[900], // Dunkler Hintergrund
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
      ),
    );
  }

  // Gibt das fertige Image-Widget zurück (inklusive Fehlerbehandlung!)
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
      // Falls z.B. das Base64 Decoding fehlschlägt
      return _errorFallback(null as dynamic, e, null); 
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