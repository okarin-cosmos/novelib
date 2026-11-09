import 'package:flutter/material.dart';

import '../../models/game.dart';

class DeleteRegistrationDialog extends StatefulWidget {
  const DeleteRegistrationDialog({
    super.key,
    required this.game,
    required this.onDelete,
  });
  final GameEntry game;
  final Future<void> Function(String) onDelete;
  @override
  State<DeleteRegistrationDialog> createState() =>
      _DeleteRegistrationDialogState();
}

class _DeleteRegistrationDialogState extends State<DeleteRegistrationDialog> {
  bool _busy = false;
  String? _error;
  Future<void> _delete() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDelete(widget.game.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '削除できませんでした。ゲームの起動・スキャンが終了してから再度お試しください。');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('この登録先を削除しますか？'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.game.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SelectableText(
                '保存場所：${widget.game.installDir ?? '未登録'}\n登録ID：${widget.game.id}',
              ),
              const SizedBox(height: 16),
              const Text(
                'この登録先の作品情報・評価・プレイ履歴・タグ・攻略メモ・予定をNoveLibから削除します。元に戻せません。\n\n同じ作品の別登録、共通カタログ、ゲーム本体やインストールフォルダは削除しません。',
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _busy ? null : _delete,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(_busy ? '削除中…' : 'この登録先を削除'),
        ),
      ],
    ),
  );
}
