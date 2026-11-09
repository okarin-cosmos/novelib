import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/services/cover_image_cache.dart';

void main() {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
  );
  test('取得失敗後の再試行、破損キャッシュ、URL変更と強制更新', () async {
    final dir = await Directory.systemTemp.createTemp('chronovel_cover_test_');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
      await dir.delete(recursive: true);
    });
    var requests = 0;
    var fail = true;
    server.listen((request) async {
      requests++;
      request.response.statusCode = fail ? 503 : 200;
      if (!fail) request.response.add(png);
      await request.response.close();
    });
    final cache = CoverImageCache.forDirectory(dir);
    final url = 'http://127.0.0.1:${server.port}/one';
    expect(await cache.get('v1', url), isNull);
    expect(cache.failureFor('v1', url), contains('503'));
    expect(cache.failureRecordFor('v1', url)?.attempts, 1);
    await cache.flushFailureHistory();
    final restored = CoverImageCache.forDirectory(dir);
    await restored.loadFailureHistory();
    expect(restored.failureFor('v1', url), contains('503'));
    expect(restored.failureRecordFor('v1', url)?.attempts, 1);
    fail = false;
    final image = await cache.get('v1', url);
    expect(image, isNotNull);
    expect(cache.failureFor('v1', url), isNull);
    await cache.flushFailureHistory();
    final cleared = CoverImageCache.forDirectory(dir);
    await cleared.loadFailureHistory();
    expect(cleared.failureFor('v1', url), isNull);
    expect(requests, 2);
    expect(await cache.get('v1', url), isNotNull);
    expect(requests, 2);
    await image!.writeAsString('broken');
    expect(await cache.get('v1', url), isNotNull);
    expect(requests, 3);
    final changed = await cache.get('v1', '$url/two');
    expect(changed!.path, isNot(image.path));
    expect(requests, 4);
    expect(await cache.get('v1', '$url/two', refresh: true), isNotNull);
    expect(requests, 5);
    expect(await cache.get('../bad', url), isNull);
  });
  test('壊れた画像エラー履歴は起動を妨げない', () async {
    final dir = await Directory.systemTemp.createTemp('chronovel_history_');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/failures.json').writeAsString('{broken');
    final cache = CoverImageCache.forDirectory(dir);
    await cache.loadFailureHistory();
    expect(cache.failureRecords, isEmpty);
  });
  test('既存キャッシュはネットワーク接続なしで引き継ぐ', () async {
    final dir = await Directory.systemTemp.createTemp(
      'chronovel_legacy_cover_',
    );
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/v2.jpg').writeAsBytes(png);
    final cache = CoverImageCache.forDirectory(dir);
    expect(
      await cache.get('v2', 'http://127.0.0.1:1/not-connected'),
      isNotNull,
    );
    expect(await File('${dir.path}/v2.jpg').exists(), isTrue);
  });
  test('画像の並列処理は4件まで・失敗後も次の待機分を処理する', () async {
    final dir = await Directory.systemTemp.createTemp('chronovel_queue_');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
      await dir.delete(recursive: true);
    });
    var active = 0, peak = 0, requests = 0;
    server.listen((request) async {
      active++;
      requests++;
      if (active > peak) peak = active;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      request.response.statusCode = 503;
      await request.response.close();
      active--;
    });
    final cache = CoverImageCache.forDirectory(dir);
    await Future.wait([
      for (var i = 1; i <= 12; i++)
        cache.get('v$i', 'http://127.0.0.1:${server.port}/$i'),
    ]);
    expect(requests, 12);
    expect(peak, lessThanOrEqualTo(4));
    expect(peak, greaterThan(1));
    await cache.flushFailureHistory();
  });
}
