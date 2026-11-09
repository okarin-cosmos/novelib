import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/services/review_sync_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeReviewTransport implements ReviewTransport {
  final uploads = <ReviewUpload>[];
  final deletes = <String>[];
  Future<void> Function()? duringUpload;
  bool fail = false;

  @override
  Future<RemoteReviewReceipt> upsert(ReviewUpload upload) async {
    uploads.add(upload);
    await duringUpload?.call();
    if (fail) throw StateError('offline');
    return RemoteReviewReceipt(
      reviewId: upload.reviewId,
      syncedAt: DateTime.utc(2026, 1, 2),
    );
  }

  @override
  Future<void> delete({
    required String reviewId,
    required String workId,
    required DateTime updatedAt,
  }) async {
    deletes.add(workId);
    if (fail) throw StateError('offline');
  }
}

void main() {
  late AppDatabase database;
  late FakeReviewTransport transport;
  late ReviewSyncService service;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    transport = FakeReviewTransport();
    service = ReviewSyncService(
      database: database,
      transport: transport,
      isAdultWork: (_) => true,
      now: () => DateTime.utc(2026, 1, 2),
    );
    await database.upsertDetectedGame(
      title: '作品',
      installDir: r'D:\game\work',
      exePath: r'D:\game\work\game.exe',
      engine: 'kirikiri',
      vndbId: 'v123',
    );
  });

  tearDown(() => database.close());

  test('評価点とコメントだけを同期して成功状態にする', () async {
    await database.setGameReview(1, 9, '良かった');
    final result = await service.syncPending();
    expect(result.uploaded, 1);
    expect(result.failed, 0);
    expect(transport.uploads.single.toJson(), {
      'workId': 'v123',
      'title': '作品',
      'isAdult': true,
      'score': 9,
      'comment': '良かった',
      'isPublic': true,
      'updatedAt': isA<String>(),
    });
    final saved = (await database.getGames()).single;
    expect(saved.reviewSyncState, 'synced');
    expect(saved.syncedAt?.toUtc(), DateTime.utc(2026, 1, 2));
  });

  test('通信中に再編集された評価を同期済みにしない', () async {
    await database.setGameReview(1, 8, '最初');
    transport.duringUpload = () => database.setGameReview(1, 10, '更新');
    final result = await service.syncPending();
    expect(result.uploaded, 0);
    final saved = (await database.getGames()).single;
    expect(saved.rating, 10);
    expect(saved.reviewSyncState, 'pending_upsert');
  });

  test('削除は再送でき、通信失敗時は同期待ちを維持する', () async {
    await database.setGameReview(1, 7, '削除予定');
    await database.setGameReview(1, null, '');
    transport.fail = true;
    expect((await service.syncPending()).failed, 1);
    expect(
      (await database.getGames()).single.reviewSyncState,
      'pending_delete',
    );
    transport.fail = false;
    expect((await service.syncPending()).deleted, 1);
    expect((await database.getGames()).single.reviewSyncState, 'synced');
  });

  test('同一作品の複数インストールは最新候補だけを送る', () async {
    await database.upsertDetectedGame(
      title: '作品 別インストール',
      installDir: r'D:\game\work2',
      exePath: r'D:\game\work2\game.exe',
      engine: 'kirikiri',
      vndbId: 'v123',
    );
    await database.setGameReview(1, 7, '一つ目');
    await database.setGameReview(2, 9, '二つ目');
    final result = await service.syncPending();
    expect(transport.uploads, hasLength(1));
    expect(result.uploaded, 1);
    expect(result.superseded, 1);
    expect(await database.pendingReviewSync(), isEmpty);
  });

  test('匿名トークンは256bit相当で、外部HTTPはHTTPSのみ許可する', () {
    expect(createAnonymousReviewToken(), hasLength(43));
    expect(
      () => HttpReviewTransport(
        endpoint: Uri.parse('http://example.com'),
        anonymousToken: createAnonymousReviewToken(),
      ),
      throwsArgumentError,
    );
  });
}
