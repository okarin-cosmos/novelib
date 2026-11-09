import 'dart:convert';

import 'package:flutter/material.dart';

class GameEdits {
  const GameEdits({
    this.title,
    this.brand,
    this.released,
    this.imagePath,
    this.blurCover,
  });
  final String? title, brand, released, imagePath;
  final bool? blurCover;
  factory GameEdits.decode(String? json) {
    if (json == null) return const GameEdits();
    try {
      final value = jsonDecode(json) as Map<String, dynamic>;
      return GameEdits(
        title: value['title'] as String?,
        brand: value['brand'] as String?,
        released: value['released'] as String?,
        imagePath: value['imagePath'] as String?,
        blurCover: value['blurCover'] as bool?,
      );
    } catch (_) {
      return const GameEdits();
    }
  }
  String encode() => jsonEncode({
    'title': title,
    'brand': brand,
    'released': released,
    'imagePath': imagePath,
    'blurCover': blurCover,
  });
  static bool validDate(String value) {
    if (value.isEmpty) return true;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final date = DateTime.tryParse(value);
    return date != null && date.toIso8601String().substring(0, 10) == value;
  }
}

enum GameStatus {
  notPlayed('未プレイ', 'not_played'),
  playing('プレイ中', 'playing'),
  cleared('クリア', 'cleared'),
  completed('コンプ', 'completed');

  const GameStatus(this.label, this.key);
  final String label;
  final String key;
}

abstract final class RatingScale {
  static const min = 1;
  static const max = 10;

  static bool isValid(int value) => value >= min && value <= max;

  static String formatAverage(Iterable<int> values) {
    if (values.isEmpty) return '-';
    final total = values.fold<int>(0, (sum, value) => sum + value);
    return (total / values.length).toStringAsFixed(1);
  }
}

class GameEntry {
  const GameEntry({
    required this.id,
    required this.title,
    required this.brand,
    required this.status,
    required this.playHours,
    required this.routeCurrent,
    required this.routeTotal,
    required this.coverColors,
    this.rating,
    this.ratingComment,
    this.tags = const [],
    this.vndbId,
    this.coverImageUrl,
    this.localCoverPath,
    this.titleRomaji,
    this.released,
    this.developers,
    this.catalogRating,
    this.catalogVoteCount = 0,
    this.isAdult = false,
    this.installDir,
    this.exePath,
    this.engine,
    this.coverBlurOverride,
    this.installations = const [],
  });

  final String id;
  final String title;
  final String brand;
  final GameStatus status;
  final double playHours;
  final int routeCurrent;
  final int routeTotal;
  final int? rating;
  final String? ratingComment;
  final List<Color> coverColors;
  final List<String> tags;
  final String? vndbId;
  final String? coverImageUrl;
  final String? localCoverPath;
  final String? titleRomaji;
  final String? released;
  final String? developers;
  final double? catalogRating;
  final int catalogVoteCount;
  final bool isAdult;
  final String? installDir;
  final String? exePath;
  final String? engine;

  /// null: follow the global setting, true/false: override for this work.
  final bool? coverBlurOverride;
  // Display-only grouping. The database continues to store individual installs.
  final List<GameEntry> installations;
  bool get isGroup => installations.length > 1;
  List<GameEntry> get members => isGroup ? installations : [this];

  double get progress => routeTotal == 0 ? 0 : routeCurrent / routeTotal;

  GameEntry copyWith({
    GameStatus? status,
    int? rating,
    String? ratingComment,
    bool clearRating = false,
    double? playHours,
    GameEdits? edits,
    List<GameEntry>? installations,
  }) {
    return GameEntry(
      id: id,
      title: edits?.title ?? title,
      brand: edits?.brand ?? brand,
      status: status ?? this.status,
      playHours: playHours ?? this.playHours,
      routeCurrent: routeCurrent,
      routeTotal: routeTotal,
      rating: clearRating ? null : rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      coverColors: coverColors,
      tags: tags,
      vndbId: vndbId,
      coverImageUrl: coverImageUrl,
      localCoverPath: edits == null ? localCoverPath : edits.imagePath,
      titleRomaji: titleRomaji,
      released: edits?.released ?? released,
      developers: edits?.brand ?? developers,
      catalogRating: catalogRating,
      catalogVoteCount: catalogVoteCount,
      isAdult: isAdult,
      installDir: installDir,
      exePath: exePath,
      engine: engine,
      coverBlurOverride: edits == null ? coverBlurOverride : edits.blurCover,
      installations: installations ?? this.installations,
    );
  }
}

List<GameEntry> groupLibraryGames(Iterable<GameEntry> games) {
  final groups = <String, List<GameEntry>>{};
  for (final game in games) {
    final id = game.vndbId;
    final key = id != null && RegExp(r'^v[1-9][0-9]*$').hasMatch(id)
        ? 'catalog:$id'
        : 'install:${game.id}';
    groups.putIfAbsent(key, () => []).add(game);
  }
  return groups.values.map((members) {
    if (members.length == 1) return members.single;
    final ordered = [...members]..sort((a, b) => a.id.compareTo(b.id));
    return ordered.first.copyWith(
      playHours: ordered.fold<double>(0, (sum, game) => sum + game.playHours),
      clearRating: true,
      installations: List.unmodifiable(ordered),
    );
  }).toList();
}
