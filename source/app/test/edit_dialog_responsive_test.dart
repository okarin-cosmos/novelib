import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/features/library/game_edit_dialog.dart';
import 'package:chronovel/features/records/work_records_dialog.dart';
import 'package:chronovel/models/game.dart';

import 'library_sort_test.dart' show game;

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> openDialog(
    WidgetTester tester,
    Widget dialog,
    String title,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => dialog,
              ),
              child: const Text('開く'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    expect(find.textContaining(title), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  testWidgets('狭い画面で作品情報を編集できる', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    GameEdits? saved;
    await openDialog(
      tester,
      GameEditDialog(
        game: game('1', '作品'),
        onSave: (edits) async => saved = edits,
      ),
      '作品情報を編集',
    );
    await tester.enterText(find.byType(TextFormField).first, '変更後の作品名');
    await tester.scrollUntilVisible(
      find.text('全体設定に従う'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('全体設定に従う'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この作品だけぼかす').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    expect(saved?.title, '変更後の作品名');
    expect(saved?.blurCover, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('狭い画面で記録とプレイ履歴タブを表示', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openDialog(
      tester,
      WorkRecordsDialog(db: db, game: game('1', '作品')),
      '作品記録',
    );
    await tester.pumpAndSettle();
    expect(find.text('タグ・予定・攻略'), findsOneWidget);
    await tester.tap(find.text('プレイ履歴'));
    await tester.pumpAndSettle();
    expect(find.text('履歴を手動追加'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
