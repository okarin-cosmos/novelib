import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/fanza_link.dart';

import '../../catalog/catalog_database.dart';
import '../../database/app_database.dart';
import '../../models/game.dart';
import '../../services/review_sync_service.dart';
import '../../theme/app_theme.dart';
import 'record_store.dart';

typedef PublicRankingsLoader = Future<List<PublicRatingSummary>> Function(
  bool includeAdult,
  int limit,
  int offset,
);
typedef PublicCommentsLoader = Future<List<PublicReviewComment>> Function(
  String workId,
  bool includeAdult,
  int limit,
  int offset,
);
typedef PublicCommentReporter = Future<void> Function(
  String reviewId,
  String reason,
  String details,
);

class InsightsPage extends StatelessWidget {
  const InsightsPage({
    super.key,
    required this.games,
    this.db,
    this.catalog,
    this.showAdult = true,
    required this.onOpen,
    this.rankings = false,
    this.reviewApiEndpoint = '',
    this.publicRankingsLoader,
    this.publicCommentsLoader,
    this.onReportComment,
  });

  final List<GameEntry> games;
  final AppDatabase? db;
  final CatalogDatabase? catalog;
  final bool showAdult;
  final ValueChanged<String> onOpen;
  final bool rankings;
  final String reviewApiEndpoint;
  final PublicRankingsLoader? publicRankingsLoader;
  final PublicCommentsLoader? publicCommentsLoader;
  final PublicCommentReporter? onReportComment;

  @override
  Widget build(BuildContext context) => rankings
      ? _CommunityRanking(
          games: games,
          catalog: catalog,
          showAdult: showAdult,
          onOpen: onOpen,
          reviewApiEndpoint: reviewApiEndpoint,
          loader: publicRankingsLoader,
          commentsLoader: publicCommentsLoader,
          onReportComment: onReportComment,
        )
      : _StatisticsDashboard(games: games, db: db);
}

class _CommunityRanking extends StatefulWidget {
  const _CommunityRanking({
    required this.games,
    required this.catalog,
    required this.showAdult,
    required this.onOpen,
    required this.reviewApiEndpoint,
    this.loader,
    this.commentsLoader,
    this.onReportComment,
  });

  final List<GameEntry> games;
  final CatalogDatabase? catalog;
  final bool showAdult;
  final ValueChanged<String> onOpen;
  final String reviewApiEndpoint;
  final PublicRankingsLoader? loader;
  final PublicCommentsLoader? commentsLoader;
  final PublicCommentReporter? onReportComment;

  @override
  State<_CommunityRanking> createState() => _CommunityRankingState();
}

class _CommunityRankingState extends State<_CommunityRanking> {
  Future<List<PublicRatingSummary>>? _rankingFuture;
  final List<PublicRatingSummary> _extraRankings = [];
  bool _loadingMore = false;
  bool _hasMore = true;
  PublicRatingSummary? _selected;

