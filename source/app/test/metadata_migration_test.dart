import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/models/game.dart';

void main() {
  test('v1の作品と評価を保持したまま最新DBへ移行する', () async {
    final temp = await Directory.systemTemp.createTemp('chronovel-migration-');
    final file = File('${temp.path}/test.sqlite');
    AppDatabase? db;
    try {
      db = AppDatabase(NativeDatabase(file));
      await db.upsertDetectedGame(
        title: '既存作品',
        installDir: 'test',
        exePath: 'test/game.exe',
        engine: 'kirikiri',
      );
      await db.setGameRating((await db.getGames()).single.id, 8);
      await db.close();
      db = null;
      final raw = sql.sqlite3.open(file.path);
      try {
        raw.execute('DROP TABLE active_play_sessions');
        raw.execute('DROP TABLE catalog_reviews');
        raw.execute('ALTER TABLE games DROP COLUMN review_updated_at');
        raw.execute('ALTER TABLE games DROP COLUMN review_sync_state');
        raw.execute('ALTER TABLE games DROP COLUMN review_sync_id');
        raw.execute('ALTER TABLE games DROP COLUMN rating_comment');
        raw.execute('ALTER TABLE games DROP COLUMN metadata_overrides');
        raw.execute('PRAGMA user_version = 1');
      } finally {
        raw.close();
      }
      db = AppDatabase(NativeDatabase(file));
      final record = (await db.getGames()).single;
      expect(record.title, '既存作品');
      expect(record.rating, 8);
      expect(record.metadataOverrides, isNull);
      await db.saveMetadataOverrides(
        record.id,
        const GameEdits(title: '修正').encode(),
      );
      expect(
        GameEdits.decode((await db.getGames()).single.metadataOverrides).title,
        '修正',
      );
    } finally {
      await db?.close();
      await temp.delete(recursive: true);
    }
  });
}
