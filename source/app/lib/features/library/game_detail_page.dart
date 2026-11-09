import 'dart:io';

import 'package:flutter/material.dart';

import 'game_edit_dialog.dart';
import 'delete_registration_dialog.dart';

import '../../models/game.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_image.dart';

class GameDetailPage extends StatelessWidget {
  const GameDetailPage({
    super.key,
    required this.game,
    required this.onBack,
    required this.onStatusChanged,
    required this.onRatingChanged,
    required this.onLaunchRequested,
    required this.isRunning,
    required this.onMetadataChanged,
    this.blurCovers = false,
    this.onCoverBlurChanged,
    this.onCatalogMatchRequested,
    this.onReviewChanged,
    this.onRecordsRequested,
    this.installations = const [],
    this.onInstallationSelected,
    this.onDeleteRequested,
    this.deletionBlocked = false,
  });

  final GameEntry game;
  final VoidCallback onBack;
  final void Function(String, GameStatus) onStatusChanged;
  final void Function(String, int?) onRatingChanged;
  final Future<void> Function(String, int?, String?)? onReviewChanged;
  final ValueChanged<String> onLaunchRequested;
  final bool isRunning;
  final Future<void> Function(GameEdits) onMetadataChanged;
  final bool blurCovers;
  final Future<void> Function(bool)? onCoverBlurChanged;
  final VoidCallback? onCatalogMatchRequested;
  final VoidCallback? onRecordsRequested;
  final List<GameEntry> installations;
  final ValueChanged<String>? onInstallationSelected;
  final Future<void> Function(String)? onDeleteRequested;
  final bool deletionBlocked;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appColors.canvas,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 82),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.appColors.border),
              ),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                IconButton(
                  tooltip: 'ライブラリへ戻る',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: onRecordsRequested,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('作品記録'),
                ),
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        GameEditDialog(game: game, onSave: onMetadataChanged),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('情報を編集'),
                ),
                const Text(
                  '作品詳細',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: onCatalogMatchRequested,
                  icon: const Icon(Icons.find_replace),
                  label: const Text('カタログを選び直す'),
                ),
                if (onDeleteRequested != null)
                  IconButton(
                    tooltip: isRunning || deletionBlocked
                        ? 'ゲーム起動中・スキャン中は削除できません'
                        : 'この登録先を削除',
                    onPressed: isRunning || deletionBlocked
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => DeleteRegistrationDialog(
                              game: game,
                              onDelete: onDeleteRequested!,
                            ),
                          ),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: isRunning || deletionBlocked
                          ? context.appColors.textMuted
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(34),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: _DetailLayout(
                    cover: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DetailCover(game: game),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: 300,
                          child: OutlinedButton.icon(
                            key: const Key('detail-cover-blur-toggle'),
                            onPressed: onCoverBlurChanged == null
                                ? null
                                : () => onCoverBlurChanged!(
                                    !(game.coverBlurOverride ?? blurCovers),
                                  ),
                            icon: Icon(
                              (game.coverBlurOverride ?? blurCovers)
                                  ? Icons.visibility_outlined
                                  : Icons.blur_on_rounded,
                            ),
                            label: Text(
                              (game.coverBlurOverride ?? blurCovers)
                                  ? 'ぼかしを解除'
                                  : '表紙をぼかす',
                            ),
                          ),
                        ),
                      ],
                    ),
                    details: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (installations.length > 1) ...[
                          Text(
                            '登録先 ${installations.length} 件 · 合計 ${installations.fold<double>(0, (sum, entry) => sum + entry.playHours).toStringAsFixed(1)} 時間',
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: game.id,
                            items: installations
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.id,
                                    child: Text(
                                      '${entry.installDir ?? entry.id} · ${entry.status.label}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (id) {
                              if (id != null) {
                                onInstallationSelected?.call(id);
                              }
                            },
                          ),
                          const Text(
                            '以下の起動・評価・状態・情報編集・カタログ変更は、選択中の登録先だけに適用します。',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          game.title,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        if (game.titleRomaji != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            game.titleRomaji!,
                            style: TextStyle(
                              color: context.appColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: game.exePath == null || isRunning
                              ? null
                              : () => onLaunchRequested(game.id),
                          icon: isRunning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow_rounded),
                          label: Text(isRunning ? 'プレイ中・終了待ち' : 'ゲームを起動'),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final status in GameStatus.values)
                              ChoiceChip(
                                label: Text(status.label),
                                selected: game.status == status,
                                onSelected: (_) =>
                                    onStatusChanged(game.id, status),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _RatingSelector(
                          value: game.rating,
                          onChanged: (rating) =>
                              onRatingChanged(game.id, rating),
                        ),
                        const SizedBox(height: 14),
                        _ReviewCommentEditor(
                          initialComment: game.ratingComment,
                          onSave: onReviewChanged == null
                              ? null
                              : (comment) => onReviewChanged!(
                                  game.id,
                                  game.rating,
                                  comment,
                                ),
                        ),
                        const SizedBox(height: 28),
                        _InfoPanel(game: game),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCommentEditor extends StatefulWidget {
  const _ReviewCommentEditor({
    required this.initialComment,
    required this.onSave,
  });

  final String? initialComment;
  final Future<void> Function(String)? onSave;

  @override
  State<_ReviewCommentEditor> createState() => _ReviewCommentEditorState();
}

class _ReviewCommentEditorState extends State<_ReviewCommentEditor> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialComment ?? '',
  );
  bool saving = false;

  @override
  void didUpdateWidget(_ReviewCommentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!saving && oldWidget.initialComment != widget.initialComment) {
      controller.text = widget.initialComment ?? '';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final callback = widget.onSave;
    if (callback == null) return;
    setState(() => saving = true);
    try {
      await callback(controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('評価コメントを保存しました。')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            enabled: !saving && widget.onSave != null,
            minLines: 3,
            maxLines: 7,
            maxLength: 4000,
            decoration: const InputDecoration(
              labelText: '評価コメント',
              hintText: '良かった点や感想を記録できます',
              alignLabelWithHint: true,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: saving || widget.onSave == null ? null : save,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('コメントを保存'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLayout extends StatelessWidget {
  const _DetailLayout({required this.cover, required this.details});
  final Widget cover;
  final Widget details;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: cover),
            const SizedBox(height: 24),
            details,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cover,
          const SizedBox(width: 38),
          Expanded(child: details),
        ],
      );
    },
  );
}

class _RatingSelector extends StatelessWidget {
  const _RatingSelector({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              '自分の評価',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 10),
            Text(
              value == null ? '未評価' : '$value / 10',
              style: const TextStyle(
                color: AppColors.accentWarm,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 10),
              TextButton(
                onPressed: () => onChanged(null),
                child: const Text('評価を解除'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (var rating = 1; rating <= 10; rating++)
              ChoiceChip(
                label: Text('$rating'),
                selected: value == rating,
                onSelected: (_) => onChanged(rating),
              ),
          ],
        ),
      ],
    );
  }
}

class _DetailCover extends StatelessWidget {
  const _DetailCover({required this.game});

  final GameEntry game;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 420,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: game.coverColors,
        ),
        border: Border.all(color: context.appColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: game.localCoverPath != null
          ? CoverPrivacyFilter(
              blurOverride: game.coverBlurOverride,
              child: Image.file(
                File(game.localCoverPath!),
                fit: BoxFit.contain,
                errorBuilder: (_, error, stack) =>
                    Center(child: Text(game.title)),
              ),
            )
          : game.vndbId != null && game.coverImageUrl != null
          ? CachedCoverImage(
              vndbId: game.vndbId!,
              imageUrl: game.coverImageUrl!,
              fit: BoxFit.contain,
              blurOverride: game.coverBlurOverride,
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  game.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.game});

  final GameEntry game;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.appColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        children: [
          _InfoRow(label: 'ブランド／開発元', value: game.developers ?? game.brand),
          _InfoRow(label: '発売日', value: game.released ?? '未登録'),
          _InfoRow(
            label: 'カタログ評価',
            value: game.catalogRating == null
                ? '未評価'
                : '${game.catalogRating!.toStringAsFixed(1)} / 10.0（${game.catalogVoteCount}票）',
          ),
          _InfoRow(
            label: '自分の評価',
            value: game.rating == null ? '未評価' : '${game.rating} / 10',
          ),
          if (game.ratingComment?.isNotEmpty == true)
            _InfoRow(label: '評価コメント', value: game.ratingComment!),
          _InfoRow(
            label: 'プレイ時間',
            value: '${game.playHours.toStringAsFixed(1)} 時間',
          ),
          _InfoRow(label: 'VNDB ID', value: game.vndbId ?? '未照合'),
          _InfoRow(
            label: '表紙ぼかし',
            value: switch (game.coverBlurOverride) {
              true => 'この作品だけぼかす',
              false => 'この作品だけぼかさない',
              null => '全体設定に従う',
            },
          ),
          _InfoRow(label: 'ゲームエンジン', value: game.engine ?? game.brand),
          _InfoRow(label: '保存場所', value: game.installDir ?? '未登録'),
          _InfoRow(label: '実行ファイル', value: game.exePath ?? '未登録', last: true),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.appColors.border),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: context.appColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
