import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

import '../../catalog/catalog_database.dart';
import '../../models/game.dart';
import '../../services/cover_image_cache.dart';
import '../../widgets/responsive_dialog.dart';

class ImageManagementDialog extends StatefulWidget {
  const ImageManagementDialog({super.key, required this.games, this.cache});
  final List<GameEntry> games;
  final CoverImageCache? cache;
  @override
  State<ImageManagementDialog> createState() => _ImageManagementDialogState();
}

class _ImageManagementDialogState extends State<ImageManagementDialog> {
  final Set<String> _selected = {};
  bool _busy = false;
  String? _message;
  late final _works = <String, GameEntry>{
    for (final g in widget.games)
      if (g.vndbId != null) g.vndbId!: g,
  };
  Future<void> _run(bool remove) async {
    if (_busy || _selected.isEmpty) return;
    final ids = Set<String>.of(_selected);
    if (remove) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${ids.length}作品の取得画像を削除しますか？'),
          content: const Text(
            'NoveLibの画像キャッシュのみを削除します。ゲーム本体・評価・履歴・手動指定画像は残ります。次回表示時や再試行で再取得できますが、オフラインでは表示できなくなります。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('画像キャッシュを削除'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final cache = widget.cache ?? CoverImageCache.instance;
      if (remove) {
        final count = await cache.removeImages(
          ids,
          protectedPaths: widget.games
              .map((g) => g.localCoverPath)
              .whereType<String>(),
        );
        if (mounted) {
          setState(() => _message = '$count個のキャッシュファイルを削除しました。配信元から再取得できます。');
        }
      } else {
        var succeeded = 0, failed = 0, skipped = 0, done = 0;
        for (final id in ids) {
          final url = _works[id]?.coverImageUrl;
          if (url == null ||
              url.isEmpty ||
              widget.games.any(
                (g) => g.vndbId == id && g.localCoverPath != null,
              )) {
            skipped++;
          } else if (await cache.refreshImage(id, url)) {
            succeeded++;
          } else {
            failed++;
          }
          done++;
          if (mounted) {
            setState(
              () => _message =
                  '$done / ${ids.length}件：成功 $succeeded、失敗 $failed、対象外（URLなし・手動画像） $skipped',
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = '処理を完了できませんでした。一部だけ処理された可能性があります。対象を確認して再試行してください。',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('画像キャッシュ管理'),
      content: SizedBox(
        width: 720,
        height: responsiveDialogHeight(context, 470),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'カタログ作品単位で管理します。同じ作品の別登録にも反映されます。手動画像のある作品は再取得から除外し、手動画像ファイルは削除しません。',
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _selected.addAll(_works.keys)),
                  child: const Text('すべて選択'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => setState(_selected.clear),
                  child: const Text('全解除'),
                ),
                Text('${_selected.length}作品選択'),
              ],
            ),
            Expanded(
              child: _works.isEmpty
                  ? const Center(child: Text('カタログ照合済みの作品がありません'))
                  : ListView(
                      children: [
                        for (final entry in _works.entries)
                          CheckboxListTile(
                            value: _selected.contains(entry.key),
                            onChanged: _busy
                                ? null
                                : (value) => setState(() {
                                    if (value == true) {
                                      _selected.add(entry.key);
                                    } else {
                                      _selected.remove(entry.key);
                                    }
                                  }),
                            title: Text(entry.value.title),
                            subtitle: Text(
                              '${entry.key} · ${entry.value.coverImageUrl == null ? '画像URLなし' : '画像URLあり'}${entry.value.localCoverPath == null ? '' : ' · 手動画像を優先表示中'}',
                            ),
                          ),
                      ],
                    ),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_message != null) Text(_message!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
        OutlinedButton(
          onPressed: _busy || _selected.isEmpty ? null : () => _run(true),
          child: const Text('選択画像を削除'),
        ),
        FilledButton(
          onPressed: _busy || _selected.isEmpty ? null : () => _run(false),
          child: const Text('選択画像を再取得'),
        ),
      ],
    ),
  );
}

class ManualRegistrationDialog extends StatefulWidget {
  const ManualRegistrationDialog({
    super.key,
    this.initialDirectory,
    this.catalog,
    required this.onSave,
  });
  final String? initialDirectory;
  final CatalogDatabase? catalog;
  final Future<void> Function(String title, String exe, CatalogWork? work)
  onSave;
  @override
  State<ManualRegistrationDialog> createState() =>
      _ManualRegistrationDialogState();
}

class _ManualRegistrationDialogState extends State<ManualRegistrationDialog> {
  final _title = TextEditingController();
  final _exe = TextEditingController();
  List<CatalogWork> _results = [];
  CatalogWork? _work;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _exe.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final selected = await openFile(
        initialDirectory: widget.initialDirectory,
        acceptedTypeGroups: const [
          XTypeGroup(label: '実行ファイル', extensions: ['exe']),
        ],
      );
      if (selected != null && mounted) {
        setState(() {
          _exe.text = selected.path;
          if (_title.text.isEmpty) {
            _title.text = p.basename(p.dirname(selected.path));
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'ファイルを選択できませんでした。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_title.text.trim().isEmpty || _exe.text.trim().isEmpty) {
      setState(() => _error = '作品名と実行ファイルを指定してください。');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(_title.text.trim(), _exe.text.trim(), _work);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = '登録できませんでした。存在する.exeの絶対パス、ゲーム起動・スキャン状態を確認してください。',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('実行ファイルを指定して登録'),
      content: SizedBox(
        width: 720,
        height: responsiveDialogHeight(context, 490),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ゲーム本体の.exeを指定してください。登録時には実行しません。同じ保存フォルダの登録がある場合は起動先を更新し、評価・履歴・手動情報を保持します。',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: '作品名／候補検索'),
              onChanged: (_) => setState(() {
                _work = null;
                _results = [];
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _exe,
              enabled: !_busy,
              decoration: InputDecoration(
                labelText: '実行ファイルの絶対パス (.exe)',
                suffixIcon: IconButton(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.folder_open),
                  tooltip: '実行ファイルを選ぶ',
                ),
              ),
            ),
            TextButton(
              onPressed: _busy || widget.catalog == null
                  ? null
                  : () {
                      try {
                        setState(() {
                          _work = null;
                          _results = widget.catalog!.matchingCandidates(
                            _title.text,
                            limit: 30,
                          );
                        });
                      } catch (_) {
                        setState(() => _error = '候補を検索できませんでした。');
                      }
                    },
              child: const Text('カタログ候補を検索'),
            ),
            Text(
              _work == null
                  ? '照合先未選択：未照合として登録（既存の照合先があれば保持）'
                  : '照合先：${_work!.titleJa}',
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final work in _results)
                    ListTile(
                      selected: _work?.vndbId == work.vndbId,
                      title: Text(work.titleJa),
                      subtitle: Text(
                        '${work.developers ?? 'ブランド不明'} · ${work.released ?? '発売日不明'} · ${work.vndbId}',
                      ),
                      onTap: _busy
                          ? null
                          : () => setState(
                              () => _work = _work?.vndbId == work.vndbId
                                  ? null
                                  : work,
                            ),
                    ),
                ],
              ),
            ),
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
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '登録中…' : '指定内容で登録'),
        ),
      ],
    ),
  );
}

