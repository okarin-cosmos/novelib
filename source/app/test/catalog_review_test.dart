import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/catalog/catalog_database.dart';
import 'package:chronovel/features/catalog/catalog_review_dialog.dart';
import 'package:chronovel/features/records/data_transfer.dart';
import 'package:chronovel/services/review_sync_service.dart';

import 'review_sync_service_test.dart' show FakeReviewTransport;

void main() {
  late AppDatabase db;
  late FakeReviewTransport transport;
  late ReviewSyncService sync;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    transport = FakeReviewTransport();
    sync = ReviewSyncService(
      database: db,
      transport: transport,
      isAdultWork: (_) => false,
    );
  });
  tearDown(() => db.close());
  Future<void> save(int? score, String comment) => db.setCatalogReview(
    workId: 'v123',
    title: '未登録作品',
    isAdult: true,
    rating: score,
    comment: comment,
  );

  test(
    'save without creating a library game and upload the work identity',
    () async {
      await save(8, '感想');
      expect(await db.getGames(), isEmpty);
      expect((await db.readWorkReview('v123')).rating, 8);
      expect((await sync.syncPending()).uploaded, 1);
      expect(transport.uploads.single.isAdult, isTrue);
      expect(transport.uploads.single.workId, 'v123');
      expect((await sync.syncPending()).uploaded, 0);
    },
  );
  test('comment-only reviews save without a score', () async {
    await save(null, 'comment only');
    expect((await sync.syncPending()).uploaded, 1);
    expect(transport.uploads.single.score, isNull);
    expect(transport.uploads.single.comment, 'comment only');
  });
  test('offline retry and removal are retained', () async {
    await save(9, '');
    transport.fail = true;
    expect((await sync.syncPending()).failed, 1);
    transport.fail = false;
    expect((await sync.syncPending()).uploaded, 1);
    await save(null, '');
    expect((await sync.syncPending()).deleted, 1);
  });
  test('editing during upload is not lost', () async {
    await save(7, 'old');
    transport.duringUpload = () => save(10, 'new');
    expect((await sync.syncPending()).uploaded, 0);
    expect(
      (await db.select(db.catalogReviews).get()).single.reviewSyncState,
      'pending_upsert',
    );
  });
  test(
    'later installed game reuses the work rating and does not double upload',
    () async {
      await save(7, 'before');
      await db.upsertDetectedGame(
        title: '作品',
        installDir: 'test',
        exePath: 'test/a.exe',
        engine: 'kirikiri',
        vndbId: 'v123',
      );
      expect((await db.watchGames().first).single.rating, 7);
      await save(10, 'after');
      expect((await db.getGames()).single.rating, 10);
      expect((await sync.syncPending()).uploaded, 1);
      expect(transport.uploads.single.score, 10);
    },
  );
  test(
    'backup restores catalog-only reviews with no registered games',
    () async {
      await save(8, 'backup');
      final encoded = (await LibraryBackup.capture(db)).encode();
      final backup = await LibraryBackup.parse(encoded);
      final other = AppDatabase(NativeDatabase.memory());
      try {
        await backup.restore(other);
        expect(await other.getGames(), isEmpty);
        expect((await other.readWorkReview('v123')).comment, 'backup');
      } finally {
        await other.close();
      }
    },
  );
  test('reject invalid score, work id and comment', () async {
    await expectLater(save(11, ''), throwsArgumentError);
    await expectLater(save(1, 'x' * 4001), throwsArgumentError);
    expect(await db.select(db.catalogReviews).get(), isEmpty);
  });
  testWidgets(
    'narrow dialog saves score and comment without registering a game',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => CatalogReviewDialog(
                    database: db,
                    work: const CatalogWork(
                      vndbId: 'v123',
                      titleJa: '作品',
                      voteCount: 0,
                    ),
                    sharingEnabled: false,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('このPCだけ'), findsOneWidget);
      await tester.tap(find.text('8'));
      await tester.enterText(find.byType(TextField), '感想');
      await tester.tap(find.text('保存'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      expect((await db.readWorkReview('v123')).rating, 8);
      expect(await db.getGames(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
