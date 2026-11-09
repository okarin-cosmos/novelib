import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

Future<void> _copyLegacyDatabaseIfNeeded(
  Directory supportDirectory,
  File destination,
) async {
  if (await destination.exists()) {
    return;
  }

  final roamingDirectory = supportDirectory.parent.parent;
  final legacyCandidates = [
    File(p.join(supportDirectory.path, 'VNManager', 'vn_manager.sqlite')),
    File(
      p.join(
        roamingDirectory.path,
        'jp.vnmanager',
        'VN Manager',
        'VNManager',
        'vn_manager.sqlite',
      ),
    ),
  ];

  File? legacy;
  for (final candidate in legacyCandidates) {
    if (await candidate.exists()) {
      legacy = candidate;
      break;
    }
  }
  if (legacy == null) {
    return;
  }

  await legacy.copy(destination.path);

  final legacyWal = File('${legacy.path}-wal');
  if (await legacyWal.exists()) {
    await legacyWal.copy('${destination.path}-wal');
  }
}

class ScanFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
}

class CatalogReviews extends Table {
  TextColumn get workId => text()();
  TextColumn get title => text()();
  BoolColumn get isAdult => boolean()();
  IntColumn get rating => integer().nullable()();
  TextColumn get ratingComment => text().nullable()();
  TextColumn get reviewSyncId => text()();
  TextColumn get reviewSyncState => text()();
  DateTimeColumn get reviewUpdatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {workId};
}

@DataClassName('GameRecord')
class Games extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get installDir => text().unique()();
  TextColumn get exePath => text()();
  TextColumn get engine => text().nullable()();
  TextColumn get rjCode => text().nullable()();
  TextColumn get vndbId => text().nullable()();
  TextColumn get workKey => text().nullable()();
  TextColumn get matchStatus =>
      text().withDefault(const Constant('unmatched'))();
  TextColumn get thumbnailUrl => text().nullable()();
  TextColumn get metadataOverrides => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('not_played'))();
  IntColumn get rating => integer().nullable()();
  TextColumn get ratingComment => text().nullable()();
  TextColumn get reviewSyncId => text().nullable()();
  TextColumn get reviewSyncState =>
      text().withDefault(const Constant('local'))();
  DateTimeColumn get reviewUpdatedAt => dateTime().nullable()();
  DateTimeColumn get ratedAt => dateTime().nullable()();
  IntColumn get totalPlaySec => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get localUpdatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

class PlaySessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
}

class ActivePlaySessions extends Table {
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {gameId};
}

class StatusHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get gameId =>
      integer().references(Games, #id, onDelete: KeyAction.cascade)();
  TextColumn get fromStatus => text()();
  TextColumn get toStatus => text()();
  DateTimeColumn get changedAt => dateTime()();
}

