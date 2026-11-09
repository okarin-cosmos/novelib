import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/models/game.dart';
import 'package:chronovel/features/records/record_store.dart';
import 'package:chronovel/features/records/data_transfer.dart';
import 'package:chronovel/features/records/work_records_dialog.dart';
import 'package:chronovel/features/records/insights_page.dart';
import 'package:chronovel/features/records/organizer_page.dart';
import 'package:chronovel/features/records/transfer_dialog.dart';
import 'package:chronovel/theme/app_theme.dart';

const entry = GameEntry(
  id: '1',
  title: 'テスト作品',
  brand: 'ブランド',
  status: GameStatus.notPlayed,
  playHours: 0,
  routeCurrent: 0,
  routeTotal: 0,
  coverColors: [Colors.blue, Colors.black],
  installDir: 'test-only',
);
void main() {
  late AppDatabase db;
  late RecordStore store;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    store = RecordStore(db);
    await db.upsertDetectedGame(
      title: 'テスト作品',
      installDir: 'test-only',
      exePath: 'test-only/game.exe',
      engine: 'kirikiri',
    );
  });
  tearDown(() async {
    await db.close();
  });
  test('タグ・ルート・予定は再スキャン後も残り削除時に除去', () async {
    final notes = WorkNotes(
      favorite: true,
      purchase: true,
      date: '2026-10-01',
      tags: ['長編', '長編'],
      memo: 'メモ',
      routes: [
        {'name': '共通', 'status': '完了', 'memo': '攻略'},
      ],
    );
    await store.save(1, notes);
    await db.upsertDetectedGame(
      title: '更新',
      installDir: 'test-only',
      exePath: 'test-only/game.exe',
      engine: 'kirikiri',
    );
    final loaded = await store.notes(1);
    expect(loaded.tags, ['長編']);
    expect(loaded.routes.single['status'], '完了');
    expect(loaded.favorite, true);
    expect(loaded.date, '2026-10-01');
    await db.deleteGame(1);
    expect(await db.readSetting('notes.1'), null);
  });
  test('存在しない予定日と不正ルートは保存しない', () async {
    expect(() => WorkNotes.decode('{"tags":[42]}'), throwsA(isA<TypeError>()));
    await expectLater(
      store.save(1, WorkNotes(date: '2026-02-30')),
      throwsFormatException,
    );
    await expectLater(
      store.save(
        1,
        WorkNotes(
          routes: [
            {'name': 'a', 'status': 'unknown', 'memo': ''},
          ],
        ),
      ),
      throwsFormatException,
    );
    expect(await db.readSetting('notes.1'), null);
  });
  test('手動履歴の追加・修正・削除が合計と最終プレイ日に反映', () async {
    final a = DateTime(2025, 1, 1, 12);
    await store.editSession(1, start: a, end: a.add(const Duration(hours: 2)));
    expect((await db.getGames()).single.totalPlaySec, 7200);
    var s = (await store.sessions(1)).single;
    await store.editSession(
      1,
      id: s.id,
      start: a,
      end: a.add(const Duration(hours: 1)),
    );
    expect((await db.getGames()).single.totalPlaySec, 3600);
    s = (await store.sessions(1)).single;
    await store.editSession(1, id: s.id, remove: true);
    expect((await db.getGames()).single.totalPlaySec, 0);
    expect((await db.getGames()).single.lastPlayedAt, null);
  });
  test('重複・未来・逆転した履歴は拒否して既存時間を保持', () async {
    final a = DateTime(2025, 1, 1);
    await store.editSession(1, start: a, end: a.add(const Duration(hours: 2)));
    await expectLater(
      store.editSession(1, start: a, end: a.add(const Duration(hours: 1))),
      throwsArgumentError,
    );
    await expectLater(
      store.editSession(1, start: a, end: a),
      throwsArgumentError,
    );
    await expectLater(
      store.editSession(
        1,
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 1)),
      ),
      throwsArgumentError,
    );
    expect((await db.getGames()).single.totalPlaySec, 7200);
    expect((await store.sessions()).length, 1);
  });
  test('別作品の履歴IDを編集できない', () async {
    await db.upsertDetectedGame(
      title: '別',
      installDir: 'other',
      exePath: 'other/g.exe',
      engine: 'manual',
    );
    final a = DateTime(2025);
    await store.editSession(1, start: a, end: a.add(const Duration(hours: 1)));
    final s = (await store.sessions()).single;
    await expectLater(
      store.editSession(2, id: s.id, remove: true),
      throwsStateError,
    );
    expect((await store.sessions()).length, 1);
  });
  test('年・月をまたぐ時間を現地時刻で分割', () {
    final sessions = [
      PlaySession(
        id: 1,
        gameId: 1,
        startedAt: DateTime(2024, 12, 31, 23).toUtc(),
        endedAt: DateTime(2025, 1, 1, 2).toUtc(),
      ),
    ];
    expect(periodSeconds(sessions), {'2024-12': 3600, '2025-01': 7200});
    expect(periodSeconds(sessions, yearly: true), {'2024': 3600, '2025': 7200});
  });
  test('全ユーザーテーブルのバックアップを別DBに復元', () async {
    await store.save(1, WorkNotes(tags: ['長編'], memo: '日本語'));
    await db.setGameRating(1, 8);
    await db.changeGameStatus(1, 'cleared');
    await db.saveScanFolder('test-only');
    await db.writeSetting('purchase.plans', jsonEncode(['未登録作品']));
    final a = DateTime(2025);
    await store.editSession(1, start: a, end: a.add(const Duration(hours: 1)));
    final backup = await LibraryBackup.parse(
      (await LibraryBackup.capture(db)).encode(),
    );
    final other = AppDatabase(NativeDatabase.memory());
    try {
      await backup.restore(other);
      expect((await other.getGames()).single.rating, 8);
      expect(await other.playSessionCount(), 1);
      expect(await other.statusHistoryCount(), 1);
      expect(await other.getScanFolders(), ['test-only']);
      expect((await RecordStore(other).notes(1)).memo, '日本語');
      expect(await other.readSetting('purchase.plans'), jsonEncode(['未登録作品']));
    } finally {
      await other.close();
    }
  });

  test('評価点とコメントを保存してPostgreSQL同期待ちにする', () async {
    await db.setGameReview(1, 9, 'とても良かった');
    final record = (await db.getGames()).single;
    expect(record.rating, 9);
    expect(record.ratingComment, 'とても良かった');
    expect(record.reviewSyncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(record.reviewSyncState, 'pending_upsert');
    expect(await db.pendingReviewSync(), hasLength(1));

    await db.setGameReview(1, null, '');
    final removed = (await db.getGames()).single;
    expect(removed.rating, isNull);
    expect(removed.ratingComment, isNull);
    expect(removed.reviewSyncState, 'pending_delete');
  });
  test('不正な復元データの挿入に失敗しても元データをロールバック', () async {
    final b = await LibraryBackup.capture(db);
    final bad = LibraryBackup(
      [...b.games, ...b.games],
      b.sessions,
      b.history,
      b.folders,
      b.settings,
    );
    await expectLater(bad.restore(db), throwsA(anything));
    expect((await db.getGames()).single.title, 'テスト作品');
  });
  test('不正バージョン・外部キー・評価・設定形式を復元前に拒否', () async {
    final original = (await LibraryBackup.capture(db)).encode();
    for (final mode in ['version', 'rating', 'settings', 'sessions']) {
      final j = jsonDecode(original) as Map<String, dynamic>;
      if (mode == 'version') j['version'] = 999;
      if (mode == 'rating') j['games'][0]['rating'] = 11;
      if (mode == 'settings') {
        j['settings'] = [
          {'key': 'notes.1', 'value': '{"routes":[{"name":"a","status":4}]}'},
        ];
      }
      if (mode == 'sessions') {
        j['sessions'] = [
          PlaySession(
            id: 1,
            gameId: 999,
            startedAt: DateTime(2025),
            endedAt: DateTime(2025, 1, 1, 1),
          ).toJson(),
        ];
      }
      await expectLater(LibraryBackup.parse(jsonEncode(j)), throwsA(anything));
    }
    expect((await db.getGames()).single.title, 'テスト作品');
  });
  test('CSVは日本語・引用符・改行・数式入力を安全に保持', () {
    final csv = libraryCsv([
      entry.copyWith(edits: const GameEdits(title: ' =SUM(1,2)\n"試験"')),
    ]);
    expect(csv.startsWith('\uFEFF'), true);
    expect(csv, contains("' =SUM(1,2)"));
    expect(csv, contains('""試験""'));
    expect(csv, contains('ブランド'));
  });
  void screen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final outcome in ['cancel', 'save-cancel', 'save-error', 'restore']) {
    testWidgets('復元画面: $outcome', (tester) async {
      screen(tester);
      final backup = (await LibraryBackup.capture(db)).encode();
      await db.setGameRating(1, 9);
      var saved = 0, restored = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: TransferDialog(
              db: db,
              games: [entry],
              onRestored: () async {
                restored++;
              },
              readBackup: () async => backup,
              writeBackup: (text, prefix, extension) async {
                saved++;
                expect((jsonDecode(text) as Map)['games'][0]['rating'], 9);
                if (outcome == 'save-error') throw StateError('退避先エラー');
                return outcome == 'save-cancel'
                    ? null
                    : 'test-only-before-restore.json';
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('JSONから復元'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('バックアップから復元しますか？'), findsOneWidget);
      await tester.tap(
        find.text(outcome == 'cancel' ? 'キャンセル' : '現在のデータを退避して復元'),
      );
      await tester.pumpAndSettle();
      expect(
        (await db.getGames()).single.rating,
        outcome == 'restore' ? null : 9,
      );
      expect(restored, outcome == 'restore' ? 1 : 0);
      expect(saved, outcome == 'cancel' ? 0 : 1);
      if (outcome == 'restore') {
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'CSVを保存'),
              )
              .onPressed,
          null,
        );
      }
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
  testWidgets('記録フォームからお気に入り・タグを保存', (tester) async {
    screen(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showDialog<void>(
                context: c,
                builder: (_) => WorkRecordsDialog(db: db, game: entry),
              ),
              child: const Text('開く'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AlertDialog),
      matchesGoldenFile('goldens/records_dialog.png'),
    );
    await tester.tap(find.text('お気に入り'));
    await tester.enterText(
      find.widgetWithText(TextField, 'タグ（カンマ区切りで作成・変更・付与）'),
      '長編,考察',
    );
    await tester.tap(find.text('タグ・予定・攻略を保存'));
    await tester.pumpAndSettle();
    expect((await store.notes(1)).favorite, true);
    expect((await store.notes(1)).tags, ['長編', '考察']);
    expect(tester.takeException(), null);
  });
  testWidgets('起動中は履歴追加が無効', (tester) async {
    screen(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: WorkRecordsDialog(db: db, game: entry, historyBlocked: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('プレイ履歴'));
    await tester.pumpAndSettle();
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '履歴を手動追加'),
    );
    expect(button.onPressed, null);
    expect(tester.takeException(), null);
  });
  testWidgets('統計とランキングは小数第1位・同点順位を表示', (tester) async {
    screen(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: InsightsPage(
            games: [entry.copyWith(rating: 8)],
            db: db,
            onOpen: (_) {},
            rankings: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ランキングを表示できません'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: InsightsPage(
            games: [entry.copyWith(rating: 8)],
            db: db,
            onOpen: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('平均評価'), findsOneWidget);
    expect(find.text('8.0/10'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets('ウィッシュリストは登録済み作品を除外', (tester) async {
    screen(tester);
    await db.writeSetting('purchase.plans', jsonEncode(['テスト作品', '未登録作品']));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: OrganizerPage(db: db, games: [entry], onOpen: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('テスト作品'), findsNothing);
    expect(find.text('未登録作品'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
