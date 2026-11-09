import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'fanza_link.dart';

class ReviewUpload {
  const ReviewUpload({
    required this.reviewId,
    required this.workId,
    required this.title,
    required this.isAdult,
    required this.score,
    required this.comment,
    required this.updatedAt,
  });

  final String reviewId;
  final String workId;
  final String title;
  final bool isAdult;
  final int? score;
  final String comment;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'workId': workId,
    'title': title,
    'isAdult': isAdult,
    'score': score,
    'comment': comment,
    'isPublic': true,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

class RemoteReviewReceipt {
  const RemoteReviewReceipt({required this.reviewId, required this.syncedAt});
  final String reviewId;
  final DateTime syncedAt;
}

class PublicRatingSummary {
  const PublicRatingSummary({
    required this.workId,
    required this.title,
    required this.averageScore,
    required this.ratingCount,
    required this.isAdult,
    this.publicCommentCount = 0,
    this.lastReviewedAt,
    this.fanzaUrl,
  });
  final String workId, title;
  final double averageScore;
  final int ratingCount;
  final bool isAdult;
  final int publicCommentCount;
  final DateTime? lastReviewedAt;
  final String? fanzaUrl;
}

class PublicReviewComment {
  const PublicReviewComment({
    required this.reviewId,
    required this.workId,
    required this.comment,
    required this.updatedAt,
    this.score,
  });

  final String reviewId, workId, comment;
  final int? score;
  final DateTime updatedAt;
}

class PublicReviewClient {
  PublicReviewClient({required Uri endpoint, this.client})
    : endpoint = _validatedEndpoint(endpoint);

  final Uri endpoint;
  final HttpClient? client;

  Future<List<PublicRatingSummary>> rankings({
    bool includeAdult = true,
    int minimumRatings = 1,
    int limit = 20,
    int offset = 0,
  }) async {
    final activeClient = client ?? HttpClient();
    try {
      final uri = _resolveEndpoint(endpoint, 'v1/rankings').replace(
        queryParameters: {
          'adult': '$includeAdult',
          'minimumRatings': '$minimumRatings',
          'limit': '$limit',
          'offset': '$offset',
        },
      );
      final request = await activeClient.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseText = await utf8.decoder.bind(response).join();
      if (response.statusCode != 200) {
        throw HttpException('評価ランキングを取得できません（${response.statusCode}）');
      }
      final decoded = jsonDecode(responseText) as Map<String, dynamic>;
      return (decoded['items'] as List<dynamic>).map((item) {
        final row = item as Map<String, dynamic>;
        return PublicRatingSummary(
          fanzaUrl: parseFanzaLink(row['fanza_url'])?.toString(),
          workId: row['work_id'] as String,
          title: row['title'] as String,
          averageScore: double.parse('${row['average_score']}'),
          ratingCount: int.parse('${row['rating_count']}'),
          isAdult: row['is_adult'] as bool,
          publicCommentCount: int.parse('${row['public_comment_count'] ?? 0}'),
          lastReviewedAt: DateTime.tryParse('${row['last_reviewed_at'] ?? ''}')
              ?.toLocal(),
        );
      }).toList();
    } finally {
      if (client == null) activeClient.close(force: true);
    }
  }

  Future<List<PublicReviewComment>> comments({
    required String workId,
    bool includeAdult = true,
    int limit = 20,
    int offset = 0,
  }) async {
    final activeClient = client ?? HttpClient();
    try {
      final uri = _resolveEndpoint(endpoint, 'v1/comments').replace(
        queryParameters: {
          'workId': workId,
          'adult': '$includeAdult',
          'limit': '$limit',
          'offset': '$offset',
        },
      );
      final request = await activeClient.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final responseText = await utf8.decoder.bind(response).join();
      if (response.statusCode != 200) {
        throw HttpException('評価コメントを取得できません（${response.statusCode}）');
      }
      final decoded = jsonDecode(responseText) as Map<String, dynamic>;
      return (decoded['items'] as List<dynamic>).map((item) {
        final row = item as Map<String, dynamic>;
        return PublicReviewComment(
          reviewId: row['review_id'] as String,
          workId: row['work_id'] as String,
          score: row['score'] == null ? null : int.parse('${row['score']}'),
          comment: row['comment'] as String,
          updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
        );
      }).toList();
    } finally {
      if (client == null) activeClient.close(force: true);
    }
  }
}

abstract interface class ReviewTransport {
  Future<RemoteReviewReceipt> upsert(ReviewUpload upload);
  Future<void> delete({
    required String reviewId,
    required String workId,
    required DateTime updatedAt,
  });
}

class ReviewSyncResult {
  const ReviewSyncResult({
    required this.uploaded,
    required this.deleted,
    required this.superseded,
    required this.skipped,
    required this.failed,
  });
  final int uploaded, deleted, superseded, skipped, failed;
}

class ReviewSyncService {
  const ReviewSyncService({
    required this.database,
    required this.transport,
    required this.isAdultWork,
    this.now = DateTime.now,
  });

