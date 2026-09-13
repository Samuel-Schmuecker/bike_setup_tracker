import 'dart:convert';
import 'dart:ui' as ui;

import 'package:bike_setup_tracker/widgets/image_toolbar_contrast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> imagePath(Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(color, BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(40, 40);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return 'data:image/png;base64,${base64Encode(bytes!.buffer.asUint8List())}';
}

void main() {
  testWidgets('toolbar adapts to replacement images and collapsed surface', (
    tester,
  ) async {
    final light = await tester.runAsync(() => imagePath(Colors.white));
    final dark = await tester.runAsync(() => imagePath(Colors.black));
    final controller = ScrollController();
    addTearDown(controller.dispose);

    Future<void> show(String path) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CustomScrollView(
              controller: controller,
              slivers: [
                ImageToolbarContrast(
                  imagePath: path,
                  expandedHeight: 240,
                  builder: (context, color) => SliverAppBar(
                    expandedHeight: 240,
                    pinned: true,
                    iconTheme: IconThemeData(color: color),
                    actionsIconTheme: IconThemeData(color: color),
                    leading: const BackButton(),
                    actions: [
                      IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 1600)),
              ],
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        await precacheImage(
          MemoryImage(base64Decode(path.split(',').last)),
          tester.element(find.byType(ImageToolbarContrast)),
        );
        // Allow the decoded image's pixel readback to finish.
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
    }

    Color? color() => tester
        .widget<SliverAppBar>(find.byType(SliverAppBar))
        .actionsIconTheme!
        .color;

    await show(light!);
    expect(color(), Colors.black);
    controller.jumpTo(240);
    await tester.pumpAndSettle();
    expect(color(), Colors.white);
    controller.jumpTo(0);
    await show(dark!);
    expect(color(), Colors.white);
    await show(light);
    expect(color(), Colors.black);
    expect(tester.takeException(), isNull);
  });
}
