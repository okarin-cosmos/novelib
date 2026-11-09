import 'dart:io';

import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class CatalogWork {
  const CatalogWork({
    required this.vndbId,
    required this.titleJa,
    required this.voteCount,
    this.titleRomaji,
    this.imageUrl,
    this.released,
    this.developers,
    this.rating,
    this.minAge,
    this.isAdult = false,
  });

  final String vndbId;
  final String titleJa;
  final String? titleRomaji;
  final String? imageUrl;
  final String? released;
  final String? developers;
  final double? rating;
  final int voteCount;
  final int? minAge;
  final bool isAdult;
}

class StoreProduct {
  const StoreProduct({
    required this.workId,
    required this.store,
    required this.productId,
    this.landingUrl,
    this.isPrimary = false,
    this.source,
    this.verifiedAt,
  });

  final String workId;
  final String store;
  final String productId;
  final String? landingUrl;
  final bool isPrimary;
  final String? source;
  final String? verifiedAt;
}

class CatalogDatabase {
  CatalogDatabase._(
    this._database,
    this._path,
    this._catalogDirectory,
    this._bundledPath,
  );

  static const assetPath = 'assets/catalog/chronovel_catalog.sqlite';
  static const catalogVersion = '2026-09-05-adult-store-links';

  Database _database;
  String _path;
  final Directory _catalogDirectory;
  final String _bundledPath;

  static CatalogDatabase openExisting(String path) {
    final absolute = File(path).absolute;
    return CatalogDatabase._(
      sqlite3.open(absolute.path, mode: OpenMode.readOnly),
      absolute.path,
      absolute.parent,
      absolute.path,
    );
  }

