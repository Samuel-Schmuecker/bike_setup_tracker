import 'package:bike_setup_tracker/cloud/guest_import.dart';
import 'package:bike_setup_tracker/data/demo_bikes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generated demo log dates do not turn the demo into user data', () {
    final demo = createDemoBikes().single.toMap();
    demo['setups'][0]['logs'][0]['timestamp'] = '2020-01-01T00:00:00Z';
    expect(isUntouchedDemo(demo), isTrue);
    expect(
      guestImportPayload({
        'bikes': [demo],
        'catalog': [],
      })['bikes'],
      isEmpty,
    );
    expect(demo['setups'][0]['logs'][0]['timestamp'], '2020-01-01T00:00:00Z');
  });

  test('user edits on a demo and custom copies are never discarded', () {
    for (final change in [
      (Map demo) => demo['setups'][0]['forkPsi'] = 123.0,
      (Map demo) => demo['setups'][0]['notes'] = 'My settings',
      (Map demo) => demo['imagePath'] = 'data:image/png;base64,AQID',
      (Map demo) => demo['id'] = 'user-created-id',
    ]) {
      final demo = createDemoBikes().single.toMap();
      change(demo);
      expect(isUntouchedDemo(demo), isFalse);
      expect(
        guestImportPayload({
          'bikes': [demo],
          'catalog': [],
        })['bikes'],
        hasLength(1),
      );
    }
  });
}
