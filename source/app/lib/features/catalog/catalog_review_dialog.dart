import 'package:flutter/material.dart';

import '../../catalog/catalog_database.dart';
import '../../database/app_database.dart';

class CatalogReviewDialog extends StatefulWidget {
  const CatalogReviewDialog({
    super.key,
    required this.database,
    required this.work,
    required this.sharingEnabled,
  });
  final AppDatabase database;
  final CatalogWork work;
  final bool sharingEnabled;
  @override
  State<CatalogReviewDialog> createState() => _CatalogReviewDialogState();
}

class _CatalogReviewDialogState extends State<CatalogReviewDialog> {
  final _comment = TextEditingController();
  int? _rating;
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final review = await widget.database.readWorkReview(widget.work.vndbId);
      if (!mounted) return;
      setState(() {
        _rating = review.rating;
        _comment.text = review.comment ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = '評価を読み込めませんでした。再試行してください。';
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving || _comment.text.trim().length > 4000) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.database.setCatalogReview(
        workId: widget.work.vndbId,
        title: widget.work.titleJa,
        isAdult: widget.work.isAdult,
        rating: _rating,
        comment: _comment.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '保存できませんでした。入力内容を確認して再試行してください。';
        });
      }
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text('作品を評価：${widget.work.titleJa}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ライブラリへの登録やゲームのインストールは不要です。'),
              const SizedBox(height: 8),
              Text(
                widget.sharingEnabled
                    ? '匿名評価の共有はオンです。保存した点数・コメントは同期時に公開されます。'
                    : 'このPCだけに保存します。ランキングへの反映には設定で匿名評価の共有をオンにしてください。',
              ),
              const SizedBox(height: 16),
              if (_loading)
                const LinearProgressIndicator()
              else ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('点数なし'),
                      selected: _rating == null,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _rating = null),
                    ),
                    for (var score = 1; score <= 10; score++)
                      ChoiceChip(
                        label: Text('$score'),
                        selected: _rating == score,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _rating = score),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _comment,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 4000,
                  decoration: const InputDecoration(labelText: '評価コメント（任意）'),
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _rating = null;
                          _comment.clear();
                        }),
                  child: const Text('評価を取り消す（空にして保存）'),
                ),
              ],
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                if (!_saving)
                  TextButton(onPressed: _load, child: const Text('読み直す')),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed:
              _loading ||
                  _saving ||
                  (_error != null && _error!.startsWith('評価を読み込'))
              ? null
              : _save,
          child: Text(_saving ? '保存中…' : '保存'),
        ),
      ],
    ),
  );
}
