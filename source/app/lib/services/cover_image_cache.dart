import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CoverImageCache extends ChangeNotifier {
  CoverImageCache._();
  CoverImageCache.forDirectory(Directory directory) : _directory = directory;
  static final instance = CoverImageCache._();
  final Map<String, Future<File?>> _pending = {};
  Directory? _directory;
  bool _managing = false;
  Set<String> changedIds = {};
  bool removed = false;
  final Map<String, String> failures = {};
  final Map<String, ImageFailureRecord> _failureRecords = {};
  bool _historyLoaded = false;
  Future<void> _historyWrite = Future.value();
  final Queue<Completer<void>> _waiting = Queue();
  int _active = 0;
  Future<void> _acquire() async {
    if (_active < 4) {
      _active++;
      return;
    }
    final ready = Completer<void>();
    _waiting.add(ready);
    await ready.future;
  }

  void _release() {
    if (_waiting.isEmpty) {
      _active--;
    } else {
      _waiting.removeFirst().complete();
    }
  }

  String? failureFor(String id, String url) => failures['$id|$url'];
  ImageFailureRecord? failureRecordFor(String id, String url) =>
      _failureRecords['$id|$url'];
  Map<String, ImageFailureRecord> get failureRecords =>
      UnmodifiableMapView(_failureRecords);

  Future<void> loadFailureHistory() async {
    if (_historyLoaded) return;
    _historyLoaded = true;
    try {
      final file = File(
        p.join((await _coverDirectory()).path, 'failures.json'),
      );
      if (!await file.exists()) return;
      final rows = jsonDecode(await file.readAsString()) as List;
      for (final value in rows.whereType<Map>()) {
        final record = ImageFailureRecord.fromJson(
          value.cast<String, dynamic>(),
        );
        if (record == null) continue;
        final key = '${record.id}|${record.url}';
        _failureRecords[key] = record;
        failures[key] = record.message;
      }
    } catch (_) {
      // A malformed history never prevents cached artwork from loading.
    }
  }

  void _recordFailure(String id, String url, String message) {
    final key = '$id|$url';
    final previous = _failureRecords[key];
    failures[key] = message;
    _failureRecords[key] = ImageFailureRecord(
      id: id,
      url: url,
      message: message,
      occurredAt: DateTime.now().toUtc(),
      attempts: (previous?.attempts ?? 0) + 1,
    );
    _scheduleHistoryWrite();
  }

  void _clearFailure(String id, String url) {
    final key = '$id|$url';
    final removedMessage = failures.remove(key) != null;
    final removedRecord = _failureRecords.remove(key) != null;
    final changed = removedMessage || removedRecord;
    if (changed) _scheduleHistoryWrite();
  }

  void _scheduleHistoryWrite() {
    _historyWrite = _historyWrite.then((_) async {
      try {
        final file = File(
          p.join((await _coverDirectory()).path, 'failures.json'),
        );
        await file.writeAsString(
          jsonEncode(_failureRecords.values.map((r) => r.toJson()).toList()),
          flush: true,
        );
      } catch (_) {
        // Diagnostics are best effort and must not break image display.
      }
    });
  }

  Future<void> flushFailureHistory() => _historyWrite;
  static Future<void> evictFile(File file) async {
    await FileImage(file).evict();
    await ResizeImage(FileImage(file), width: 600).evict();
  }

  Future<int> removeImages(
    Set<String> ids, {
    Iterable<String> protectedPaths = const [],
  }) async {
    if (_managing) throw StateError('画像管理を実行中です');
    if (ids.any((id) => !RegExp(r'^v[1-9][0-9]*$').hasMatch(id))) {
      throw ArgumentError('作品IDが不正です');
    }
    _managing = true;
    var count = 0;
    try {
      await Future.wait(_pending.values.toList());
      final dir = await _coverDirectory();
      final root = await dir.resolveSymbolicLinks();
      final protected = <String>[];
      for (final path in protectedPaths) {
        final file = File(path);
        if (await file.exists()) {
          protected.add(await file.resolveSymbolicLinks());
        }
      }
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        final match = RegExp(r'^(v[1-9][0-9]*)(?:_[0-9a-f]+)?\.(jpg|url)$')
            .firstMatch(name);
        if (match == null || !ids.contains(match.group(1))) continue;
        final target = await entity.resolveSymbolicLinks();
        if (protected.any((path) => p.equals(path, target))) continue;
        if (!p.isWithin(root, target)) throw StateError('キャッシュ外のファイルは削除できません');
        if (p.extension(name) == '.jpg') await evictFile(entity);
        await entity.delete();
        count++;
      }
      return count;
    } finally {
      _managing = false;
      changedIds = Set.of(ids);
      removed = true;
      notifyListeners();
    }
  }

  Future<bool> refreshImage(String id, String url) async {
    final pending = _pending['$id|$url'];
    if (pending != null) await pending;
    final file = await get(id, url, refresh: true);
    if (file != null) {
      await evictFile(file);
      changedIds = {id};
      removed = false;
      notifyListeners();
    }
    return file != null;
  }

  Future<File?> get(String vndbId, String imageUrl, {bool refresh = false}) {
    if (_managing) return Future.value(null);
    if (!RegExp(r'^v[1-9][0-9]*$').hasMatch(vndbId)) return Future.value(null);
    final key = '$vndbId|$imageUrl';
    return _pending.putIfAbsent(key, () async {
      await loadFailureHistory();
      try {
        return await _load(vndbId, imageUrl, refresh);
      } finally {
        _pending.remove(key);
      }
    });
  }

  Future<bool> _valid(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<File?> _load(String id, String url, bool refresh) async {
    try {
      // URL-specific filenames avoid reusing artwork from an older URL.
      var hash = 2166136261;
      for (final byte in url.codeUnits) {
        hash = ((hash ^ byte) * 16777619) & 0xffffffff;
      }
      final directory = await _coverDirectory();
      final file = File(
        p.join(directory.path, '${id}_${hash.toRadixString(16)}.jpg'),
      );
      // Adopt the old ID-only cache once, preserving offline use on upgrade.
      final adopted = File(p.join(directory.path, '$id.url'));
      final legacy = File(p.join(directory.path, '$id.jpg'));
      if (!await adopted.exists()) {
        if (!refresh &&
            !await file.exists() &&
            await legacy.exists() &&
            await _valid(await legacy.readAsBytes())) {
          await legacy.copy(file.path);
        }
        await adopted.writeAsString(url, flush: true);
      }
      if (!refresh &&
          await file.exists() &&
          await _valid(await file.readAsBytes())) {
        _clearFailure(id, url);
        return file;
      }
      await _acquire();
      final client = HttpClient()
        ..userAgent = 'NoveLib/0.31.0'
        ..connectionTimeout = const Duration(seconds: 15);
      try {
        final request = await client
            .getUrl(Uri.parse(url))
            .timeout(const Duration(seconds: 20));
        final response = await request.close().timeout(
          const Duration(seconds: 20),
        );
        if (response.statusCode != HttpStatus.ok) {
          _recordFailure(id, url, '配信元エラー（HTTP ${response.statusCode}）');
          return null;
        }
        final bytes = await response
            .fold<BytesBuilder>(BytesBuilder(copy: false), (buffer, data) {
              if (buffer.length + data.length > 20 * 1024 * 1024) {
                throw const FormatException('Image too large');
              }
              return buffer..add(data);
            })
            .timeout(const Duration(seconds: 20));
        final data = bytes.takeBytes();
        if (!await _valid(data)) {
          _recordFailure(id, url, '画像データを読み取れません');
          return null;
        }
        await file.writeAsBytes(data, flush: true);
        _clearFailure(id, url);
        return file;
      } finally {
        client.close(force: true);
        _release();
      }
    } on SocketException {
      _recordFailure(id, url, '接続できません（オフラインなど）');
      return null;
    } on TimeoutException {
      _recordFailure(id, url, '通信がタイムアウトしました');
      return null;
    } catch (_) {
      _recordFailure(id, url, '画像の取得・保存に失敗しました');
      return null;
    }
  }

  Future<Directory> _coverDirectory() async {
    final existing = _directory;
    if (existing != null) {
      await existing.create(recursive: true);
      return existing;
    }
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'Chronovel', 'covers'));
    await directory.create(recursive: true);
    _directory = directory;
    return directory;
  }
}

class ImageFailureRecord {
  const ImageFailureRecord({
    required this.id,
    required this.url,
    required this.message,
    required this.occurredAt,
    required this.attempts,
  });
  final String id;
  final String url;
  final String message;
  final DateTime occurredAt;
  final int attempts;

  Map<String, Object> toJson() => {
    'id': id,
    'url': url,
    'message': message,
    'occurredAt': occurredAt.toIso8601String(),
    'attempts': attempts,
  };

  static ImageFailureRecord? fromJson(Map<String, dynamic> json) {
    final id = json['id'], url = json['url'], message = json['message'];
    final occurredAt = DateTime.tryParse(json['occurredAt'] as String? ?? '');
    final attempts = json['attempts'];
    if (id is! String ||
        !RegExp(r'^v[1-9][0-9]*$').hasMatch(id) ||
        url is! String ||
        message is! String ||
        occurredAt == null ||
        attempts is! int ||
        attempts < 1) {
      return null;
    }
    return ImageFailureRecord(
      id: id,
      url: url,
      message: message,
      occurredAt: occurredAt,
      attempts: attempts,
    );
  }
}
