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
    expect(() => isolateWebCaches('unexpected worker'), throwsStateError);
  });
}
