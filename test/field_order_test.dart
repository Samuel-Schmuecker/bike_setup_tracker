import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/bike_parameters.dart';
import 'package:bike_setup_tracker/models/trail_setup.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/bike_detail/setup_detail_screen.dart';
import 'package:bike_setup_tracker/widgets/reorderable_field_wrap.dart';

Bike fixture(String id, {int setups = 2}) => Bike(
  id: id,
  brand: 'Test',
  model: 'Bike',
  category: 'Trail',
  travelFront: 150,
  travelRear: 140,
  availableParameters: BikeParameters(),
  setups: List.generate(
    setups,
    (i) => TrailSetup(
      id: '$id-$i',
      name: 'Setup $i',
      forkPsi: 70 + i.toDouble(),
      customParameters: i == 0 ? null : BikeParameters(forkPsi: false),
    ),
  ),
);

Future<BikeProvider> loadProvider({int setups = 2}) async {
  SharedPreferences.setMockInitialValues({
    'bikes_data': jsonEncode([
      fixture('a', setups: setups).toMap(),
      fixture('b').toMap(),
    ]),
  });
  final provider = BikeProvider();
  await provider.loadFromDevice();
  return provider;
}

Future<void> dragField(WidgetTester tester, String from, String to) async {
  final source = find.byKey(ValueKey(from));
  final target = find.byKey(ValueKey(to));
  final destination = tester.getCenter(target);
  final gesture = await tester.startGesture(tester.getCenter(source));
  await tester.pump(const Duration(milliseconds: 200));
  await gesture.moveTo(destination);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [400.0, 200.0, 100.0]) {
    testWidgets('fields animate live into place at width $width', (
      tester,
    ) async {
      var order = <String>['a', 'hidden', 'b', 'c'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: StatefulBuilder(
                  builder: (context, setState) => ReorderableFieldWrap(
                    categoryId: 'fork',
                    order: order,
                    editing: true,
                    dragLabel: 'Drag',
                    onReorder: (value) => setState(() => order = value),
                    children: [
                      for (final id in ['a', 'b', 'c'])
                        SizedBox(
                          key: ValueKey(id),
                          width: 85,
                          height: 85,
                          child: Text(id),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Future<void> insert(String source, String anchor, bool before) async {
        final rect = tester.getRect(find.byKey(ValueKey(anchor)));
        final visible = order.where((id) => id != 'hidden').toList();
        final movedId =
            !before && visible.indexOf(source) > visible.indexOf(anchor)
            ? visible[visible.indexOf(anchor) + 1]
            : anchor;
        final movedStart = tester.getTopLeft(find.byKey(ValueKey(movedId)));
        final vertical = width == 100;
        final destination = vertical
            ? Offset(rect.center.dx, before ? rect.top - 6 : rect.bottom + 6)
            : Offset(before ? rect.left - 6 : rect.right + 6, rect.center.dy);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(ValueKey(source))),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await gesture.moveTo(destination);
        await tester.pump();
        final marker = find.byKey(const ValueKey('insertion-fork'));
        expect(marker, findsNothing);
        final orderBeforeDrop = List<String>.of(order);
        await tester.pump(const Duration(milliseconds: 125));
        final halfway = tester.getTopLeft(find.byKey(ValueKey(movedId)));
        await tester.pumpAndSettle();
        final preview = tester.getTopLeft(find.byKey(ValueKey(movedId)));
        // The surrounding cards move before releasing the pointer.
        expect(preview, isNot(movedStart));
        expect(halfway, isNot(preview));
        expect(order, orderBeforeDrop);
        await gesture.moveTo(destination + const Offset(0.1, 0.1));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byKey(ValueKey(movedId))), preview);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(marker, findsNothing);
      }

      await insert('c', 'a', false);
      expect(order, ['a', 'c', 'hidden', 'b']);
      await insert('c', 'b', false);
      expect(order, ['a', 'hidden', 'b', 'c']);
      await insert('c', 'a', true);
      expect(order, ['c', 'a', 'hidden', 'b']);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'orders survive serialization and unrelated setup edits; old data loads',
    () {
      final setup = TrailSetup(
        id: 's',
        name: 'Setup',
        categoryOrder: ['shock', 'fork', 'tires'],
        fieldOrders: {
          'fork': ['forkLsr', 'forkPsi', 'custom:sag'],
        },
      );
      final restored = TrailSetup.fromMap(
        jsonDecode(jsonEncode(setup.toMap())),
      );
      expect(
        restored.copyWith(notes: 'Updated').fieldOrders,
        setup.fieldOrders,
      );
      expect(TrailSetup.fromMap({'id': 'old'}).fieldOrders, isEmpty);
      expect(
        restored.copyWith(notes: 'Updated').categoryOrder,
        setup.categoryOrder,
      );
      expect(TrailSetup.fromMap({'id': 'old'}).categoryOrder, isEmpty);
    },
  );

  test('propagation affects only order on this bike and persists', () async {
    final provider = await loadProvider();
    final before = provider.bikes.map((bike) => bike.toMap()).toList();
    const order = {
      'fork': ['forkLsr', 'forkPsi'],
    };
    provider.updateFieldOrders('a', 'a-0', order);
    expect(provider.bikes.first.setups.last.fieldOrders, isEmpty);
    provider.updateFieldOrders('a', 'a-0', order, applyToAll: true);
    await provider.saveToDevice();
    await provider.loadFromDevice();
    for (var i = 0; i < 2; i++) {
      final setup = provider.bikes.first.setups[i];
      expect(setup.fieldOrders, order);
      final actual = setup.toMap()..remove('fieldOrders');
      final original = Map<String, dynamic>.from(
        (before.first['setups'] as List)[i],
      )..remove('fieldOrders');
      expect(actual, original);
    }
    expect(provider.bikes.last.toMap(), before.last);
  });

  testWidgets('drag reorders within a category and rejects another category', (
    tester,
  ) async {
    var order = <String>['hidden', 'pressure', 'rebound'];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                ReorderableFieldWrap(
                  categoryId: 'fork',
                  order: order,
                  editing: true,
                  dragLabel: 'Drag',
                  onReorder: (value) => setState(() => order = value),
                  children: const [
                    SizedBox(
                      key: ValueKey('pressure'),
                      width: 85,
                      height: 85,
                      child: Text('Pressure'),
                    ),
                    SizedBox(
                      key: ValueKey('rebound'),
                      width: 85,
                      height: 85,
                      child: Text('Rebound'),
                    ),
                  ],
                ),
                ReorderableFieldWrap(
                  categoryId: 'shock',
                  order: const [],
                  editing: true,
                  dragLabel: 'Drag',
                  onReorder: (_) => fail('Cross-category drop accepted'),
                  children: const [
                    SizedBox(key: ValueKey('shock'), width: 85, height: 85),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await dragField(tester, 'rebound', 'pressure');
    expect(order, ['hidden', 'rebound', 'pressure']);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('rebound'))).dx,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('pressure'))).dx),
    );
    final rebound = find.byKey(const ValueKey('rebound'));
    final originalPosition = tester.getTopLeft(rebound);
    final destination = tester.getCenter(rebound);
    final outside = tester.getCenter(find.byKey(const ValueKey('shock')));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('pressure'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveTo(destination);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(rebound), isNot(originalPosition));
    await gesture.moveTo(outside);
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(rebound), originalPosition);
    expect(order, ['hidden', 'rebound', 'pressure']);
    expect(tester.takeException(), isNull);
  });

  for (final applyAll in [false, true]) {
    testWidgets('categories move together and save with applyAll=$applyAll', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = await loadProvider();
      final source = provider.bikes.first.setups.first;
      provider.updateSetup(
        'a',
        source.copyWith(
          customParameters: BikeParameters(
            customCategories: const [
              CustomSetupCategory(
                id: 'custom-fit',
                name: 'Fit',
                notesEnabled: true,
                notes: 'Keep these notes',
                fields: [
                  CustomSetupField(
                    id: 'reach',
                    name: 'Reach',
                    type: CustomFieldType.number,
                    value: '480',
                  ),
                ],
              ),
            ],
          ),
          fieldOrders: {
            'fork': ['forkLsr', 'forkPsi', 'forkLsc'],
          },
        ),
      );
      final before = provider.bikes.first.setups
          .map((setup) => setup.toMap())
          .toList();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(
            home: SetupDetailScreen(bikeId: 'a', setupId: 'a-0'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Felder anordnen'));
      await tester.pumpAndSettle();
      final handle = find.byKey(const ValueKey('category-handle-custom-fit'));
      final destination = tester.getTopLeft(
        find.byKey(const ValueKey('category-fork')),
      );
      final start = tester.getCenter(
        applyAll
            ? find.descendant(
                of: handle,
                matching: find.byIcon(Icons.drag_indicator),
              )
            : handle,
      );
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 600));
      for (var y = start.dy; y > destination.dy - 40; y -= 60) {
        await gesture.moveTo(Offset(195, y));
        await tester.pump(const Duration(milliseconds: 250));
      }
      await gesture.moveTo(Offset(195, destination.dy - 40));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('category-custom-fit'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('category-fork'))).dy,
        ),
      );
      expect(find.text('480'), findsOneWidget);
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(find.text('Anordnung übernehmen?'), findsOneWidget);
      await tester.tap(
        find.text(applyAll ? 'Für alle übernehmen' : 'Nur dieses Setup'),
      );
      await tester.pumpAndSettle();
      expect(provider.bikes.first.setups.first.categoryOrder, [
        'custom-fit',
        'fork',
        'shock',
        'tires',
      ]);
      expect(
        provider.bikes.first.setups.last.categoryOrder.isNotEmpty,
        applyAll,
      );
      expect(provider.bikes.last.setups.first.categoryOrder, isEmpty);
      for (var i = 0; i < 2; i++) {
        expect(
          provider.bikes.first.setups[i].toMap()..remove('categoryOrder'),
          before[i]..remove('categoryOrder'),
        );
      }
      await provider.saveToDevice();
      await provider.loadFromDevice();
      expect(
        provider.bikes.first.setups.first.categoryOrder.first,
        'custom-fit',
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('category-custom-fit'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('category-fork'))).dy,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('finish asks and saves with applyAll=$applyAll', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = await loadProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(
            home: SetupDetailScreen(bikeId: 'a', setupId: 'a-0'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Felder anordnen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(find.text('Anordnung übernehmen?'), findsNothing);
      await tester.tap(find.byTooltip('Felder anordnen'));
      await tester.pumpAndSettle();
      await dragField(tester, 'forkLsr', 'forkPsi');
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(find.text('Anordnung übernehmen?'), findsOneWidget);
      await tester.tap(
        find.text(applyAll ? 'Für alle übernehmen' : 'Nur dieses Setup'),
      );
      await tester.pumpAndSettle();
      expect(
        provider.bikes.first.setups.first.fieldOrders['fork']!.first,
        'forkLsr',
      );
      expect(provider.bikes.first.setups.last.fieldOrders.isNotEmpty, applyAll);
      expect(provider.bikes.last.setups.first.fieldOrders, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('one setup saves without question and cancel discards changes', (
    tester,
  ) async {
    final provider = await loadProvider(setups: 1);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: const MaterialApp(
          home: SetupDetailScreen(bikeId: 'a', setupId: 'a-0'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Felder anordnen'));
    await tester.pumpAndSettle();
    await dragField(tester, 'forkLsr', 'forkPsi');
    await tester.tap(find.byTooltip('Abbrechen'));
    await tester.pumpAndSettle();
    expect(provider.bikes.first.setups.first.fieldOrders, isEmpty);
    await tester.tap(find.byTooltip('Felder anordnen'));
    await tester.pumpAndSettle();
    await dragField(tester, 'forkLsr', 'forkPsi');
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    expect(find.text('Anordnung übernehmen?'), findsNothing);
    expect(
      provider.bikes.first.setups.first.fieldOrders['fork']!.first,
      'forkLsr',
    );
    expect(tester.takeException(), isNull);
  });
}
