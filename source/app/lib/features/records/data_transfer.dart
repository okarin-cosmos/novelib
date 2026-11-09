import 'dart:convert';

import 'package:drift/native.dart';

import '../../database/app_database.dart';
import '../../models/game.dart';
import 'record_store.dart';

/// Portable, versioned logical backup of every user database table.
class LibraryBackup {
  LibraryBackup(
    this.games,
    this.sessions,
    this.history,
    this.folders,
    this.settings, [
    this.catalogReviews = const [],
  ]);
  final List<GameRecord> games;
  final List<PlaySession> sessions;
  final List<StatusHistoryData> history;
  final List<ScanFolder> folders;
  final List<AppSetting> settings;
  final List<CatalogReview> catalogReviews;
  static Future<LibraryBackup> capture(AppDatabase db) => db.transaction(
    () async => LibraryBackup(
      await db.getGames(),
      await db.select(db.playSessions).get(),
      await db.select(db.statusHistory).get(),
      await db.select(db.scanFolders).get(),
      (await db.select(db.appSettings).get())
          .where((row) => !_privateSettingKeys.contains(row.key))
          .toList(),
      await db.select(db.catalogReviews).get(),
    ),
  );
  String encode() => const JsonEncoder.withIndent('  ').convert({
    'format': 'chronovel-backup',
    'version': 1,
    'schema': 5,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'games': games.map((r) => r.toJson()).toList(),
    'sessions': sessions.map((r) => r.toJson()).toList(),
    'history': history.map((r) => r.toJson()).toList(),
    'folders': folders.map((r) => r.toJson()).toList(),
    'settings': settings.map((r) => r.toJson()).toList(),
    'catalogReviews': catalogReviews.map((r) => r.toJson()).toList(),
  });
  static Future<LibraryBackup> parse(String text) async {
    final j = jsonDecode(text) as Map<String, dynamic>;
    if (j['format'] != 'chronovel-backup' ||
        j['version'] != 1 ||
        ![2, 3, 5].contains(j['schema'])) {
      throw const FormatException('対応するNoveLibバックアップではありません。');
    }
    List<T> rows<T>(String key, T Function(Map<String, dynamic>) parse) =>
        (j[key] as List)
            .map((r) => parse(Map<String, dynamic>.from(r as Map)))
            .toList();
    final backup = LibraryBackup(
      rows('games', (row) {
        row.putIfAbsent('ratingComment', () => null);
        row.putIfAbsent('reviewSyncId', () => null);
        row.putIfAbsent('reviewSyncState', () => 'local');
        row.putIfAbsent('reviewUpdatedAt', () => null);
        return GameRecord.fromJson(row);
      }),
      rows('sessions', PlaySession.fromJson),
      rows('history', StatusHistoryData.fromJson),
      rows('folders', ScanFolder.fromJson),
      rows('settings', AppSetting.fromJson),
      j['schema'] == 5 ? rows('catalogReviews', CatalogReview.fromJson) : [],
    );
    for (final r in backup.catalogReviews) {
      if (!RegExp(r'^v[1-9][0-9]*$').hasMatch(r.workId) ||
          r.title.trim().isEmpty ||
          (r.rating != null && !RatingScale.isValid(r.rating!)) ||
          (r.ratingComment?.length ?? 0) > 4000 ||
          !RegExp(r'^[0-9a-f-]{36}$').hasMatch(r.reviewSyncId) ||
          ![
            'pending_upsert',
            'pending_delete',
            'synced',
            'superseded',
            'local',
          ].contains(r.reviewSyncState)) {
        throw const FormatException('カタログ評価に不正な値があります。');
      }
    }
    for (final g in backup.games) {
      if (g.id <= 0 ||
          g.title.trim().isEmpty ||
          g.totalPlaySec < 0 ||
          !GameStatus.values.any((s) => s.key == g.status) ||
          (g.rating != null && !RatingScale.isValid(g.rating!))) {
        throw const FormatException('作品データに不正な値があります。');
      }
    }
    for (final s in backup.sessions) {
      if (!s.endedAt.isAfter(s.startedAt)) {
        throw const FormatException('履歴の時刻が不正です。');
      }
    }
    for (final s in backup.settings) {
      if (s.key.startsWith('notes.')) {
        final id = int.tryParse(s.key.substring(6));
        if (!backup.games.any((g) => g.id == id)) {
          throw const FormatException('作品のない記録があります。');
        }
        WorkNotes.decode(s.value);
      }
      if (s.key == 'purchase.plans') {
        (jsonDecode(s.value) as List).cast<String>().toList();
      }
    }
    // Validate uniqueness and foreign keys in an isolated database before restore.
    final trial = AppDatabase(NativeDatabase.memory());
    try {
      await backup.restore(trial);
    } finally {
      await trial.close();
    }
    return backup;
  }

  Future<void> restore(AppDatabase db) => db.transaction(() async {
    final privateSettings = (await db.select(db.appSettings).get())
        .where((row) => _privateSettingKeys.contains(row.key))
        .toList();
    await db.delete(db.playSessions).go();
    await db.delete(db.statusHistory).go();
    await db.delete(db.games).go();
    await db.delete(db.catalogReviews).go();
    await db.delete(db.scanFolders).go();
    await db.delete(db.appSettings).go();
    for (final row in games) {
      await db.into(db.games).insert(row);
    }
    for (final row in catalogReviews) {
      await db.into(db.catalogReviews).insert(row);
    }
    for (final row in sessions) {
      await db.into(db.playSessions).insert(row);
    }
    for (final row in history) {
      await db.into(db.statusHistory).insert(row);
    }
    for (final row in folders) {
      await db.into(db.scanFolders).insert(row);
    }
    for (final row in settings) {
      if (_privateSettingKeys.contains(row.key)) continue;
      await db.into(db.appSettings).insert(row);
    }
    for (final row in privateSettings) {
      await db.into(db.appSettings).insert(row);
    }
  });
}

const _privateSettingKeys = {'cloud.reviewAnonymousToken'};

String libraryCsv(List<GameEntry> games) {
  String cell(Object? v) {
    var s = v?.toString() ?? '';
    // Spreadsheet formula injection protection, including leading whitespace.
    if (RegExp(r'^[\s]*[=+@-]').hasMatch(s)) s = "'$s";
    return '"${s.replaceAll('"', '""')}"';
  }

  return '\uFEFF${[
    ['登録ID', '作品名', 'ブランド', '状態', '自分の評価（10段階）', '評価コメント', 'カタログ評価', 'プレイ時間（h）', 'タグ', 'VNDB ID', '表紙ぼかし', 'インストール先'],
    ...games.map((g) => [g.id, g.title, g.brand, g.status.label, g.rating, g.ratingComment, g.catalogRating?.toStringAsFixed(1), g.playHours.toStringAsFixed(1), g.tags.join(' / '), g.vndbId, switch (g.coverBlurOverride) {
      true => 'ぼかす',
      false => 'ぼかさない',
      null => '全体設定',
    }, g.installDir]),
  ].map((row) => row.map(cell).join(',')).join('\r\n')}\r\n';
}
