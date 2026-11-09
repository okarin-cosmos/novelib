import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/game.dart';

class WorkNotes {
  WorkNotes({
    this.favorite = false,
    this.purchase = false,
    this.date = '',
    this.memo = '',
    List<String>? tags,
    List<Map<String, dynamic>>? routes,
  }) : tags = tags ?? [],
       routes = routes ?? [];
  bool favorite, purchase;
  String date, memo;
  List<String> tags;
  List<Map<String, dynamic>> routes;
  factory WorkNotes.decode(String? raw) {
    if (raw == null) return WorkNotes();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final notes = WorkNotes(
      favorite: j['favorite'] as bool? ?? false,
      purchase: j['purchase'] as bool? ?? false,
      date: j['date'] as String? ?? '',
      memo: j['memo'] as String? ?? '',
      tags: (j['tags'] as List? ?? []).cast<String>().toList(),
      routes: (j['routes'] as List? ?? [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList(),
    );
    if (!GameEdits.validDate(notes.date) ||
        notes.routes.any(
          (r) =>
              r['name'] is! String ||
              (r['name'] as String).trim().isEmpty ||
              r['memo'] is! String ||
              !['未着手', '攻略中', '完了'].contains(r['status']),
        )) {
      throw const FormatException('予定日またはルートの形式が不正です。');
    }
    return notes;
  }
  String encode() => jsonEncode({
    'favorite': favorite,
    'purchase': purchase,
    'date': date,
    'memo': memo,
    'tags': tags.toSet().toList(),
    'routes': routes,
  });
}

class RecordStore {
  RecordStore(this.db);
  final AppDatabase db;
  Future<WorkNotes> notes(int id) async =>
      WorkNotes.decode(await db.readSetting('notes.$id'));
  Future<void> save(int id, WorkNotes value) => db.transaction(() async {
    WorkNotes.decode(value.encode());
    await (db.select(db.games)..where((g) => g.id.equals(id))).getSingle();
    await db.writeSetting('notes.$id', value.encode());
    await (db.update(db.games)..where((g) => g.id.equals(id))).write(
      GamesCompanion(localUpdatedAt: Value(DateTime.now().toUtc())),
    );
  });
  Future<List<PlaySession>> sessions([int? gameId]) =>
      (db.select(db.playSessions)
            ..where(
              (s) => gameId == null
                  ? const Constant(true)
                  : s.gameId.equals(gameId),
            )
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .get();
  Future<void> editSession(
    int gameId, {
    int? id,
    DateTime? start,
    DateTime? end,
    bool remove = false,
  }) => db.transaction(() async {
    final game = await (db.select(
      db.games,
    )..where((g) => g.id.equals(gameId))).getSingle();
    final old = id == null
        ? null
        : await (db.select(db.playSessions)
                ..where((s) => s.id.equals(id) & s.gameId.equals(gameId)))
              .getSingle();
    if (!remove &&
        (start == null ||
            end == null ||
            end.difference(start).inSeconds <= 0 ||
            end.isAfter(DateTime.now()))) {
      throw ArgumentError('開始 < 終了、終了は現在以前にしてください。');
    }
    if (!remove) {
      for (final other in await sessions(gameId)) {
        if (other.id != id &&
            start!.isBefore(other.endedAt) &&
            end!.isAfter(other.startedAt)) {
          throw ArgumentError('同じ作品の履歴と時間が重なっています。');
        }
      }
    }
    if (old != null) {
      await (db.delete(
        db.playSessions,
      )..where((s) => s.id.equals(old.id))).go();
    }
    if (!remove) {
      await db
          .into(db.playSessions)
          .insert(
            PlaySessionsCompanion.insert(
              gameId: gameId,
              startedAt: start!.toUtc(),
              endedAt: end!.toUtc(),
            ),
          );
    }
    final delta =
        (remove ? 0 : end!.difference(start!).inSeconds) -
        (old == null ? 0 : old.endedAt.difference(old.startedAt).inSeconds);
    final remaining = await sessions(gameId);
    remaining.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    await (db.update(db.games)..where((g) => g.id.equals(gameId))).write(
      GamesCompanion(
        totalPlaySec: Value(math.max(0, game.totalPlaySec + delta)),
        lastPlayedAt: Value(remaining.isEmpty ? null : remaining.first.endedAt),
        localUpdatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  });
}

/// Split recorded intervals at local calendar boundaries, including New Year.
Map<String, int> periodSeconds(
  Iterable<PlaySession> sessions, {
  bool yearly = false,
}) {
  final result = <String, int>{};
  for (final session in sessions) {
    var cursor = session.startedAt.toLocal();
    final end = session.endedAt.toLocal();
    while (cursor.isBefore(end)) {
      final boundary = yearly
          ? DateTime(cursor.year + 1)
          : DateTime(cursor.year, cursor.month + 1);
      final stop = boundary.isBefore(end) ? boundary : end;
      final key = yearly
          ? '${cursor.year}'
          : '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
      result.update(
        key,
        (v) => v + stop.difference(cursor).inSeconds,
        ifAbsent: () => stop.difference(cursor).inSeconds,
      );
      cursor = stop;
    }
  }
  return result;
}
