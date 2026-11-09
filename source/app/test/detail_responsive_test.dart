import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/features/library/game_detail_page.dart';

import 'library_sort_test.dart' show game;

void main() {
  for (final width in [400.0, 774.0, 1180.0]) {
    testWidgets('詳細画面 幅$width で操作と情報を表示', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var records = 0;
      var matches = 0;
      var backs = 0;
      int? rating;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameDetailPage(
              game: game('1', '長い作品タイトル・テスト作品', rating: 5),
              onBack: () => backs++,
              onStatusChanged: (_, _) {},
              onRatingChanged: (_, value) => rating = value,
              onLaunchRequested: (_) {},
              isRunning: false,
              onMetadataChanged: (_) async {},
              onRecordsRequested: () => records++,
              onCatalogMatchRequested: () => matches++,
              onDeleteRequested: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('作品記録'));
      await tester.tap(find.text('カタログを選び直す'));
      expect(records, 1);
      expect(matches, 1);
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, '10'));
      await tester.tap(find.widgetWithText(ChoiceChip, '10'));
      expect(rating, 10);
      await tester.ensureVisible(find.text('実行ファイル'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('ライブラリへ戻る'));
      expect(backs, 1);
    });
  }

  testWidgets('評価の点数とコメントを保存できる', (tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? savedRating;
    String? savedComment;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameDetailPage(
            game: game('1', '評価テスト', rating: 7),
            onBack: () {},
            onStatusChanged: (_, _) {},
            onRatingChanged: (_, _) {},
            onReviewChanged: (_, rating, comment) async {
              savedRating = rating;
              savedComment = comment;
            },
            onLaunchRequested: (_) {},
            isRunning: false,
            onMetadataChanged: (_) async {},
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(TextField, '評価コメント'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextField, '評価コメント'),
      '心に残る作品でした。',
    );
    await tester.tap(find.text('コメントを保存'));
    await tester.pumpAndSettle();

    expect(savedRating, 7);
    expect(savedComment, '心に残る作品でした。');
    expect(find.text('評価コメントを保存しました。'), findsOneWidget);
  });

  testWidgets('作品画像の下から個別ぼかしを切り替えられる', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? savedBlur;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameDetailPage(
            game: game('1', 'ぼかしテスト'),
            blurCovers: false,
            onCoverBlurChanged: (value) async => savedBlur = value,
            onBack: () {},
            onStatusChanged: (_, _) {},
            onRatingChanged: (_, _) {},
            onLaunchRequested: (_) {},
            isRunning: false,
            onMetadataChanged: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('detail-cover-blur-toggle'));
    expect(find.text('表紙をぼかす'), findsOneWidget);
    expect(tester.getTopLeft(toggle).dy, greaterThan(420));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(savedBlur, isTrue);
  });
}
