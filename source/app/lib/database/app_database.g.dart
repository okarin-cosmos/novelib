// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ScanFoldersTable extends ScanFolders
    with TableInfo<$ScanFoldersTable, ScanFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, path];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
    );
  }

  @override
  $ScanFoldersTable createAlias(String alias) {
    return $ScanFoldersTable(attachedDatabase, alias);
  }
}

class ScanFolder extends DataClass implements Insertable<ScanFolder> {
  final int id;
  final String path;
  const ScanFolder({required this.id, required this.path});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['path'] = Variable<String>(path);
    return map;
  }

  ScanFoldersCompanion toCompanion(bool nullToAbsent) {
    return ScanFoldersCompanion(id: Value(id), path: Value(path));
  }

  factory ScanFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanFolder(
      id: serializer.fromJson<int>(json['id']),
      path: serializer.fromJson<String>(json['path']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'path': serializer.toJson<String>(path),
    };
  }

  ScanFolder copyWith({int? id, String? path}) =>
      ScanFolder(id: id ?? this.id, path: path ?? this.path);
  ScanFolder copyWithCompanion(ScanFoldersCompanion data) {
    return ScanFolder(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanFolder(')
          ..write('id: $id, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanFolder && other.id == this.id && other.path == this.path);
}

class ScanFoldersCompanion extends UpdateCompanion<ScanFolder> {
  final Value<int> id;
  final Value<String> path;
  const ScanFoldersCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
  });
  ScanFoldersCompanion.insert({
    this.id = const Value.absent(),
    required String path,
  }) : path = Value(path);
  static Insertable<ScanFolder> custom({
    Expression<int>? id,
    Expression<String>? path,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
    });
  }

  ScanFoldersCompanion copyWith({Value<int>? id, Value<String>? path}) {
    return ScanFoldersCompanion(id: id ?? this.id, path: path ?? this.path);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanFoldersCompanion(')
          ..write('id: $id, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }
}

class $GamesTable extends Games with TableInfo<$GamesTable, GameRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installDirMeta = const VerificationMeta(
    'installDir',
  );
  @override
  late final GeneratedColumn<String> installDir = GeneratedColumn<String>(
    'install_dir',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _exePathMeta = const VerificationMeta(
    'exePath',
  );
  @override
  late final GeneratedColumn<String> exePath = GeneratedColumn<String>(
    'exe_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _engineMeta = const VerificationMeta('engine');
  @override
  late final GeneratedColumn<String> engine = GeneratedColumn<String>(
    'engine',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rjCodeMeta = const VerificationMeta('rjCode');
  @override
  late final GeneratedColumn<String> rjCode = GeneratedColumn<String>(
    'rj_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vndbIdMeta = const VerificationMeta('vndbId');
  @override
  late final GeneratedColumn<String> vndbId = GeneratedColumn<String>(
    'vndb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _workKeyMeta = const VerificationMeta(
    'workKey',
  );
  @override
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchStatusMeta = const VerificationMeta(
    'matchStatus',
  );
  @override
  late final GeneratedColumn<String> matchStatus = GeneratedColumn<String>(
    'match_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unmatched'),
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataOverridesMeta = const VerificationMeta(
    'metadataOverrides',
  );
  @override
  late final GeneratedColumn<String> metadataOverrides =
      GeneratedColumn<String>(
        'metadata_overrides',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('not_played'),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingCommentMeta = const VerificationMeta(
    'ratingComment',
  );
  @override
  late final GeneratedColumn<String> ratingComment = GeneratedColumn<String>(
    'rating_comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewSyncIdMeta = const VerificationMeta(
    'reviewSyncId',
  );
  @override
  late final GeneratedColumn<String> reviewSyncId = GeneratedColumn<String>(
    'review_sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewSyncStateMeta = const VerificationMeta(
    'reviewSyncState',
  );
  @override
  late final GeneratedColumn<String> reviewSyncState = GeneratedColumn<String>(
    'review_sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _reviewUpdatedAtMeta = const VerificationMeta(
    'reviewUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewUpdatedAt =
      GeneratedColumn<DateTime>(
        'review_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ratedAtMeta = const VerificationMeta(
    'ratedAt',
  );
  @override
  late final GeneratedColumn<DateTime> ratedAt = GeneratedColumn<DateTime>(
    'rated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPlaySecMeta = const VerificationMeta(
    'totalPlaySec',
  );
  @override
  late final GeneratedColumn<int> totalPlaySec = GeneratedColumn<int>(
    'total_play_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    installDir,
    exePath,
    engine,
    rjCode,
    vndbId,
    workKey,
    matchStatus,
    thumbnailUrl,
    metadataOverrides,
    status,
    rating,
    ratingComment,
    reviewSyncId,
    reviewSyncState,
    reviewUpdatedAt,
    ratedAt,
    totalPlaySec,
    lastPlayedAt,
    createdAt,
    localUpdatedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'games';
  @override
  VerificationContext validateIntegrity(
    Insertable<GameRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('install_dir')) {
      context.handle(
        _installDirMeta,
        installDir.isAcceptableOrUnknown(data['install_dir']!, _installDirMeta),
      );
    } else if (isInserting) {
      context.missing(_installDirMeta);
    }
    if (data.containsKey('exe_path')) {
      context.handle(
        _exePathMeta,
        exePath.isAcceptableOrUnknown(data['exe_path']!, _exePathMeta),
      );
    } else if (isInserting) {
      context.missing(_exePathMeta);
    }
    if (data.containsKey('engine')) {
      context.handle(
        _engineMeta,
        engine.isAcceptableOrUnknown(data['engine']!, _engineMeta),
      );
    }
    if (data.containsKey('rj_code')) {
      context.handle(
        _rjCodeMeta,
        rjCode.isAcceptableOrUnknown(data['rj_code']!, _rjCodeMeta),
      );
    }
    if (data.containsKey('vndb_id')) {
      context.handle(
        _vndbIdMeta,
        vndbId.isAcceptableOrUnknown(data['vndb_id']!, _vndbIdMeta),
      );
    }
    if (data.containsKey('work_key')) {
      context.handle(
        _workKeyMeta,
        workKey.isAcceptableOrUnknown(data['work_key']!, _workKeyMeta),
      );
    }
    if (data.containsKey('match_status')) {
      context.handle(
        _matchStatusMeta,
        matchStatus.isAcceptableOrUnknown(
          data['match_status']!,
          _matchStatusMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('metadata_overrides')) {
      context.handle(
        _metadataOverridesMeta,
        metadataOverrides.isAcceptableOrUnknown(
          data['metadata_overrides']!,
          _metadataOverridesMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('rating_comment')) {
      context.handle(
        _ratingCommentMeta,
        ratingComment.isAcceptableOrUnknown(
          data['rating_comment']!,
          _ratingCommentMeta,
        ),
      );
    }
    if (data.containsKey('review_sync_id')) {
      context.handle(
        _reviewSyncIdMeta,
        reviewSyncId.isAcceptableOrUnknown(
          data['review_sync_id']!,
          _reviewSyncIdMeta,
        ),
      );
    }
    if (data.containsKey('review_sync_state')) {
      context.handle(
        _reviewSyncStateMeta,
        reviewSyncState.isAcceptableOrUnknown(
          data['review_sync_state']!,
          _reviewSyncStateMeta,
        ),
      );
    }
    if (data.containsKey('review_updated_at')) {
      context.handle(
        _reviewUpdatedAtMeta,
        reviewUpdatedAt.isAcceptableOrUnknown(
          data['review_updated_at']!,
          _reviewUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('rated_at')) {
      context.handle(
        _ratedAtMeta,
        ratedAt.isAcceptableOrUnknown(data['rated_at']!, _ratedAtMeta),
      );
    }
    if (data.containsKey('total_play_sec')) {
      context.handle(
        _totalPlaySecMeta,
        totalPlaySec.isAcceptableOrUnknown(
          data['total_play_sec']!,
          _totalPlaySecMeta,
        ),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      installDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_dir'],
      )!,
      exePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exe_path'],
      )!,
      engine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}engine'],
      ),
      rjCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rj_code'],
      ),
      vndbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vndb_id'],
      ),
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      ),
      matchStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_status'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      metadataOverrides: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_overrides'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      ratingComment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating_comment'],
      ),
      reviewSyncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_sync_id'],
      ),
      reviewSyncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_sync_state'],
      )!,
      reviewUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}review_updated_at'],
      ),
      ratedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rated_at'],
      ),
      totalPlaySec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_play_sec'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $GamesTable createAlias(String alias) {
    return $GamesTable(attachedDatabase, alias);
  }
}

class GameRecord extends DataClass implements Insertable<GameRecord> {
  final int id;
  final String title;
  final String installDir;
  final String exePath;
  final String? engine;
  final String? rjCode;
  final String? vndbId;
  final String? workKey;
  final String matchStatus;
  final String? thumbnailUrl;
  final String? metadataOverrides;
  final String status;
  final int? rating;
  final String? ratingComment;
  final String? reviewSyncId;
  final String reviewSyncState;
  final DateTime? reviewUpdatedAt;
  final DateTime? ratedAt;
  final int totalPlaySec;
  final DateTime? lastPlayedAt;
  final DateTime createdAt;
  final DateTime localUpdatedAt;
  final DateTime? syncedAt;
  const GameRecord({
    required this.id,
    required this.title,
    required this.installDir,
    required this.exePath,
    this.engine,
    this.rjCode,
    this.vndbId,
    this.workKey,
    required this.matchStatus,
    this.thumbnailUrl,
    this.metadataOverrides,
    required this.status,
    this.rating,
    this.ratingComment,
    this.reviewSyncId,
    required this.reviewSyncState,
    this.reviewUpdatedAt,
    this.ratedAt,
    required this.totalPlaySec,
    this.lastPlayedAt,
    required this.createdAt,
    required this.localUpdatedAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['install_dir'] = Variable<String>(installDir);
    map['exe_path'] = Variable<String>(exePath);
    if (!nullToAbsent || engine != null) {
      map['engine'] = Variable<String>(engine);
    }
    if (!nullToAbsent || rjCode != null) {
      map['rj_code'] = Variable<String>(rjCode);
    }
    if (!nullToAbsent || vndbId != null) {
      map['vndb_id'] = Variable<String>(vndbId);
    }
    if (!nullToAbsent || workKey != null) {
      map['work_key'] = Variable<String>(workKey);
    }
    map['match_status'] = Variable<String>(matchStatus);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || metadataOverrides != null) {
      map['metadata_overrides'] = Variable<String>(metadataOverrides);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    if (!nullToAbsent || ratingComment != null) {
      map['rating_comment'] = Variable<String>(ratingComment);
    }
    if (!nullToAbsent || reviewSyncId != null) {
      map['review_sync_id'] = Variable<String>(reviewSyncId);
    }
    map['review_sync_state'] = Variable<String>(reviewSyncState);
    if (!nullToAbsent || reviewUpdatedAt != null) {
      map['review_updated_at'] = Variable<DateTime>(reviewUpdatedAt);
    }
    if (!nullToAbsent || ratedAt != null) {
      map['rated_at'] = Variable<DateTime>(ratedAt);
    }
    map['total_play_sec'] = Variable<int>(totalPlaySec);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  GamesCompanion toCompanion(bool nullToAbsent) {
    return GamesCompanion(
      id: Value(id),
      title: Value(title),
      installDir: Value(installDir),
      exePath: Value(exePath),
      engine: engine == null && nullToAbsent
          ? const Value.absent()
          : Value(engine),
      rjCode: rjCode == null && nullToAbsent
          ? const Value.absent()
          : Value(rjCode),
      vndbId: vndbId == null && nullToAbsent
          ? const Value.absent()
          : Value(vndbId),
      workKey: workKey == null && nullToAbsent
          ? const Value.absent()
          : Value(workKey),
      matchStatus: Value(matchStatus),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      metadataOverrides: metadataOverrides == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataOverrides),
      status: Value(status),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      ratingComment: ratingComment == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingComment),
      reviewSyncId: reviewSyncId == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewSyncId),
      reviewSyncState: Value(reviewSyncState),
      reviewUpdatedAt: reviewUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewUpdatedAt),
      ratedAt: ratedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(ratedAt),
      totalPlaySec: Value(totalPlaySec),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      createdAt: Value(createdAt),
      localUpdatedAt: Value(localUpdatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory GameRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameRecord(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      installDir: serializer.fromJson<String>(json['installDir']),
      exePath: serializer.fromJson<String>(json['exePath']),
      engine: serializer.fromJson<String?>(json['engine']),
      rjCode: serializer.fromJson<String?>(json['rjCode']),
      vndbId: serializer.fromJson<String?>(json['vndbId']),
      workKey: serializer.fromJson<String?>(json['workKey']),
      matchStatus: serializer.fromJson<String>(json['matchStatus']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      metadataOverrides: serializer.fromJson<String?>(
        json['metadataOverrides'],
      ),
      status: serializer.fromJson<String>(json['status']),
      rating: serializer.fromJson<int?>(json['rating']),
      ratingComment: serializer.fromJson<String?>(json['ratingComment']),
      reviewSyncId: serializer.fromJson<String?>(json['reviewSyncId']),
      reviewSyncState: serializer.fromJson<String>(json['reviewSyncState']),
      reviewUpdatedAt: serializer.fromJson<DateTime?>(json['reviewUpdatedAt']),
      ratedAt: serializer.fromJson<DateTime?>(json['ratedAt']),
      totalPlaySec: serializer.fromJson<int>(json['totalPlaySec']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'installDir': serializer.toJson<String>(installDir),
      'exePath': serializer.toJson<String>(exePath),
      'engine': serializer.toJson<String?>(engine),
      'rjCode': serializer.toJson<String?>(rjCode),
      'vndbId': serializer.toJson<String?>(vndbId),
      'workKey': serializer.toJson<String?>(workKey),
      'matchStatus': serializer.toJson<String>(matchStatus),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'metadataOverrides': serializer.toJson<String?>(metadataOverrides),
      'status': serializer.toJson<String>(status),
      'rating': serializer.toJson<int?>(rating),
      'ratingComment': serializer.toJson<String?>(ratingComment),
      'reviewSyncId': serializer.toJson<String?>(reviewSyncId),
      'reviewSyncState': serializer.toJson<String>(reviewSyncState),
      'reviewUpdatedAt': serializer.toJson<DateTime?>(reviewUpdatedAt),
      'ratedAt': serializer.toJson<DateTime?>(ratedAt),
      'totalPlaySec': serializer.toJson<int>(totalPlaySec),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  GameRecord copyWith({
    int? id,
    String? title,
    String? installDir,
    String? exePath,
    Value<String?> engine = const Value.absent(),
    Value<String?> rjCode = const Value.absent(),
    Value<String?> vndbId = const Value.absent(),
    Value<String?> workKey = const Value.absent(),
    String? matchStatus,
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<String?> metadataOverrides = const Value.absent(),
    String? status,
    Value<int?> rating = const Value.absent(),
    Value<String?> ratingComment = const Value.absent(),
    Value<String?> reviewSyncId = const Value.absent(),
    String? reviewSyncState,
    Value<DateTime?> reviewUpdatedAt = const Value.absent(),
    Value<DateTime?> ratedAt = const Value.absent(),
    int? totalPlaySec,
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? localUpdatedAt,
    Value<DateTime?> syncedAt = const Value.absent(),
  }) => GameRecord(
    id: id ?? this.id,
    title: title ?? this.title,
    installDir: installDir ?? this.installDir,
    exePath: exePath ?? this.exePath,
    engine: engine.present ? engine.value : this.engine,
    rjCode: rjCode.present ? rjCode.value : this.rjCode,
    vndbId: vndbId.present ? vndbId.value : this.vndbId,
    workKey: workKey.present ? workKey.value : this.workKey,
    matchStatus: matchStatus ?? this.matchStatus,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    metadataOverrides: metadataOverrides.present
        ? metadataOverrides.value
        : this.metadataOverrides,
    status: status ?? this.status,
    rating: rating.present ? rating.value : this.rating,
    ratingComment: ratingComment.present
        ? ratingComment.value
        : this.ratingComment,
    reviewSyncId: reviewSyncId.present ? reviewSyncId.value : this.reviewSyncId,
    reviewSyncState: reviewSyncState ?? this.reviewSyncState,
    reviewUpdatedAt: reviewUpdatedAt.present
        ? reviewUpdatedAt.value
        : this.reviewUpdatedAt,
    ratedAt: ratedAt.present ? ratedAt.value : this.ratedAt,
    totalPlaySec: totalPlaySec ?? this.totalPlaySec,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    createdAt: createdAt ?? this.createdAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  GameRecord copyWithCompanion(GamesCompanion data) {
    return GameRecord(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      installDir: data.installDir.present
          ? data.installDir.value
          : this.installDir,
      exePath: data.exePath.present ? data.exePath.value : this.exePath,
      engine: data.engine.present ? data.engine.value : this.engine,
      rjCode: data.rjCode.present ? data.rjCode.value : this.rjCode,
      vndbId: data.vndbId.present ? data.vndbId.value : this.vndbId,
      workKey: data.workKey.present ? data.workKey.value : this.workKey,
      matchStatus: data.matchStatus.present
          ? data.matchStatus.value
          : this.matchStatus,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      metadataOverrides: data.metadataOverrides.present
          ? data.metadataOverrides.value
          : this.metadataOverrides,
      status: data.status.present ? data.status.value : this.status,
      rating: data.rating.present ? data.rating.value : this.rating,
      ratingComment: data.ratingComment.present
          ? data.ratingComment.value
          : this.ratingComment,
      reviewSyncId: data.reviewSyncId.present
          ? data.reviewSyncId.value
          : this.reviewSyncId,
      reviewSyncState: data.reviewSyncState.present
          ? data.reviewSyncState.value
          : this.reviewSyncState,
      reviewUpdatedAt: data.reviewUpdatedAt.present
          ? data.reviewUpdatedAt.value
          : this.reviewUpdatedAt,
      ratedAt: data.ratedAt.present ? data.ratedAt.value : this.ratedAt,
      totalPlaySec: data.totalPlaySec.present
          ? data.totalPlaySec.value
          : this.totalPlaySec,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameRecord(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('installDir: $installDir, ')
          ..write('exePath: $exePath, ')
          ..write('engine: $engine, ')
          ..write('rjCode: $rjCode, ')
          ..write('vndbId: $vndbId, ')
          ..write('workKey: $workKey, ')
          ..write('matchStatus: $matchStatus, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('metadataOverrides: $metadataOverrides, ')
          ..write('status: $status, ')
          ..write('rating: $rating, ')
          ..write('ratingComment: $ratingComment, ')
          ..write('reviewSyncId: $reviewSyncId, ')
          ..write('reviewSyncState: $reviewSyncState, ')
          ..write('reviewUpdatedAt: $reviewUpdatedAt, ')
          ..write('ratedAt: $ratedAt, ')
          ..write('totalPlaySec: $totalPlaySec, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    installDir,
    exePath,
    engine,
    rjCode,
    vndbId,
    workKey,
    matchStatus,
    thumbnailUrl,
    metadataOverrides,
    status,
    rating,
    ratingComment,
    reviewSyncId,
    reviewSyncState,
    reviewUpdatedAt,
    ratedAt,
    totalPlaySec,
    lastPlayedAt,
    createdAt,
    localUpdatedAt,
    syncedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameRecord &&
          other.id == this.id &&
          other.title == this.title &&
          other.installDir == this.installDir &&
          other.exePath == this.exePath &&
          other.engine == this.engine &&
          other.rjCode == this.rjCode &&
          other.vndbId == this.vndbId &&
          other.workKey == this.workKey &&
          other.matchStatus == this.matchStatus &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.metadataOverrides == this.metadataOverrides &&
          other.status == this.status &&
          other.rating == this.rating &&
          other.ratingComment == this.ratingComment &&
          other.reviewSyncId == this.reviewSyncId &&
          other.reviewSyncState == this.reviewSyncState &&
          other.reviewUpdatedAt == this.reviewUpdatedAt &&
          other.ratedAt == this.ratedAt &&
          other.totalPlaySec == this.totalPlaySec &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.createdAt == this.createdAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.syncedAt == this.syncedAt);
}

class GamesCompanion extends UpdateCompanion<GameRecord> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> installDir;
  final Value<String> exePath;
  final Value<String?> engine;
  final Value<String?> rjCode;
  final Value<String?> vndbId;
  final Value<String?> workKey;
  final Value<String> matchStatus;
  final Value<String?> thumbnailUrl;
  final Value<String?> metadataOverrides;
  final Value<String> status;
  final Value<int?> rating;
  final Value<String?> ratingComment;
  final Value<String?> reviewSyncId;
  final Value<String> reviewSyncState;
  final Value<DateTime?> reviewUpdatedAt;
  final Value<DateTime?> ratedAt;
  final Value<int> totalPlaySec;
  final Value<DateTime?> lastPlayedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> syncedAt;
  const GamesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.installDir = const Value.absent(),
    this.exePath = const Value.absent(),
    this.engine = const Value.absent(),
    this.rjCode = const Value.absent(),
    this.vndbId = const Value.absent(),
    this.workKey = const Value.absent(),
    this.matchStatus = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.metadataOverrides = const Value.absent(),
    this.status = const Value.absent(),
    this.rating = const Value.absent(),
    this.ratingComment = const Value.absent(),
    this.reviewSyncId = const Value.absent(),
    this.reviewSyncState = const Value.absent(),
    this.reviewUpdatedAt = const Value.absent(),
    this.ratedAt = const Value.absent(),
    this.totalPlaySec = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  GamesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String installDir,
    required String exePath,
    this.engine = const Value.absent(),
    this.rjCode = const Value.absent(),
    this.vndbId = const Value.absent(),
    this.workKey = const Value.absent(),
    this.matchStatus = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.metadataOverrides = const Value.absent(),
    this.status = const Value.absent(),
    this.rating = const Value.absent(),
    this.ratingComment = const Value.absent(),
    this.reviewSyncId = const Value.absent(),
    this.reviewSyncState = const Value.absent(),
    this.reviewUpdatedAt = const Value.absent(),
    this.ratedAt = const Value.absent(),
    this.totalPlaySec = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime localUpdatedAt,
    this.syncedAt = const Value.absent(),
  }) : title = Value(title),
       installDir = Value(installDir),
       exePath = Value(exePath),
       createdAt = Value(createdAt),
       localUpdatedAt = Value(localUpdatedAt);
  static Insertable<GameRecord> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? installDir,
    Expression<String>? exePath,
    Expression<String>? engine,
    Expression<String>? rjCode,
    Expression<String>? vndbId,
    Expression<String>? workKey,
    Expression<String>? matchStatus,
    Expression<String>? thumbnailUrl,
    Expression<String>? metadataOverrides,
    Expression<String>? status,
    Expression<int>? rating,
    Expression<String>? ratingComment,
    Expression<String>? reviewSyncId,
    Expression<String>? reviewSyncState,
    Expression<DateTime>? reviewUpdatedAt,
    Expression<DateTime>? ratedAt,
    Expression<int>? totalPlaySec,
    Expression<DateTime>? lastPlayedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (installDir != null) 'install_dir': installDir,
      if (exePath != null) 'exe_path': exePath,
      if (engine != null) 'engine': engine,
      if (rjCode != null) 'rj_code': rjCode,
      if (vndbId != null) 'vndb_id': vndbId,
      if (workKey != null) 'work_key': workKey,
      if (matchStatus != null) 'match_status': matchStatus,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (metadataOverrides != null) 'metadata_overrides': metadataOverrides,
      if (status != null) 'status': status,
      if (rating != null) 'rating': rating,
      if (ratingComment != null) 'rating_comment': ratingComment,
      if (reviewSyncId != null) 'review_sync_id': reviewSyncId,
      if (reviewSyncState != null) 'review_sync_state': reviewSyncState,
      if (reviewUpdatedAt != null) 'review_updated_at': reviewUpdatedAt,
      if (ratedAt != null) 'rated_at': ratedAt,
      if (totalPlaySec != null) 'total_play_sec': totalPlaySec,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  GamesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? installDir,
    Value<String>? exePath,
    Value<String?>? engine,
    Value<String?>? rjCode,
    Value<String?>? vndbId,
    Value<String?>? workKey,
    Value<String>? matchStatus,
    Value<String?>? thumbnailUrl,
    Value<String?>? metadataOverrides,
    Value<String>? status,
    Value<int?>? rating,
    Value<String?>? ratingComment,
    Value<String?>? reviewSyncId,
    Value<String>? reviewSyncState,
    Value<DateTime?>? reviewUpdatedAt,
    Value<DateTime?>? ratedAt,
    Value<int>? totalPlaySec,
    Value<DateTime?>? lastPlayedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? syncedAt,
  }) {
    return GamesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      installDir: installDir ?? this.installDir,
      exePath: exePath ?? this.exePath,
      engine: engine ?? this.engine,
      rjCode: rjCode ?? this.rjCode,
      vndbId: vndbId ?? this.vndbId,
      workKey: workKey ?? this.workKey,
      matchStatus: matchStatus ?? this.matchStatus,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      metadataOverrides: metadataOverrides ?? this.metadataOverrides,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      reviewSyncId: reviewSyncId ?? this.reviewSyncId,
      reviewSyncState: reviewSyncState ?? this.reviewSyncState,
      reviewUpdatedAt: reviewUpdatedAt ?? this.reviewUpdatedAt,
      ratedAt: ratedAt ?? this.ratedAt,
      totalPlaySec: totalPlaySec ?? this.totalPlaySec,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt ?? this.createdAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (installDir.present) {
      map['install_dir'] = Variable<String>(installDir.value);
    }
    if (exePath.present) {
      map['exe_path'] = Variable<String>(exePath.value);
    }
    if (engine.present) {
      map['engine'] = Variable<String>(engine.value);
    }
    if (rjCode.present) {
      map['rj_code'] = Variable<String>(rjCode.value);
    }
    if (vndbId.present) {
      map['vndb_id'] = Variable<String>(vndbId.value);
    }
    if (workKey.present) {
      map['work_key'] = Variable<String>(workKey.value);
    }
    if (matchStatus.present) {
      map['match_status'] = Variable<String>(matchStatus.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (metadataOverrides.present) {
      map['metadata_overrides'] = Variable<String>(metadataOverrides.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (ratingComment.present) {
      map['rating_comment'] = Variable<String>(ratingComment.value);
    }
    if (reviewSyncId.present) {
      map['review_sync_id'] = Variable<String>(reviewSyncId.value);
    }
    if (reviewSyncState.present) {
      map['review_sync_state'] = Variable<String>(reviewSyncState.value);
    }
    if (reviewUpdatedAt.present) {
      map['review_updated_at'] = Variable<DateTime>(reviewUpdatedAt.value);
    }
    if (ratedAt.present) {
      map['rated_at'] = Variable<DateTime>(ratedAt.value);
    }
    if (totalPlaySec.present) {
      map['total_play_sec'] = Variable<int>(totalPlaySec.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GamesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('installDir: $installDir, ')
          ..write('exePath: $exePath, ')
          ..write('engine: $engine, ')
          ..write('rjCode: $rjCode, ')
          ..write('vndbId: $vndbId, ')
          ..write('workKey: $workKey, ')
          ..write('matchStatus: $matchStatus, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('metadataOverrides: $metadataOverrides, ')
          ..write('status: $status, ')
          ..write('rating: $rating, ')
          ..write('ratingComment: $ratingComment, ')
          ..write('reviewSyncId: $reviewSyncId, ')
          ..write('reviewSyncState: $reviewSyncState, ')
          ..write('reviewUpdatedAt: $reviewUpdatedAt, ')
          ..write('ratedAt: $ratedAt, ')
          ..write('totalPlaySec: $totalPlaySec, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

class $PlaySessionsTable extends PlaySessions
    with TableInfo<$PlaySessionsTable, PlaySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, gameId, startedAt, endedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaySession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaySession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
    );
  }

  @override
  $PlaySessionsTable createAlias(String alias) {
    return $PlaySessionsTable(attachedDatabase, alias);
  }
}

class PlaySession extends DataClass implements Insertable<PlaySession> {
  final int id;
  final int gameId;
  final DateTime startedAt;
  final DateTime endedAt;
  const PlaySession({
    required this.id,
    required this.gameId,
    required this.startedAt,
    required this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    return map;
  }

  PlaySessionsCompanion toCompanion(bool nullToAbsent) {
    return PlaySessionsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
    );
  }

  factory PlaySession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaySession(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
    };
  }

  PlaySession copyWith({
    int? id,
    int? gameId,
    DateTime? startedAt,
    DateTime? endedAt,
  }) => PlaySession(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
  );
  PlaySession copyWithCompanion(PlaySessionsCompanion data) {
    return PlaySession(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaySession(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, gameId, startedAt, endedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaySession &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt);
}

class PlaySessionsCompanion extends UpdateCompanion<PlaySession> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  const PlaySessionsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
  });
  PlaySessionsCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) : gameId = Value(gameId),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt);
  static Insertable<PlaySession> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
    });
  }

  PlaySessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
  }) {
    return PlaySessionsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaySessionsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }
}

class $ActivePlaySessionsTable extends ActivePlaySessions
    with TableInfo<$ActivePlaySessionsTable, ActivePlaySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivePlaySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [gameId, startedAt, lastSeenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_play_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivePlaySession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSeenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gameId};
  @override
  ActivePlaySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivePlaySession(
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      )!,
    );
  }

  @override
  $ActivePlaySessionsTable createAlias(String alias) {
    return $ActivePlaySessionsTable(attachedDatabase, alias);
  }
}

class ActivePlaySession extends DataClass
    implements Insertable<ActivePlaySession> {
  final int gameId;
  final DateTime startedAt;
  final DateTime lastSeenAt;
  const ActivePlaySession({
    required this.gameId,
    required this.startedAt,
    required this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['game_id'] = Variable<int>(gameId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    return map;
  }

  ActivePlaySessionsCompanion toCompanion(bool nullToAbsent) {
    return ActivePlaySessionsCompanion(
      gameId: Value(gameId),
      startedAt: Value(startedAt),
      lastSeenAt: Value(lastSeenAt),
    );
  }

  factory ActivePlaySession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivePlaySession(
      gameId: serializer.fromJson<int>(json['gameId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      lastSeenAt: serializer.fromJson<DateTime>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gameId': serializer.toJson<int>(gameId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'lastSeenAt': serializer.toJson<DateTime>(lastSeenAt),
    };
  }

  ActivePlaySession copyWith({
    int? gameId,
    DateTime? startedAt,
    DateTime? lastSeenAt,
  }) => ActivePlaySession(
    gameId: gameId ?? this.gameId,
    startedAt: startedAt ?? this.startedAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
  );
  ActivePlaySession copyWithCompanion(ActivePlaySessionsCompanion data) {
    return ActivePlaySession(
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivePlaySession(')
          ..write('gameId: $gameId, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(gameId, startedAt, lastSeenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivePlaySession &&
          other.gameId == this.gameId &&
          other.startedAt == this.startedAt &&
          other.lastSeenAt == this.lastSeenAt);
}

class ActivePlaySessionsCompanion extends UpdateCompanion<ActivePlaySession> {
  final Value<int> gameId;
  final Value<DateTime> startedAt;
  final Value<DateTime> lastSeenAt;
  const ActivePlaySessionsCompanion({
    this.gameId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  });
  ActivePlaySessionsCompanion.insert({
    this.gameId = const Value.absent(),
    required DateTime startedAt,
    required DateTime lastSeenAt,
  }) : startedAt = Value(startedAt),
       lastSeenAt = Value(lastSeenAt);
  static Insertable<ActivePlaySession> custom({
    Expression<int>? gameId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? lastSeenAt,
  }) {
    return RawValuesInsertable({
      if (gameId != null) 'game_id': gameId,
      if (startedAt != null) 'started_at': startedAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
    });
  }

  ActivePlaySessionsCompanion copyWith({
    Value<int>? gameId,
    Value<DateTime>? startedAt,
    Value<DateTime>? lastSeenAt,
  }) {
    return ActivePlaySessionsCompanion(
      gameId: gameId ?? this.gameId,
      startedAt: startedAt ?? this.startedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivePlaySessionsCompanion(')
          ..write('gameId: $gameId, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }
}

class $StatusHistoryTable extends StatusHistory
    with TableInfo<$StatusHistoryTable, StatusHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatusHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<int> gameId = GeneratedColumn<int>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES games (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fromStatusMeta = const VerificationMeta(
    'fromStatus',
  );
  @override
  late final GeneratedColumn<String> fromStatus = GeneratedColumn<String>(
    'from_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toStatusMeta = const VerificationMeta(
    'toStatus',
  );
  @override
  late final GeneratedColumn<String> toStatus = GeneratedColumn<String>(
    'to_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    gameId,
    fromStatus,
    toStatus,
    changedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'status_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<StatusHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('from_status')) {
      context.handle(
        _fromStatusMeta,
        fromStatus.isAcceptableOrUnknown(data['from_status']!, _fromStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_fromStatusMeta);
    }
    if (data.containsKey('to_status')) {
      context.handle(
        _toStatusMeta,
        toStatus.isAcceptableOrUnknown(data['to_status']!, _toStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_toStatusMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StatusHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StatusHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}game_id'],
      )!,
      fromStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_status'],
      )!,
      toStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_status'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
    );
  }

  @override
  $StatusHistoryTable createAlias(String alias) {
    return $StatusHistoryTable(attachedDatabase, alias);
  }
}

class StatusHistoryData extends DataClass
    implements Insertable<StatusHistoryData> {
  final int id;
  final int gameId;
  final String fromStatus;
  final String toStatus;
  final DateTime changedAt;
  const StatusHistoryData({
    required this.id,
    required this.gameId,
    required this.fromStatus,
    required this.toStatus,
    required this.changedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['game_id'] = Variable<int>(gameId);
    map['from_status'] = Variable<String>(fromStatus);
    map['to_status'] = Variable<String>(toStatus);
    map['changed_at'] = Variable<DateTime>(changedAt);
    return map;
  }

  StatusHistoryCompanion toCompanion(bool nullToAbsent) {
    return StatusHistoryCompanion(
      id: Value(id),
      gameId: Value(gameId),
      fromStatus: Value(fromStatus),
      toStatus: Value(toStatus),
      changedAt: Value(changedAt),
    );
  }

  factory StatusHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StatusHistoryData(
      id: serializer.fromJson<int>(json['id']),
      gameId: serializer.fromJson<int>(json['gameId']),
      fromStatus: serializer.fromJson<String>(json['fromStatus']),
      toStatus: serializer.fromJson<String>(json['toStatus']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'gameId': serializer.toJson<int>(gameId),
      'fromStatus': serializer.toJson<String>(fromStatus),
      'toStatus': serializer.toJson<String>(toStatus),
      'changedAt': serializer.toJson<DateTime>(changedAt),
    };
  }

  StatusHistoryData copyWith({
    int? id,
    int? gameId,
    String? fromStatus,
    String? toStatus,
    DateTime? changedAt,
  }) => StatusHistoryData(
    id: id ?? this.id,
    gameId: gameId ?? this.gameId,
    fromStatus: fromStatus ?? this.fromStatus,
    toStatus: toStatus ?? this.toStatus,
    changedAt: changedAt ?? this.changedAt,
  );
  StatusHistoryData copyWithCompanion(StatusHistoryCompanion data) {
    return StatusHistoryData(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      fromStatus: data.fromStatus.present
          ? data.fromStatus.value
          : this.fromStatus,
      toStatus: data.toStatus.present ? data.toStatus.value : this.toStatus,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StatusHistoryData(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('fromStatus: $fromStatus, ')
          ..write('toStatus: $toStatus, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, gameId, fromStatus, toStatus, changedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatusHistoryData &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.fromStatus == this.fromStatus &&
          other.toStatus == this.toStatus &&
          other.changedAt == this.changedAt);
}

class StatusHistoryCompanion extends UpdateCompanion<StatusHistoryData> {
  final Value<int> id;
  final Value<int> gameId;
  final Value<String> fromStatus;
  final Value<String> toStatus;
  final Value<DateTime> changedAt;
  const StatusHistoryCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.fromStatus = const Value.absent(),
    this.toStatus = const Value.absent(),
    this.changedAt = const Value.absent(),
  });
  StatusHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int gameId,
    required String fromStatus,
    required String toStatus,
    required DateTime changedAt,
  }) : gameId = Value(gameId),
       fromStatus = Value(fromStatus),
       toStatus = Value(toStatus),
       changedAt = Value(changedAt);
  static Insertable<StatusHistoryData> custom({
    Expression<int>? id,
    Expression<int>? gameId,
    Expression<String>? fromStatus,
    Expression<String>? toStatus,
    Expression<DateTime>? changedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (fromStatus != null) 'from_status': fromStatus,
      if (toStatus != null) 'to_status': toStatus,
      if (changedAt != null) 'changed_at': changedAt,
    });
  }

  StatusHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? gameId,
    Value<String>? fromStatus,
    Value<String>? toStatus,
    Value<DateTime>? changedAt,
  }) {
    return StatusHistoryCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      fromStatus: fromStatus ?? this.fromStatus,
      toStatus: toStatus ?? this.toStatus,
      changedAt: changedAt ?? this.changedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<int>(gameId.value);
    }
    if (fromStatus.present) {
      map['from_status'] = Variable<String>(fromStatus.value);
    }
    if (toStatus.present) {
      map['to_status'] = Variable<String>(toStatus.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatusHistoryCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('fromStatus: $fromStatus, ')
          ..write('toStatus: $toStatus, ')
          ..write('changedAt: $changedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogReviewsTable extends CatalogReviews
    with TableInfo<$CatalogReviewsTable, CatalogReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workIdMeta = const VerificationMeta('workId');
  @override
  late final GeneratedColumn<String> workId = GeneratedColumn<String>(
    'work_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAdultMeta = const VerificationMeta(
    'isAdult',
  );
  @override
  late final GeneratedColumn<bool> isAdult = GeneratedColumn<bool>(
    'is_adult',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_adult" IN (0, 1))',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingCommentMeta = const VerificationMeta(
    'ratingComment',
  );
  @override
  late final GeneratedColumn<String> ratingComment = GeneratedColumn<String>(
    'rating_comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewSyncIdMeta = const VerificationMeta(
    'reviewSyncId',
  );
  @override
  late final GeneratedColumn<String> reviewSyncId = GeneratedColumn<String>(
    'review_sync_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewSyncStateMeta = const VerificationMeta(
    'reviewSyncState',
  );
  @override
  late final GeneratedColumn<String> reviewSyncState = GeneratedColumn<String>(
    'review_sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewUpdatedAtMeta = const VerificationMeta(
    'reviewUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewUpdatedAt =
      GeneratedColumn<DateTime>(
        'review_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    workId,
    title,
    isAdult,
    rating,
    ratingComment,
    reviewSyncId,
    reviewSyncState,
    reviewUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_id')) {
      context.handle(
        _workIdMeta,
        workId.isAcceptableOrUnknown(data['work_id']!, _workIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_adult')) {
      context.handle(
        _isAdultMeta,
        isAdult.isAcceptableOrUnknown(data['is_adult']!, _isAdultMeta),
      );
    } else if (isInserting) {
      context.missing(_isAdultMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('rating_comment')) {
      context.handle(
        _ratingCommentMeta,
        ratingComment.isAcceptableOrUnknown(
          data['rating_comment']!,
          _ratingCommentMeta,
        ),
      );
    }
    if (data.containsKey('review_sync_id')) {
      context.handle(
        _reviewSyncIdMeta,
        reviewSyncId.isAcceptableOrUnknown(
          data['review_sync_id']!,
          _reviewSyncIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewSyncIdMeta);
    }
    if (data.containsKey('review_sync_state')) {
      context.handle(
        _reviewSyncStateMeta,
        reviewSyncState.isAcceptableOrUnknown(
          data['review_sync_state']!,
          _reviewSyncStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewSyncStateMeta);
    }
    if (data.containsKey('review_updated_at')) {
      context.handle(
        _reviewUpdatedAtMeta,
        reviewUpdatedAt.isAcceptableOrUnknown(
          data['review_updated_at']!,
          _reviewUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workId};
  @override
  CatalogReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogReview(
      workId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isAdult: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_adult'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      ratingComment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating_comment'],
      ),
      reviewSyncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_sync_id'],
      )!,
      reviewSyncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_sync_state'],
      )!,
      reviewUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}review_updated_at'],
      )!,
    );
  }

  @override
  $CatalogReviewsTable createAlias(String alias) {
    return $CatalogReviewsTable(attachedDatabase, alias);
  }
}

class CatalogReview extends DataClass implements Insertable<CatalogReview> {
  final String workId;
  final String title;
  final bool isAdult;
  final int? rating;
  final String? ratingComment;
  final String reviewSyncId;
  final String reviewSyncState;
  final DateTime reviewUpdatedAt;
  const CatalogReview({
    required this.workId,
    required this.title,
    required this.isAdult,
    this.rating,
    this.ratingComment,
    required this.reviewSyncId,
    required this.reviewSyncState,
    required this.reviewUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_id'] = Variable<String>(workId);
    map['title'] = Variable<String>(title);
    map['is_adult'] = Variable<bool>(isAdult);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<int>(rating);
    }
    if (!nullToAbsent || ratingComment != null) {
      map['rating_comment'] = Variable<String>(ratingComment);
    }
    map['review_sync_id'] = Variable<String>(reviewSyncId);
    map['review_sync_state'] = Variable<String>(reviewSyncState);
    map['review_updated_at'] = Variable<DateTime>(reviewUpdatedAt);
    return map;
  }

  CatalogReviewsCompanion toCompanion(bool nullToAbsent) {
    return CatalogReviewsCompanion(
      workId: Value(workId),
      title: Value(title),
      isAdult: Value(isAdult),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      ratingComment: ratingComment == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingComment),
      reviewSyncId: Value(reviewSyncId),
      reviewSyncState: Value(reviewSyncState),
      reviewUpdatedAt: Value(reviewUpdatedAt),
    );
  }

  factory CatalogReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogReview(
      workId: serializer.fromJson<String>(json['workId']),
      title: serializer.fromJson<String>(json['title']),
      isAdult: serializer.fromJson<bool>(json['isAdult']),
      rating: serializer.fromJson<int?>(json['rating']),
      ratingComment: serializer.fromJson<String?>(json['ratingComment']),
      reviewSyncId: serializer.fromJson<String>(json['reviewSyncId']),
      reviewSyncState: serializer.fromJson<String>(json['reviewSyncState']),
      reviewUpdatedAt: serializer.fromJson<DateTime>(json['reviewUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workId': serializer.toJson<String>(workId),
      'title': serializer.toJson<String>(title),
      'isAdult': serializer.toJson<bool>(isAdult),
      'rating': serializer.toJson<int?>(rating),
      'ratingComment': serializer.toJson<String?>(ratingComment),
      'reviewSyncId': serializer.toJson<String>(reviewSyncId),
      'reviewSyncState': serializer.toJson<String>(reviewSyncState),
      'reviewUpdatedAt': serializer.toJson<DateTime>(reviewUpdatedAt),
    };
  }

  CatalogReview copyWith({
    String? workId,
    String? title,
    bool? isAdult,
    Value<int?> rating = const Value.absent(),
    Value<String?> ratingComment = const Value.absent(),
    String? reviewSyncId,
    String? reviewSyncState,
    DateTime? reviewUpdatedAt,
  }) => CatalogReview(
    workId: workId ?? this.workId,
    title: title ?? this.title,
    isAdult: isAdult ?? this.isAdult,
    rating: rating.present ? rating.value : this.rating,
    ratingComment: ratingComment.present
        ? ratingComment.value
        : this.ratingComment,
    reviewSyncId: reviewSyncId ?? this.reviewSyncId,
    reviewSyncState: reviewSyncState ?? this.reviewSyncState,
    reviewUpdatedAt: reviewUpdatedAt ?? this.reviewUpdatedAt,
  );
  CatalogReview copyWithCompanion(CatalogReviewsCompanion data) {
    return CatalogReview(
      workId: data.workId.present ? data.workId.value : this.workId,
      title: data.title.present ? data.title.value : this.title,
      isAdult: data.isAdult.present ? data.isAdult.value : this.isAdult,
      rating: data.rating.present ? data.rating.value : this.rating,
      ratingComment: data.ratingComment.present
          ? data.ratingComment.value
          : this.ratingComment,
      reviewSyncId: data.reviewSyncId.present
          ? data.reviewSyncId.value
          : this.reviewSyncId,
      reviewSyncState: data.reviewSyncState.present
          ? data.reviewSyncState.value
          : this.reviewSyncState,
      reviewUpdatedAt: data.reviewUpdatedAt.present
          ? data.reviewUpdatedAt.value
          : this.reviewUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogReview(')
          ..write('workId: $workId, ')
          ..write('title: $title, ')
          ..write('isAdult: $isAdult, ')
          ..write('rating: $rating, ')
          ..write('ratingComment: $ratingComment, ')
          ..write('reviewSyncId: $reviewSyncId, ')
          ..write('reviewSyncState: $reviewSyncState, ')
          ..write('reviewUpdatedAt: $reviewUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workId,
    title,
    isAdult,
    rating,
    ratingComment,
    reviewSyncId,
    reviewSyncState,
    reviewUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogReview &&
          other.workId == this.workId &&
          other.title == this.title &&
          other.isAdult == this.isAdult &&
          other.rating == this.rating &&
          other.ratingComment == this.ratingComment &&
          other.reviewSyncId == this.reviewSyncId &&
          other.reviewSyncState == this.reviewSyncState &&
          other.reviewUpdatedAt == this.reviewUpdatedAt);
}

class CatalogReviewsCompanion extends UpdateCompanion<CatalogReview> {
  final Value<String> workId;
  final Value<String> title;
  final Value<bool> isAdult;
  final Value<int?> rating;
  final Value<String?> ratingComment;
  final Value<String> reviewSyncId;
  final Value<String> reviewSyncState;
  final Value<DateTime> reviewUpdatedAt;
  final Value<int> rowid;
  const CatalogReviewsCompanion({
    this.workId = const Value.absent(),
    this.title = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.rating = const Value.absent(),
    this.ratingComment = const Value.absent(),
    this.reviewSyncId = const Value.absent(),
    this.reviewSyncState = const Value.absent(),
    this.reviewUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogReviewsCompanion.insert({
    required String workId,
    required String title,
    required bool isAdult,
    this.rating = const Value.absent(),
    this.ratingComment = const Value.absent(),
    required String reviewSyncId,
    required String reviewSyncState,
    required DateTime reviewUpdatedAt,
    this.rowid = const Value.absent(),
  }) : workId = Value(workId),
       title = Value(title),
       isAdult = Value(isAdult),
       reviewSyncId = Value(reviewSyncId),
       reviewSyncState = Value(reviewSyncState),
       reviewUpdatedAt = Value(reviewUpdatedAt);
  static Insertable<CatalogReview> custom({
    Expression<String>? workId,
    Expression<String>? title,
    Expression<bool>? isAdult,
    Expression<int>? rating,
    Expression<String>? ratingComment,
    Expression<String>? reviewSyncId,
    Expression<String>? reviewSyncState,
    Expression<DateTime>? reviewUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workId != null) 'work_id': workId,
      if (title != null) 'title': title,
      if (isAdult != null) 'is_adult': isAdult,
      if (rating != null) 'rating': rating,
      if (ratingComment != null) 'rating_comment': ratingComment,
      if (reviewSyncId != null) 'review_sync_id': reviewSyncId,
      if (reviewSyncState != null) 'review_sync_state': reviewSyncState,
      if (reviewUpdatedAt != null) 'review_updated_at': reviewUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogReviewsCompanion copyWith({
    Value<String>? workId,
    Value<String>? title,
    Value<bool>? isAdult,
    Value<int?>? rating,
    Value<String?>? ratingComment,
    Value<String>? reviewSyncId,
    Value<String>? reviewSyncState,
    Value<DateTime>? reviewUpdatedAt,
    Value<int>? rowid,
  }) {
    return CatalogReviewsCompanion(
      workId: workId ?? this.workId,
      title: title ?? this.title,
      isAdult: isAdult ?? this.isAdult,
      rating: rating ?? this.rating,
      ratingComment: ratingComment ?? this.ratingComment,
      reviewSyncId: reviewSyncId ?? this.reviewSyncId,
      reviewSyncState: reviewSyncState ?? this.reviewSyncState,
      reviewUpdatedAt: reviewUpdatedAt ?? this.reviewUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workId.present) {
      map['work_id'] = Variable<String>(workId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isAdult.present) {
      map['is_adult'] = Variable<bool>(isAdult.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (ratingComment.present) {
      map['rating_comment'] = Variable<String>(ratingComment.value);
    }
    if (reviewSyncId.present) {
      map['review_sync_id'] = Variable<String>(reviewSyncId.value);
    }
    if (reviewSyncState.present) {
      map['review_sync_state'] = Variable<String>(reviewSyncState.value);
    }
    if (reviewUpdatedAt.present) {
      map['review_updated_at'] = Variable<DateTime>(reviewUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogReviewsCompanion(')
          ..write('workId: $workId, ')
          ..write('title: $title, ')
          ..write('isAdult: $isAdult, ')
          ..write('rating: $rating, ')
          ..write('ratingComment: $ratingComment, ')
          ..write('reviewSyncId: $reviewSyncId, ')
          ..write('reviewSyncState: $reviewSyncState, ')
          ..write('reviewUpdatedAt: $reviewUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScanFoldersTable scanFolders = $ScanFoldersTable(this);
  late final $GamesTable games = $GamesTable(this);
  late final $PlaySessionsTable playSessions = $PlaySessionsTable(this);
  late final $ActivePlaySessionsTable activePlaySessions =
      $ActivePlaySessionsTable(this);
  late final $StatusHistoryTable statusHistory = $StatusHistoryTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $CatalogReviewsTable catalogReviews = $CatalogReviewsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scanFolders,
    games,
    playSessions,
    activePlaySessions,
    statusHistory,
    appSettings,
    catalogReviews,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('play_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('active_play_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'games',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('status_history', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ScanFoldersTableCreateCompanionBuilder =
    ScanFoldersCompanion Function({Value<int> id, required String path});
typedef $$ScanFoldersTableUpdateCompanionBuilder =
    ScanFoldersCompanion Function({Value<int> id, Value<String> path});

class $$ScanFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $ScanFoldersTable> {
  $$ScanFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScanFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanFoldersTable> {
  $$ScanFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScanFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanFoldersTable> {
  $$ScanFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);
}

class $$ScanFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScanFoldersTable,
          ScanFolder,
          $$ScanFoldersTableFilterComposer,
          $$ScanFoldersTableOrderingComposer,
          $$ScanFoldersTableAnnotationComposer,
          $$ScanFoldersTableCreateCompanionBuilder,
          $$ScanFoldersTableUpdateCompanionBuilder,
          (
            ScanFolder,
            BaseReferences<_$AppDatabase, $ScanFoldersTable, ScanFolder>,
          ),
          ScanFolder,
          PrefetchHooks Function()
        > {
  $$ScanFoldersTableTableManager(_$AppDatabase db, $ScanFoldersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> path = const Value.absent(),
          }) => ScanFoldersCompanion(id: id, path: path),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String path,
          }) => ScanFoldersCompanion.insert(id: id, path: path),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScanFoldersTable, ScanFolder>(table),
                  BaseReferences<_$AppDatabase, $ScanFoldersTable, ScanFolder>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScanFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScanFoldersTable,
      ScanFolder,
      $$ScanFoldersTableFilterComposer,
      $$ScanFoldersTableOrderingComposer,
      $$ScanFoldersTableAnnotationComposer,
      $$ScanFoldersTableCreateCompanionBuilder,
      $$ScanFoldersTableUpdateCompanionBuilder,
      (
        ScanFolder,
        BaseReferences<_$AppDatabase, $ScanFoldersTable, ScanFolder>,
      ),
      ScanFolder,
      PrefetchHooks Function()
    >;
typedef $$GamesTableCreateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  required String title,
  required String installDir,
  required String exePath,
  Value<String?> engine,
  Value<String?> rjCode,
  Value<String?> vndbId,
  Value<String?> workKey,
  Value<String> matchStatus,
  Value<String?> thumbnailUrl,
  Value<String?> metadataOverrides,
  Value<String> status,
  Value<int?> rating,
  Value<String?> ratingComment,
  Value<String?> reviewSyncId,
  Value<String> reviewSyncState,
  Value<DateTime?> reviewUpdatedAt,
  Value<DateTime?> ratedAt,
  Value<int> totalPlaySec,
  Value<DateTime?> lastPlayedAt,
  required DateTime createdAt,
  required DateTime localUpdatedAt,
  Value<DateTime?> syncedAt,
});
typedef $$GamesTableUpdateCompanionBuilder = GamesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> installDir,
  Value<String> exePath,
  Value<String?> engine,
  Value<String?> rjCode,
  Value<String?> vndbId,
  Value<String?> workKey,
  Value<String> matchStatus,
  Value<String?> thumbnailUrl,
  Value<String?> metadataOverrides,
  Value<String> status,
  Value<int?> rating,
  Value<String?> ratingComment,
  Value<String?> reviewSyncId,
  Value<String> reviewSyncState,
  Value<DateTime?> reviewUpdatedAt,
  Value<DateTime?> ratedAt,
  Value<int> totalPlaySec,
  Value<DateTime?> lastPlayedAt,
  Value<DateTime> createdAt,
  Value<DateTime> localUpdatedAt,
  Value<DateTime?> syncedAt,
});

final class $$GamesTableReferences
    extends BaseReferences<_$AppDatabase, $GamesTable, GameRecord> {
  $$GamesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaySessionsTable, List<PlaySession>>
  _playSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.playSessions,
    aliasName: 'games__id__play_sessions__game_id',
  );

  $$PlaySessionsTableProcessedTableManager get playSessionsRefs {
    final manager = $$PlaySessionsTableTableManager(
      $_db,
      $_db.playSessions,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ActivePlaySessionsTable, List<ActivePlaySession>>
  _activePlaySessionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.activePlaySessions,
        aliasName: 'games__id__active_play_sessions__game_id',
      );

  $$ActivePlaySessionsTableProcessedTableManager get activePlaySessionsRefs {
    final manager = $$ActivePlaySessionsTableTableManager(
      $_db,
      $_db.activePlaySessions,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _activePlaySessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StatusHistoryTable, List<StatusHistoryData>>
  _statusHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.statusHistory,
    aliasName: 'games__id__status_history__game_id',
  );

  $$StatusHistoryTableProcessedTableManager get statusHistoryRefs {
    final manager = $$StatusHistoryTableTableManager(
      $_db,
      $_db.statusHistory,
    ).filter((f) => f.gameId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_statusHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GamesTableFilterComposer extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installDir => $composableBuilder(
    column: $table.installDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exePath => $composableBuilder(
    column: $table.exePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rjCode => $composableBuilder(
    column: $table.rjCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vndbId => $composableBuilder(
    column: $table.vndbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workKey => $composableBuilder(
    column: $table.workKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchStatus => $composableBuilder(
    column: $table.matchStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataOverrides => $composableBuilder(
    column: $table.metadataOverrides,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratingComment => $composableBuilder(
    column: $table.ratingComment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewSyncId => $composableBuilder(
    column: $table.reviewSyncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewSyncState => $composableBuilder(
    column: $table.reviewSyncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewUpdatedAt => $composableBuilder(
    column: $table.reviewUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ratedAt => $composableBuilder(
    column: $table.ratedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPlaySec => $composableBuilder(
    column: $table.totalPlaySec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playSessionsRefs(
    Expression<bool> Function($$PlaySessionsTableFilterComposer f) f,
  ) {
    final $$PlaySessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playSessions,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaySessionsTableFilterComposer(
            $db: $db,
            $table: $db.playSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> activePlaySessionsRefs(
    Expression<bool> Function($$ActivePlaySessionsTableFilterComposer f) f,
  ) {
    final $$ActivePlaySessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activePlaySessions,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ActivePlaySessionsTableFilterComposer(
            $db: $db,
            $table: $db.activePlaySessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> statusHistoryRefs(
    Expression<bool> Function($$StatusHistoryTableFilterComposer f) f,
  ) {
    final $$StatusHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.statusHistory,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatusHistoryTableFilterComposer(
            $db: $db,
            $table: $db.statusHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableOrderingComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installDir => $composableBuilder(
    column: $table.installDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exePath => $composableBuilder(
    column: $table.exePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get engine => $composableBuilder(
    column: $table.engine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rjCode => $composableBuilder(
    column: $table.rjCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vndbId => $composableBuilder(
    column: $table.vndbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workKey => $composableBuilder(
    column: $table.workKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchStatus => $composableBuilder(
    column: $table.matchStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataOverrides => $composableBuilder(
    column: $table.metadataOverrides,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratingComment => $composableBuilder(
    column: $table.ratingComment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewSyncId => $composableBuilder(
    column: $table.reviewSyncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewSyncState => $composableBuilder(
    column: $table.reviewSyncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewUpdatedAt => $composableBuilder(
    column: $table.reviewUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ratedAt => $composableBuilder(
    column: $table.ratedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPlaySec => $composableBuilder(
    column: $table.totalPlaySec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GamesTable> {
  $$GamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get installDir => $composableBuilder(
    column: $table.installDir,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exePath =>
      $composableBuilder(column: $table.exePath, builder: (column) => column);

  GeneratedColumn<String> get engine =>
      $composableBuilder(column: $table.engine, builder: (column) => column);

  GeneratedColumn<String> get rjCode =>
      $composableBuilder(column: $table.rjCode, builder: (column) => column);

  GeneratedColumn<String> get vndbId =>
      $composableBuilder(column: $table.vndbId, builder: (column) => column);

  GeneratedColumn<String> get workKey =>
      $composableBuilder(column: $table.workKey, builder: (column) => column);

  GeneratedColumn<String> get matchStatus => $composableBuilder(
    column: $table.matchStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataOverrides => $composableBuilder(
    column: $table.metadataOverrides,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get ratingComment => $composableBuilder(
    column: $table.ratingComment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewSyncId => $composableBuilder(
    column: $table.reviewSyncId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewSyncState => $composableBuilder(
    column: $table.reviewSyncState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewUpdatedAt => $composableBuilder(
    column: $table.reviewUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ratedAt =>
      $composableBuilder(column: $table.ratedAt, builder: (column) => column);

  GeneratedColumn<int> get totalPlaySec => $composableBuilder(
    column: $table.totalPlaySec,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  Expression<T> playSessionsRefs<T extends Object>(
    Expression<T> Function($$PlaySessionsTableAnnotationComposer a) f,
  ) {
    final $$PlaySessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playSessions,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaySessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.playSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> activePlaySessionsRefs<T extends Object>(
    Expression<T> Function($$ActivePlaySessionsTableAnnotationComposer a) f,
  ) {
    final $$ActivePlaySessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.activePlaySessions,
          getReferencedColumn: (t) => t.gameId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ActivePlaySessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.activePlaySessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> statusHistoryRefs<T extends Object>(
    Expression<T> Function($$StatusHistoryTableAnnotationComposer a) f,
  ) {
    final $$StatusHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.statusHistory,
      getReferencedColumn: (t) => t.gameId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatusHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.statusHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GamesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GamesTable,
          GameRecord,
          $$GamesTableFilterComposer,
          $$GamesTableOrderingComposer,
          $$GamesTableAnnotationComposer,
          $$GamesTableCreateCompanionBuilder,
          $$GamesTableUpdateCompanionBuilder,
          (GameRecord, $$GamesTableReferences),
          GameRecord,
          PrefetchHooks Function({
            bool playSessionsRefs,
            bool activePlaySessionsRefs,
            bool statusHistoryRefs,
          })
        > {
  $$GamesTableTableManager(_$AppDatabase db, $GamesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> installDir = const Value.absent(),
                Value<String> exePath = const Value.absent(),
                Value<String?> engine = const Value.absent(),
                Value<String?> rjCode = const Value.absent(),
                Value<String?> vndbId = const Value.absent(),
                Value<String?> workKey = const Value.absent(),
                Value<String> matchStatus = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> metadataOverrides = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<String?> ratingComment = const Value.absent(),
                Value<String?> reviewSyncId = const Value.absent(),
                Value<String> reviewSyncState = const Value.absent(),
                Value<DateTime?> reviewUpdatedAt = const Value.absent(),
                Value<DateTime?> ratedAt = const Value.absent(),
                Value<int> totalPlaySec = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => GamesCompanion(
                id: id,
                title: title,
                installDir: installDir,
                exePath: exePath,
                engine: engine,
                rjCode: rjCode,
                vndbId: vndbId,
                workKey: workKey,
                matchStatus: matchStatus,
                thumbnailUrl: thumbnailUrl,
                metadataOverrides: metadataOverrides,
                status: status,
                rating: rating,
                ratingComment: ratingComment,
                reviewSyncId: reviewSyncId,
                reviewSyncState: reviewSyncState,
                reviewUpdatedAt: reviewUpdatedAt,
                ratedAt: ratedAt,
                totalPlaySec: totalPlaySec,
                lastPlayedAt: lastPlayedAt,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String installDir,
                required String exePath,
                Value<String?> engine = const Value.absent(),
                Value<String?> rjCode = const Value.absent(),
                Value<String?> vndbId = const Value.absent(),
                Value<String?> workKey = const Value.absent(),
                Value<String> matchStatus = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<String?> metadataOverrides = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<String?> ratingComment = const Value.absent(),
                Value<String?> reviewSyncId = const Value.absent(),
                Value<String> reviewSyncState = const Value.absent(),
                Value<DateTime?> reviewUpdatedAt = const Value.absent(),
                Value<DateTime?> ratedAt = const Value.absent(),
                Value<int> totalPlaySec = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime localUpdatedAt,
                Value<DateTime?> syncedAt = const Value.absent(),
              }) => GamesCompanion.insert(
                id: id,
                title: title,
                installDir: installDir,
                exePath: exePath,
                engine: engine,
                rjCode: rjCode,
                vndbId: vndbId,
                workKey: workKey,
                matchStatus: matchStatus,
                thumbnailUrl: thumbnailUrl,
                metadataOverrides: metadataOverrides,
                status: status,
                rating: rating,
                ratingComment: ratingComment,
                reviewSyncId: reviewSyncId,
                reviewSyncState: reviewSyncState,
                reviewUpdatedAt: reviewUpdatedAt,
                ratedAt: ratedAt,
                totalPlaySec: totalPlaySec,
                lastPlayedAt: lastPlayedAt,
                createdAt: createdAt,
                localUpdatedAt: localUpdatedAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GamesTable, GameRecord>(table),
                  $$GamesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                playSessionsRefs = false,
                activePlaySessionsRefs = false,
                statusHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playSessionsRefs) db.playSessions,
                    if (activePlaySessionsRefs) db.activePlaySessions,
                    if (statusHistoryRefs) db.statusHistory,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playSessionsRefs)
                        await $_getPrefetchedData<
                          GameRecord,
                          $GamesTable,
                          PlaySession
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._playSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).playSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (activePlaySessionsRefs)
                        await $_getPrefetchedData<
                          GameRecord,
                          $GamesTable,
                          ActivePlaySession
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._activePlaySessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).activePlaySessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (statusHistoryRefs)
                        await $_getPrefetchedData<
                          GameRecord,
                          $GamesTable,
                          StatusHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$GamesTableReferences
                              ._statusHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GamesTableReferences(
                                db,
                                table,
                                p0,
                              ).statusHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.gameId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GamesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GamesTable,
      GameRecord,
      $$GamesTableFilterComposer,
      $$GamesTableOrderingComposer,
      $$GamesTableAnnotationComposer,
      $$GamesTableCreateCompanionBuilder,
      $$GamesTableUpdateCompanionBuilder,
      (GameRecord, $$GamesTableReferences),
      GameRecord,
      PrefetchHooks Function({
        bool playSessionsRefs,
        bool activePlaySessionsRefs,
        bool statusHistoryRefs,
      })
    >;
typedef $$PlaySessionsTableCreateCompanionBuilder =
    PlaySessionsCompanion Function({
      Value<int> id,
      required int gameId,
      required DateTime startedAt,
      required DateTime endedAt,
    });
typedef $$PlaySessionsTableUpdateCompanionBuilder =
    PlaySessionsCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
    });

final class $$PlaySessionsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaySessionsTable, PlaySession> {
  $$PlaySessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('play_sessions__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaySessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaySessionsTable,
          PlaySession,
          $$PlaySessionsTableFilterComposer,
          $$PlaySessionsTableOrderingComposer,
          $$PlaySessionsTableAnnotationComposer,
          $$PlaySessionsTableCreateCompanionBuilder,
          $$PlaySessionsTableUpdateCompanionBuilder,
          (PlaySession, $$PlaySessionsTableReferences),
          PlaySession,
          PrefetchHooks Function({bool gameId})
        > {
  $$PlaySessionsTableTableManager(_$AppDatabase db, $PlaySessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
              }) => PlaySessionsCompanion(
                id: id,
                gameId: gameId,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required DateTime startedAt,
                required DateTime endedAt,
              }) => PlaySessionsCompanion.insert(
                id: id,
                gameId: gameId,
                startedAt: startedAt,
                endedAt: endedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaySessionsTable, PlaySession>(table),
                  $$PlaySessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $$PlaySessionsTableReferences
                            ._gameIdTable(db),
                        referencedColumn: $$PlaySessionsTableReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaySessionsTable,
      PlaySession,
      $$PlaySessionsTableFilterComposer,
      $$PlaySessionsTableOrderingComposer,
      $$PlaySessionsTableAnnotationComposer,
      $$PlaySessionsTableCreateCompanionBuilder,
      $$PlaySessionsTableUpdateCompanionBuilder,
      (PlaySession, $$PlaySessionsTableReferences),
      PlaySession,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$ActivePlaySessionsTableCreateCompanionBuilder =
    ActivePlaySessionsCompanion Function({
      Value<int> gameId,
      required DateTime startedAt,
      required DateTime lastSeenAt,
    });
typedef $$ActivePlaySessionsTableUpdateCompanionBuilder =
    ActivePlaySessionsCompanion Function({
      Value<int> gameId,
      Value<DateTime> startedAt,
      Value<DateTime> lastSeenAt,
    });

final class $$ActivePlaySessionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ActivePlaySessionsTable,
          ActivePlaySession
        > {
  $$ActivePlaySessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('active_play_sessions__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ActivePlaySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivePlaySessionsTable> {
  $$ActivePlaySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivePlaySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivePlaySessionsTable> {
  $$ActivePlaySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivePlaySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivePlaySessionsTable> {
  $$ActivePlaySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ActivePlaySessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivePlaySessionsTable,
          ActivePlaySession,
          $$ActivePlaySessionsTableFilterComposer,
          $$ActivePlaySessionsTableOrderingComposer,
          $$ActivePlaySessionsTableAnnotationComposer,
          $$ActivePlaySessionsTableCreateCompanionBuilder,
          $$ActivePlaySessionsTableUpdateCompanionBuilder,
          (ActivePlaySession, $$ActivePlaySessionsTableReferences),
          ActivePlaySession,
          PrefetchHooks Function({bool gameId})
        > {
  $$ActivePlaySessionsTableTableManager(
    _$AppDatabase db,
    $ActivePlaySessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivePlaySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivePlaySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivePlaySessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> gameId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> lastSeenAt = const Value.absent(),
              }) => ActivePlaySessionsCompanion(
                gameId: gameId,
                startedAt: startedAt,
                lastSeenAt: lastSeenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> gameId = const Value.absent(),
                required DateTime startedAt,
                required DateTime lastSeenAt,
              }) => ActivePlaySessionsCompanion.insert(
                gameId: gameId,
                startedAt: startedAt,
                lastSeenAt: lastSeenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivePlaySessionsTable, ActivePlaySession>(
                    table,
                  ),
                  $$ActivePlaySessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $$ActivePlaySessionsTableReferences
                            ._gameIdTable(db),
                        referencedColumn: $$ActivePlaySessionsTableReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ActivePlaySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivePlaySessionsTable,
      ActivePlaySession,
      $$ActivePlaySessionsTableFilterComposer,
      $$ActivePlaySessionsTableOrderingComposer,
      $$ActivePlaySessionsTableAnnotationComposer,
      $$ActivePlaySessionsTableCreateCompanionBuilder,
      $$ActivePlaySessionsTableUpdateCompanionBuilder,
      (ActivePlaySession, $$ActivePlaySessionsTableReferences),
      ActivePlaySession,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$StatusHistoryTableCreateCompanionBuilder =
    StatusHistoryCompanion Function({
      Value<int> id,
      required int gameId,
      required String fromStatus,
      required String toStatus,
      required DateTime changedAt,
    });
typedef $$StatusHistoryTableUpdateCompanionBuilder =
    StatusHistoryCompanion Function({
      Value<int> id,
      Value<int> gameId,
      Value<String> fromStatus,
      Value<String> toStatus,
      Value<DateTime> changedAt,
    });

final class $$StatusHistoryTableReferences
    extends
        BaseReferences<_$AppDatabase, $StatusHistoryTable, StatusHistoryData> {
  $$StatusHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GamesTable _gameIdTable(_$AppDatabase db) =>
      db.games.createAlias('status_history__game_id__games__id');

  $$GamesTableProcessedTableManager get gameId {
    final $_column = $_itemColumn<int>('game_id')!;

    final manager = $$GamesTableTableManager(
      $_db,
      $_db.games,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_gameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StatusHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $StatusHistoryTable> {
  $$StatusHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toStatus => $composableBuilder(
    column: $table.toStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GamesTableFilterComposer get gameId {
    final $$GamesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableFilterComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StatusHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $StatusHistoryTable> {
  $$StatusHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toStatus => $composableBuilder(
    column: $table.toStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GamesTableOrderingComposer get gameId {
    final $$GamesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableOrderingComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StatusHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $StatusHistoryTable> {
  $$StatusHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromStatus => $composableBuilder(
    column: $table.fromStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toStatus =>
      $composableBuilder(column: $table.toStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  $$GamesTableAnnotationComposer get gameId {
    final $$GamesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.gameId,
      referencedTable: $db.games,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GamesTableAnnotationComposer(
            $db: $db,
            $table: $db.games,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StatusHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StatusHistoryTable,
          StatusHistoryData,
          $$StatusHistoryTableFilterComposer,
          $$StatusHistoryTableOrderingComposer,
          $$StatusHistoryTableAnnotationComposer,
          $$StatusHistoryTableCreateCompanionBuilder,
          $$StatusHistoryTableUpdateCompanionBuilder,
          (StatusHistoryData, $$StatusHistoryTableReferences),
          StatusHistoryData,
          PrefetchHooks Function({bool gameId})
        > {
  $$StatusHistoryTableTableManager(_$AppDatabase db, $StatusHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StatusHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StatusHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StatusHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> gameId = const Value.absent(),
                Value<String> fromStatus = const Value.absent(),
                Value<String> toStatus = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
              }) => StatusHistoryCompanion(
                id: id,
                gameId: gameId,
                fromStatus: fromStatus,
                toStatus: toStatus,
                changedAt: changedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int gameId,
                required String fromStatus,
                required String toStatus,
                required DateTime changedAt,
              }) => StatusHistoryCompanion.insert(
                id: id,
                gameId: gameId,
                fromStatus: fromStatus,
                toStatus: toStatus,
                changedAt: changedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StatusHistoryTable, StatusHistoryData>(table),
                  $$StatusHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({gameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (gameId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.gameId,
                        referencedTable: $$StatusHistoryTableReferences
                            ._gameIdTable(db),
                        referencedColumn: $$StatusHistoryTableReferences
                            ._gameIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StatusHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StatusHistoryTable,
      StatusHistoryData,
      $$StatusHistoryTableFilterComposer,
      $$StatusHistoryTableOrderingComposer,
      $$StatusHistoryTableAnnotationComposer,
      $$StatusHistoryTableCreateCompanionBuilder,
      $$StatusHistoryTableUpdateCompanionBuilder,
      (StatusHistoryData, $$StatusHistoryTableReferences),
      StatusHistoryData,
      PrefetchHooks Function({bool gameId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$CatalogReviewsTableCreateCompanionBuilder =
    CatalogReviewsCompanion Function({
      required String workId,
      required String title,
      required bool isAdult,
      Value<int?> rating,
      Value<String?> ratingComment,
      required String reviewSyncId,
      required String reviewSyncState,
      required DateTime reviewUpdatedAt,
      Value<int> rowid,
    });
typedef $$CatalogReviewsTableUpdateCompanionBuilder =
    CatalogReviewsCompanion Function({
      Value<String> workId,
      Value<String> title,
      Value<bool> isAdult,
      Value<int?> rating,
      Value<String?> ratingComment,
      Value<String> reviewSyncId,
      Value<String> reviewSyncState,
      Value<DateTime> reviewUpdatedAt,
      Value<int> rowid,
    });

class $$CatalogReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogReviewsTable> {
  $$CatalogReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workId => $composableBuilder(
    column: $table.workId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratingComment => $composableBuilder(
    column: $table.ratingComment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewSyncId => $composableBuilder(
    column: $table.reviewSyncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewSyncState => $composableBuilder(
    column: $table.reviewSyncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewUpdatedAt => $composableBuilder(
    column: $table.reviewUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogReviewsTable> {
  $$CatalogReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workId => $composableBuilder(
    column: $table.workId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratingComment => $composableBuilder(
    column: $table.ratingComment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewSyncId => $composableBuilder(
    column: $table.reviewSyncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewSyncState => $composableBuilder(
    column: $table.reviewSyncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewUpdatedAt => $composableBuilder(
    column: $table.reviewUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogReviewsTable> {
  $$CatalogReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workId =>
      $composableBuilder(column: $table.workId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isAdult =>
      $composableBuilder(column: $table.isAdult, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get ratingComment => $composableBuilder(
    column: $table.ratingComment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewSyncId => $composableBuilder(
    column: $table.reviewSyncId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewSyncState => $composableBuilder(
    column: $table.reviewSyncState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewUpdatedAt => $composableBuilder(
    column: $table.reviewUpdatedAt,
    builder: (column) => column,
  );
}

class $$CatalogReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogReviewsTable,
          CatalogReview,
          $$CatalogReviewsTableFilterComposer,
          $$CatalogReviewsTableOrderingComposer,
          $$CatalogReviewsTableAnnotationComposer,
          $$CatalogReviewsTableCreateCompanionBuilder,
          $$CatalogReviewsTableUpdateCompanionBuilder,
          (
            CatalogReview,
            BaseReferences<_$AppDatabase, $CatalogReviewsTable, CatalogReview>,
          ),
          CatalogReview,
          PrefetchHooks Function()
        > {
  $$CatalogReviewsTableTableManager(
    _$AppDatabase db,
    $CatalogReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<int?> rating = const Value.absent(),
                Value<String?> ratingComment = const Value.absent(),
                Value<String> reviewSyncId = const Value.absent(),
                Value<String> reviewSyncState = const Value.absent(),
                Value<DateTime> reviewUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogReviewsCompanion(
                workId: workId,
                title: title,
                isAdult: isAdult,
                rating: rating,
                ratingComment: ratingComment,
                reviewSyncId: reviewSyncId,
                reviewSyncState: reviewSyncState,
                reviewUpdatedAt: reviewUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workId,
                required String title,
                required bool isAdult,
                Value<int?> rating = const Value.absent(),
                Value<String?> ratingComment = const Value.absent(),
                required String reviewSyncId,
                required String reviewSyncState,
                required DateTime reviewUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CatalogReviewsCompanion.insert(
                workId: workId,
                title: title,
                isAdult: isAdult,
                rating: rating,
                ratingComment: ratingComment,
                reviewSyncId: reviewSyncId,
                reviewSyncState: reviewSyncState,
                reviewUpdatedAt: reviewUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CatalogReviewsTable, CatalogReview>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CatalogReviewsTable,
                    CatalogReview
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogReviewsTable,
      CatalogReview,
      $$CatalogReviewsTableFilterComposer,
      $$CatalogReviewsTableOrderingComposer,
      $$CatalogReviewsTableAnnotationComposer,
      $$CatalogReviewsTableCreateCompanionBuilder,
      $$CatalogReviewsTableUpdateCompanionBuilder,
      (
        CatalogReview,
        BaseReferences<_$AppDatabase, $CatalogReviewsTable, CatalogReview>,
      ),
      CatalogReview,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScanFoldersTableTableManager get scanFolders =>
      $$ScanFoldersTableTableManager(_db, _db.scanFolders);
  $$GamesTableTableManager get games =>
      $$GamesTableTableManager(_db, _db.games);
  $$PlaySessionsTableTableManager get playSessions =>
      $$PlaySessionsTableTableManager(_db, _db.playSessions);
  $$ActivePlaySessionsTableTableManager get activePlaySessions =>
      $$ActivePlaySessionsTableTableManager(_db, _db.activePlaySessions);
  $$StatusHistoryTableTableManager get statusHistory =>
      $$StatusHistoryTableTableManager(_db, _db.statusHistory);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$CatalogReviewsTableTableManager get catalogReviews =>
      $$CatalogReviewsTableTableManager(_db, _db.catalogReviews);
}
