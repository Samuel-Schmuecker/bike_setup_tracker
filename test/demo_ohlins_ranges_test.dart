import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_setup_tracker/models/bike_parameters.dart';
import 'package:bike_setup_tracker/models/setting_range.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/data/demo_bikes.dart';
import 'package:bike_setup_tracker/models/trail_setup.dart';
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
    expect(params.forkNegative, isTrue);
    expect(params.forkOtt, isFalse);
    expect(params.legacyFork, isFalse);
    expect(
      provider.bikes.single.setups.every(
        (setup) => setup.forkNegative == 210 && setup.forkOtt == null,
      ),
      isTrue,
    );
    expect(provider.bikes.single.setups, hasLength(2));
    expect(provider.bikes.single.setups.map((setup) => setup.name), [
      'Bikepark Setup',
      'Nass & Wurzeln',
    ]);
    await provider.saveToDevice();
    provider.dispose();
  });
  test(
    'saved legacy demo resolves chamber values once and preserves custom setups',
    () async {
      final legacy = createDemoBikes().single.copyWith(
        availableParameters: BikeParameters(
          forkOtt: true,
          legacyFork: true,
          ranges: {'forkOtt': const SettingRange(min: 100, max: 300)},
          unitOverrides: {'forkOtt': 'PSI'},
        ),
        setups: [
          TrailSetup(
            id: 's4',
            name: 'Edited demo',
            forkOtt: 215,
            notes: 'Keep',
          ),
          TrailSetup(
            id: 'custom',
            name: 'Custom',
            forkOtt: 4,
            customParameters: BikeParameters(forkOtt: true),
          ),
        ],
      );
      SharedPreferences.setMockInitialValues({
        'bikes_data': jsonEncode([legacy.toMap()]),
      });
      final provider = BikeProvider();
      await provider.ready;
      final demo = provider.bikes.single;
      expect(demo.availableParameters!.forkNegative, isTrue);
      expect(demo.availableParameters!.forkOtt, isFalse);
      expect(demo.availableParameters!.legacyFork, isFalse);
      expect(demo.availableParameters!.ranges['forkNegative']!.max, 300);
      expect(demo.availableParameters!.unitOverrides['forkNegative'], 'PSI');
      expect(demo.setups.first.forkNegative, 215);
      expect(demo.setups.first.forkOtt, isNull);
      expect(demo.setups.first.notes, 'Keep');
      expect(demo.setups.last.forkOtt, 4);
      expect(demo.setups.last.forkNegative, isNull);
      await provider.loadFromDevice();
      expect(provider.bikes.single.toMap(), demo.toMap());
      final own = legacy.copyWith(id: 'own');
      expect(identical(resolveDemoNegativeChamber(own), own), isTrue);
      provider.dispose();
    },
  );
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
