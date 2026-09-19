import 'package:flutter_test/flutter_test.dart';
import '../tool/isolate_web_cache.dart';

void main() {
  test('all generated caches are isolated by worker scope', () {
    const source =
        "const MANIFEST = 'flutter-app-manifest';\n"
        "const TEMP = 'flutter-temp-cache';\n"
        "const CACHE_NAME = 'flutter-app-cache';\n"
        'const RESOURCES = {};';
    final isolated = isolateWebCaches(source);
    expect('self.registration.scope'.allMatches(isolated), hasLength(3));
    expect(isolated, contains('const RESOURCES = {};'));
    expect(isolateWebCaches(isolated), isolated);
    expect(() => isolateWebCaches('unexpected worker'), throwsStateError);
  });

  test('empty worker has no caches to isolate', () {
    expect(isolateWebCaches(''), '');
    expect(isolateWebCaches('\n'), '\n');
  });

  test('new Flutter cleanup worker is preserved', () {
    // Lifecycle used by the current upstream Flutter cleanup worker.
    const source = '''
self.addEventListener('install', () => { self.skipWaiting(); });
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await self.registration.unregister();
    const clients = await self.clients.matchAll({type: 'window'});
    clients.forEach((client) => { client.navigate(client.url); });
  })());
});
''';
    expect(isolateWebCaches(source), source);
    // A worker that also accesses caches must not silently bypass isolation.
    expect(
      () => isolateWebCaches("$source\ncaches.open('shared');"),
      throwsStateError,
    );
  });

  test('partially changed caching worker still fails closed', () {
    expect(
      () => isolateWebCaches("const MANIFEST = 'flutter-app-manifest';"),
      throwsStateError,
    );
  });
}
