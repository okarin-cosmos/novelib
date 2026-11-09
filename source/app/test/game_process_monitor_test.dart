import 'dart:io';

import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/services/game_process_monitor.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('Windowsの実行中プロセス一覧から実行パスを取得できる', () async {
    if (!Platform.isWindows) return;
    final processes = await GameProcessMonitor.loadWindowsProcesses();
    expect(processes, isNotEmpty);
    expect(processes.any((process) => process.path.isNotEmpty), isTrue);
  });

  test('アプリ起動前から実行中の登録作品を検出して終了時に記録する', () async {
    await database.upsertDetectedGame(
      title: '監視作品',
      installDir: r'D:\games\title',
      exePath: r'D:\games\title\game.exe',
      engine: 'kirikiri',
    );
    var snapshots = [
      RunningProcessInfo(
        pid: 42,
        path: r'D:\games\title\game.exe',
        startedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 10)),
      ),
    ];
    Set<String> running = {};
    final monitor = GameProcessMonitor(
      database: database,
      onRunningChanged: (ids) => running = ids,
      loadProcesses: () async => snapshots,
    );

    await monitor.pollNow();
    expect(running, {'1'});
    expect(await database.getActivePlaySessions(), hasLength(1));
    expect((await database.getGames()).single.status, 'playing');

    snapshots = [];
    await monitor.pollNow();
    expect(running, isEmpty);
    expect(await database.getActivePlaySessions(), isEmpty);
    expect(
      (await database.getGames()).single.totalPlaySec,
      greaterThanOrEqualTo(599),
    );
    expect(await database.playSessionCount(), 1);
  });

  test('同じ親フォルダ内では実行ファイルに最も近い登録だけを記録する', () async {
    for (final entry in [
      (r'D:\games', r'D:\games\launcher.exe'),
      (r'D:\games\title', r'D:\games\title\game.exe'),
    ]) {
      await database.upsertDetectedGame(
        title: entry.$1,
        installDir: entry.$1,
        exePath: entry.$2,
        engine: 'manual',
      );
    }
    final monitor = GameProcessMonitor(
      database: database,
      onRunningChanged: (_) {},
      loadProcesses: () async => [
        RunningProcessInfo(
          pid: 7,
          path: r'D:\games\title\game.exe',
          startedAt: DateTime.now().toUtc(),
        ),
      ],
    );

    await monitor.pollNow();
    final active = await database.getActivePlaySessions();
    expect(active, hasLength(1));
    expect(active.single.gameId, 2);
  });

  test('アプリ停止中に再起動されたゲームは別セッションとして扱う', () async {
    await database.upsertDetectedGame(
      title: '再起動作品',
      installDir: r'D:\games\restart',
      exePath: r'D:\games\restart\game.exe',
      engine: 'manual',
    );
    final oldStart = DateTime.utc(2026, 9, 5, 10);
    await database.touchActivePlaySession(
      gameId: 1,
      startedAt: oldStart,
      seenAt: oldStart.add(const Duration(minutes: 10)),
    );
    final newStart = oldStart.add(const Duration(hours: 2));
    final monitor = GameProcessMonitor(
      database: database,
      onRunningChanged: (_) {},
      loadProcesses: () async => [
        RunningProcessInfo(
          pid: 8,
          path: r'D:\games\restart\game.exe',
          startedAt: newStart,
        ),
      ],
    );

    await monitor.pollNow();
    expect(await database.playSessionCount(), 1);
    expect((await database.getGames()).single.totalPlaySec, 600);
    expect(
      (await database.getActivePlaySessions()).single.startedAt,
      newStart.toLocal(),
    );
  });
}
