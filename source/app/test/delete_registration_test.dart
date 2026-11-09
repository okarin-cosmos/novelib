import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/app.dart';
import 'package:chronovel/data/demo_games.dart';
import 'package:chronovel/features/library/delete_registration_dialog.dart';
import 'package:chronovel/features/library/game_detail_page.dart';

void main() {
  testWidgets('ゲーム起動中・スキャン中は詳細画面の削除を無効化する', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final running in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameDetailPage(
              game: demoGames.first,
              onBack: () {},
              onStatusChanged: (_, status) {},
              onRatingChanged: (_, rating) {},
              onLaunchRequested: (_) {},
              isRunning: running,
              deletionBlocked: !running,
              onMetadataChanged: (_) async {},
              onDeleteRequested: (_) async {},
            ),
          ),
        ),
      );
      final button = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'ゲーム起動中・スキャン中は削除できません',
      );
      expect(tester.widget<IconButton>(button).onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
  Future<void> open(
    WidgetTester tester,
    Future<void> Function(String) callback,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => DeleteRegistrationDialog(
                  game: demoGames.first,
                  onDelete: callback,
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

  testWidgets('キャンセルでは削除しない', (tester) async {
    var count = 0;
    await open(tester, (_) async {
      count++;
    });
    expect(find.textContaining('登録ID：${demoGames.first.id}'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(count, 0);
  });
  testWidgets('削除中は二重実行を防ぎ指定IDだけ渡す', (tester) async {
    final pending = Completer<void>();
    final ids = <String>[];
    await open(tester, (id) {
      ids.add(id);
      return pending.future;
    });
    await tester.tap(find.text('この登録先を削除'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'キャンセル'))
          .onPressed,
      isNull,
    );
    expect(ids, [demoGames.first.id]);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DeleteRegistrationDialog), findsNothing);
  });
  testWidgets('保存失敗時はダイアログを残して再試行できる', (tester) async {
    var attempts = 0;
    await open(tester, (_) async {
      if (++attempts == 1) throw StateError('test');
    });
    await tester.tap(find.text('この登録先を削除'));
    await tester.pumpAndSettle();
    expect(find.textContaining('削除できませんでした'), findsOneWidget);
    await tester.tap(find.text('この登録先を削除'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(DeleteRegistrationDialog), findsNothing);
  });
  testWidgets('詳細画面から削除するとライブラリへ戻る', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChronovelApp());
    await tester.tap(find.text('霧港のアリア'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('この登録先を削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この登録先を削除'));
    await tester.pumpAndSettle();
    expect(find.text('霧港のアリア'), findsNothing);
    expect(find.text('作品詳細'), findsNothing);
    expect(find.text('ライブラリ'), findsWidgets);
    expect(find.text('あかつきの残響'), findsOneWidget);
  });
}
