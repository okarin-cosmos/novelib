import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/features/board/board_page.dart';
import 'package:chronovel/models/game.dart';

import 'library_sort_test.dart' show game;

void main() {
  for (final width in [320.0, 600.0, 1180.0]) {
    testWidgets('積み棚 幅$width で表示できる', (tester) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoardPage(
              games: [game('1', 'テスト作品')],
              onStatusChanged: (_, _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('テスト作品'), findsOneWidget);
      expect(find.byTooltip('状態を変更'), findsOneWidget);
    });
  }

  testWidgets('カードのメニューで状態を変更できる', (tester) async {
    String? changedId;
    GameStatus? changedStatus;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardPage(
            games: [game('work-1', 'テスト作品')],
            onStatusChanged: (id, status) {
              changedId = id;
              changedStatus = status;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('状態を変更'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('プレイ中').last);
    await tester.pumpAndSettle();
    expect(changedId, 'work-1');
    expect(changedStatus, GameStatus.playing);
  });
}
