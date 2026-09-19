import 'dart:io';

/// CacheStorage is shared by all service workers on an origin, even when their
/// scopes differ. Namespace all generated Flutter caches by registration scope.
String isolateWebCaches(String source) {
  // --pwa-strategy=none produces an empty worker. Recent Flutter versions
  // instead emit a cleanup worker which unregisters itself without using caches.
  if (source.trim().isEmpty) return source;
  final cleanupWorker =
      source.contains('self.registration.unregister()') &&
      RegExp(r'''addEventListener\(['"]install['"]''').hasMatch(source) &&
      RegExp(r'''addEventListener\(['"]activate['"]''').hasMatch(source) &&
      !RegExp(r'\b(caches|MANIFEST|TEMP|CACHE_NAME)\b').hasMatch(source);
  if (cleanupWorker) return source;

  for (final name in ['MANIFEST', 'TEMP', 'CACHE_NAME']) {
    // Accept an already processed worker so local reruns are safe.
    final pattern = RegExp(
      "const $name = '[^']+'"
      r'(?: \+ ":" \+ self\.registration\.scope)?;',
    );
    if (pattern.allMatches(source).length != 1) {
      throw StateError('Unexpected Flutter service worker: $name missing');
    }
    source = source.replaceFirstMapped(pattern, (match) {
      final declaration = match.group(0)!;
      if (declaration.contains('self.registration.scope')) return declaration;
      return '${declaration.substring(0, declaration.length - 1)}'
          ' + ":" + self.registration.scope;';
    });
  }
  return source;
}

void main() {
  final worker = File('build/web/flutter_service_worker.js');
  final original = worker.readAsStringSync();
  final isolated = isolateWebCaches(original);
  if (isolated != original) {
    worker.writeAsStringSync(isolated);
    stdout.writeln('Flutter offline caches isolated by service-worker scope.');
  } else {
    stdout.writeln(
      'No cache changes needed: worker is cache-free or isolated.',
    );
  }
}
