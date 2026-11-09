import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'features/settings/maintenance_dialogs.dart';
import 'features/records/record_store.dart';
import 'features/records/work_records_dialog.dart';
import 'features/records/organizer_page.dart';
import 'features/records/insights_page.dart';
import 'features/records/transfer_dialog.dart';
import 'services/cover_image_cache.dart';
import 'services/desktop_tray_service.dart';
import 'services/game_process_monitor.dart';
import 'services/review_sync_service.dart';
import 'features/settings/help_dialogs.dart';

import 'features/library/catalog_match_dialog.dart';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/demo_games.dart';
import 'catalog/catalog_database.dart';
import 'database/app_database.dart';
import 'features/board/board_page.dart';
import 'features/catalog/catalog_page.dart';
import 'features/library/game_detail_page.dart';
import 'features/library/library_page.dart';
import 'features/settings/settings_page.dart';
import 'models/game.dart';
import 'scanner/game_scanner.dart';
import 'theme/app_theme.dart';
import 'widgets/cover_image.dart';

const defaultReviewApiEndpoint = String.fromEnvironment(
  'NOVELIB_REVIEW_API_URL',
  defaultValue:
      'https://obviivsrjjmofuiniwix.supabase.co/functions/v1/review-api/',
);

class ChronovelApp extends StatefulWidget {
  const ChronovelApp({
    super.key,
    this.database,
    this.scanner,
    this.catalog,
    this.showWelcome = false,
    this.enableDesktopIntegration = false,
    this.reviewApiEndpoint = defaultReviewApiEndpoint,
  });
  final bool showWelcome;
  final bool enableDesktopIntegration;
  final String reviewApiEndpoint;

  final AppDatabase? database;
  final GameScanner? scanner;
  final CatalogDatabase? catalog;

  @override
  State<ChronovelApp> createState() => _ChronovelAppState();
}

class _ChronovelAppState extends State<ChronovelApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _blurCovers = false;

  @override
  void initState() {
    super.initState();
    _restoreTheme();
  }

  Future<void> _restoreTheme() async {
    final saved = await widget.database?.readSetting('appearance.theme');
    final blur = await widget.database?.readSetting('appearance.blurCovers');
    if (!mounted) return;
    setState(() {
      _themeMode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
      _blurCovers = blur == 'true';
    });
  }

  Future<void> _setThemeMode(ThemeMode value) async {
    await widget.database?.writeSetting(
      'appearance.theme',
      value == ThemeMode.light ? 'light' : 'dark',
    );
    if (mounted) setState(() => _themeMode = value);
  }

  Future<void> _setBlurCovers(bool value) async {
    await widget.database?.writeSetting(
      'appearance.blurCovers',
      value.toString(),
    );
    if (mounted) setState(() => _blurCovers = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NoveLib',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: CoverPrivacy(
        blurEnabled: _blurCovers,
        child: AppShell(
          database: widget.database,
          scanner: widget.scanner,
          catalog: widget.catalog,
          showWelcome: widget.showWelcome,
          enableDesktopIntegration: widget.enableDesktopIntegration,
          themeMode: _themeMode,
          onThemeModeChanged: _setThemeMode,
          blurCovers: _blurCovers,
          onBlurCoversChanged: _setBlurCovers,
          reviewApiEndpoint: widget.reviewApiEndpoint,
        ),
      ),
    );
  }
}

