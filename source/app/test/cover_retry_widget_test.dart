import 'package:flutter/material.dart';

import 'dart:io';

import 'package:chronovel/services/cover_image_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/widgets/cover_image.dart';

class FailedCache extends CoverImageCache {
  FailedCache() : super.forDirectory(Directory('.'));
  int calls = 0;
  @override
  Future<File?> get(String id, String url, {bool refresh = false}) async {
    calls++;
    return null;
  }
}

void main() {
  testWidgets('画像失敗時の再試行は親カードの操作を実行しない', (tester) async {
    var cardTaps = 0;
    final cache = FailedCache();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: () => cardTaps++,
            child: SizedBox(
              width: 200,
              height: 300,
              child: CachedCoverImage(
                cache: cache,
                vndbId: 'v1',
                imageUrl: 'http://127.0.0.1:1/fail',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.byTooltip('画像を取得できませんでした。クリックして再試行');
    expect(retry, findsOneWidget);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(retry, findsOneWidget);
    expect(cardTaps, 0);
    expect(cache.calls, 2);
    expect(tester.takeException(), isNull);
  });
}
