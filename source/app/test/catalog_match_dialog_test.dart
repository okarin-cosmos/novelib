import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/catalog/catalog_database.dart';
import 'package:chronovel/data/demo_games.dart';
import 'package:chronovel/features/library/catalog_match_dialog.dart';

void main() {
  late CatalogDatabase catalog;
  setUp(
    () => catalog = CatalogDatabase.openExisting(
      'assets/catalog/chronovel_catalog.sqlite',
    ),
  );
  tearDown(() => catalog.close());
  Future<void> open(
    WidgetTester tester,
    Future<void> Function(CatalogWork) save,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CatalogMatchDialog(
                  game: demoGames.first,
                  catalog: catalog,
                  onSave: save,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), '9-nine-はるいろ');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('9-nine-はるいろはるこいはるのかぜ'));
    await tester.pumpAndSettle();
  }

  testWidgets('候補の検索・選択・確定で正しい作品IDを渡す', (tester) async {
    CatalogWork? saved;
    await open(tester, (work) async {
      saved = work;
    });
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await select(tester);
    expect(saved, isNull);
    await tester.tap(find.text('この作品に変更'));
    await tester.pumpAndSettle();
    expect(saved?.vndbId, 'v23740');
    expect(find.byType(CatalogMatchDialog), findsNothing);
  });
  testWidgets('キャンセルでは変更しない', (tester) async {
    var saves = 0;
    await open(tester, (_) async {
      saves++;
    });
    await select(tester);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(saves, 0);
  });
  testWidgets('保存失敗時は候補を保持して再試行できる', (tester) async {
    var attempts = 0;
    await open(tester, (_) async {
      if (++attempts == 1) throw StateError('test');
    });
    await select(tester);
    await tester.tap(find.text('この作品に変更'));
    await tester.pumpAndSettle();
    expect(find.textContaining('保存できませんでした'), findsOneWidget);
    await tester.tap(find.text('この作品に変更'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(CatalogMatchDialog), findsNothing);
  });
}
