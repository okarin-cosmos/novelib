import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/services/cover_image_cache.dart';
import 'package:chronovel/features/settings/maintenance_dialogs.dart';
import 'package:chronovel/models/game.dart';
import 'package:chronovel/scanner/game_scanner.dart';

class RecordingCache extends CoverImageCache {
  RecordingCache() : super.forDirectory(Directory('.'));
  Set<String>? removedIds;
  final refreshed = <String>[];
  @override
  Future<bool> refreshImage(String id, String url) async {
    refreshed.add(id);
    return id == 'v1';
  }

  @override
  Future<int> removeImages(
    Set<String> ids, {
    Iterable<String> protectedPaths = const [],
  }) async {
    removedIds = ids;
    return ids.length;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('一括再取得は成功失敗を表示し手動画像を除外する', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cache = RecordingCache();
    final games = [
      for (final id in ['v1', 'v2', 'v3'])
        GameEntry(
          id: id,
          title: id,
          brand: 'ブランド',
          status: GameStatus.notPlayed,
          playHours: 0,
          routeCurrent: 0,
          routeTotal: 0,
          coverColors: const [Colors.blue, Colors.black],
          vndbId: id,
          coverImageUrl: 'https://example.invalid/$id.jpg',
          localCoverPath: id == 'v3' ? 'D:/manual.jpg' : null,
        ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImageManagementDialog(games: games, cache: cache),
        ),
      ),
    );
    await tester.tap(find.text('すべて選択'));
    await tester.pump();
    await tester.tap(find.text('選択画像を再取得'));
    await tester.pumpAndSettle();
    expect(cache.refreshed, ['v1', 'v2']);
    expect(find.textContaining('成功 1、失敗 1、対象外（URLなし・手動画像） 1'), findsOneWidget);
  });
  test('未検出のフォルダとインストーラーのみの理由を記録する', () async {
    final dir = await Directory.systemTemp.createTemp('chronovel_diagnostic_');
    addTearDown(() => dir.delete(recursive: true));
    await Directory(p.join(dir.path, 'empty')).create();
    final installer = await Directory(p.join(dir.path, 'install-only'))
        .create();
    await File(p.join(installer.path, 'setup.exe'))
        .writeAsString('not executed');
    final scanner = GameScanner();
    expect(await scanner.scan(dir.path), isEmpty);
    expect(
      scanner.warnings.any(
        (w) => w.contains('インストーラーのみ') && w.contains('install-only'),
      ),
      isTrue,
    );
    expect(
      scanner.warnings.any((w) => w.contains('本体を未検出') && w.endsWith('empty')),
      isTrue,
    );
  });
  test('診断結果はDBを開き直しても残る', () async {
    final dir = await Directory.systemTemp.createTemp(
      'chronovel_diagnostic_db_',
    );
    final file = File(p.join(dir.path, 'test.sqlite'));
    var db = AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
    await db.writeSetting('scan.diagnostics.v1', '{"folder":["未検出"]}');
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    expect(await db.readSetting('scan.diagnostics.v1'), contains('未検出'));
  });
  testWidgets('診断一覧から未照合の詳細と未検出パスを渡す', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? opened, directory;
    final game = GameEntry(
      id: '42',
      title: '未照合作品',
      brand: '不明',
      status: GameStatus.notPlayed,
      playHours: 0,
      routeCurrent: 0,
      routeTotal: 0,
      coverColors: const [Colors.blue, Colors.black],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScanDiagnosticsDialog(
            games: [game],
            reports: const ['[2026-09-04] 対応データ未確認: D:/games/test'],
            imageFailures: [
              ImageFailureRecord(
                id: 'v99',
                url: 'https://example.invalid/cover.jpg',
                message: '通信がタイムアウトしました',
                occurredAt: DateTime.utc(2026, 9, 4, 12, 30),
                attempts: 3,
              ),
            ],
            onOpen: (id) => opened = id,
            onRegister: (path) => directory = path,
          ),
        ),
      ),
    );
    await tester.tap(find.text('詳細で照合'));
    expect(opened, '42');
    await tester.tap(find.text('未検出・除外の理由'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('手動登録'));
    expect(directory, 'D:/games/test');
    await tester.tap(find.text('画像取得エラー'));
    await tester.pumpAndSettle();
    expect(find.textContaining('通信がタイムアウトしました'), findsOneWidget);
    expect(find.textContaining('3回'), findsOneWidget);
  });
  test('手動登録は既存の評価・照合・履歴を保持し再スキャンでも起動先を保持', () async {
    final dir = await Directory.systemTemp.createTemp('chronovel_manual_');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
    final exe = await File(p.join(dir.path, 'game.exe'))
        .writeAsString('not executed');
    final id = await db.registerManualGame('手動作品', exe.path);
    await db.setGameRating(id, 8);
    await db.selectCatalogWork(id, 'v11', 'Fate/stay night');
    await db.recordPlaySession(
      gameId: id,
      startedAt: DateTime.utc(2026),
      endedAt: DateTime.utc(2026).add(const Duration(minutes: 5)),
    );
    final second = await File(p.join(dir.path, 'game2.exe'))
        .writeAsString('not executed');
    expect(await db.registerManualGame('別タイトル', second.path), id);
    await db.upsertDetectedGame(
      title: '自動タイトル',
      installDir: dir.path,
      exePath: exe.path,
      engine: 'kirikiri',
      vndbId: 'v50',
    );
    final row = (await db.getGames()).single;
    expect(row.exePath, second.path);
    expect(row.rating, 8);
    expect(row.totalPlaySec, 300);
    expect(row.vndbId, 'v11');
    expect(row.title, 'Fate/stay night');
    await expectLater(db.registerManualGame('', exe.path), throwsArgumentError);
    await expectLater(
      db.registerManualGame('名前', p.join(dir.path, 'missing.exe')),
      throwsArgumentError,
    );
    await db.writeSetting('scan.diagnostics.v1', '{"folder":["未検出"]}');
    expect(await db.readSetting('scan.diagnostics.v1'), contains('未検出'));
  });
  test('画像削除は指定IDのみで手動画像・別作品・子フォルダを保持', () async {
    final dir = await Directory.systemTemp.createTemp(
      'chronovel_remove_cache_',
    );
    addTearDown(() => dir.delete(recursive: true));
    for (final name in [
      'v1.jpg',
      'v1_ab.jpg',
      'v1.url',
      'v2.jpg',
      'manual.jpg',
    ]) {
      await File(p.join(dir.path, name)).writeAsString('test');
    }
    final nested = await Directory(p.join(dir.path, 'nested')).create();
    await File(p.join(nested.path, 'v1.jpg')).writeAsString('keep');
    final cache = CoverImageCache.forDirectory(dir);
    expect(
      await cache.removeImages(
        {'v1'},
        protectedPaths: [p.join(dir.path, 'v1_ab.jpg')],
      ),
      2,
    );
    for (final name in ['v1_ab.jpg', 'v2.jpg', 'manual.jpg', 'nested/v1.jpg']) {
      expect(await File(p.join(dir.path, name)).exists(), isTrue);
    }
    expect(await File(p.join(dir.path, 'v1.jpg')).exists(), isFalse);
    await expectLater(cache.removeImages({'../v2'}), throwsArgumentError);
  });
  testWidgets('画像削除は確認でキャンセルでき確定したIDだけ渡す', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cache = RecordingCache();
    final game = GameEntry(
      id: '1',
      title: '作品',
      brand: 'ブランド',
      status: GameStatus.notPlayed,
      playHours: 0,
      routeCurrent: 0,
      routeTotal: 0,
      coverColors: const [Colors.blue, Colors.black],
      vndbId: 'v1',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImageManagementDialog(games: [game], cache: cache),
        ),
      ),
    );
    await tester.tap(find.text('すべて選択'));
    await tester.pump();
    await tester.tap(find.text('選択画像を削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(cache.removedIds, isNull);
    await tester.tap(find.text('選択画像を削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '画像キャッシュを削除'));
    await tester.pumpAndSettle();
    expect(cache.removedIds, {'v1'});
  });
  testWidgets('手動登録は未入力と保存失敗を表示し二重送信を防ぐ', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManualRegistrationDialog(
            onSave: (title, path, work) async {
              calls++;
              throw StateError('test');
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('指定内容で登録'));
    await tester.pump();
    expect(calls, 0);
    await tester.enterText(find.byType(TextField).first, '作品');
    await tester.enterText(find.byType(TextField).last, 'D:/game/game.exe');
    await tester.tap(find.text('指定内容で登録'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.textContaining('登録できませんでした'), findsOneWidget);
  });
}
