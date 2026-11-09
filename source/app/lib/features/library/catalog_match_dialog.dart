import 'dart:async';

import 'package:flutter/material.dart';

import '../../catalog/catalog_database.dart';
import '../../models/game.dart';
import '../../widgets/responsive_dialog.dart';

class CatalogMatchDialog extends StatefulWidget {
  const CatalogMatchDialog({
    super.key,
    required this.game,
    required this.catalog,
    required this.onSave,
  });
  final GameEntry game;
  final CatalogDatabase catalog;
  final Future<void> Function(CatalogWork) onSave;
  @override
  State<CatalogMatchDialog> createState() => _CatalogMatchDialogState();
}

class _CatalogMatchDialogState extends State<CatalogMatchDialog> {
  late final _query = TextEditingController(text: widget.game.title);
  List<CatalogWork> _results = [];
  CatalogWork? _selected;
  Timer? _timer;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _search();
  }

  void _search() {
    try {
      final results = widget.catalog.matchingCandidates(_query.text, limit: 50);
      setState(() {
        _results = results;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = '検索できませんでした。再度お試しください。');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final selected = _selected;
    if (selected == null || _busy) return;
    _timer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(selected);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = '保存できませんでした。選択内容を確認して再度お試しください。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('カタログ作品を選び直す'),
      content: SizedBox(
        width: 700,
        height: responsiveDialogHeight(context, 510, minimum: 300),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '対象：${widget.game.title}（${widget.game.vndbId ?? '未照合'}）',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '保存場所：${widget.game.installDir ?? '不明'}\n実行ファイル：${widget.game.exePath ?? '不明'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            const Text(
              '正式名・ブランド・発売日・表紙の参照先を変更します。評価・履歴・手動修正は残ります。手動修正がある項目はそちらを優先表示します。',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _query,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: '作品名・別名・ブランドで検索',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) {
                _timer?.cancel();
                setState(() => _selected = null);
                _timer = Timer(const Duration(milliseconds: 200), _search);
              },
            ),
            const SizedBox(height: 8),
            const Text('短縮名からの候補も表示します。ブランド・発売日を確認して選んでください（最大50件）。'),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text(
                        '該当する作品がありません。正式名称でも検索してください。\nカタログにない場合は詳細の「情報を編集」から画像を指定できます。',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final work = _results[index];
                        return ListTile(
                          selected: _selected?.vndbId == work.vndbId,
                          leading: Icon(
                            _selected?.vndbId == work.vndbId
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          title: Text(work.titleJa),
                          subtitle: Text(
                            '${work.developers ?? 'ブランド不明'} · ${work.released ?? '発売日不明'} · ${work.vndbId}',
                          ),
                          onTap: _busy
                              ? null
                              : () => setState(() => _selected = work),
                        );
                      },
                    ),
            ),
            if (_selected != null)
              Text('変更先：${_selected!.titleJa}（${_selected!.vndbId}）'),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _busy || _selected == null ? null : _save,
          child: Text(_busy ? '保存中…' : 'この作品に変更'),
        ),
      ],
    ),
  );
}
