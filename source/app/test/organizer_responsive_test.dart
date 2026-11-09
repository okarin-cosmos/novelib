import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/features/records/organizer_page.dart';

import 'library_sort_test.dart' show game;

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  for (final width in [320.0, 900.0]) {
    testWidgets('ウィッシュリスト 幅$width で未登録作品を表示', (tester) async {
      tester.view.physicalSize = Size(width, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await db.writeSetting('purchase.plans', '["未登録の長い作品タイトル"]');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrganizerPage(
              db: db,
              games: [game('1', '長い作品タイトル')],
              onOpen: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('未登録の長い作品タイトル'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Ctrl+Fで絞り込みへ移動しEscで解除', (tester) async {
    await db.writeSetting('purchase.plans', '["未登録作品"]');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizerPage(db: db, games: [game('1', '作品')], onOpen: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), '該当なし');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(field.controller!.text, isEmpty);
    expect(find.text('未登録作品'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('登録済み作品はウィッシュリストから自動除外', (tester) async {
    await db.writeSetting('purchase.plans', '["作品", "未登録作品"]');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrganizerPage(db: db, games: [game('1', '作品')], onOpen: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('作品'), findsNothing);
    expect(find.text('未登録作品'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