enum AppSection {
  library,
  detail,
  catalog,
  board,
  records,
  rankings,
  statistics,
  settings,
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.database,
    this.scanner,
    this.catalog,
    this.showWelcome = false,
    this.enableDesktopIntegration = false,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.blurCovers,
    required this.onBlurCoversChanged,
    this.reviewApiEndpoint = defaultReviewApiEndpoint,
  });
  final bool showWelcome;
  final bool enableDesktopIntegration;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final bool blurCovers;
  final ValueChanged<bool> onBlurCoversChanged;
  final String reviewApiEndpoint;

  final AppDatabase? database;
  final GameScanner? scanner;
  final CatalogDatabase? catalog;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppSection _section = AppSection.library;
  late List<GameEntry> _games;
  late final GameScanner _scanner;
  StreamSubscription<List<GameEntry>>? _databaseSubscription;
  List<String> _scanFolders = const [];
  bool _isScanning = false;
  bool _isRemovingFolder = false;
  bool _isRegistering = false;
  bool _isUpdatingCatalog = false;
  Map<String, List<String>> _diagnostics = {};
  String? _scanMessage;
  String? _selectedGameId;
  final Set<String> _runningGameIds = {};
  Map<int, WorkNotes> _notes = {};
  bool _showAdult = true;
  bool _closeToTray = true;
  GameStatus? _libraryFilter;
  LibraryViewMode _libraryViewMode = LibraryViewMode.grid;
  Map<String, ShelfPlacement> _libraryShelfPlacements = {};
  int? _libraryShelfRows;
  DesktopTrayService? _trayService;
  GameProcessMonitor? _processMonitor;
  bool _reviewSharingEnabled = false;
  bool _reviewSyncing = false;
  bool _reviewSharingPromptOpen = false;
  String? _reviewSyncStatus;

  @override
  void initState() {
    super.initState();
    _scanner = widget.scanner ?? GameScanner();
    _games = widget.database == null ? [...demoGames] : [];
    if (widget.showWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWelcome();
      });
    }
    final database = widget.database;
    if (database != null) {
      _databaseSubscription = database
          .watchGames()
          .asyncMap((records) async {
            final saved = await database.select(database.appSettings).get();
            final values = {for (final row in saved) row.key: row.value};
            _showAdult = values['display.showAdult'] != 'false';
            _libraryViewMode = LibraryViewMode.values.firstWhere(
              (value) => value.name == values['library.viewMode'],
              orElse: () => LibraryViewMode.grid,
            );
            final savedShelfRows = values['library.shelfRows'];
            _libraryShelfRows =
                savedShelfRows == null || savedShelfRows == 'auto'
                ? null
                : int.tryParse(savedShelfRows)?.clamp(1, 12);
            try {
              final raw = jsonDecode(
                values['library.shelfPositions'] ?? '{}',
              ) as Map<String, dynamic>;
              final placements = <String, ShelfPlacement>{};
              for (final entry in raw.entries) {
                final placement = ShelfPlacement.fromJson(entry.value);
                if (placement != null) placements[entry.key] = placement;
              }
              _libraryShelfPlacements = placements;
            } catch (_) {
              _libraryShelfPlacements = {};
            }
            final orderedIds = <int>[];
            try {
              orderedIds.addAll(
                (jsonDecode(values['library.manualOrder'] ?? '[]') as List).map(
                  (value) => int.parse('$value'),
                ),
              );
            } catch (_) {}
            if (orderedIds.isNotEmpty) {
              final positions = {
                for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
              };
              records.sort((a, b) {
                final ai = positions[a.id] ?? 0x7fffffff;
                final bi = positions[b.id] ?? 0x7fffffff;
                return ai != bi ? ai.compareTo(bi) : a.id.compareTo(b.id);
              });
            }
            _notes = {};
            for (final record in records) {
              try {
                _notes[record.id] = WorkNotes.decode(
                  values['notes.${record.id}'],
                );
              } catch (_) {
                _notes[record.id] = WorkNotes();
              }
            }
            return _mapGameRecords(records);
          })
          .listen((games) {
            if (!mounted) return;
            setState(() => _games = games);
          });
      _refreshScanFolders();
      _loadDiagnostics();
      unawaited(_restoreReviewSharing(database));
      if (widget.enableDesktopIntegration) {
        _initializeDesktopServices(database);
      }
    }
  }

  Future<void> _initializeDesktopServices(AppDatabase database) async {
    _closeToTray = await database.readSetting('window.closeToTray') != 'false';
    final tray = DesktopTrayService();
    _trayService = tray;
    await tray.initialize(enabled: _closeToTray);
    final monitor = GameProcessMonitor(
      database: database,
      onRunningChanged: (ids) {
        if (!mounted) return;
        setState(() {
          _runningGameIds
            ..clear()
            ..addAll(ids);
        });
      },
    );
    _processMonitor = monitor;
    await monitor.start();
  }

  @override
  void dispose() {
    _processMonitor?.dispose();
    _trayService?.dispose();
    _databaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _showWelcome() async {
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WelcomeDialog(
        onComplete: () async {
          await widget.database?.writeSetting(welcomeSettingKey, 'true');
        },
      ),
    );
    if (mounted && completed == true) {
      setState(() => _section = AppSection.settings);
      await _promptReviewSharing();
    }
  }

  Future<void> _changeStatus(String gameId, GameStatus status) async {
    setState(() {
      final index = _games.indexWhere((game) => game.id == gameId);
      if (index == -1 || _games[index].status == status) return;
      _games[index] = _games[index].copyWith(status: status);
    });
    final database = widget.database;
    final numericId = int.tryParse(gameId);
    if (database != null && numericId != null) {
      await database.changeGameStatus(numericId, status.key);
    }
  }

  Future<void> _setShowAdult(bool value) async {
    if (value && mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('R18作品を表示しますか？'),
          content: const Text('18歳以上で、居住地域の法令により成人向け作品を閲覧できる場合だけ有効にしてください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('表示しない'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('18歳以上・表示する'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await widget.database?.writeSetting('display.showAdult', value.toString());
    if (!mounted) return;
    setState(() {
      _showAdult = value;
      if (!value &&
          _section == AppSection.detail &&
          _games
              .where((game) => game.id == _selectedGameId)
              .any((game) => game.isAdult)) {
        _section = AppSection.library;
      }
    });
  }

  Future<void> _changeRating(String gameId, int? rating) async {
    setState(() {
      final index = _games.indexWhere((game) => game.id == gameId);
      if (index == -1) return;
      _games[index] = _games[index].copyWith(
        rating: rating,
        clearRating: rating == null,
      );
    });
    final database = widget.database;
    final numericId = int.tryParse(gameId);
    if (database != null && numericId != null) {
      await database.setGameRating(numericId, rating);
      if (_reviewSharingEnabled) unawaited(_syncReviews());
    }
  }

  Future<void> _changeReview(
    String gameId,
    int? rating,
    String? comment,
  ) async {
    setState(() {
      final index = _games.indexWhere((game) => game.id == gameId);
      if (index == -1) return;
      _games[index] = _games[index].copyWith(
        rating: rating,
        clearRating: rating == null,
        ratingComment: comment?.trim() ?? '',
      );
    });
    final numericId = int.tryParse(gameId);
    if (widget.database != null && numericId != null) {
      await widget.database!.setGameReview(numericId, rating, comment);
      if (_reviewSharingEnabled) unawaited(_syncReviews());
    }
  }

  Future<void> _restoreReviewSharing(AppDatabase database) async {
    final saved = await database.readSetting('cloud.reviewSharingEnabled');
    final enabled = widget.reviewApiEndpoint.isNotEmpty && saved == 'true';
    if (!mounted) return;
    setState(() {
      _reviewSharingEnabled = enabled;
      _reviewSyncStatus = widget.reviewApiEndpoint.isEmpty
          ? '評価サーバーはまだ接続されていません。'
          : enabled
          ? '匿名評価の共有は有効です。'
          : '匿名評価の共有はオフです。';
    });
    if (enabled) unawaited(_syncReviews());
    if (saved == null &&
        widget.reviewApiEndpoint.isNotEmpty &&
        !widget.showWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_promptReviewSharing());
      });
    }
  }

  Future<void> _promptReviewSharing() async {
    final database = widget.database;
    if (!mounted ||
        database == null ||
        widget.reviewApiEndpoint.isEmpty ||
        _reviewSharingPromptOpen) {
      return;
    }
    final saved = await database.readSetting('cloud.reviewSharingEnabled');
    if (!mounted || saved != null) return;
    _reviewSharingPromptOpen = true;
    var share = true;
    final enabled = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('評価ランキングへの共有'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'みんなの評価ランキングを充実させるため、匿名で評価を共有できます。共有するのは作品ID、点数、任意の評価コメントです。保存場所やプレイ履歴は送信しません。',
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: share,
                  onChanged: (value) =>
                      setDialogState(() => share = value ?? true),
                  title: const Text('匿名で評価を共有する（おすすめ）'),
                  subtitle: const Text('あとから設定画面でいつでも変更できます。'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('今回は共有しない'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, share),
              child: const Text('この設定で開始'),
            ),
          ],
        ),
      ),
    );
    _reviewSharingPromptOpen = false;
    if (enabled != null) await _setReviewSharing(enabled);
  }

  Future<void> _setReviewSharing(bool enabled) async {
    final database = widget.database;
    if (database == null || widget.reviewApiEndpoint.isEmpty) return;
    await database.writeSetting(
      'cloud.reviewSharingEnabled',
      enabled.toString(),
    );
    if (!mounted) return;
    setState(() {
      _reviewSharingEnabled = enabled;
      _reviewSyncStatus = enabled
          ? '匿名評価の共有を有効にしました。'
          : '匿名評価の共有を停止しました。端末内の評価は保持されます。';
    });
    if (enabled) await _syncReviews();
  }

  Future<void> _syncReviews() async {
    final database = widget.database;
    if (database == null ||
        widget.reviewApiEndpoint.isEmpty ||
        !_reviewSharingEnabled ||
        _reviewSyncing) {
      return;
    }
    setState(() {
      _reviewSyncing = true;
      _reviewSyncStatus = '匿名評価を同期しています…';
    });
    try {
      final token = await _reviewToken(database);
      final transport = HttpReviewTransport(
        endpoint: Uri.parse(widget.reviewApiEndpoint),
        anonymousToken: token,
      );
      final result = await ReviewSyncService(
        database: database,
        transport: transport,
        isAdultWork: (workId) => _games
            .where((game) => game.vndbId == workId)
            .every((game) => game.isAdult),
      ).syncPending();
      if (!mounted) return;
      setState(() {
        _reviewSyncStatus = result.failed > 0
            ? '${result.uploaded + result.deleted}件を同期、${result.failed}件は後で再試行します。'
            : result.uploaded + result.deleted == 0
            ? '同期する変更はありません。'
            : '${result.uploaded + result.deleted}件を同期しました。';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _reviewSyncStatus = '同期できませんでした。時間をおいて再試行してください。');
      }
    } finally {
      if (mounted) setState(() => _reviewSyncing = false);
    }
  }

  Future<String> _reviewToken(AppDatabase database) async {
    var token = await database.readSetting('cloud.reviewAnonymousToken');
    if (token == null || token.isEmpty) {
      token = createAnonymousReviewToken();
      await database.writeSetting('cloud.reviewAnonymousToken', token);
    }
    return token;
  }

  Future<void> _reportComment(
    String reviewId,
    String reason,
    String details,
  ) async {
    final database = widget.database;
    if (database == null || widget.reviewApiEndpoint.isEmpty) {
      throw StateError('評価サーバーへ接続されていません。');
    }
    final token = await _reviewToken(database);
    await HttpReviewTransport(
      endpoint: Uri.parse(widget.reviewApiEndpoint),
      anonymousToken: token,
    ).reportComment(reviewId: reviewId, reason: reason, details: details);
  }

  Future<void> _eraseSharedReviews() async {
    final database = widget.database;
    if (!mounted || database == null || widget.reviewApiEndpoint.isEmpty) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('共有済み評価をサーバーから削除'),
        content: const Text(
          'この端末から共有した評価点とコメントをサーバーからすべて削除します。'
          '端末内の評価・コメントは残り、評価共有はオフになります。この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('サーバーから削除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _reviewSyncing = true;
      _reviewSyncStatus = '共有済み評価を削除しています…';
    });
    try {
      final token = await _reviewToken(database);
      final count = await HttpReviewTransport(
        endpoint: Uri.parse(widget.reviewApiEndpoint),
        anonymousToken: token,
      ).eraseSharedReviews();
      await database.writeSetting('cloud.reviewSharingEnabled', 'false');
      await database.writeSetting('cloud.reviewAnonymousToken', '');
      if (mounted) {
        setState(() {
          _reviewSharingEnabled = false;
          _reviewSyncStatus = 'サーバーから$count件を削除しました。端末内の評価は保持しています。';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _reviewSyncStatus = '削除できませんでした。通信状態を確認して再試行してください。');
      }
    } finally {
      if (mounted) setState(() => _reviewSyncing = false);
    }
  }

  Future<void> _reorderLibrary(List<String> visibleOrder) async {
    if (visibleOrder.length < 2) return;
    final desired = <String, int>{
      for (var i = 0; i < visibleOrder.length; i++) visibleOrder[i]: i,
    };
    final groups = groupLibraryGames(_games);
    final movable =
        groups.where((group) => desired.containsKey(group.id)).toList()
          ..sort((a, b) => desired[a.id]!.compareTo(desired[b.id]!));
    var next = 0;
    final reordered = <GameEntry>[];
    for (final group in groups) {
      final replacement = desired.containsKey(group.id)
          ? movable[next++]
          : group;
      reordered.addAll(replacement.members);
    }
    setState(() => _games = reordered);
    await widget.database?.writeSetting(
      'library.manualOrder',
      jsonEncode(reordered.map((game) => game.id).toList()),
    );
  }

  Future<void> _launchGame(String gameId) async {
    if (_runningGameIds.contains(gameId)) return;
    final index = _games.indexWhere((game) => game.id == gameId);
    if (index == -1) return;
    final game = _games[index];
    final exePath = game.exePath;
    if (exePath == null || !await File(exePath).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('実行ファイルが見つかりません。再スキャンしてください。')),
        );
      }
      return;
    }

    setState(() => _runningGameIds.add(gameId));
    final startedAt = DateTime.now().toUtc();
    try {
      final process = await Process.start(
        exePath,
        const [],
        workingDirectory: game.installDir,
        mode: ProcessStartMode.normal,
      );
      if (game.status == GameStatus.notPlayed) {
        await _changeStatus(gameId, GameStatus.playing);
      }
      final database = widget.database;
      final numericId = int.tryParse(gameId);
      if (database != null && numericId != null) {
        await database.touchActivePlaySession(
          gameId: numericId,
          startedAt: startedAt,
          seenAt: startedAt,
        );
        Timer(
          const Duration(seconds: 1),
          () => unawaited(_processMonitor?.pollNow()),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('「${game.title}」を起動しました。プレイ時間を監視します。')),
          );
        }
        return;
      }

      await process.exitCode;
      final endedAt = DateTime.now().toUtc();
      final seconds = endedAt.difference(startedAt).inSeconds;
      if (seconds > 0 && mounted) {
        setState(() {
          final currentIndex = _games.indexWhere(
            (candidate) => candidate.id == gameId,
          );
          if (currentIndex != -1) {
            final current = _games[currentIndex];
            _games[currentIndex] = current.copyWith(
              playHours: current.playHours + seconds / 3600,
            );
          }
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${game.title}」のプレイ時間を記録しました。')),
        );
      }
    } on ProcessException catch (error) {
      if (mounted) setState(() => _runningGameIds.remove(gameId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ゲームを起動できませんでした: ${error.message}')),
        );
      }
    }
  }

  Future<void> _deleteGame(String gameId) async {
    await _deleteGames({gameId});
  }

  Future<int> _deleteGames(Set<String> gameIds) async {
    if (gameIds.isEmpty) return 0;
    if (_isScanning || gameIds.any(_runningGameIds.contains)) {
      throw StateError('起動中・スキャン中は削除できません');
    }
    final database = widget.database;
    var deleted = 0;
    if (database != null) {
      final numericIds = gameIds.map(int.tryParse).whereType<int>();
      deleted = await database.deleteGames(numericIds);
    } else {
      final before = _games.length;
      setState(() => _games.removeWhere((game) => gameIds.contains(game.id)));
      deleted = before - _games.length;
    }
    if (!mounted || deleted == 0) return deleted;
    if (_selectedGameId != null && gameIds.contains(_selectedGameId)) {
      setState(() {
        _selectedGameId = null;
        _section = AppSection.library;
      });
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$deleted 本をライブラリから削除しました。')));
    return deleted;
  }

  void _openGame(String gameId) {
    setState(() {
      _selectedGameId = gameId;
      _section = AppSection.detail;
    });
  }

  Future<void> _refreshScanFolders() async {
    final database = widget.database;
    if (database == null) return;
    final folders = await database.getScanFolders();
    if (mounted) setState(() => _scanFolders = folders);
  }

  Future<void> _loadDiagnostics() async {
    try {
      final raw = await widget.database?.readSetting('scan.diagnostics.v1');
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final reports = <String, List<String>>{
        for (final entry in decoded.entries)
          if (entry.value is List)
            entry.key: (entry.value as List).whereType<String>().toList(),
      };
      if (mounted) setState(() => _diagnostics = reports);
    } catch (_) {
      /* Older or malformed diagnostic data does not block startup. */
    }
  }

  void _showDiagnostics() {
    final imageFailures =
        CoverImageCache.instance.failureRecords.values.toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ScanDiagnosticsDialog(
        games: List.of(_games),
        reports: _diagnostics.values.expand((items) => items).toList(),
        imageFailures: imageFailures,
        onOpen: (id) {
          Navigator.pop(dialogContext);
          _openGame(id);
        },
        onRegister: (path) {
          Navigator.pop(dialogContext);
          _manualRegister(path);
        },
      ),
    );
  }

  Future<void> _reviewImages() async {
    final cache = CoverImageCache.instance;
    final items = _games
        .where(
          (g) =>
              g.localCoverPath == null &&
              (g.vndbId == null ||
                  g.coverImageUrl == null ||
                  cache.failureFor(g.vndbId!, g.coverImageUrl!) != null),
        )
        .toList();
    final chosen = await showDialog<GameEntry>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('画像・照合を確認'),
        content: SizedBox(
          width: 760,
          height: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '未照合は画像の再取得だけでは解決しません。候補を選ぶか、詳細の「情報を編集」で手元の画像を指定してください。\n取得失敗の理由・最終発生時刻・試行回数は再起動後も保存されます。',
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final g = items[i];
                    final failure = g.vndbId == null || g.coverImageUrl == null
                        ? null
                        : cache.failureRecordFor(g.vndbId!, g.coverImageUrl!);
                    final reason = g.vndbId == null
                        ? '作品を特定できていません（候補を確認）'
                        : g.coverImageUrl == null
                        ? 'カタログに画像の登録がありません'
                        : failure == null
                        ? cache.failureFor(g.vndbId!, g.coverImageUrl!)!
                        : '${failure.message}（${failure.attempts}回）';
                    return ListTile(
                      title: Text(g.title),
                      subtitle: Text('$reason\n${g.installDir ?? ''}'),
                      trailing: TextButton(
                        onPressed: () => Navigator.pop(c, g),
                        child: Text(g.vndbId == null ? '候補を選ぶ' : '詳細を開く'),
                      ),
                    );
                  },
                ),
              ),
              if (items.isEmpty) const Text('未照合・画像未登録・確認済みの取得失敗はありません。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    _openGame(chosen.id);
    if (chosen.vndbId == null &&
        widget.database != null &&
        widget.catalog != null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CatalogMatchDialog(
          game: chosen,
          catalog: widget.catalog!,
          onSave: (work) => widget.database!.selectCatalogWork(
            int.parse(chosen.id),
            work.vndbId,
            work.titleJa,
          ),
        ),
      );
    }
  }

  Future<void> _updateCatalog() async {
    final catalog = widget.catalog;
    if (catalog == null || _isUpdatingCatalog || _isScanning) return;
    final selected = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'NoveLib作品カタログ', extensions: ['sqlite', 'db']),
      ],
      confirmButtonText: 'このカタログを確認',
    );
    if (selected == null || !mounted) return;
    CatalogUpdateInfo preview;
    try {
      await catalog.verifyOfficialUpdate(selected.path);
      preview = catalog.inspectUpdate(selected.path);
    } on CatalogUpdateException catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('カタログを更新できません'),
          content: Text(error.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('作品カタログを更新'),
        content: Text(
          '${preview.workCount}作品\n更新 ${preview.sourceTimestamp}\nSHA-256確認済み\n\n'
          'このカタログへ切り替えます。評価・記録・ゲーム登録には影響しません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('更新する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isUpdatingCatalog = true);
    try {
      final info = await catalog.installUpdate(selected.path);
      final records = await widget.database?.getGames();
      if (!mounted) return;
      setState(() {
        if (records != null) {
          _games = _mapGameRecords(records);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '作品カタログを更新しました（${info.workCount}作品・${info.sourceTimestamp}）。',
          ),
        ),
      );
    } on CatalogUpdateException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingCatalog = false);
    }
  }

  Future<void> _restoreCatalog() async {
    final catalog = widget.catalog;
    if (catalog == null || !catalog.isUsingUpdate || _isUpdatingCatalog) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('同梱カタログに戻す'),
        content: const Text('更新前の同梱カタログへ戻します。評価・記録・ゲーム登録には影響しません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('同梱版に戻す'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isUpdatingCatalog = true);
    try {
      final info = await catalog.restoreBundled();
      final records = await widget.database?.getGames();
      if (!mounted) return;
      setState(() {
        if (records != null) _games = _mapGameRecords(records);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('同梱カタログへ戻しました（${info.workCount}作品）。')),
      );
    } on CatalogUpdateException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isUpdatingCatalog = false);
    }
  }

  Future<void> _manualRegister([String? directory]) async {
    final database = widget.database;
    if (database == null ||
        _isScanning ||
        _isRemovingFolder ||
        _isRegistering ||
        _runningGameIds.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ゲーム起動中・処理中は手動登録できません。終了後にお試しください。')),
      );
      return;
    }
    setState(() => _isRegistering = true);
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ManualRegistrationDialog(
          initialDirectory: directory,
          catalog: widget.catalog,
          onSave: (title, exe, work) async {
            if (_isScanning || _runningGameIds.isNotEmpty) {
              throw StateError('起動・スキャン中は登録できません');
            }
            await database.transaction(() async {
              final id = await database.registerManualGame(title, exe);
              if (work != null) {
                await database.selectCatalogWork(id, work.vndbId, work.titleJa);
              }
            });
            if (mounted) {
              setState(() => _scanMessage = '指定した実行ファイルを登録しました。ゲームは起動していません。');
            }
          },
        ),
      );
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _removeScanFolder(String path) async {
    final database = widget.database;
    if (database == null ||
        _isScanning ||
        _isRemovingFolder ||
        _isRegistering) {
      return;
    }
    setState(() => _isRemovingFolder = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('スキャン対象から外しますか？'),
          content: Text(
            '$path\n\n登録済みの作品・評価・プレイ履歴と、ゲーム本体は残ります。\n必要になったら再度追加できます。親フォルダも登録している場合は、そちらのスキャン対象には引き続き含まれます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('対象から外す'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await database.removeScanFolder(path);
      await _refreshScanFolders();
      if (mounted) {
        setState(() => _scanMessage = 'スキャン対象から外しました。登録作品やゲーム本体は残っています。');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _scanMessage = 'フォルダ設定を変更できませんでした。もう一度お試しください。');
      }
    } finally {
      if (mounted) setState(() => _isRemovingFolder = false);
    }
  }

  Future<void> _scanFolder({String? existingPath}) async {
    final database = widget.database;
    if (database == null ||
        _isScanning ||
        _isRemovingFolder ||
        _isRegistering) {
      return;
    }

    setState(() {
      _isScanning = true;
      _scanMessage = 'フォルダを確認しています…';
    });

    try {
      final folderPath =
          existingPath ??
          await getDirectoryPath(confirmButtonText: 'このフォルダを登録');
      if (!mounted) return;
      if (folderPath == null) {
        setState(() => _scanMessage = null);
        return;
      }
      if (!await Directory(folderPath).exists()) {
        throw FileSystemException(
          'フォルダが見つかりません。保存場所やドライブの接続を確認してください。',
          folderPath,
        );
      }
      if (mounted) setState(() => _scanMessage = '$folderPath をスキャンしています…');
      final detected = await _scanner.scan(folderPath);
      final nextDiagnostics = {
        ..._diagnostics,
        folderPath: _scanner.warnings
            .map(
              (w) =>
                  '[${DateTime.now().toLocal().toIso8601String().substring(0, 16)}] $w',
            )
            .toList(),
      };
      var unmatched = 0;
      var heldGeneralGames = 0;
      await database.transaction(() async {
        await database.saveScanFolder(folderPath);
        for (final game in detected) {
          final catalogMatch = widget.catalog?.matchTitles([
            game.title,
            ...game.titleCandidates,
          ]);
          if (!shouldAutoRegisterDetectedGame(
            game,
            hasCatalogMatch: catalogMatch != null,
          )) {
            heldGeneralGames++;
            continue;
          }
          if (catalogMatch == null) unmatched++;
          await database.upsertDetectedGame(
            title: catalogMatch?.titleJa ?? game.title,
            installDir: game.installDir,
            exePath: game.exePath,
            engine: game.engine,
            rjCode: game.rjCode,
            vndbId: catalogMatch?.vndbId,
          );
        }
        await database.writeSetting(
          'scan.diagnostics.v1',
          jsonEncode(nextDiagnostics),
        );
      });
      _diagnostics = nextDiagnostics;
      await _refreshScanFolders();
      if (mounted) {
        setState(
          () => _scanMessage =
              '${detected.length - heldGeneralGames} 件を登録・更新（カタログ未照合 $unmatched 件）。'
              '${heldGeneralGames == 0 ? '' : '一般ゲームの可能性がある $heldGeneralGames 件は自動登録を保留しました。'}'
              '既存登録は自動削除しません。'
              '${_scanner.warnings.isEmpty ? '' : ' 対応データ未確認・読取不可の場所: ${_scanner.warnings.length} 件。'}',
        );
      }
    } on FileSystemException catch (error) {
      if (mounted) setState(() => _scanMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _scanMessage = 'スキャン中に問題が発生しました。別のフォルダでお試しください。');
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  List<GameEntry> _mapGameRecords(List<GameRecord> records) {
    final ids = records.map((record) => record.vndbId).whereType<String>();
    final works =
        widget.catalog?.findByIds(ids) ?? const <String, CatalogWork>{};
    return records.map((record) => _toGameEntry(record, works)).toList();
  }

  GameEntry _toGameEntry(
    GameRecord record,
    Map<String, CatalogWork> catalogWorks,
  ) {
    final catalogWork = catalogWorks[record.vndbId];
    final edits = GameEdits.decode(record.metadataOverrides);
    final notes = _notes[record.id] ?? WorkNotes();
    return GameEntry(
      id: '${record.id}',
      title: edits.title ?? record.title,
      brand:
          edits.brand ?? catalogWork?.developers ?? _engineLabel(record.engine),
      status: GameStatus.values.firstWhere(
        (status) => status.key == record.status,
        orElse: () => GameStatus.notPlayed,
      ),
      playHours: record.totalPlaySec / 3600,
      routeCurrent: notes.routes.where((r) => r['status'] == '完了').length,
      routeTotal: notes.routes.length,
      rating: record.rating,
      ratingComment: record.ratingComment,
      coverColors: _coverColors(record.id),
      tags: notes.tags,
      vndbId: record.vndbId,
      coverImageUrl: catalogWork?.imageUrl,
      localCoverPath: edits.imagePath,
      titleRomaji: catalogWork?.titleRomaji,
      released: edits.released ?? catalogWork?.released,
      developers: edits.brand ?? catalogWork?.developers,
      catalogRating: catalogWork?.rating,
      catalogVoteCount: catalogWork?.voteCount ?? 0,
      isAdult: catalogWork?.isAdult ?? false,
      installDir: record.installDir,
      exePath: record.exePath,
      engine: _engineLabel(record.engine),
      coverBlurOverride: edits.blurCover,
    );
  }

  String _engineLabel(String? engine) => switch (engine) {
    'kirikiri' => '吉里吉里',
    'nscripter' => 'NScripter',
    'renpy' => "Ren'Py",
    'unity' => 'Unity',
    'yu-ris' => 'Yu-ris',
    'catsystem2' => 'CatSystem2',
    'ethornell' => 'Ethornell',
    'tyrano' => 'ティラノスクリプト',
    'system4' => 'System4',
    'system3' => 'System3',
    'siglus' => 'SiglusEngine',
    'exhibit' => 'ExHIBIT',
    'manual' => '手動登録',
    _ => 'ローカル作品',
  };

  List<Color> _coverColors(int seed) {
    const palettes = [
      [Color(0xFF58C4DB), Color(0xFF132033)],
      [Color(0xFFD788B7), Color(0xFF241C2E)],
      [Color(0xFF5DCEBE), Color(0xFF142E2C)],
      [Color(0xFFA178D4), Color(0xFF211A30)],
      [Color(0xFFE8BF50), Color(0xFF382A16)],
      [Color(0xFF759CDF), Color(0xFF192239)],
    ];
    return palettes[seed % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    void select(AppSection section) {
      if (_section != section) setState(() => _section = section);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
            select(AppSection.library),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            select(AppSection.board),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
            select(AppSection.rankings),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
            select(AppSection.statistics),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
            select(AppSection.records),
        const SingleActivator(LogicalKeyboardKey.digit6, control: true): () =>
            select(AppSection.settings),
        const SingleActivator(LogicalKeyboardKey.comma, control: true): () =>
            select(AppSection.settings),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () {
          if (_section == AppSection.detail) select(AppSection.library);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_section == AppSection.detail) select(AppSection.library);
        },
      },
      child: Focus(
        autofocus: true,
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: _buildScaffold(context),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final visibleGames = _showAdult
        ? _games
        : _games.where((game) => !game.isAdult).toList();
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 1100 || constraints.maxHeight < 720;
          return Row(
            children: [
              AppSidebar(
                compact: compact,
                selected: _section,
                games: visibleGames,
                onSelected: (section) => setState(() => _section = section),
                onHome: () => setState(() => _section = AppSection.library),
              ),
              Expanded(child: _buildPage(visibleGames)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPage(List<GameEntry> visibleGames) {
    return switch (_section) {
      AppSection.library => LibraryPage(
        onReviewImages: _reviewImages,
        games: visibleGames,
        onStatusChanged: _changeStatus,
        onDeleteRequested: _deleteGame,
        onDeleteManyRequested: _deleteGames,
        onGameOpened: _openGame,
        onScanRequested: widget.database == null ? null : _scanFolder,
        isScanning: _isScanning,
        initialFilter: _libraryFilter,
        onFilterChanged: (value) => setState(() => _libraryFilter = value),
        initialViewMode: _libraryViewMode,
        onViewModeChanged: (value) async {
          setState(() => _libraryViewMode = value);
          await widget.database?.writeSetting('library.viewMode', value.name);
        },
        onGamesReordered: _reorderLibrary,
        initialShelfPlacements: _libraryShelfPlacements,
        initialShelfRows: _libraryShelfRows,
        onShelfPlacementsChanged: (positions) async {
          setState(() => _libraryShelfPlacements = Map.of(positions));
          await widget.database?.writeSetting(
            'library.shelfPositions',
            jsonEncode({
              for (final entry in positions.entries)
                entry.key: entry.value.toJson(),
            }),
          );
        },
        onShelfRowsChanged: (rows) async {
          setState(() => _libraryShelfRows = rows);
          await widget.database?.writeSetting(
            'library.shelfRows',
            rows?.toString() ?? 'auto',
          );
        },
      ),
      AppSection.detail => _buildDetailPage(),
      AppSection.catalog => CatalogPage(
        key: ValueKey(widget.catalog?.sourceTimestamp),
        catalog: widget.catalog,
        showAdult: _showAdult,
        database: widget.database,
        sharingEnabled: _reviewSharingEnabled,
        onReviewSaved: () {
          if (_reviewSharingEnabled) unawaited(_syncReviews());
        },
      ),
      AppSection.board => BoardPage(
        games: visibleGames,
        onStatusChanged: _changeStatus,
      ),
      AppSection.records =>
        widget.database == null
            ? const EmptySection(
                icon: Icons.edit_note,
                title: 'ウィッシュリスト',
                message: 'データベース接続時に利用できます。',
              )
            : OrganizerPage(
                db: widget.database!,
                games: visibleGames,
                onOpen: _openGame,
              ),
      AppSection.rankings => InsightsPage(
        games: visibleGames,
        db: widget.database,
        catalog: widget.catalog,
        showAdult: _showAdult,
        onOpen: _openGame,
        rankings: true,
        reviewApiEndpoint: widget.database == null
            ? ''
            : widget.reviewApiEndpoint,
        onReportComment: _reportComment,
      ),
      AppSection.statistics => InsightsPage(
        games: visibleGames,
        db: widget.database,
        onOpen: _openGame,
      ),
      AppSection.settings => SettingsPage(
        onOpenCatalog: () => setState(() => _section = AppSection.catalog),
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        blurCovers: widget.blurCovers,
        onBlurCoversChanged: widget.onBlurCoversChanged,
        reviewSharingAvailable:
            widget.database != null && widget.reviewApiEndpoint.isNotEmpty,
        reviewSharingEnabled: _reviewSharingEnabled,
        reviewSyncing: _reviewSyncing,
        reviewSyncStatus: _reviewSyncStatus,
        onReviewSharingChanged: _setReviewSharing,
        onReviewSyncRequested: _syncReviews,
        onEraseSharedReviews: _eraseSharedReviews,
        closeToTray: _closeToTray,
        onCloseToTrayChanged: widget.enableDesktopIntegration
            ? (value) async {
                await widget.database?.writeSetting(
                  'window.closeToTray',
                  value.toString(),
                );
                await _trayService?.setEnabled(value);
                if (mounted) setState(() => _closeToTray = value);
              }
            : null,
        showAdult: _showAdult,
        onShowAdultChanged: _setShowAdult,
        catalog: widget.catalog,
        isUpdatingCatalog: _isUpdatingCatalog,
        onUpdateCatalog: widget.catalog == null ? null : _updateCatalog,
        onRestoreCatalog: _restoreCatalog,
        onGuide: _showWelcome,
        onInformation: () => showDialog<void>(
          context: context,
          builder: (_) => AppInformationDialog(catalog: widget.catalog),
        ),
        scanFolders: _scanFolders,
        isScanning: _isScanning,
        isManagingFolders: _isRemovingFolder || _isRegistering,
        scanMessage: _scanMessage,
        onAddFolder: _scanFolder,
        onRescanFolder: (path) => _scanFolder(existingPath: path),
        onRemoveFolder: _removeScanFolder,
        onDiagnostics: _showDiagnostics,
        onDataTransfer: widget.database == null || _runningGameIds.isNotEmpty
            ? null
            : () async {
                if (_isScanning || _isRegistering || _isRemovingFolder) return;
                await showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => TransferDialog(
                    db: widget.database!,
                    games: List.of(_games),
                    onRestored: () async {
                      await _refreshScanFolders();
                      _diagnostics = {};
                      await _loadDiagnostics();
                    },
                  ),
                );
              },
        onManualRegister: widget.database == null || _runningGameIds.isNotEmpty
            ? null
            : () => _manualRegister(),
        onManageImages: () => showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ImageManagementDialog(games: List.of(_games)),
        ),
      ),
    };
  }

  Widget _buildDetailPage() {
    final index = _games.indexWhere((game) => game.id == _selectedGameId);
    if (index == -1) {
      return LibraryPage(
        games: _games,
        onStatusChanged: _changeStatus,
        onDeleteRequested: _deleteGame,
        onDeleteManyRequested: _deleteGames,
        onGameOpened: _openGame,
        onScanRequested: widget.database == null ? null : _scanFolder,
        isScanning: _isScanning,
      );
    }
    final selectedGame = _games[index];
    final installs = groupLibraryGames(_games)
        .firstWhere(
          (entry) => entry.members.any((game) => game.id == selectedGame.id),
        )
        .members;
    return GameDetailPage(
      game: selectedGame,
      blurCovers: widget.blurCovers,
      onRecordsRequested: widget.database == null
          ? null
          : () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => WorkRecordsDialog(
                db: widget.database!,
                game: selectedGame,
                historyBlocked: _runningGameIds.contains(selectedGame.id),
              ),
            ),
      deletionBlocked: _isScanning,
      onDeleteRequested: (id) async {
        if (_isScanning || _runningGameIds.contains(id)) {
          throw StateError('ゲーム起動中・スキャン中は削除できません');
        }
        await _deleteGame(id);
      },
      installations: installs,
      onInstallationSelected: _openGame,
      onCatalogMatchRequested: widget.catalog == null || widget.database == null
          ? null
          : () {
              final game = selectedGame;
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => CatalogMatchDialog(
                  game: game,
                  catalog: widget.catalog!,
                  onSave: (work) => widget.database!.selectCatalogWork(
                    int.parse(game.id),
                    work.vndbId,
                    work.titleJa,
                  ),
                ),
              );
            },
      onBack: () => setState(() => _section = AppSection.library),
      onStatusChanged: _changeStatus,
      onRatingChanged: _changeRating,
      onReviewChanged: _changeReview,
      onMetadataChanged: (edits) async {
        final game = selectedGame;
        final database = widget.database;
        if (database != null) {
          await database.saveMetadataOverrides(
            int.parse(game.id),
            edits.encode(),
          );
        } else {
          final currentIndex = _games.indexWhere(
            (entry) => entry.id == game.id,
          );
          if (mounted && currentIndex != -1) {
            setState(
              () => _games[currentIndex] = _games[currentIndex].copyWith(
                edits: edits,
              ),
            );
          }
        }
      },
      onCoverBlurChanged: (blur) async {
        final game = selectedGame;
        final database = widget.database;
        if (database != null) {
          final id = int.parse(game.id);
          final records = await database.getGames();
          final record = records.firstWhere((entry) => entry.id == id);
          final current = GameEdits.decode(record.metadataOverrides);
          await database.saveMetadataOverrides(
            id,
            GameEdits(
              title: current.title,
              brand: current.brand,
              released: current.released,
              imagePath: current.imagePath,
              blurCover: blur,
            ).encode(),
          );
        } else {
          final currentIndex = _games.indexWhere(
            (entry) => entry.id == game.id,
          );
          if (mounted && currentIndex != -1) {
            setState(() {
              _games[currentIndex] = _games[currentIndex].copyWith(
                edits: GameEdits(
                  title: game.title,
                  brand: game.brand,
                  released: game.released,
                  imagePath: game.localCoverPath,
                  blurCover: blur,
                ),
              );
            });
          }
        }
      },
      onLaunchRequested: _launchGame,
      isRunning: _runningGameIds.contains(_games[index].id),
    );
  }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selected,
    required this.games,
    required this.onSelected,
    required this.onHome,
    this.compact = false,
  });

  final AppSection selected;
  final List<GameEntry> games;
  final ValueChanged<AppSection> onSelected;
  final VoidCallback onHome;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final playing = games
        .where((game) => game.status == GameStatus.playing)
        .length;
    return Container(
      key: const Key('app-sidebar'),
      width: compact ? 76 : 250,
      decoration: BoxDecoration(
        color: context.appColors.sidebar,
        border: Border(right: BorderSide(color: context.appColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Tooltip(
              message: 'ホーム（ライブラリ）へ戻る',
              child: InkWell(
                onTap: onHome,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 20 : 22,
                    20,
                    compact ? 20 : 18,
                    compact ? 18 : 26,
                  ),
                  child: Row(
                    children: [
                      const BrandMark(),
                      if (!compact) ...[
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NoveLib',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (!compact) const SidebarLabel('LIBRARY'),
            SidebarItem(
              compact: compact,
              icon: Icons.grid_view_rounded,
              title: 'ライブラリ',
              count: '${groupLibraryGames(games).length}',
              selected: selected == AppSection.library,
              onTap: () => onSelected(AppSection.library),
            ),
            SidebarItem(
              compact: compact,
              icon: Icons.view_kanban_rounded,
              title: 'プレイ状況',
              count: '$playing',
              selected: selected == AppSection.board,
              onTap: () => onSelected(AppSection.board),
            ),
            SizedBox(height: compact ? 8 : 20),
            if (!compact) const SidebarLabel('DISCOVER'),
            SidebarItem(
              compact: compact,
              icon: Icons.leaderboard_rounded,
              title: '評価ランキング',
              selected: selected == AppSection.rankings,
              onTap: () => onSelected(AppSection.rankings),
            ),
            SidebarItem(
              compact: compact,
              icon: Icons.insights_rounded,
              title: '統計',
              selected: selected == AppSection.statistics,
              onTap: () => onSelected(AppSection.statistics),
            ),
            SizedBox(height: compact ? 8 : 20),
            if (!compact) const SidebarLabel('MY LISTS'),
            SidebarItem(
              compact: compact,
              icon: Icons.edit_note,
              title: 'ウィッシュリスト',
              selected: selected == AppSection.records,
              onTap: () => onSelected(AppSection.records),
            ),
            if (!compact)
              Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 14, 4),
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final tag
                        in games.expand((g) => g.tags).toSet().take(8))
                      TagChip(tag),
                  ],
                ),
              ),
            const Spacer(),
            SidebarItem(
              compact: compact,
              icon: Icons.tune_rounded,
              title: '設定',
              selected: selected == AppSection.settings,
              onTap: () => onSelected(AppSection.settings),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/branding/novelib_icon.png',
          width: 34,
          height: 34,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: AppColors.accent,
            child: Icon(
              Icons.auto_stories_rounded,
              color: context.appColors.canvas,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarLabel extends StatelessWidget {
  const SidebarLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          color: context.appColors.textFaint,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  const SidebarItem({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.count,
    this.compact = false,
  });
  final IconData icon;
  final String title;
  final String? count;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final item = Semantics(
      button: true,
      selected: selected,
      label: count == null ? title : '$title、$count件',
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: 2,
        ),
        child: Material(
          color: selected ? context.appColors.selected : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            focusColor: AppColors.accent.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 46,
              padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
              decoration: selected
                  ? const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.accent, width: 3),
                      ),
                    )
                  : null,
              child: Row(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? AppColors.accent
                        : context.appColors.textMuted,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (count != null)
                      Text(
                        count!,
                        style: TextStyle(
                          color: context.appColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return compact ? Tooltip(message: title, child: item) : item;
  }
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.appColors.chip,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(color: context.appColors.textMuted, fontSize: 11),
      ),
    );
  }
}

class EmptySection extends StatelessWidget {
  const EmptySection({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appColors.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.accent),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appColors.textMuted,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
