import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/features/records/insights_page.dart';
import 'package:chronovel/catalog/catalog_database.dart';
import 'package:chronovel/models/game.dart';
import 'package:chronovel/services/review_sync_service.dart';

import 'library_sort_test.dart' show game;

void main() {
  testWidgets('Supabase評価を表示し作品の公開コメントへ進める', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? requestedAdult;
    String? reportedId;
    final installed = GameEntry(
      id: '42',
      title: '端末側の作品名',
      brand: 'ブランド',
      status: GameStatus.notPlayed,
      playHours: 0,
      routeCurrent: 0,
      routeTotal: 0,
      coverColors: const [Colors.blue, Colors.black],
      vndbId: 'v24702',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightsPage(
            games: [installed],
            rankings: true,
            reviewApiEndpoint: 'https://example.test/review-api/',
            publicRankingsLoader: (includeAdult, limit, offset) async {
              requestedAdult = includeAdult;
              expect(limit, 20);
              expect(offset, 0);
              return const [
                PublicRatingSummary(
                  workId: 'v24702',
                  title: 'アオナツライン',
                  averageScore: 8.75,
                  ratingCount: 12,
                  publicCommentCount: 4,
                  isAdult: true,
                ),
              ];
            },
            publicCommentsLoader: (workId, includeAdult, limit, offset) async =>
                [
                  PublicReviewComment(
                    reviewId: 'review-1',
                    workId: workId,
                    score: 9,
                    comment: 'とても良かったです',
                    updatedAt: DateTime(2026, 9, 5),
                  ),
                ],
            onReportComment: (reviewId, reason, details) async {
              reportedId = reviewId;
            },
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requestedAdult, isTrue);
    expect(find.text('NoveLib総合ランキング 1位まで'), findsOneWidget);
    expect(find.text('アオナツライン'), findsOneWidget);
    expect(find.text('8.8'), findsOneWidget);
    expect(find.text('12件・コメント4件'), findsOneWidget);
    await tester.tap(find.text('アオナツライン'));
    await tester.pumpAndSettle();
    expect(find.text('最新コメント 1件'), findsOneWidget);
    expect(find.text('とても良かったです'), findsOneWidget);
    expect(find.text('9/10'), findsOneWidget);
    await tester.tap(find.byTooltip('このコメントを通報'));
    await tester.pumpAndSettle();
    expect(find.text('コメントを通報'), findsOneWidget);
    await tester.tap(find.text('通報する'));
    await tester.pumpAndSettle();
    expect(reportedId, 'review-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Supabase評価が空の場合は初期状態を案内', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightsPage(
            games: const [],
            rankings: true,
            publicRankingsLoader: (_, _, _) async => const [],
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('まだ共有評価がありません'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 560.0, 900.0]) {
    testWidgets('ランキング 幅$width で評価情報と遷移を維持', (tester) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final catalog = CatalogDatabase.openExisting(
        'assets/catalog/chronovel_catalog.sqlite',
      );
      addTearDown(catalog.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InsightsPage(
              games: [game('1', '長い作品タイトルのテスト', rating: 8)],
              catalog: catalog,
              rankings: true,
              onOpen: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1位'), findsOneWidget);
      expect(find.textContaining('VNDB利用者の公開投票'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('狭い統計画面でブランド集計を表示', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InsightsPage(
            games: [game('1', '作品', brand: '長いブランド名', rating: 7, hours: 12.5)],
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('長いブランド名'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('長いブランド名'), findsOneWidget);
    expect(find.textContaining('12.5 h'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
