import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/trail_setup.dart';
import 'package:bike_setup_tracker/utils/image_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Bike.copyWith preserves unchanged fields', () {
    final bike = Bike(
      id: 'bike-1',
      brand: 'Brand',
      model: 'Model',
      category: 'Enduro',
      travelFront: 170,
      travelRear: 160,
    );
    final setups = [TrailSetup(id: 'setup-1', name: 'Park')];

    final updated = bike.copyWith(setups: setups);

    expect(updated.brand, bike.brand);
    expect(updated.travelFront, bike.travelFront);
    expect(updated.setups, setups);
  });

  test('default category images point to existing asset names', () {
    expect(
      ImageHelper.getDefaultImageForCategory('E-Bike'),
      'assets/images/e_bike.png',
    );
    expect(
      ImageHelper.getDefaultImageForCategory('Unknown'),
      'assets/images/trail.png',
    );
  });
}
