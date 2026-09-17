import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_setup_tracker/models/bike_parameters.dart';
import 'package:bike_setup_tracker/models/setting_range.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'field_order_test.dart' show fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('new demo includes model-specific ranges and coil controls', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = BikeProvider();
    await provider.loadFromDevice();
    final params = provider.bikes.single.availableParameters!;
    expect(params.ranges['forkLsc']!.max, 15);
    expect(params.ranges['forkHsc']!.max, 3);
    expect(params.ranges['shockHsc']!.min, 1);
    expect(params.ranges['shockLsc']!.max, 16);
    expect(params.ranges['shockLsr']!.max, 7);
    expect(params.shockHbo, isFalse);
    expect(params.shockPsi, isFalse);
    expect(provider.bikes.single.setups, hasLength(2));
    expect(
      provider.bikes.single.setups.map((setup) => setup.name),
      ['Bikepark Setup', 'Nass & Wurzeln'],
    );
    await provider.saveToDevice();
    provider.dispose();
  });
  test(
    'existing demo retains values and overrides; migration runs once',
    () async {
      final demo = fixture('3').copyWith(
        brand: 'Commencal',
        model: 'Supreme V5',
        availableParameters: BikeParameters(
          ranges: {
            'forkLsc': const SettingRange(min: 0, max: 12),
            'forkHsc': null,
          },
        ),
      );
      SharedPreferences.setMockInitialValues({
        'bikes_data': jsonEncode([demo.toMap(), fixture('other').toMap()]),
      });
      final provider = BikeProvider();
      await provider.loadFromDevice();
      final restored = provider.bikes.first;
      expect(restored.availableParameters!.ranges['forkLsc']!.max, 12);
      expect(restored.availableParameters!.ranges['forkHsc'], isNull);
      expect(restored.availableParameters!.ranges['shockLsc']!.max, 16);
      expect(
        restored.setups.map((s) => s.toMap()).toList(),
        demo.setups.map((s) => s.toMap()).toList(),
      );
      expect(provider.bikes.last.availableParameters!.ranges, isEmpty);
      provider.updateBikeParameters(
        '3',
        restored.availableParameters!.copyWith(ranges: {}),
      );
      await provider.saveToDevice();
      await provider.loadFromDevice();
      expect(provider.bikes.first.availableParameters!.ranges, isEmpty);
      provider.dispose();
    },
  );
}