  static Future<CatalogDatabase> open() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final catalogDirectory = Directory(
      p.join(supportDirectory.path, 'Chronovel', 'catalog'),
    );
    await catalogDirectory.create(recursive: true);
    final catalogFile = File(
      p.join(catalogDirectory.path, 'catalog-$catalogVersion.sqlite'),
    );
    if (!await catalogFile.exists()) {
      final asset = await rootBundle.load(assetPath);
      final bytes = asset.buffer.asUint8List(
        asset.offsetInBytes,
        asset.lengthInBytes,
      );
      await catalogFile.writeAsBytes(bytes, flush: true);
    }
    var selected = catalogFile;
    final pointer = File(p.join(catalogDirectory.path, 'active-catalog.txt'));
    Database? selectedDatabase;
    try {
      if (await pointer.exists()) {
        final fileName = (await pointer.readAsString()).trim();
        if (fileName == p.basename(fileName)) {
          final candidate = File(p.join(catalogDirectory.path, fileName));
          if (await candidate.exists()) selected = candidate;
        }
      }
      selectedDatabase = sqlite3.open(selected.path, mode: OpenMode.readOnly);
      _inspect(selectedDatabase);
      return CatalogDatabase._(
        selectedDatabase,
        selected.path,
        catalogDirectory,
        catalogFile.path,
      );
    } catch (_) {
      selectedDatabase?.close();
      final database = sqlite3.open(catalogFile.path, mode: OpenMode.readOnly);
      return CatalogDatabase._(
        database,
        catalogFile.path,
        catalogDirectory,
        catalogFile.path,
      );
    }
  }

  String get fileName => p.basename(_path);
  bool get isUsingUpdate => !p.equals(_path, _bundledPath);

  CatalogUpdateInfo inspectUpdate(String path) {
    Database? candidate;
    try {
      candidate = sqlite3.open(path, mode: OpenMode.readOnly);
      return _inspect(candidate);
    } catch (error) {
      if (error is CatalogUpdateException) rethrow;
      throw CatalogUpdateException('カタログファイルを読み取れません。');
    } finally {
      candidate?.close();
    }
  }

  Future<void> verifyOfficialUpdate(String sourcePath) async {
    final checksumFile = File('$sourcePath.sha256');
    if (!await checksumFile.exists()) {
      throw const CatalogUpdateException(
        '安全性を確認する .sha256 ファイルが見つかりません。公式カタログと同じフォルダへ配置してください。',
      );
    }
    final checksumText = (await checksumFile.readAsString()).trim();
    final match = RegExp(r'^[0-9a-fA-F]{64}').firstMatch(checksumText);
    if (match == null) {
      throw const CatalogUpdateException('カタログのSHA-256確認ファイルが不正です。');
    }
    final actual = await sha256.bind(File(sourcePath).openRead()).first;
    if (actual.toString().toLowerCase() != match.group(0)!.toLowerCase()) {
      throw const CatalogUpdateException(
        'カタログのSHA-256が一致しません。破損または改変の可能性があります。',
      );
    }
  }

  Future<CatalogUpdateInfo> installUpdate(String sourcePath) async {
    final preview = inspectUpdate(sourcePath);
    await _catalogDirectory.create(recursive: true);
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final targetName = 'catalog-update-$stamp.sqlite';
    final temporary = File(
      p.join(_catalogDirectory.path, '$targetName.installing'),
    );
    final target = File(p.join(_catalogDirectory.path, targetName));
    try {
      await File(sourcePath).copy(temporary.path);
      inspectUpdate(temporary.path);
      await temporary.rename(target.path);

      final next = sqlite3.open(target.path, mode: OpenMode.readOnly);
      try {
        _inspect(next);
        final pointer = File(
          p.join(_catalogDirectory.path, 'active-catalog.txt'),
        );
        await pointer.writeAsString(targetName, flush: true);
        final previous = _database;
        _database = next;
        _path = target.path;
        previous.close();
      } catch (_) {
        next.close();
        rethrow;
      }
      return preview;
    } catch (error) {
      if (await temporary.exists()) await temporary.delete();
      if (error is CatalogUpdateException) rethrow;
      throw CatalogUpdateException('カタログを安全に保存できませんでした。');
    }
  }

  Future<CatalogUpdateInfo> restoreBundled() async {
    final next = sqlite3.open(_bundledPath, mode: OpenMode.readOnly);
    try {
      final info = _inspect(next);
      final pointer = File(
        p.join(_catalogDirectory.path, 'active-catalog.txt'),
      );
      if (await pointer.exists()) await pointer.delete();
      final previous = _database;
      _database = next;
      _path = _bundledPath;
      previous.close();
      return info;
    } catch (error) {
      next.close();
      if (error is CatalogUpdateException) rethrow;
      throw CatalogUpdateException('同梱カタログへ戻せませんでした。');
    }
  }

  static CatalogUpdateInfo _inspect(Database database) {
    try {
      final check = database.select('PRAGMA quick_check').first.values.first;
      if (check != 'ok') {
        throw CatalogUpdateException('データベースの整合性を確認できません。');
      }
      const required = {
        'works': {
          'vndb_id',
          'title_ja',
          'title_romaji',
          'normalized_title',
          'image_url',
          'released',
          'developers',
          'rating',
          'vote_count',
          'min_age',
          'is_adult',
        },
        'aliases': {'work_id', 'normalized_alias'},
        'store_products': {
          'work_id',
          'store',
          'product_id',
          'landing_url',
          'is_primary',
          'source',
          'verified_at',
        },
        'metadata': {'key', 'value'},
      };
      for (final entry in required.entries) {
        final columns = database
            .select('PRAGMA table_info(${entry.key})')
            .map((row) => row['name'])
            .whereType<String>()
            .toSet();
        if (!columns.containsAll(entry.value)) {
          throw CatalogUpdateException('NoveLib用のカタログ形式ではありません。');
        }
      }
      final count = database.select('SELECT COUNT(*) count FROM works').first;
      final workCount = count['count'] as int;
      final metadata = database.select(
        "SELECT value FROM metadata WHERE key = 'source_timestamp' LIMIT 1",
      );
      final sourceTimestamp = metadata.isEmpty
          ? ''
          : metadata.first['value'] as String? ?? '';
      if (workCount < 1 || sourceTimestamp.trim().isEmpty) {
        throw CatalogUpdateException('作品または更新日時が入っていません。');
      }
      return CatalogUpdateInfo(
        workCount: workCount,
        sourceTimestamp: sourceTimestamp,
      );
    } on CatalogUpdateException {
      rethrow;
    } catch (_) {
      throw CatalogUpdateException('NoveLib用のカタログ形式ではありません。');
    }
  }

  int get workCount {
    final row = _database.select('SELECT COUNT(*) AS count FROM works').first;
    return row['count'] as int;
  }

  String get sourceTimestamp {
    final rows = _database.select(
      "SELECT value FROM metadata WHERE key = 'source_timestamp'",
    );
    return rows.isEmpty ? '' : rows.first['value'] as String;
  }

  CatalogWork? matchTitle(String title) {
    return matchTitles([title]);
  }

  CatalogWork? matchTitles(Iterable<String> titles) {
    final candidates = titles
        .expand(catalogTitleVariants)
        .where((title) => title.length >= 2)
        .toSet();
    final exact = <String, CatalogWork>{};
    for (final title in candidates) {
      final normalized = title;
      final verified = findById(_verifiedVariants[normalized]);
      if (verified != null) return verified;
      final rows = _database.select(
        '''
        SELECT DISTINCT w.vndb_id, w.title_ja, w.title_romaji, w.image_url,
          w.released, w.developers, w.rating, w.vote_count, w.min_age,
          w.is_adult
        FROM works w LEFT JOIN aliases a ON a.work_id = w.vndb_id
        WHERE w.normalized_title = ? OR a.normalized_alias = ? LIMIT 2
      ''',
        [normalized, normalized],
      );
      for (final row in rows) {
        final work = _toWork(row);
        exact[work.vndbId] = work;
      }
      // Prefer a unique exact match from the highest-priority name over a
      // lower-priority abbreviation that may describe another work.
      if (exact.length == 1) return exact.values.single;
      if (exact.length > 1) return null;
    }
    if (exact.length == 1) return exact.values.single;
    if (exact.length > 1) return null;
    final fuzzy = <String, CatalogWork>{};
    for (final title in candidates) {
      final match = _matchSingleTitle(title);
      if (match != null) fuzzy[match.vndbId] = match;
    }
    return fuzzy.length == 1 ? fuzzy.values.single : null;
  }

  CatalogWork? _matchSingleTitle(String title) {
    final normalized = normalizeCatalogTitle(title);
    if (normalized.isEmpty) return null;
    final exactRows = _database.select(
      '''
      SELECT DISTINCT
        w.vndb_id, w.title_ja, w.title_romaji, w.image_url, w.released,
        w.developers, w.rating, w.vote_count, w.min_age, w.is_adult
      FROM works w
      LEFT JOIN aliases a ON a.work_id = w.vndb_id
      WHERE w.normalized_title = ? OR a.normalized_alias = ?
      ORDER BY w.vote_count DESC
      LIMIT 1
      ''',
      [normalized, normalized],
    );
    if (exactRows.isNotEmpty) {
      return _toWork(exactRows.first);
    }

    final prefixLength = normalized.length.clamp(1, 4);
    final prefix = normalized.substring(0, prefixLength);
    final candidateRows = _database.select(
      '''
      SELECT DISTINCT
        w.vndb_id, w.title_ja, w.title_romaji, w.image_url, w.normalized_title,
        w.released, w.developers, w.rating, w.vote_count, w.min_age,
        w.is_adult, a.normalized_alias
      FROM works w
      LEFT JOIN aliases a ON a.work_id = w.vndb_id
      WHERE w.normalized_title LIKE ? OR a.normalized_alias LIKE ?
      ORDER BY w.vote_count DESC
      LIMIT 120
      ''',
      ['$prefix%', '$prefix%'],
    );
    if (candidateRows.isEmpty) return null;

    final prefixMatches = <String, Row>{};
    for (final row in candidateRows) {
      final names = [
        row['normalized_title'] as String,
        if (row['normalized_alias'] case final String alias) alias,
      ];
      if (names.any(
        (candidate) =>
            candidate.startsWith(normalized) ||
            normalized.startsWith(candidate),
      )) {
        prefixMatches[row['vndb_id'] as String] = row;
      }
    }
    if (prefixMatches.length == 1) {
      return _toWork(prefixMatches.values.single);
    }

    final bestByWork = <String, ({Row row, double score})>{};
    for (final row in candidateRows) {
      final names = [
        row['normalized_title'] as String,
        if (row['normalized_alias'] case final String alias) alias,
      ];
      final score = names
          .map((name) => _titleSimilarity(normalized, name))
          .reduce((a, b) => a > b ? a : b);
      final id = row['vndb_id'] as String;
      if (bestByWork[id] == null || score > bestByWork[id]!.score) {
        bestByWork[id] = (row: row, score: score);
      }
    }
    final scored = bestByWork.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final best = scored.first;
    final secondScore = scored.length < 2 ? 0.0 : scored[1].score;
    if (best.score >= 0.82 && best.score - secondScore >= 0.08) {
      return _toWork(best.row);
    }
    return null;
  }

  static const _verifiedVariants = {
    'rance6': 'v2047',
    'ランス6': 'v2047',
    'ランス9': 'v13802',
    'rance9': 'v13802',
    'ランス10': 'v20802',
    'rance10': 'v20802',
    '素晴らしき日々': 'v3144',
    '素晴らしき日々hd': 'v3144',
    'カルタグラ': 'v515',
    'カルタグラfhd': 'v515',
    'sennagi': 'v44199',
    '戦凪': 'v44199',
    // Some installers expose a developer name plus an abbreviated executable
    // title instead of the work title.
    'astronautssiriusryorankawarazak': 'v22180',
    'astronautssiriusryorankawarazaki': 'v22180',
    'ryorankawarazak': 'v22180',
    'ryorankawarazaki': 'v22180',
    // Common romanisation/OCR variants seen in the packaged executable name.
    'kanojyonoanetonolkenaikankei': 'v36134',
    'kanojyonoanetonoikenaikankei': 'v36134',
  };

  /// Wider suggestions require explicit user selection; not used by scanning.
  List<CatalogWork> matchingCandidates(String query, {int limit = 50}) {
    final results = <String, CatalogWork>{};
    final verified = findById(_verifiedVariants[normalizeCatalogTitle(query)]);
    if (verified != null) results[verified.vndbId] = verified;
    final suggestions = <String>[query];
    if (normalizeCatalogTitle(query) == 'fate') {
      for (final id in ['v11', 'v50']) {
        final work = findById(id);
        if (work != null) results[work.vndbId] = work;
      }
    }
    switch (normalizeCatalogTitle(query)) {
      case 'aozora':
        suggestions.add('この青空に約束を');
      case 'parfaitro':
        suggestions.add('パルフェ');
      case 'cm3d2cbl':
        suggestions.add('Custom Maid');
    }
    final withoutVersion = query
        .replaceFirst(
          RegExp(
            r'\s*[_ ]?(?:ver\.?|v)\d+(?:\.\d+)*\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    if (withoutVersion != query) suggestions.add(withoutVersion);
    final withoutEdition = query
        .replaceFirst(
          RegExp(
            r'\s*(?:fhd|full\s*hd|hd|リメイク|remake|新装)\s*(?:版)?\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    if (withoutEdition != query) suggestions.add(withoutEdition);
    suggestions.addAll(catalogTitleVariants(query));
    for (final title in suggestions) {
      for (final work in search(title, limit: limit)) {
        results.putIfAbsent(work.vndbId, () => work);
      }
    }
    return results.values.take(limit).toList();
  }

  List<CatalogWork> search(
    String query, {
    int limit = 100,
    bool showAdult = true,
  }) {
    final trimmed = query.trim();
    final ResultSet rows;
    if (trimmed.isEmpty) {
      rows = _database.select(
        '''
        SELECT vndb_id, title_ja, title_romaji, image_url, released,
               developers, rating, vote_count, min_age, is_adult
        FROM works
        WHERE (? = 1 OR is_adult = 0)
        ORDER BY vote_count DESC, rating DESC
        LIMIT ?
        ''',
        [showAdult ? 1 : 0, limit],
      );
    } else {
      final like = '%$trimmed%';
      final normalized = normalizeCatalogTitle(trimmed);
      rows = _database.select(
        '''
        SELECT DISTINCT
          w.vndb_id, w.title_ja, w.title_romaji, w.image_url, w.released,
          w.developers, w.rating, w.vote_count, w.min_age, w.is_adult
        FROM works w
        LEFT JOIN aliases a ON a.work_id = w.vndb_id
        WHERE (w.title_ja LIKE ?
           OR COALESCE(w.title_romaji, '') LIKE ?
           OR COALESCE(w.developers, '') LIKE ?
           OR a.normalized_alias LIKE ?
        ) AND (? = 1 OR w.is_adult = 0)
        ORDER BY w.vote_count DESC, w.rating DESC
        LIMIT ?
        ''',
        [like, like, like, '%$normalized%', showAdult ? 1 : 0, limit],
      );
    }
    return rows.map(_toWork).toList();
  }

  List<CatalogWork> topRated({
    int limit = 100,
    int minimumVotes = 100,
    bool showAdult = true,
  }) {
    final rows = _database.select(
      '''
      SELECT vndb_id, title_ja, title_romaji, image_url, released,
             developers, rating, vote_count, min_age, is_adult
      FROM works
      WHERE rating IS NOT NULL
        AND vote_count >= ?
        AND (? = 1 OR is_adult = 0)
      ORDER BY rating DESC, vote_count DESC, title_ja
      LIMIT ?
      ''',
      [minimumVotes, showAdult ? 1 : 0, limit],
    );
    return rows.map(_toWork).toList();
  }

  CatalogWork? findById(String? vndbId) {
    if (vndbId == null) return null;
    final rows = _database.select(
      '''
      SELECT vndb_id, title_ja, title_romaji, image_url, released,
             developers, rating, vote_count, min_age, is_adult
      FROM works
      WHERE vndb_id = ?
      LIMIT 1
      ''',
      [vndbId],
    );
    return rows.isEmpty ? null : _toWork(rows.first);
  }

  Map<String, CatalogWork> findByIds(Iterable<String> vndbIds) {
    final ids = vndbIds.toSet().toList();
    final results = <String, CatalogWork>{};
    for (var start = 0; start < ids.length; start += 900) {
      final end = (start + 900).clamp(0, ids.length);
      final chunk = ids.sublist(start, end);
      if (chunk.isEmpty) continue;
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = _database.select('''
        SELECT vndb_id, title_ja, title_romaji, image_url, released,
               developers, rating, vote_count, min_age, is_adult
        FROM works
        WHERE vndb_id IN ($placeholders)
        ''', chunk);
      for (final row in rows) {
        final work = _toWork(row);
        results[work.vndbId] = work;
      }
    }
    return results;
  }

  CatalogWork _toWork(Row row) {
    return CatalogWork(
      vndbId: row['vndb_id'] as String,
      titleJa: row['title_ja'] as String,
      titleRomaji: row['title_romaji'] as String?,
      imageUrl: row['image_url'] as String?,
      released: row['released'] as String?,
      developers: row['developers'] as String?,
      rating: row['rating'] as double?,
      voteCount: row['vote_count'] as int,
      minAge: row['min_age'] as int?,
      isAdult: row['is_adult'] == 1,
    );
  }

  List<StoreProduct> storeProductsFor(String vndbId, {String? store}) {
    final rows = _database.select(
      '''
      SELECT work_id, store, product_id, landing_url, is_primary, source,
             verified_at
      FROM store_products
      WHERE work_id = ? AND (? IS NULL OR store = ?)
      ORDER BY is_primary DESC, store, product_id
      ''',
      [vndbId, store, store],
    );
    return rows
        .map(
          (row) => StoreProduct(
            workId: row['work_id'] as String,
            store: row['store'] as String,
            productId: row['product_id'] as String,
            landingUrl: row['landing_url'] as String?,
            isPrimary: row['is_primary'] == 1,
            source: row['source'] as String?,
            verifiedAt: row['verified_at'] as String?,
          ),
        )
        .toList();
  }

  void close() => _database.close();
}

class CatalogUpdateInfo {
  const CatalogUpdateInfo({
    required this.workCount,
    required this.sourceTimestamp,
  });
  final int workCount;
  final String sourceTimestamp;
}

class CatalogUpdateException implements Exception {
  const CatalogUpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

final _catalogEditionSuffix = RegExp(
  r'(?:dl版|ダウンロード版|download版?|パッケージ版|package版?|豪華版|完全版|通常版|限定版|初回版|廉価版|普及版|復刻版|新装版|リニューアル版|renewal|リメイク版?|remake|fhd版?|fullhd版?|hd版?|windows(?:xp|vista|7|8|10|11)?対応版|全年齢(?:対象)?版|r18版)$',
  caseSensitive: false,
);

final _catalogVersionSuffix = RegExp(
  r'(?:ver|version|v)\d+(?:\.\d+)*$',
  caseSensitive: false,
);

String _foldCatalogTitle(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune >= 0xFF01 && rune <= 0xFF5E) {
      buffer.writeCharCode(rune - 0xFEE0);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString().toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]', unicode: true),
    '',
  );
}

/// Returns conservative alternatives from the written title through titles
/// with trailing version and distribution labels removed.
Set<String> catalogTitleVariants(String value) {
  final result = <String>{};
  var current = _foldCatalogTitle(value);
  if (current.isEmpty) return result;
  result.add(current);
  for (var pass = 0; pass < 4; pass++) {
    final stripped = current
        .replaceFirst(_catalogVersionSuffix, '')
        .replaceFirst(_catalogEditionSuffix, '');
    if (stripped == current || stripped.isEmpty) break;
    result.add(stripped);
    current = stripped;
  }
  return result;
}

String normalizeCatalogTitle(String value) {
  final variants = catalogTitleVariants(value);
  return variants.isEmpty ? '' : variants.last;
}

double _titleSimilarity(String left, String right) {
  if (left == right) return 1;
  if (left.isEmpty || right.isEmpty) return 0;
  final previous = List<int>.generate(right.length + 1, (index) => index);
  for (var leftIndex = 0; leftIndex < left.length; leftIndex++) {
    var diagonal = previous[0];
    previous[0] = leftIndex + 1;
    for (var rightIndex = 0; rightIndex < right.length; rightIndex++) {
      final above = previous[rightIndex + 1];
      final substitution =
          diagonal +
          (left.codeUnitAt(leftIndex) == right.codeUnitAt(rightIndex) ? 0 : 1);
      previous[rightIndex + 1] = [
        above + 1,
        previous[rightIndex] + 1,
        substitution,
      ].reduce((a, b) => a < b ? a : b);
      diagonal = above;
    }
  }
  final longest = left.length > right.length ? left.length : right.length;
  return 1 - previous.last / longest;
}
