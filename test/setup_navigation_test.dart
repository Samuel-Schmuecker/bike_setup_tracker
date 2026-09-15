import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bike_setup_tracker/providers/bike_provider.dart';
import 'package:bike_setup_tracker/providers/language_provider.dart';
import 'package:bike_setup_tracker/screens/bike_detail/setup_detail_screen.dart';
import 'field_order_test.dart' show loadProvider;

void main() {
  testWidgets('swipes and ordering lock without navigation header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = await loadProvider(setups: 3);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BikeProvider>.value(value: provider),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const SetupDetailScreen(bikeId: 'a', setupId: 'a-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    double currentPage() =>
        tester.widget<PageView>(find.byType(PageView)).controller!.page!;
    expect(find.text('Setup 2 von 3'), findsNothing);
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(currentPage(), 1);
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(currentPage(), 2);
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(currentPage(), 2);
    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(currentPage(), 1);
    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(currentPage(), 0);
    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(currentPage(), 0);
    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(currentPage(), 0);
    expect(tester.takeException(), isNull);
  });
}
