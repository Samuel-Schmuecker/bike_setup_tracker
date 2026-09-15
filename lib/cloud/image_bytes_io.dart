import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readLocalImage(String path) => File(path).readAsBytes();
