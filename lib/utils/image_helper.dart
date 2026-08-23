// lib/utils/image_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageHelper {
  // Gibt das fertige Image-Widget zurück
  static Widget buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    if (path.startsWith('data:image')) {
      // Base64 codiertes Bild (Unser neuer Web-Standard)
      final base64Str = path.split(',').last;
      return Image.memory(base64Decode(base64Str), fit: fit);
    } else if (path.startsWith('assets/')) {
      // Lokales Test-Asset (wie das Commencal)
      return Image.asset(path, fit: fit);
    } else if (kIsWeb) {
      // Fallback für Web
      return Image.network(path, fit: fit);
    } else {
      // Fallback für native Apps (falls doch alte Dateipfade existieren)
      return Image.file(File(path), fit: fit);
    }
  }

  // Gibt den ImageProvider zurück (wird für Hintergrundbilder/DecorationImage benötigt)
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