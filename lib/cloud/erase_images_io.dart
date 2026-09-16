import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> eraseAccountImages(Set<String> paths) async {
  final local = paths
      .where(
        (path) =>
            !path.startsWith('data:') &&
            !path.startsWith('assets/') &&
            !path.startsWith('cloud:'),
      )
      .toList();
  if (local.isEmpty) return;
  final directory = await getApplicationDocumentsDirectory();
  final root = await directory.resolveSymbolicLinks();
  for (final path in local) {
    final file = File(path);
    // Delete only app-created image copies, never user-selected originals.
    if (!RegExp(r'^\d+\.jpg$').hasMatch(file.uri.pathSegments.last)) continue;
    if (!await file.exists()) continue;
    if (await file.parent.resolveSymbolicLinks() != root) continue;
    if (await FileSystemEntity.isLink(path)) continue;
    await file.delete();
  }
}
