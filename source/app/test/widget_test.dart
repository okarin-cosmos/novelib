import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/app.dart';
import 'package:chronovel/catalog/catalog_database.dart';
import 'package:chronovel/features/library/library_page.dart';

void main() {
  testWidgets('画像未照合の一覧から作品詳細へ進める', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChronovelApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('画像・照合を確認'));
    await tester.pumpAndSettle();
    expect(find.textContaining('未照合は画像の再取得だけでは'), findsOneWidget);
    await tester.tap(find.text('候補を選ぶ').first);
    await tester.pumpAndSettle();
    expect(find.text('作品詳細'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('作品情報を編集して保存・キャンセルできる', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChronovelApp());
    await tester.tap(find.text('霧港のアリア'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('情報を編集'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('タイトルを入力してください'), findsOneWidget);
    await tester.enterText(fields.at(0), '手動タイトル');
    await tester.enterText(fields.at(1), '手動ブランド');
    await tester.enterText(fields.at(2), '2024-02-29');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('手動タイトル'), findsWidgets);
    expect(find.text('手動ブランド'), findsWidgets);
    await tester.tap(find.text('情報を編集'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'キャンセル対象');
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('キャンセル対象'), findsNothing);
  });
  testWidgets('ライブラリ画面を表示して検索できる', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChronovelApp());
    await tester.pumpAndSettle();

    expect(find.text('ライブラリ'), findsWidgets);
    expect(find.text('霧港のアリア'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '星屑');
    await tester.pump();

    expect(find.text('星屑インデックス'), findsOneWidget);
    expect(find.text('霧港のアリア'), findsNothing);
  });

  testWidgets('プレイ状況へ移動できる', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChronovelApp());
    await tester.tap(find.text('プレイ状況'));
    await tester.pumpAndSettle();

    expect(find.textContaining('状態をすばやく変更できます'), findsOneWidget);
    for (final label in ['未プレイ', 'プレイ中', 'クリア', 'コンプ']) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('別画面からライブラリへ戻っても状態フィルターを保持する', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChronovelApp());
    await tester.pumpAndSettle();

    final playingFilterFinder = find.byWidgetPredicate(
      (widget) => widget is FilterChipButton && widget.label == 'プレイ中',
      description: 'プレイ中の状態フィルター',
    );
    await tester.tap(playingFilterFinder);
    await tester.pumpAndSettle();
    expect(find.text('雪見坂ノスタルジア'), findsOneWidget);
    expect(find.text('霧港のアリア'), findsNothing);

    await tester.tap(find.text('プレイ状況'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ライブラリ'));
    await tester.pumpAndSettle();

    final playingFilter = tester.widget<FilterChipButton>(playingFilterFinder);
    expect(playingFilter.selected, isTrue);
    expect(find.text('雪見坂ノスタルジア'), findsOneWidget);
    expect(find.text('霧港のアリア'), findsNothing);
  });

  testWidgets('ライブラリ画面の視覚基準', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChronovelApp());
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/branding/novelib_icon.png'),
        tester.element(find.byType(Scaffold)),
      );
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/library_1440x900.png'),
    );
  });

  testWidgets('作品カタログを開いて正式名称を検索できる', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = CatalogDatabase.openExisting(
      'assets/catalog/chronovel_catalog.sqlite',
    );
    addTearDown(catalog.close);

    await tester.pumpWidget(ChronovelApp(catalog: catalog));
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('作品カタログを見る'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('作品カタログを見る'));
    await tester.pumpAndSettle();

    expect(find.text('国内ビジュアルノベル 37493 作品を収録'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'はるいろはるこい');
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('9-nine-はるいろはるこいはるのかぜ'), findsOneWidget);
  });

  testWidgets('確認後に作品をライブラリから削除できる', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChronovelApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ステータスと作品操作').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ライブラリから削除'));
    await tester.pumpAndSettle();

    expect(find.text('ライブラリから削除しますか？'), findsOneWidget);
    expect(find.textContaining('ゲーム本体やインストールフォルダは削除されません'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('霧港のアリア'), findsOneWidget);

    await tester.tap(find.byTooltip('ステータスと作品操作').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ライブラリから削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(find.text('霧港のアリア'), findsNothing);
    expect(find.text('1 本をライブラリから削除しました。'), findsOneWidget);
  });

  testWidgets('作品カードをクリックして詳細画面へ移動できる', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChronovelApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('霧港のアリア'));
    await tester.pumpAndSettle();

    expect(find.text('作品詳細'), findsOneWidget);
    expect(find.text('ブランド／開発元'), findsOneWidget);
    expect(find.text('保存場所'), findsOneWidget);
    expect(find.text('ゲームを起動'), findsOneWidget);
    await tester.tap(find.text('9'));
    await tester.pumpAndSettle();
    expect(find.text('9 / 10'), findsWidgets);
    await tester.tap(find.text('評価を解除'));
    await tester.pumpAndSettle();
    expect(find.text('未評価'), findsWidgets);
    await tester.tap(find.byTooltip('ライブラリへ戻る'));
    await tester.pumpAndSettle();
    expect(find.text('ライブラリ'), findsWidgets);
  });

  testWidgets('複数作品を選択してまとめて削除できる', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChronovelApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('選択'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('霧港のアリア'));
    await tester.tap(find.text('あかつきの残響'));
    await tester.pumpAndSettle();

    expect(find.text('2 本選択'), findsOneWidget);
    await tester.tap(find.text('まとめて削除'));
    await tester.pumpAndSettle();
    expect(find.text('2 本をライブラリから削除しますか？'), findsOneWidget);
    await tester.tap(find.text('まとめて削除').last);
    await tester.pumpAndSettle();

    expect(find.text('霧港のアリア'), findsNothing);
    expect(find.text('あかつきの残響'), findsNothing);
    expect(find.text('2 本をライブラリから削除しました。'), findsOneWidget);
  });
}