class AppSettings extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    ScanFolders,
    Games,
    PlaySessions,
    ActivePlaySessions,
    StatusHistory,
    AppSettings,
    CatalogReviews,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.open() {
    return AppDatabase(
      LazyDatabase(() async {
        final supportDirectory = await getApplicationSupportDirectory();
        final databaseDirectory = Directory(
          p.join(supportDirectory.path, 'Chronovel'),
        );
        await databaseDirectory.create(recursive: true);
        final file = File(p.join(databaseDirectory.path, 'chronovel.sqlite'));
        await _copyLegacyDatabaseIfNeeded(supportDirectory, file);
        return NativeDatabase.createInBackground(file);
      }),
    );
  }

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 5) await migrator.createTable(catalogReviews);
      if (from < 2) await migrator.addColumn(games, games.metadataOverrides);
      if (from < 3) await migrator.createTable(activePlaySessions);
      if (from < 4) {
        await migrator.addColumn(games, games.ratingComment);
        await migrator.addColumn(games, games.reviewSyncId);
        await migrator.addColumn(games, games.reviewSyncState);
        await migrator.addColumn(games, games.reviewUpdatedAt);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Stream<List<GameRecord>> watchGames() {
    return (select(games)
          ..orderBy([(game) => OrderingTerm.desc(game.localUpdatedAt)]))
        .watch()
        .asyncMap((records) async {
          final reviews = {
            for (final r in await select(catalogReviews).get()) r.workId: r,
          };
          return records.map((record) {
            final review = reviews[record.vndbId];
            if (review == null ||
                !review.reviewUpdatedAt.isAfter(
                  record.reviewUpdatedAt ?? record.ratedAt ?? DateTime(0),
                )) {
              return record;
            }
            return record.copyWith(
              rating: Value(review.rating),
              ratingComment: Value(review.ratingComment),
            );
          }).toList();
        });
  }

  Future<List<GameRecord>> getGames() => select(games).get();

  Future<void> setCatalogReview({
    required String workId,
    required String title,
    required bool isAdult,
    required int? rating,
    required String? comment,
  }) => transaction(() async {
    if (!RegExp(r'^v[1-9][0-9]*$').hasMatch(workId) ||
        title.trim().isEmpty ||
        (rating != null && (rating < 1 || rating > 10)) ||
        (comment?.trim().length ?? 0) > 4000) {
      throw ArgumentError('作品ID・評価・コメントを確認してください。');
    }
    final installed = await (select(
      games,
    )..where((g) => g.vndbId.equals(workId))).get();
    if (installed.isNotEmpty) {
      // Reuse the existing game review, not a second independent vote.
      for (final game in installed) {
        await setGameReview(game.id, rating, comment);
      }
      return;
    }
    final current = await (select(
      catalogReviews,
    )..where((r) => r.workId.equals(workId))).getSingleOrNull();
    final text = comment?.trim() ?? '';
    final clock = DateTime.now().toUtc();
    final updated = current != null && !clock.isAfter(current.reviewUpdatedAt)
        ? current.reviewUpdatedAt.add(const Duration(milliseconds: 1))
        : clock;
    await into(catalogReviews).insertOnConflictUpdate(
      CatalogReviewsCompanion.insert(
        workId: workId,
        title: title,
        isAdult: isAdult,
        rating: Value(rating),
        ratingComment: Value(text.isEmpty ? null : text),
        reviewSyncId: current?.reviewSyncId ?? _uuidV4(),
        reviewSyncState: rating == null && text.isEmpty
            ? 'pending_delete'
            : 'pending_upsert',
        reviewUpdatedAt: updated,
      ),
    );
  });

  Future<({int? rating, String? comment})> readWorkReview(String workId) async {
    final installed = await (select(
      games,
    )..where((g) => g.vndbId.equals(workId))).get();
    installed.sort(
      (a, b) => (b.reviewUpdatedAt ?? b.ratedAt ?? DateTime(0)).compareTo(
        a.reviewUpdatedAt ?? a.ratedAt ?? DateTime(0),
      ),
    );
    final catalog = await (select(
      catalogReviews,
    )..where((r) => r.workId.equals(workId))).getSingleOrNull();
    final game = installed.isEmpty ? null : installed.first;
    if (catalog != null &&
        (game == null ||
            catalog.reviewUpdatedAt.isAfter(
              game.reviewUpdatedAt ?? game.ratedAt ?? DateTime(0),
            ))) {
      return (rating: catalog.rating, comment: catalog.ratingComment);
    }
    return (rating: game?.rating, comment: game?.ratingComment);
  }

  Future<String?> readSetting(String key) async => (await (select(
    appSettings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;
  Future<void> writeSetting(String key, String value) => into(appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      )
      .then((_) {});

  Future<int> registerManualGame(String title, String exePath) async {
    final file = File(exePath);
    if (title.trim().isEmpty ||
        !p.isAbsolute(exePath) ||
        p.extension(exePath).toLowerCase() != '.exe' ||
        !await file.exists()) {
      throw ArgumentError('存在する実行ファイル（.exe）の絶対パスと作品名を指定してください。');
    }
    final normalized = p.normalize(exePath);
    final dir = p.dirname(normalized);
    return transaction(() async {
      final matches = (await getGames())
          .where((g) => p.equals(p.normalize(g.installDir), dir))
          .toList();
      if (matches.isNotEmpty) {
        final existing = matches.first;
        await (update(games)..where((g) => g.id.equals(existing.id))).write(
          GamesCompanion(
            exePath: Value(normalized),
            engine: const Value('manual'),
            localUpdatedAt: Value(DateTime.now().toUtc()),
          ),
        );
        return existing.id;
      }
      final now = DateTime.now().toUtc();
      return into(games).insert(
        GamesCompanion.insert(
          title: title.trim(),
          installDir: dir,
          exePath: normalized,
          engine: const Value('manual'),
          matchStatus: const Value('manual'),
          createdAt: now,
          localUpdatedAt: now,
        ),
      );
    });
  }

  Future<void> saveMetadataOverrides(int gameId, String json) async {
    await (update(games)..where((game) => game.id.equals(gameId))).write(
      GamesCompanion(
        metadataOverrides: Value(json),
        localUpdatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> saveScanFolder(String folderPath) async {
    await into(scanFolders).insert(
      ScanFoldersCompanion.insert(path: folderPath),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<List<String>> getScanFolders() async {
    final rows = await (select(
      scanFolders,
    )..orderBy([(folder) => OrderingTerm.asc(folder.path)])).get();
    return rows.map((row) => row.path).toList();
  }

  Future<int> removeScanFolder(String folderPath) => (delete(
    scanFolders,
  )..where((folder) => folder.path.equals(folderPath))).go();

  Future<void> upsertDetectedGame({
    required String title,
    required String installDir,
    required String exePath,
    required String engine,
    String? rjCode,
    String? vndbId,
  }) async {
    await transaction(() async {
      final existing = await (select(
        games,
      )..where((game) => game.installDir.equals(installDir))).getSingleOrNull();
      final now = DateTime.now().toUtc();
      final workKey = rjCode != null
          ? 'rj:$rjCode'
          : vndbId == null
          ? null
          : 'vndb:$vndbId';
      final isMatched = rjCode != null || vndbId != null;

      if (existing == null) {
        await into(games).insert(
          GamesCompanion.insert(
            title: title,
            installDir: installDir,
            exePath: exePath,
            engine: Value(engine),
            rjCode: Value(rjCode),
            vndbId: Value(vndbId),
            workKey: Value(workKey),
            matchStatus: Value(isMatched ? 'confirmed' : 'unmatched'),
            createdAt: now,
            localUpdatedAt: now,
          ),
        );
        return;
      }

      await (update(games)..where((game) => game.id.equals(existing.id))).write(
        GamesCompanion(
          title: existing.matchStatus == 'manual'
              ? const Value.absent()
              : Value(title),
          exePath: existing.engine == 'manual'
              ? const Value.absent()
              : Value(exePath),
          engine: existing.engine == 'manual'
              ? const Value.absent()
              : Value(engine),
          rjCode: Value(rjCode),
          vndbId: existing.matchStatus == 'manual'
              ? const Value.absent()
              : Value(vndbId),
          workKey: existing.matchStatus == 'manual'
              ? const Value.absent()
              : Value(workKey),
          matchStatus: existing.matchStatus == 'manual'
              ? const Value.absent()
              : Value(isMatched ? 'confirmed' : existing.matchStatus),
          localUpdatedAt: Value(now),
        ),
      );
    });
  }

  Future<int> removeInvalidScannerArtifacts(String rootPath) async {
    const invalidTitles = {'setup', 'install', 'data', 'dl_image'};
    final records = await getGames();
    final removable = records.where((record) {
      final isInsideRoot =
          p.equals(record.installDir, rootPath) ||
          p.isWithin(rootPath, record.installDir);
      return isInsideRoot &&
          record.matchStatus != 'manual' &&
          invalidTitles.contains(record.title.trim().toLowerCase()) &&
          record.status == 'not_played' &&
          record.rating == null &&
          record.metadataOverrides == null &&
          record.totalPlaySec == 0;
    }).toList();

    await transaction(() async {
      for (final record in removable) {
        await (delete(games)..where((game) => game.id.equals(record.id))).go();
      }
    });
    return removable.length;
  }

  Future<bool> deleteGame(int gameId) async {
    final deleted = await deleteGames([gameId]);
    return deleted > 0;
  }

  Future<void> selectCatalogWork(
    int gameId,
    String vndbId,
    String title,
  ) async {
    if (!RegExp(r'^v[1-9][0-9]*$').hasMatch(vndbId) || title.trim().isEmpty) {
      throw ArgumentError('有効なカタログ作品を指定してください');
    }
    final count = await (update(games)..where((game) => game.id.equals(gameId)))
        .write(
          GamesCompanion(
            title: Value(title),
            vndbId: Value(vndbId),
            workKey: Value('vndb:$vndbId'),
            matchStatus: const Value('manual'),
            localUpdatedAt: Value(DateTime.now().toUtc()),
          ),
        );
    if (count == 0) throw StateError('作品が見つかりません');
  }

  Future<int> deleteGames(Iterable<int> gameIds) async {
    final ids = gameIds.toSet().toList();
    if (ids.isEmpty) return 0;
    return transaction(() async {
      await (delete(
        appSettings,
      )..where((s) => s.key.isIn(ids.map((id) => 'notes.$id')))).go();
      return (delete(games)..where((game) => game.id.isIn(ids))).go();
    });
  }

  Future<void> setGameRating(int gameId, int? rating) async {
    final current = await (select(
      games,
    )..where((game) => game.id.equals(gameId))).getSingle();
    final review = current.vndbId == null
        ? null
        : await readWorkReview(current.vndbId!);
    await setGameReview(
      gameId,
      rating,
      review != null ? review.comment : current.ratingComment,
    );
  }

  Future<void> setGameReview(int gameId, int? rating, String? comment) async {
    if (rating != null && (rating < 1 || rating > 10)) {
      throw ArgumentError.value(rating, 'rating', '1～10で指定してください');
    }
    final normalizedComment = comment?.trim() ?? '';
    if (normalizedComment.length > 4000) {
      throw ArgumentError.value(comment, 'comment', '4000文字以内で指定してください');
    }
    final current = await (select(
      games,
    )..where((game) => game.id.equals(gameId))).getSingle();
    final clock = DateTime.now().toUtc();
    final catalog = current.vndbId == null
        ? null
        : await (select(
            catalogReviews,
          )..where((r) => r.workId.equals(current.vndbId!))).getSingleOrNull();
    final gameTime = current.reviewUpdatedAt?.toUtc();
    final previous =
        catalog != null &&
            (gameTime == null || catalog.reviewUpdatedAt.isAfter(gameTime))
        ? catalog.reviewUpdatedAt
        : gameTime;
    final clockMilliseconds = clock.millisecondsSinceEpoch;
    final previousMilliseconds = previous?.millisecondsSinceEpoch;
    final now = DateTime.fromMillisecondsSinceEpoch(
      previousMilliseconds != null && clockMilliseconds <= previousMilliseconds
          ? previousMilliseconds + 1
          : clockMilliseconds,
      isUtc: true,
    );
    final hasReview = rating != null || normalizedComment.isNotEmpty;
    final syncId = current.reviewSyncId ?? (hasReview ? _uuidV4() : null);
    await (update(games)..where((game) => game.id.equals(gameId))).write(
      GamesCompanion(
        rating: Value(rating),
        ratingComment: Value(
          normalizedComment.isEmpty ? null : normalizedComment,
        ),
        reviewSyncId: Value(syncId),
        reviewSyncState: Value(
          hasReview
              ? 'pending_upsert'
              : syncId == null
              ? 'local'
              : 'pending_delete',
        ),
        reviewUpdatedAt: Value(now),
        ratedAt: Value(rating == null ? null : now),
        localUpdatedAt: Value(now),
      ),
    );
  }

  Future<List<GameRecord>> pendingReviewSync() => (select(
    games,
  )..where((game) => game.reviewSyncState.like('pending_%'))).get();

  /// Marks an upload only when the local review has not changed in flight.
  Future<bool> markReviewSyncSucceeded({
    required int gameId,
    required String expectedSyncId,
    required DateTime expectedUpdatedAt,
    required String expectedSyncState,
    required int? expectedRating,
    required String? expectedComment,
    required String canonicalSyncId,
    required DateTime syncedAt,
  }) async {
    return transaction(() async {
      final current = await (select(
        games,
      )..where((game) => game.id.equals(gameId))).getSingleOrNull();
      if (current == null ||
          current.reviewSyncId != expectedSyncId ||
          current.reviewUpdatedAt?.millisecondsSinceEpoch !=
              expectedUpdatedAt.millisecondsSinceEpoch ||
          current.reviewSyncState != expectedSyncState ||
          current.rating != expectedRating ||
          current.ratingComment != expectedComment) {
        return false;
      }
      final changed =
          await (update(games)..where((game) => game.id.equals(gameId))).write(
            GamesCompanion(
              reviewSyncId: Value(canonicalSyncId),
              reviewSyncState: const Value('synced'),
              syncedAt: Value(syncedAt.toUtc()),
            ),
          );
      return changed == 1;
    });
  }

  Future<bool> markReviewSyncSuperseded({
    required int gameId,
    required String expectedSyncId,
    required DateTime expectedUpdatedAt,
  }) async {
    final changed =
        await (update(games)..where(
              (game) =>
                  game.id.equals(gameId) &
                  game.reviewSyncId.equals(expectedSyncId) &
                  game.reviewUpdatedAt.equals(expectedUpdatedAt),
            ))
            .write(const GamesCompanion(reviewSyncState: Value('superseded')));
    return changed == 1;
  }

  Future<int> recordPlaySession({
    required int gameId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final seconds = endedAt.difference(startedAt).inSeconds;
    if (seconds <= 0) return 0;
    await transaction(() async {
      final current = await (select(
        games,
      )..where((game) => game.id.equals(gameId))).getSingle();
      await into(playSessions).insert(
        PlaySessionsCompanion.insert(
          gameId: gameId,
          startedAt: startedAt.toUtc(),
          endedAt: endedAt.toUtc(),
        ),
      );
      await (update(games)..where((game) => game.id.equals(gameId))).write(
        GamesCompanion(
          totalPlaySec: Value(current.totalPlaySec + seconds),
          lastPlayedAt: Value(endedAt.toUtc()),
          localUpdatedAt: Value(endedAt.toUtc()),
        ),
      );
    });
    return seconds;
  }

  Future<void> touchActivePlaySession({
    required int gameId,
    required DateTime startedAt,
    required DateTime seenAt,
  }) async {
    final existing = await (select(
      activePlaySessions,
    )..where((row) => row.gameId.equals(gameId))).getSingleOrNull();
    final start = startedAt.toUtc();
    final seen = seenAt.toUtc();
    await into(activePlaySessions).insertOnConflictUpdate(
      ActivePlaySessionsCompanion.insert(
        gameId: Value(gameId),
        startedAt: existing != null && existing.startedAt.isBefore(start)
            ? existing.startedAt
            : start,
        lastSeenAt: seen,
      ),
    );
  }

  Future<int> finishActivePlaySession(int gameId) async {
    final active = await (select(
      activePlaySessions,
    )..where((row) => row.gameId.equals(gameId))).getSingleOrNull();
    if (active == null) return 0;
    final seconds = active.lastSeenAt.difference(active.startedAt).inSeconds;
    if (seconds <= 0) {
      await (delete(
        activePlaySessions,
      )..where((row) => row.gameId.equals(gameId))).go();
      return 0;
    }
    await transaction(() async {
      final current = await (select(
        games,
      )..where((game) => game.id.equals(gameId))).getSingle();
      await into(playSessions).insert(
        PlaySessionsCompanion.insert(
          gameId: gameId,
          startedAt: active.startedAt,
          endedAt: active.lastSeenAt,
        ),
      );
      await (update(games)..where((game) => game.id.equals(gameId))).write(
        GamesCompanion(
          totalPlaySec: Value(current.totalPlaySec + seconds),
          lastPlayedAt: Value(active.lastSeenAt),
          localUpdatedAt: Value(active.lastSeenAt),
        ),
      );
      await (delete(
        activePlaySessions,
      )..where((row) => row.gameId.equals(gameId))).go();
    });
    return seconds;
  }

  Future<List<ActivePlaySession>> getActivePlaySessions() =>
      select(activePlaySessions).get();

  Future<int> playSessionCount() async {
    final count = countAll();
    final query = selectOnly(playSessions)..addColumns([count]);
    return (await query.map((row) => row.read(count) ?? 0).getSingle());
  }

  Future<void> changeGameStatus(int gameId, String nextStatus) async {
    await transaction(() async {
      final current = await (select(
        games,
      )..where((game) => game.id.equals(gameId))).getSingle();
      if (current.status == nextStatus) return;
      final changedAt = DateTime.now().toUtc();
      await into(statusHistory).insert(
        StatusHistoryCompanion.insert(
          gameId: gameId,
          fromStatus: current.status,
          toStatus: nextStatus,
          changedAt: changedAt,
        ),
      );
      await (update(games)..where((game) => game.id.equals(gameId))).write(
        GamesCompanion(
          status: Value(nextStatus),
          localUpdatedAt: Value(changedAt),
        ),
      );
    });
  }

  Future<int> statusHistoryCount() async {
    final count = countAll();
    final query = selectOnly(statusHistory)..addColumns([count]);
    return (await query.map((row) => row.read(count) ?? 0).getSingle());
  }
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final value = bytes.map(hex).join();
  return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
      '${value.substring(12, 16)}-${value.substring(16, 20)}-'
      '${value.substring(20)}';
}
