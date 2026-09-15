import 'dart:typed_data';

Future<Uint8List> readLocalImage(String path) =>
    Future.error(StateError('Image must be imported as image data on web.'));
