import 'package:flutter_test/flutter_test.dart';
import 'field_order_test.dart' show loadProvider;

void main() {
  test('favorites lead while manual order persists after reload', () async {
    final provider = await loadProvider(setups: 3);
    provider.reorderSetups('a', ['a-2', 'a-0', 'a-1']);
    provider.toggleSetupFavorite('a', 'a-1');
    expect(provider.bikes.first.orderedSetups.map((s) => s.id), [
      'a-1',
      'a-2',
      'a-0',
    ]);
    await provider.saveToDevice();
    await provider.loadFromDevice();
    expect(provider.bikes.first.orderedSetups.map((s) => s.id), [
      'a-1',
      'a-2',
      'a-0',
    ]);
    provider.toggleSetupFavorite('a', 'a-1');
    expect(provider.bikes.first.orderedSetups.map((s) => s.id), [
      'a-2',
      'a-0',
      'a-1',
    ]);
    provider.reorderSetups('a', ['a-0', 'a-0', 'a-1']);
    expect(provider.bikes.first.setups.map((s) => s.id), ['a-2', 'a-0', 'a-1']);
  });
}