class ScanDiagnosticsDialog extends StatelessWidget {
  const ScanDiagnosticsDialog({
    super.key,
    required this.games,
    required this.reports,
    required this.onOpen,
    required this.onRegister,
    this.imageFailures = const [],
  });
  final List<GameEntry> games;
  final List<String> reports;
  final ValueChanged<String> onOpen;
  final ValueChanged<String?> onRegister;
  final List<ImageFailureRecord> imageFailures;

  GameEntry? _gameFor(String vndbId) {
    for (final game in games) {
      if (game.vndbId == vndbId) return game;
    }
    return null;
  }

  String _failureDate(ImageFailureRecord failure) {
    final local = failure.occurredAt.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}/${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: AlertDialog(
      title: const Text('未検出・未照合の確認'),
      content: SizedBox(
        width: 800,
        height: responsiveDialogHeight(context, 510),
        child: Column(
          children: [
            const Text('未検出は保存されたスキャン時点の結果です。現在の状態は再スキャンで更新してください。'),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: '未照合の登録'),
                Tab(text: '未検出・除外の理由'),
                Tab(text: '画像取得エラー'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    children: [
                      if (!games.any((g) => g.vndbId == null))
                        const ListTile(title: Text('未照合の登録はありません')),
                      for (final game in games.where((g) => g.vndbId == null))
                        ListTile(
                          title: Text(game.title),
                          subtitle: Text(
                            '一意のカタログ作品へ照合されていません。\n${game.installDir ?? ''}',
                          ),
                          trailing: TextButton(
                            onPressed: () => onOpen(game.id),
                            child: const Text('詳細で照合'),
                          ),
                        ),
                    ],
                  ),
                  ListView(
                    children: [
                      if (reports.isEmpty)
                        const ListTile(
                          title: Text('診断結果がありません。設定から再スキャンしてください。'),
                        ),
                      for (final report in reports)
                        ListTile(
                          title: SelectableText(report),
                          trailing: TextButton(
                            onPressed: () {
                              final i = report.lastIndexOf(': ');
                              onRegister(
                                i < 0 ? null : report.substring(i + 2),
                              );
                            },
                            child: const Text('手動登録'),
                          ),
                        ),
                    ],
                  ),
                  ListView(
                    children: [
                      if (imageFailures.isEmpty)
                        const ListTile(
                          title: Text('保存された画像取得エラーはありません'),
                          subtitle: Text('画像の取得に成功すると、以前のエラーは自動的に解消されます。'),
                        ),
                      for (final failure in imageFailures)
                        Builder(
                          builder: (_) {
                            final game = _gameFor(failure.id);
                            return ListTile(
                              title: Text(game?.title ?? failure.id),
                              subtitle: Text(
                                '${failure.message}\n'
                                '最終発生 ${_failureDate(failure)} ・ ${failure.attempts}回\n'
                                '${failure.id}',
                              ),
                              trailing: game == null
                                  ? null
                                  : TextButton(
                                      onPressed: () => onOpen(game.id),
                                      child: const Text('詳細を開く'),
                                    ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => onRegister(null),
          child: const Text('実行ファイルを指定'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}
