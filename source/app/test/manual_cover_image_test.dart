import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/services/cover_image_cache.dart';

const testCoverDownload = bool.fromEnvironment('CHRONOVEL_TEST_COVER_DOWNLOAD');

void main() {
  test('VNDBの作品画像を端末キャッシュ形式で保存する', () async {
    if (!testCoverDownload) return;

    final directory = await Directory.systemTemp.createTemp(
      'chronovel-cover-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final cache = CoverImageCache.forDirectory(directory);

    final file = await cache.get(
      'v23740',
      'https://t.vndb.org/cv/31/95131.jpg',
    );

    expect(file, isNotNull);
    expect(await file!.exists(), isTrue);
    expect(await file.length(), greaterThan(10000));
  });
}
