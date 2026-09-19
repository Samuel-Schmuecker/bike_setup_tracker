import 'dart:io';

/// CacheStorage is shared by all service workers on an origin, even when their
/// scopes differ. Namespace all generated Flutter caches by registration scope.
String isolateWebCaches(String source) {
  for (final name in ['MANIFEST', 'TEMP', 'CACHE_NAME']) {
    final pattern = RegExp("const $name = '[^']+';");
    if (pattern.allMatches(source).length != 1) {
      throw StateError('Unexpected Flutter service worker: $name missing');
    }
    source = source.replaceFirstMapped(pattern, (match) {
      final declaration = match.group(0)!;
      return '${declaration.substring(0, declaration.length - 1)}'
          ' + ":" + self.registration.scope;';
    });
  }
  return source;
}

void main() {
  final worker = File('build/web/flutter_service_worker.js');
  worker.writeAsStringSync(isolateWebCaches(worker.readAsStringSync()));
}
