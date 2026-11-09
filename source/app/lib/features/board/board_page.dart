import 'package:flutter/material.dart';

import '../../models/game.dart';
import '../../theme/app_theme.dart';
import '../library/library_page.dart';

class BoardPage extends StatelessWidget {
  const BoardPage({
    super.key,
    required this.games,
    required this.onStatusChanged,
  });

  final List<GameEntry> games;
  final void Function(String gameId, GameStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(30, 26, 30, 22),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.appColors.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'プレイ状況を整理',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  '作品を「未プレイ・プレイ中・クリア・コンプ」へドラッグして、状態をすばやく変更できます。',
                  style: TextStyle(
                    color: context.appColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 800;
                final columnWidth = compact
                    ? (constraints.maxWidth - 24).clamp(220.0, 280.0).toDouble()
                    : 280.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.all(compact ? 12 : 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final status in GameStatus.values) ...[
                        BoardColumn(
                          width: columnWidth,
                          status: status,
                          games: games
                              .where((game) => game.status == status)
                              .toList(),
                          onStatusChanged: onStatusChanged,
                        ),
                        if (status != GameStatus.values.last)
                          SizedBox(width: compact ? 10 : 16),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BoardColumn extends StatelessWidget {
  const BoardColumn({
    super.key,
    required this.status,
    required this.games,
    required this.onStatusChanged,
    this.width = 280,
  });
  final GameStatus status;
  final List<GameEntry> games;
  final void Function(String, GameStatus) onStatusChanged;
  final double width;

  Color get accent => switch (status) {
    GameStatus.notPlayed => const Color(0xFFE9AFC7),
    GameStatus.playing => AppColors.accentWarm,
    GameStatus.cleared => AppColors.accent,
    GameStatus.completed => AppColors.accentBlue,
  };

  @override
  Widget build(BuildContext context) {
    return DragTarget<GameEntry>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) =>
          onStatusChanged(details.data.id, status),
      builder: (context, candidates, rejected) {
        final active = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: .08)
                : context.appColors.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? accent : context.appColors.border,
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        status.label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.appColors.chip,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${games.length}',
                        style: TextStyle(
                          color: context.appColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: games.isEmpty
                    ? Center(
                        child: Text(
                          active ? 'ここに移動' : '作品はありません',
                          style: TextStyle(
                            color: active
                                ? accent
                                : context.appColors.textFaint,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: games.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final game = games[index];
                          return Draggable<GameEntry>(
                            data: game,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 256,
                                child: BoardGameCard(
                                  game: game,
                                  dragging: true,
                                  onStatusChanged: onStatusChanged,
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: .28,
                              child: BoardGameCard(
                                game: game,
                                onStatusChanged: onStatusChanged,
                              ),
                            ),
                            child: BoardGameCard(
                              game: game,
                              onStatusChanged: onStatusChanged,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BoardGameCard extends StatelessWidget {
  const BoardGameCard({
    super.key,
    required this.game,
    required this.onStatusChanged,
    this.dragging = false,
  });
  final GameEntry game;
  final void Function(String, GameStatus) onStatusChanged;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appColors.panelLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: dragging ? AppColors.accent : context.appColors.border,
        ),
        boxShadow: dragging
            ? const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 66,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: game.coverColors,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 18,
              color: Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  game.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${game.playHours.toStringAsFixed(1)}h · ${game.routeCurrent}/${game.routeTotal} ルート',
                  style: TextStyle(
                    color: context.appColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                if (game.rating != null) ...[
                  const SizedBox(height: 5),
                  RatingBadge(value: game.rating!),
                ],
              ],
            ),
          ),
          PopupMenuButton<GameStatus>(
            tooltip: '状態を変更',
            enabled: !dragging,
            onSelected: (status) => onStatusChanged(game.id, status),
            itemBuilder: (context) => [
              for (final status in GameStatus.values)
                PopupMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: status == game.status
                            ? const Icon(Icons.check_rounded, size: 17)
                            : null,
                      ),
                      Text(status.label),
                    ],
                  ),
                ),
            ],
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.appColors.textFaint,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
