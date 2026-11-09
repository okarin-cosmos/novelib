import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/catalog/catalog_database.dart';
import 'package:chronovel/features/catalog/catalog_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CatalogDatabase catalog;
  setUp(
    () => catalog = CatalogDatabase.openExisting(
      'assets/catalog/chronovel_catalog.sqlite',
    ),
  );
  tearDown(() => catalog.close());

  for (final width in [320.0, 700.0, 1100.0]) {
    testWidgets('作品カタログ 幅$width で検索結果を表示', (tester) async {
      tester.view.physicalSize = Size(width, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CatalogPage(catalog: catalog)),
        ),
      );
      await tester.enterText(find.byType(TextField), 'アオナツライン');
      await tester.pump(const Duration(milliseconds: 220));
      expect(
        find.descendant(
          of: find.byType(CatalogWorkRow),
          matching: find.text('アオナツライン'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Ctrl+Fで検索へ移動しEscで検索を消去', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CatalogPage(catalog: catalog)),
      ),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), '検索語');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(field.controller!.text, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