  final AppDatabase database;
  final ReviewTransport transport;
  final bool Function(String vndbId) isAdultWork;
  final DateTime Function() now;

  Future<ReviewSyncResult> syncPending() async {
    final pending =
        [
          ...(await database.pendingReviewSync()).map(_PendingReview.game),
          ...(await (database.select(
            database.catalogReviews,
          )..where((r) => r.reviewSyncState.like('pending_%'))).get()).map(
            _PendingReview.catalog,
          ),
        ]..sort(
          (a, b) => (b.reviewUpdatedAt ?? DateTime(0)).compareTo(
            a.reviewUpdatedAt ?? DateTime(0),
          ),
        );
    final selected = <String, _PendingReview>{};
    var superseded = 0;
    var skipped = 0;
    for (final row in pending) {
      final workId = row.vndbId;
      final syncId = row.reviewSyncId;
      final updatedAt = row.reviewUpdatedAt;
      if (workId == null ||
          !RegExp(r'^v[1-9][0-9]*$').hasMatch(workId) ||
          syncId == null ||
          updatedAt == null) {
        skipped++;
        continue;
      }
      if (selected.containsKey(workId)) {
        if (await row.markSuperseded(database)) {
          superseded++;
        }
      } else {
        selected[workId] = row;
      }
    }

    var uploaded = 0;
    var deleted = 0;
    var failed = 0;
    for (final row in selected.values) {
      final syncId = row.reviewSyncId!;
      final updatedAt = row.reviewUpdatedAt!;
      try {
        if (row.reviewSyncState == 'pending_delete') {
          await transport.delete(
            reviewId: syncId,
            workId: row.vndbId!,
            updatedAt: updatedAt,
          );
          final marked = await row.markSucceeded(
            database,
            syncId,
            now().toUtc(),
          );
          if (marked) deleted++;
        } else {
          final receipt = await transport.upsert(
            ReviewUpload(
              reviewId: syncId,
              workId: row.vndbId!,
              title: row.title,
              isAdult: row.catalogRecord?.isAdult ?? isAdultWork(row.vndbId!),
              score: row.rating,
              comment: row.ratingComment ?? '',
              updatedAt: updatedAt,
            ),
          );
          final marked = await row.markSucceeded(
            database,
            receipt.reviewId,
            receipt.syncedAt,
          );
          if (marked) uploaded++;
        }
      } catch (_) {
        // Keep pending state. The next explicit/background sync can retry it.
        failed++;
      }
    }
    return ReviewSyncResult(
      uploaded: uploaded,
      deleted: deleted,
      superseded: superseded,
      skipped: skipped,
      failed: failed,
    );
  }
}

class _PendingReview {
  _PendingReview.game(this.gameRecord) : catalogRecord = null;
  _PendingReview.catalog(this.catalogRecord) : gameRecord = null;
  final GameRecord? gameRecord;
  final CatalogReview? catalogRecord;
  String? get vndbId => gameRecord?.vndbId ?? catalogRecord?.workId;
  String get title => gameRecord?.title ?? catalogRecord!.title;
  String? get reviewSyncId =>
      gameRecord?.reviewSyncId ?? catalogRecord?.reviewSyncId;
  String get reviewSyncState =>
      gameRecord?.reviewSyncState ?? catalogRecord!.reviewSyncState;
  DateTime? get reviewUpdatedAt =>
      gameRecord?.reviewUpdatedAt ?? catalogRecord?.reviewUpdatedAt;
  int? get rating =>
      gameRecord != null ? gameRecord!.rating : catalogRecord?.rating;
  String? get ratingComment => gameRecord != null
      ? gameRecord!.ratingComment
      : catalogRecord?.ratingComment;

  Future<bool> markSuperseded(AppDatabase db) {
    if (gameRecord != null) {
      return db.markReviewSyncSuperseded(
        gameId: gameRecord!.id,
        expectedSyncId: reviewSyncId!,
        expectedUpdatedAt: reviewUpdatedAt!,
      );
    }
    return _markCatalog(db, 'superseded', reviewSyncId!);
  }

  Future<bool> markSucceeded(AppDatabase db, String id, DateTime at) {
    if (gameRecord != null) {
      return db.markReviewSyncSucceeded(
        gameId: gameRecord!.id,
        expectedSyncId: reviewSyncId!,
        expectedUpdatedAt: reviewUpdatedAt!,
        expectedSyncState: reviewSyncState,
        expectedRating: rating,
        expectedComment: ratingComment,
        canonicalSyncId: id,
        syncedAt: at,
      );
    }
    return _markCatalog(db, 'synced', id);
  }

