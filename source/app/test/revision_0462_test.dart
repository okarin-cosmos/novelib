import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/app.dart';
import 'package:chronovel/features/library/library_page.dart';
import 'package:chronovel/features/records/insights_page.dart';
import 'package:chronovel/models/game.dart';
import 'package:chronovel/services/review_sync_service.dart';

void main() {
  testWidgets('library filter survives navigation and can return to all', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChronovelApp());
    await tester.pumpAndSettle();
    final playing = find.descendant(
      of: find.byType(FilterChipButton),
      matching: find.textContaining('プレイ中'),
    );
    await tester.tap(playing);
    await tester.pumpAndSettle();
    final selected = tester
        .widget<LibraryPage>(find.byType(LibraryPage))
        .initialFilter;
    expect(selected, isNotNull);
    for (final destination in ['プレイ状況', '設定']) {
      await tester.tap(find.text(destination).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ライブラリ').first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<LibraryPage>(find.byType(LibraryPage)).initialFilter,
        selected,
      );
    }
    await tester.tap(
      find.descendant(
        of: find.byType(FilterChipButton),
        matching: find.textContaining('すべて'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<LibraryPage>(find.byType(LibraryPage)).initialFilter,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  const valid =
      'https://al.fanza.co.jp/?af_id=test-990&lurl=https%3A%2F%2Fdlsoft.dmm.co.jp%2Fdetail%2Fx%2F';
  for (final scenario in [
    (true, valid, true),
    (false, valid, false),
    (true, 'https://evil.test', false),
    (true, null, false),
  ]) {
    testWidgets('PR visibility: $scenario', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InsightsPage(
              games: const <GameEntry>[],
              rankings: true,
              showAdult: scenario.$1,
              onOpen: (_) {},
              publicRankingsLoader: (_, _, _) async => [
                PublicRatingSummary(
                  workId: 'v1',
                  title: 'テスト作品',
                  averageScore: 8,
                  ratingCount: 1,
                  isAdult: false,
                  fanzaUrl: scenario.$2,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('PR｜FANZAで見る'),
        scenario.$3 ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
