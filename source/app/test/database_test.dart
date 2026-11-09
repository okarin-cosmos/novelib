import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/models/game.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('同じ作品IDの一登録を削除しても別登録の評価と履歴を残す', () async {
    for (final path in ['install-a', 'install-b']) {
      await database.upsertDetectedGame(
        title: '共通作品',
        installDir: path,
        exePath: '$path/game.exe',
        engine: 'kirikiri',
        vndbId: 'v1',
      );
    }
    final records = await database.getGames();
    final removed = records.firstWhere(
      (game) => game.installDir == 'install-a',
    );
    final retained = records.firstWhere(
      (game) => game.installDir == 'install-b',
    );
    for (final record in records) {
      await database.setGameRating(record.id, 9);
      await database.changeGameStatus(record.id, 'playing');
      await database.recordPlaySession(
        gameId: record.id,
        startedAt: DateTime.utc(2026),
        endedAt: DateTime.utc(2026).add(const Duration(minutes: 5)),
      );
    }
    expect(await database.deleteGame(removed.id), isTrue);
    final remaining = (await database.getGames()).single;
    expect(remaining.id, retained.id);
    expect(remaining.rating, 9);
    expect(remaining.totalPlaySec, 300);
    expect(remaining.status, 'playing');
    expect(await database.playSessionCount(), 1);
    expect(await database.statusHistoryCount(), 1);
  });

  test('対象フォルダの解除は指定行だけを削除し作品と履歴を残す', () async {
    await database.saveScanFolder('parent');
    await database.saveScanFolder('parent/child');
    await database.upsertDetectedGame(
      title: '作品',
      installDir: 'parent/child/game',
      exePath: 'game.exe',
      engine: 'kirikiri',
    );
    final id = (await database.getGames()).single.id;
    await database.setGameRating(id, 8);
    await database.changeGameStatus(id, 'playing');
    await database.recordPlaySession(
      gameId: id,
      startedAt: DateTime.utc(2026),
      endedAt: DateTime.utc(2026).add(const Duration(minutes: 1)),
    );
    expect(await database.removeScanFolder('parent'), 1);
    expect(await database.getScanFolders(), ['parent/child']);
    expect((await database.getGames()).single.rating, 8);
    expect((await database.getGames()).single.totalPlaySec, 60);
    expect(await database.statusHistoryCount(), 1);
    expect(await database.playSessionCount(), 1);
    expect(await database.removeScanFolder('parent'), 0);
    await database.saveScanFolder('parent');
    expect(await database.getScanFolders(), ['parent', 'parent/child']);
  });

  test('手動照合と再スキャンは評価・履歴・手動情報を保持する', () async {
    await database.upsertDetectedGame(
      title: '誤照合',
      installDir: 'manual',
      exePath: 'old.exe',
      engine: 'kirikiri',
      vndbId: 'v1',
    );
    final id = (await database.getGames()).single.id;
    await database.setGameRating(id, 9);
    await database.changeGameStatus(id, 'playing');
    await database.saveMetadataOverrides(
      id,
      const GameEdits(title: '手動名', imagePath: 'cover.png').encode(),
    );
    await database.recordPlaySession(
      gameId: id,
      startedAt: DateTime.utc(2026),
      endedAt: DateTime.utc(2026).add(const Duration(minutes: 5)),
    );
    await database.selectCatalogWork(id, 'v23740', '正式名');
    await database.upsertDetectedGame(
      title: '誤照合再発',
      installDir: 'manual',
      exePath: 'new.exe',
      engine: 'kirikiri',
      vndbId: 'v2',
    );
    final saved = (await database.getGames()).single;
    expect(saved.vndbId, 'v23740');
    expect(saved.title, '正式名');
    expect(saved.workKey, 'vndb:v23740');
    expect(saved.matchStatus, 'manual');
    expect(saved.rating, 9);
    expect(saved.status, 'playing');
    expect(saved.totalPlaySec, 300);
    expect(saved.exePath, 'new.exe');
    expect(GameEdits.decode(saved.metadataOverrides).title, '手動名');
    expect(GameEdits.decode(saved.metadataOverrides).imagePath, 'cover.png');
    expect(await database.playSessionCount(), 1);
    expect(await database.statusHistoryCount(), 1);
    await database.selectCatalogWork(id, 'v2', '再選択');
    expect((await database.getGames()).single.vndbId, 'v2');
    await expectLater(
      database.selectCatalogWork(id, 'invalid', 'name'),
      throwsArgumentError,
    );
    await expectLater(
      database.selectCatalogWork(999, 'v1', 'name'),
      throwsStateError,
    );
  });

  test('手動情報は再スキャンで上書きされない', () async {
    await database.upsertDetectedGame(
      title: 'original',
      installDir: 'test',
      exePath: 'test/game.exe',
      engine: 'kirikiri',
    );
    final id = (await database.getGames()).single.id;
    const edits = GameEdits(
      title: '修正タイトル',
      brand: 'ブランド',
      released: '2024-02-29',
      imagePath: 'cover.png',
      blurCover: true,
    );
    await database.saveMetadataOverrides(id, edits.encode());
    await database.upsertDetectedGame(
      title: 'rescanned',
      installDir: 'test',
      exePath: 'test/game.exe',
      engine: 'kirikiri',
    );
    final saved = GameEdits.decode(
      (await database.getGames()).single.metadataOverrides,
    );
    expect(saved.title, edits.title);
    expect(saved.brand, edits.brand);
    expect(saved.released, edits.released);
    expect(saved.imagePath, edits.imagePath);
    expect(saved.blurCover, isTrue);
  });

  test('日付と不正な保存値を検証する', () {
    expect(GameEdits.validDate('2024-02-29'), isTrue);
    expect(GameEdits.validDate('2023-02-29'), isFalse);
    expect(GameEdits.validDate('2024-13-01'), isFalse);
    expect(GameEdits.validDate(''), isTrue);
    expect(GameEdits.decode('broken').title, isNull);
  });

  test('検出作品を保存し、再検出時もユーザーの状態を維持する', () async {
    await database.upsertDetectedGame(
      title: 'テスト作品',
      installDir: r'C:\Games\RJ123456_test',
      exePath: r'C:\Games\RJ123456_test\game.exe',
      engine: 'kirikiri',
      rjCode: 'RJ123456',
    );

    var games = await database.getGames();
    expect(games, hasLength(1));
    expect(games.single.workKey, 'rj:RJ123456');
    expect(games.single.matchStatus, 'confirmed');

    await database.changeGameStatus(games.single.id, 'playing');
    await database.upsertDetectedGame(
      title: 'テスト作品 改訂版',
      installDir: r'C:\Games\RJ123456_test',
      exePath: r'C:\Games\RJ123456_test\game.exe',
      engine: 'kirikiri',
      rjCode: 'RJ123456',
    );

    games = await database.getGames();
    expect(games, hasLength(1));
    expect(games.single.title, 'テスト作品 改訂版');
    expect(games.single.status, 'playing');
    expect(await database.statusHistoryCount(), 1);
  });

  test('同じスキャンフォルダは重複保存しない', () async {
    await database.saveScanFolder(r'C:\Games');
    await database.saveScanFolder(r'C:\Games');

    expect(await database.getScanFolders(), [r'C:\Games']);
  });

  test('未使用のsetup誤検出だけを安全に削除する', () async {
    await database.upsertDetectedGame(
      title: 'setup',
      installDir: r'C:\Games\作品\data\setup',
      exePath: r'C:\Games\作品\data\setup\game.exe',
      engine: 'catsystem2',
    );
    await database.upsertDetectedGame(
      title: 'setup',
      installDir: r'C:\Other\作品\setup',
      exePath: r'C:\Other\作品\setup\game.exe',
      engine: 'catsystem2',
    );

    expect(await database.removeInvalidScannerArtifacts(r'C:\Games'), 1);
    final games = await database.getGames();
    expect(games, hasLength(1));
    expect(games.single.installDir, r'C:\Other\作品\setup');
  });

  test('作品を削除すると関連する状態履歴も削除する', () async {
    await database.upsertDetectedGame(
      title: '削除対象作品',
      installDir: r'C:/Games/delete-test',
      exePath: r'C:/Games/delete-test/game.exe',
      engine: 'kirikiri',
    );
    final game = (await database.getGames()).single;
    await database.changeGameStatus(game.id, 'playing');

    expect(await database.deleteGame(game.id), isTrue);
    expect(await database.getGames(), isEmpty);
    expect(await database.statusHistoryCount(), 0);
    expect(await database.deleteGame(game.id), isFalse);
  });

  test('複数作品を選択して関連履歴ごと削除する', () async {
    for (var index = 0; index < 3; index++) {
      await database.upsertDetectedGame(
        title: '一括削除作品$index',
        installDir: 'C:/Games/bulk-delete-$index',
        exePath: 'C:/Games/bulk-delete-$index/game.exe',
        engine: 'kirikiri',
      );
    }
    final games = await database.getGames();
    await database.changeGameStatus(games[0].id, 'playing');
    await database.changeGameStatus(games[1].id, 'cleared');

    expect(await database.deleteGames([games[0].id, games[1].id]), 2);
    expect((await database.getGames()).single.id, games[2].id);
    expect(await database.statusHistoryCount(), 0);
  });

  test('詳細画面の10段階評価を保存・解除できる', () async {
    await database.upsertDetectedGame(
      title: '評価対象作品',
      installDir: 'C:/Games/rating-test',
      exePath: 'C:/Games/rating-test/game.exe',
      engine: 'kirikiri',
    );
    final game = (await database.getGames()).single;

    await database.setGameRating(game.id, 9);
    var updated = (await database.getGames()).single;
    expect(updated.rating, 9);
    expect(updated.ratedAt, isNotNull);

    await database.setGameRating(game.id, null);
    updated = (await database.getGames()).single;
    expect(updated.rating, isNull);
    expect(updated.ratedAt, isNull);
    expect(() => database.setGameRating(game.id, 11), throwsArgumentError);
  });

  test('ゲーム終了時にセッションと累計プレイ時間を記録する', () async {
    await database.upsertDetectedGame(
      title: 'プレイ記録作品',
      installDir: 'C:/Games/session-test',
      exePath: 'C:/Games/session-test/game.exe',
      engine: 'kirikiri',
    );
    final game = (await database.getGames()).single;
    final startedAt = DateTime.utc(2026, 9, 3, 12);
    final endedAt = startedAt.add(const Duration(minutes: 42, seconds: 8));

    expect(
      await database.recordPlaySession(
        gameId: game.id,
        startedAt: startedAt,
        endedAt: endedAt,
      ),
      2528,
    );
    final updated = (await database.getGames()).single;
    expect(updated.totalPlaySec, 2528);
    expect(updated.lastPlayedAt?.toUtc(), endedAt);
    expect(await database.playSessionCount(), 1);
  });

  test('10段階評価の平均は小数第1位で表示する', () {
    expect(RatingScale.isValid(1), isTrue);
    expect(RatingScale.isValid(10), isTrue);
    expect(RatingScale.isValid(11), isFalse);
    expect(RatingScale.formatAverage([8, 9, 8]), '8.3');
    expect(RatingScale.formatAverage(const []), '-');
  });
}