  bool get _usesNoveLib =>
      widget.loader != null || widget.reviewApiEndpoint.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_usesNoveLib) _rankingFuture = _load();
  }

  @override
  void didUpdateWidget(covariant _CommunityRanking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showAdult != widget.showAdult ||
        oldWidget.reviewApiEndpoint != widget.reviewApiEndpoint ||
        oldWidget.loader != widget.loader) {
      _rankingFuture = _usesNoveLib ? _load() : null;
      _extraRankings.clear();
      _hasMore = true;
      _selected = null;
    }
  }

  Future<List<PublicRatingSummary>> _load({int offset = 0}) {
    final loader = widget.loader;
    if (loader != null) return loader(widget.showAdult, 20, offset);
    return PublicReviewClient(endpoint: Uri.parse(widget.reviewApiEndpoint))
        .rankings(
          includeAdult: widget.showAdult,
          minimumRatings: 1,
          limit: 20,
          offset: offset,
        );
  }

  void _reload() => setState(() {
    _rankingFuture = _load();
    _extraRankings.clear();
    _hasMore = true;
    _selected = null;
  });

  Future<void> _loadMore(int currentCount) async {
    if (_loadingMore || !_hasMore || currentCount >= 100) return;
    setState(() => _loadingMore = true);
    try {
      final next = await _load(offset: currentCount);
      if (!mounted) return;
      setState(() {
        _extraRankings.addAll(next.take(100 - currentCount));
        _hasMore = next.length == 20 && currentCount + next.length < 100;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_usesNoveLib) return _buildNoveLib(context);
    final works =
        widget.catalog?.topRated(
          limit: 100,
          minimumVotes: 100,
          showAdult: widget.showAdult,
        ) ??
        const <CatalogWork>[];
    final installed = {
      for (final game in widget.games)
        if (game.vndbId != null) game.vndbId!: game,
    };
    final compact = MediaQuery.sizeOf(context).width < 700;
    return ListView(
      padding: EdgeInsets.all(compact ? 16 : 28),
      children: [
        Text('評価ランキング', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 7),
        Text(
          '現在はVNDB利用者の公開投票を表示しています。NoveLibの投稿評価はPostgreSQL同期の公開後に統合します。',
          style: TextStyle(color: context.appColors.textMuted),
        ),
        const SizedBox(height: 18),
        if (works.isEmpty)
          _InsightPanel(
            title: 'ランキングを表示できません',
            child: const Text('作品カタログを接続すると、公開評価ランキングを確認できます。'),
          )
        else
          _InsightPanel(
            title: '総合ランキング TOP ${works.length}',
            subtitle: '100票以上の作品を対象。評価が同じ場合は投票数順です。',
            child: Column(
              children: [
                for (var index = 0; index < works.length; index++)
                  _CommunityTile(
                    rank: index + 1,
                    work: works[index],
                    installed: installed[works[index].vndbId],
                    onOpen: widget.onOpen,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNoveLib(BuildContext context) {
    final selected = _selected;
    if (selected != null) {
      return _PublicCommentsPage(
        summary: selected,
        showAdult: widget.showAdult,
        reviewApiEndpoint: widget.reviewApiEndpoint,
        loader: widget.commentsLoader,
        onReportComment: widget.onReportComment,
        onBack: () => setState(() => _selected = null),
      );
    }
    final installed = {
      for (final game in widget.games)
        if (game.vndbId != null) game.vndbId!: game,
    };
    final compact = MediaQuery.sizeOf(context).width < 700;
    return ListView(
      padding: EdgeInsets.all(compact ? 16 : 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '評価ランキング',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              onPressed: _reload,
              tooltip: 'ランキングを更新',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'NoveLib利用者が共有した評価を集計しています。匿名評価が1件以上ある作品が対象です。',
          style: TextStyle(color: context.appColors.textMuted),
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<PublicRatingSummary>>(
          future: _rankingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _InsightPanel(
                title: 'ランキングを読み込み中',
                child: LinearProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return _InsightPanel(
                title: 'ランキングを取得できません',
                subtitle: '通信状態を確認して、もう一度お試しください。',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('再試行'),
                  ),
                ),
              );
            }
            final rankings = [
              ...(snapshot.data ?? const <PublicRatingSummary>[]),
              ..._extraRankings,
            ];
            if (rankings.isEmpty) {
              return const _InsightPanel(
                title: 'まだ共有評価がありません',
                child: Text('評価共有が増えると、ここにランキングが表示されます。'),
              );
            }
            final catalogWorks =
                widget.catalog?.findByIds(
                  rankings.map((item) => item.workId),
                ) ??
                const <String, CatalogWork>{};
            return _InsightPanel(
              title: 'NoveLib総合ランキング ${rankings.length}位まで',
              subtitle: '20件ずつ読み込み、最大100位まで表示します。平均点が同じ場合は評価件数順です。',
              child: Column(
                children: [
                  for (var index = 0; index < rankings.length; index++)
                    _NoveLibRankingTile(
                      rank: index + 1,
                      summary: rankings[index],
                      showFanza: widget.showAdult,
                      catalogWork: catalogWorks[rankings[index].workId],
                      installed: installed[rankings[index].workId],
                      onOpen: () => setState(() => _selected = rankings[index]),
                    ),
                  if ((snapshot.data?.length ?? 0) == 20 &&
                      _hasMore &&
                      rankings.length < 100)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: _loadingMore
                            ? null
                            : () => _loadMore(rankings.length),
                        icon: _loadingMore
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more_rounded),
                        label: Text(_loadingMore ? '読み込み中' : 'さらに20件表示'),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NoveLibRankingTile extends StatelessWidget {
  const _NoveLibRankingTile({
    required this.rank,
    required this.summary,
    required this.catalogWork,
    required this.showFanza,
    required this.installed,
    required this.onOpen,
  });

  final int rank;
  final PublicRatingSummary summary;
  final CatalogWork? catalogWork;
  final bool showFanza;
  final GameEntry? installed;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.appColors.border)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final title = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  catalogWork?.developers ?? summary.workId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (showFanza && parseFanzaLink(summary.fanzaUrl) != null)
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('PR｜FANZAで見る'),
                    onPressed: () async {
                      try {
                        final opened = await launchUrl(
                          parseFanzaLink(summary.fanzaUrl)!,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!opened) throw StateError('open failed');
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('リンクを開けませんでした。')),
                          );
                        }
                      }
                    },
                  ),
              ],
            );
            final score = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  summary.averageScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.accentWarm,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${summary.ratingCount}件・コメント${summary.publicCommentCount}件',
                  style: TextStyle(
                    color: context.appColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            );
            final rankLabel = SizedBox(
              width: 52,
              child: Text(
                '$rank位',
                style: TextStyle(
                  color: rank <= 3
                      ? AppColors.accentWarm
                      : context.appColors.textMuted,
                  fontSize: rank <= 3 ? 17 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      rankLabel,
                      Expanded(child: title),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (installed != null) ...[
                        const Chip(label: Text('登録済み')),
                        const SizedBox(width: 10),
                      ],
                      score,
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                rankLabel,
                Expanded(child: title),
                if (installed != null)
                  const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Chip(label: Text('ライブラリに登録済み')),
                  ),
                score,
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _PublicCommentsPage extends StatefulWidget {
  const _PublicCommentsPage({
    required this.summary,
    required this.showAdult,
    required this.reviewApiEndpoint,
    required this.onBack,
    this.loader,
    this.onReportComment,
  });

  final PublicRatingSummary summary;
  final bool showAdult;
  final String reviewApiEndpoint;
  final VoidCallback onBack;
  final PublicCommentsLoader? loader;
  final PublicCommentReporter? onReportComment;

  @override
  State<_PublicCommentsPage> createState() => _PublicCommentsPageState();
}

class _PublicCommentsPageState extends State<_PublicCommentsPage> {
  late Future<List<PublicReviewComment>> _first;
  final List<PublicReviewComment> _extra = [];
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _first = _load(0);
  }

  Future<List<PublicReviewComment>> _load(int offset) {
    final loader = widget.loader;
    if (loader != null) {
      return loader(widget.summary.workId, widget.showAdult, 20, offset);
    }
    return PublicReviewClient(endpoint: Uri.parse(widget.reviewApiEndpoint))
        .comments(
          workId: widget.summary.workId,
          includeAdult: widget.showAdult,
          limit: 20,
          offset: offset,
        );
  }

  Future<void> _loadMore(int currentCount) async {
    if (_loadingMore || !_hasMore || currentCount >= 50) return;
    setState(() => _loadingMore = true);
    try {
      final next = await _load(currentCount);
      if (!mounted) return;
      setState(() {
        _extra.addAll(next.take(50 - currentCount));
        _hasMore = next.length == 20 && currentCount + next.length < 50;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return ListView(
      padding: EdgeInsets.all(compact ? 16 : 28),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              tooltip: 'ランキングへ戻る',
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.summary.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '最新の公開コメント（最大50件）',
                    style: TextStyle(color: context.appColors.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              widget.summary.averageScore.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.accentWarm,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<PublicReviewComment>>(
          future: _first,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return _InsightPanel(
                title: 'コメントを取得できません',
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _first = _load(0)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('再試行'),
                ),
              );
            }
            final comments = [
              ...(snapshot.data ?? const <PublicReviewComment>[]),
              ..._extra,
            ];
            if (comments.isEmpty) {
              return const _InsightPanel(
                title: '公開コメントはまだありません',
                child: Text('点数のみの評価はランキング集計に含まれます。'),
              );
            }
            return _InsightPanel(
              title: '最新コメント ${comments.length}件',
              subtitle: '匿名で共有されたコメントです。不適切な内容は旗ボタンから通報できます。',
              child: Column(
                children: [
                  for (final item in comments)
                    _PublicCommentTile(
                      comment: item,
                      onReport: widget.onReportComment == null
                          ? null
                          : () => _report(context, item),
                    ),
                  if ((snapshot.data?.length ?? 0) == 20 &&
                      _hasMore &&
                      comments.length < 50)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: _loadingMore
                            ? null
                            : () => _loadMore(comments.length),
                        icon: const Icon(Icons.expand_more_rounded),
                        label: const Text('さらに20件表示'),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _report(
    BuildContext context,
    PublicReviewComment comment,
  ) async {
    var reason = 'spam';
    final details = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('コメントを通報'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: const InputDecoration(labelText: '理由'),
                  items: const [
                    DropdownMenuItem(value: 'spam', child: Text('スパム・無関係')),
                    DropdownMenuItem(
                      value: 'harassment',
                      child: Text('嫌がらせ・攻撃的表現'),
                    ),
                    DropdownMenuItem(value: 'spoiler', child: Text('重大なネタバレ')),
                    DropdownMenuItem(value: 'illegal', child: Text('違法・危険な内容')),
                    DropdownMenuItem(value: 'other', child: Text('その他')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => reason = value ?? reason),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: details,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '補足（任意）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('通報する'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) {
      details.dispose();
      return;
    }
    try {
      await widget.onReportComment!(comment.reviewId, reason, details.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('通報を受け付けました。')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通報できませんでした。時間をおいて再試行してください。')),
        );
      }
    } finally {
      details.dispose();
    }
  }
}

class _PublicCommentTile extends StatelessWidget {
  const _PublicCommentTile({required this.comment, this.onReport});
  final PublicReviewComment comment;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final date = comment.updatedAt;
    final dateText =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.appColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (comment.score != null)
                Text(
                  '${comment.score}/10',
                  style: const TextStyle(
                    color: AppColors.accentWarm,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                const Text('コメントのみ'),
              const Spacer(),
              Text(
                dateText,
                style: TextStyle(
                  color: context.appColors.textMuted,
                  fontSize: 11,
                ),
              ),
              if (onReport != null)
                IconButton(
                  onPressed: onReport,
                  tooltip: 'このコメントを通報',
                  icon: const Icon(Icons.flag_outlined, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(comment.comment),
        ],
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({
    required this.rank,
    required this.work,
    required this.installed,
    required this.onOpen,
  });

  final int rank;
  final CatalogWork work;
  final GameEntry? installed;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: installed == null ? null : () => onOpen(installed!.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.appColors.border)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                '$rank位',
                style: TextStyle(
                  color: rank <= 3
                      ? AppColors.accentWarm
                      : context.appColors.textMuted,
                  fontSize: rank <= 3 ? 17 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    work.titleJa,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    work.developers ?? 'ブランド未登録',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (installed != null)
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: Chip(label: Text('ライブラリに登録済み')),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  work.rating?.toStringAsFixed(1) ?? '—',
                  style: const TextStyle(
                    color: AppColors.accentWarm,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${work.voteCount}票',
                  style: TextStyle(
                    color: context.appColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatisticsDashboard extends StatelessWidget {
  const _StatisticsDashboard({required this.games, required this.db});
  final List<GameEntry> games;
  final AppDatabase? db;

  @override
  Widget build(BuildContext context) {
    final rated = games.where((game) => game.rating != null).toList();
    final cleared = games
        .where(
          (game) =>
              game.status == GameStatus.cleared ||
              game.status == GameStatus.completed,
        )
        .length;
    final totalHours = games.fold<double>(
      0,
      (sum, game) => sum + game.playHours,
    );
    final brands = <String, List<GameEntry>>{};
    for (final game in games) {
      brands.putIfAbsent(game.brand, () => []).add(game);
    }
    final brandEntries = brands.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    final maxBrandCount = brandEntries.isEmpty
        ? 1
        : brandEntries.first.value.length;
    final maxStatusCount = games.isEmpty
        ? 1
        : GameStatus.values
              .map(
                (status) => games.where((game) => game.status == status).length,
              )
              .reduce((a, b) => a > b ? a : b);
    final compact = MediaQuery.sizeOf(context).width < 700;

    return ListView(
      padding: EdgeInsets.all(compact ? 16 : 28),
      children: [
        Text('統計ダッシュボード', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 7),
        Text(
          '遊んだ量・評価の傾向・好きなブランドを、グラフで振り返れます。',
          style: TextStyle(color: context.appColors.textMuted),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              icon: Icons.library_books_outlined,
              label: '登録作品',
              value: '${games.length} 本',
            ),
            _MetricCard(
              icon: Icons.task_alt_rounded,
              label: 'クリア済み',
              value: '$cleared 本',
            ),
            _MetricCard(
              icon: Icons.star_rounded,
              label: '平均評価',
              value:
                  '${RatingScale.formatAverage(rated.map((game) => game.rating!))}/10',
            ),
            _MetricCard(
              icon: Icons.schedule_rounded,
              label: '累計プレイ',
              value: '${totalHours.toStringAsFixed(1)} h',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _InsightPanel(
          title: 'プレイ状況',
          subtitle: '現在のライブラリを状態別に比較',
          child: Column(
            children: [
              for (final status in GameStatus.values)
                _BarRow(
                  label: status.label,
                  value: games.where((game) => game.status == status).length,
                  maximum: maxStatusCount,
                  color: _statusColor(status),
                  suffix: '本',
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _InsightPanel(
          title: '評価分布',
          subtitle: '10段階評価。未評価作品は除外しています。',
          child: Column(
            children: [
              for (var score = 10; score >= 1; score--)
                _BarRow(
                  label: '$score 点',
                  value: rated.where((game) => game.rating == score).length,
                  maximum: rated.isEmpty
                      ? 1
                      : [
                              for (var n = 1; n <= 10; n++)
                                rated.where((game) => game.rating == n).length,
                            ]
                            .reduce((a, b) => a > b ? a : b)
                            .clamp(1, rated.length),
                  color: AppColors.accentWarm,
                  suffix: '本',
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _InsightPanel(
          title: 'プレイ時間の推移',
          subtitle: 'プレイ履歴に保存されている時間を月別に表示',
          child: db == null
              ? const Text('データベース接続時に表示します。')
              : StreamBuilder<List<PlaySession>>(
                  stream: db!.select(db!.playSessions).watch(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('履歴の読み込みに失敗しました。');
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final monthly = periodSeconds(snapshot.data!);
                    final months = monthly.keys.toList()
                      ..sort((a, b) => b.compareTo(a));
                    final shown = months.take(12).toList().reversed.toList();
                    final maxSeconds = shown.isEmpty
                        ? 1
                        : shown
                              .map((month) => monthly[month]!)
                              .reduce((a, b) => a > b ? a : b);
                    if (shown.isEmpty) return const Text('プレイ履歴はまだありません。');
                    return Column(
                      children: [
                        for (final month in shown)
                          _BarRow(
                            label: month,
                            value: monthly[month]!,
                            maximum: maxSeconds,
                            color: AppColors.accentBlue,
                            displayValue:
                                '${(monthly[month]! / 3600).toStringAsFixed(1)} h',
                          ),
                      ],
                    );
                  },
                ),
        ),
        const SizedBox(height: 18),
        _InsightPanel(
          title: 'ブランド別',
          subtitle: '登録本数が多い順。評価とプレイ時間も合わせて表示',
          child: brandEntries.isEmpty
              ? const Text('作品を登録すると表示されます。')
              : Column(
                  children: [
                    for (final entry in brandEntries.take(20))
                      _BrandRow(
                        name: entry.key,
                        games: entry.value,
                        maximum: maxBrandCount,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

Color _statusColor(GameStatus status) => switch (status) {
  GameStatus.notPlayed => const Color(0xFFD989B6),
  GameStatus.playing => AppColors.accentWarm,
  GameStatus.cleared => AppColors.accent,
  GameStatus.completed => AppColors.accentBlue,
};

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 190,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appColors.panel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.appColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appColors.textMuted,
                  fontSize: 11,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({
    required this.title,
    required this.child,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: context.appColors.panel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.appColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: TextStyle(color: context.appColors.textMuted, fontSize: 11),
          ),
        ],
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.maximum,
    required this.color,
    this.suffix = '',
    this.displayValue,
  });
  final String label;
  final int value;
  final int maximum;
  final Color color;
  final String suffix;
  final String? displayValue;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(label, style: const TextStyle(fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 11,
              value: maximum <= 0 ? 0 : value / maximum,
              color: color,
              backgroundColor: context.appColors.canvas,
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(
            displayValue ?? '$value$suffix',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({
    required this.name,
    required this.games,
    required this.maximum,
  });
  final String name;
  final List<GameEntry> games;
  final int maximum;

  @override
  Widget build(BuildContext context) {
    final hours = games.fold<double>(0, (sum, game) => sum + game.playHours);
    final ratings = games.map((game) => game.rating).whereType<int>();
    final summary =
        '${games.length}本  ·  ${hours.toStringAsFixed(1)} h  ·  平均 ${RatingScale.formatAverage(ratings)}/10';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (constraints.maxWidth < 500) ...[
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(
                summary,
                style: TextStyle(
                  color: context.appColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    summary,
                    style: TextStyle(
                      color: context.appColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: games.length / maximum,
                color: AppColors.accent,
                backgroundColor: context.appColors.canvas,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