  Future<bool> _markCatalog(AppDatabase db, String state, String id) =>
      db.transaction(() async {
        final current = await (db.select(
          db.catalogReviews,
        )..where((r) => r.workId.equals(vndbId!))).getSingleOrNull();
        if (current == null ||
            current.reviewSyncId != reviewSyncId ||
            current.reviewUpdatedAt != reviewUpdatedAt ||
            current.reviewSyncState != reviewSyncState ||
            current.rating != rating ||
            current.ratingComment != ratingComment) {
          return false;
        }
        await (db.update(
          db.catalogReviews,
        )..where((r) => r.workId.equals(vndbId!))).write(
          CatalogReviewsCompanion(
            reviewSyncId: Value(id),
            reviewSyncState: Value(state),
          ),
        );
        return true;
      });
}

class HttpReviewTransport implements ReviewTransport {
  HttpReviewTransport({
    required Uri endpoint,
    required this.anonymousToken,
    HttpClient? client,
  }) : endpoint = _validatedEndpoint(endpoint),
       _client = client ?? HttpClient();

  final Uri endpoint;
  final String anonymousToken;
  final HttpClient _client;

  @override
  Future<RemoteReviewReceipt> upsert(ReviewUpload upload) async {
    final response = await _request(
      'PUT',
      '/v1/reviews/${upload.reviewId}',
      upload.toJson(),
    );
    final body = jsonDecode(response) as Map<String, dynamic>;
    return RemoteReviewReceipt(
      reviewId: body['reviewId'] as String,
      syncedAt: DateTime.parse(body['syncedAt'] as String).toUtc(),
    );
  }

  @override
  Future<void> delete({
    required String reviewId,
    required String workId,
    required DateTime updatedAt,
  }) async {
    await _request(
      'DELETE',
      '/v1/reviews/$reviewId',
      {'workId': workId, 'updatedAt': updatedAt.toUtc().toIso8601String()},
      accepted: const {204},
    );
  }

  Future<List<PublicRatingSummary>> rankings({
    bool includeAdult = true,
    int minimumRatings = 5,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = _resolveEndpoint(endpoint, 'v1/rankings').replace(
      queryParameters: {
        'adult': '$includeAdult',
        'minimumRatings': '$minimumRatings',
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final request = await _client.getUrl(uri);
    final response = await request.close().timeout(const Duration(seconds: 15));
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200) {
      throw HttpException('評価ランキングを取得できません（${response.statusCode}）');
    }
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    return (decoded['items'] as List<dynamic>).map((item) {
      final row = item as Map<String, dynamic>;
      return PublicRatingSummary(
        fanzaUrl: parseFanzaLink(row['fanza_url'])?.toString(),
        workId: row['work_id'] as String,
        title: row['title'] as String,
        averageScore: double.parse('${row['average_score']}'),
        ratingCount: int.parse('${row['rating_count']}'),
        isAdult: row['is_adult'] as bool,
        publicCommentCount: int.parse('${row['public_comment_count'] ?? 0}'),
        lastReviewedAt: DateTime.tryParse('${row['last_reviewed_at'] ?? ''}')
            ?.toLocal(),
      );
    }).toList();
  }

  Future<void> reportComment({
    required String reviewId,
    required String reason,
    String details = '',
  }) async {
    await _request(
      'POST',
      '/v1/reports',
      {'reviewId': reviewId, 'reason': reason, 'details': details},
      accepted: const {202},
    );
  }

  Future<int> eraseSharedReviews() async {
    final response = await _request('DELETE', '/v1/reviewer', const {});
    final value = jsonDecode(response) as Map<String, dynamic>;
    return int.parse('${value['deletedReviews'] ?? 0}');
  }

  Future<String> _request(
    String method,
    String path,
    Map<String, Object?> body, {
    Set<int> accepted = const {200},
  }) async {
    final request = await _client.openUrl(
      method,
      _resolveEndpoint(endpoint, path),
    );
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.authorizationHeader, 'Bearer $anonymousToken');
    request.write(jsonEncode(body));
    final response = await request.close().timeout(const Duration(seconds: 15));
    final text = await utf8.decoder.bind(response).join();
    if (!accepted.contains(response.statusCode)) {
      throw HttpException('評価同期に失敗しました（${response.statusCode}）');
    }
    return text;
  }
}

/// Resolves API paths without discarding a deployment prefix such as
/// `/functions/v1/review-api/` used by Supabase Edge Functions.
Uri _resolveEndpoint(Uri endpoint, String path) {
  final base = endpoint.path.endsWith('/')
      ? endpoint
      : endpoint.replace(path: '${endpoint.path}/');
  return base.resolve(path.startsWith('/') ? path.substring(1) : path);
}

Uri _validatedEndpoint(Uri endpoint) {
  final local =
      endpoint.host == 'localhost' ||
      endpoint.host == '127.0.0.1' ||
      endpoint.host == '::1';
  if (!endpoint.hasAuthority || (endpoint.scheme != 'https' && !local)) {
    throw ArgumentError('評価APIはHTTPSのURLを指定してください。');
  }
  return endpoint;
}

String createAnonymousReviewToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}
