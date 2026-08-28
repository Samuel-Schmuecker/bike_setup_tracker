import 'package:bike_setup_tracker/models/bike_parameters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('custom categories and fields survive serialization', () {
    final parameters = BikeParameters(
      unitOverrides: const {'forkPsi': 'bar'},
      customCategories: [
        CustomSetupCategory(
          id: 'fork',
          name: 'Gabel',
          fields: [
            CustomSetupField(
              id: 'field-1',
              name: 'SAG',
              type: CustomFieldType.number,
              unit: '%',
              value: '18',
            ),
          ],
        ),
      ],
    );

    final restored = BikeParameters.fromMap(parameters.toMap());

    expect(restored.customCategories, hasLength(1));
    expect(restored.customCategories.single.name, 'Gabel');
    expect(restored.customCategories.single.fields.single.name, 'SAG');
    expect(
      restored.customCategories.single.fields.single.type,
      CustomFieldType.number,
    );
    expect(restored.customCategories.single.fields.single.unit, '%');
    expect(restored.customCategories.single.fields.single.value, '18');
    expect(restored.unitOverrides['forkPsi'], 'bar');
  });
}
