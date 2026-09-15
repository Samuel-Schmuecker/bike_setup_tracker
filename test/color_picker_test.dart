import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/widgets/color_picker_dialog.dart';

void main() {
  testWidgets(
    'Palette selects white and black and cancellation returns no color',
    (tester) async {
      Color? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<Color>(
                    context: context,
                    builder: (_) =>
                        const ColorPickerDialog(color: Colors.red, lang: 'de'),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final palette = find.byKey(const ValueKey('color-palette'));
      await tester.tapAt(tester.getTopLeft(palette));
      await tester.pump();
      await tester.tap(find.text('Farbe übernehmen'));
      await tester.pumpAndSettle();
      expect(result?.toARGB32(), 0xFFFFFFFF);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(palette));
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 300));
      await gesture.up();
      await tester.pump();
      await tester.tap(find.text('Farbe übernehmen'));
      await tester.pumpAndSettle();
      expect(result?.toARGB32(), 0xFF000000);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
