import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/game.dart';
import '../../widgets/responsive_dialog.dart';
import 'record_store.dart';

class WorkRecordsDialog extends StatefulWidget {
  const WorkRecordsDialog({
    super.key,
    required this.db,
    required this.game,
    this.historyBlocked = false,
  });
  final AppDatabase db;
  final GameEntry game;
  final bool historyBlocked;
  @override
  State<WorkRecordsDialog> createState() => _WorkRecordsState();
}

class _WorkRecordsState extends State<WorkRecordsDialog> {
  late final store = RecordStore(widget.db);
  final tags = TextEditingController(),
      date = TextEditingController(),
      memo = TextEditingController();
  WorkNotes? notes;
  List<PlaySession> sessions = [];
  bool busy = false;
  String? error;
  int get id => int.parse(widget.game.id);
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final n = await store.notes(id);
      final s = await store.sessions(id);
      if (!mounted) return;
      setState(() {
        notes = n;
        sessions = s;
        tags.text = n.tags.join(', ');
        date.text = n.date;
        memo.text = n.memo;
      });
    } catch (e) {
      if (mounted) setState(() => error = '記録を読み込めません: $e');
    }
  }

  @override
  void dispose() {
    tags.dispose();
    date.dispose();
    memo.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!GameEdits.validDate(date.text.trim())) {
      setState(() => error = '予定日は YYYY-MM-DD 形式の実在する日付を指定してください。');
      return;
    }
    setState(() => busy = true);
    try {
      notes!
        ..date = date.text.trim()
        ..memo = memo.text
        ..tags = tags.text
            .split(RegExp('[,、]'))
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList();
      await store.save(id, notes!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '保存できません: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> route([int? index]) async {
    final old = index == null ? null : notes!.routes[index];
    final name = TextEditingController(text: old?['name'] as String? ?? '');
    final note = TextEditingController(text: old?['memo'] as String? ?? '');
    var status = old?['status'] as String? ?? '未着手';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, change) => AlertDialog(
          title: const Text('ルートの記録'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'ルート名'),
                  ),
                  DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    items: ['未着手', '攻略中', '完了']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => change(() => status = v!),
                  ),
                  TextField(
                    controller: note,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: '攻略メモ'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, {
                    'name': name.text.trim(),
                    'status': status,
                    'memo': note.text,
                  });
                }
              },
              child: const Text('反映'),
            ),
          ],
        ),
      ),
    );
    // Controllers stay alive until the dialog's closing animation is finished.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    name.dispose();
    note.dispose();
    if (result != null && mounted) {
      setState(() {
        if (index == null) {
          notes!.routes.add(result);
        } else {
          notes!.routes[index] = result;
        }
      });
    }
  }

  Future<void> session([PlaySession? old]) async {
    final result = await showDialog<(DateTime, DateTime)>(
      context: context,
      builder: (_) => SessionEditor(session: old),
    );
    if (result == null) return;
    setState(() => busy = true);
    try {
      await store.editSession(
        id,
        id: old?.id,
        start: result.$1,
        end: result.$2,
      );
      final s = await store.sessions(id);
      if (mounted) setState(() => sessions = s);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> removeSession(PlaySession s) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('この履歴を削除しますか？'),
        content: const Text('この履歴の時間を合計プレイ時間から差し引きます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => busy = true);
    try {
      await store.editSession(id, id: s.id, remove: true);
      final items = await store.sessions(id);
      if (mounted) setState(() => sessions = items);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text('作品記録 — ${widget.game.title}'),
      content: SizedBox(
        width: 760,
        height: responsiveDialogHeight(context, 550, minimum: 300),
        child: notes == null
            ? Center(child: Text(error ?? '読み込み中…'))
            : DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const Text('記録は選択中の登録先ごとに保存します。履歴の変更はその都度保存されます。'),
                    Text(
                      widget.game.installDir ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const TabBar(
                      tabs: [
                        Tab(text: 'タグ・予定・攻略'),
                        Tab(text: 'プレイ履歴'),
                      ],
                    ),
                    if (error != null)
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          ListView(
                            children: [
                              CheckboxListTile(
                                title: const Text('お気に入り'),
                                value: notes!.favorite,
                                onChanged: busy
                                    ? null
                                    : (v) =>
                                          setState(() => notes!.favorite = v!),
                              ),
                              CheckboxListTile(
                                title: const Text('購入予定'),
                                value: notes!.purchase,
                                onChanged: busy
                                    ? null
                                    : (v) =>
                                          setState(() => notes!.purchase = v!),
                              ),
                              TextField(
                                controller: date,
                                decoration: const InputDecoration(
                                  labelText: 'プレイ予定日（YYYY-MM-DD、空欄で解除）',
                                ),
                              ),
                              TextField(
                                controller: tags,
                                decoration: const InputDecoration(
                                  labelText: 'タグ（カンマ区切りで作成・変更・付与）',
                                ),
                              ),
                              TextField(
                                controller: memo,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: '作品メモ',
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('ルート・攻略状況'),
                              for (var i = 0; i < notes!.routes.length; i++)
                                ListTile(
                                  title: Text(
                                    '${notes!.routes[i]['name']} · ${notes!.routes[i]['status']}',
                                  ),
                                  subtitle: Text(
                                    notes!.routes[i]['memo'] as String? ?? '',
                                  ),
                                  onTap: busy ? null : () => route(i),
                                  trailing: IconButton(
                                    tooltip: 'ルートを除外（保存で確定）',
                                    onPressed: busy
                                        ? null
                                        : () => setState(
                                            () => notes!.routes.removeAt(i),
                                          ),
                                    icon: const Icon(Icons.close),
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: busy ? null : () => route(),
                                icon: const Icon(Icons.add),
                                label: const Text('ルートを追加'),
                              ),
                            ],
                          ),
                          ListView(
                            children: [
                              const Text('時刻はこのPCの現地時刻です。同じ作品の重複時間は登録できません。'),
                              if (widget.historyBlocked)
                                const Text('ゲーム起動中は履歴を編集できません。'),
                              TextButton.icon(
                                onPressed: busy || widget.historyBlocked
                                    ? null
                                    : () => session(),
                                icon: const Icon(Icons.add),
                                label: const Text('履歴を手動追加'),
                              ),
                              if (sessions.isEmpty) const Text('履歴はまだありません。'),
                              for (final s in sessions)
                                ListTile(
                                  title: Text(
                                    '${s.startedAt.toLocal()} → ${s.endedAt.toLocal()}',
                                  ),
                                  subtitle: Text(
                                    '${(s.endedAt.difference(s.startedAt).inSeconds / 3600).toStringAsFixed(1)} h',
                                  ),
                                  onTap: busy || widget.historyBlocked
                                      ? null
                                      : () => session(s),
                                  trailing: IconButton(
                                    tooltip: '履歴を削除',
                                    onPressed: busy || widget.historyBlocked
                                        ? null
                                        : () => removeSession(s),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('閉じる（未保存の編集を破棄）'),
        ),
        FilledButton(
          onPressed: busy || notes == null ? null : save,
          child: Text(busy ? '保存中…' : 'タグ・予定・攻略を保存'),
        ),
      ],
    ),
  );
}

class SessionEditor extends StatefulWidget {
  const SessionEditor({super.key, this.session});
  final PlaySession? session;
  @override
  State<SessionEditor> createState() => _SessionEditorState();
}

class _SessionEditorState extends State<SessionEditor> {
  late final start = TextEditingController(
    text:
        (widget.session?.startedAt.toLocal() ??
                DateTime.now().subtract(const Duration(hours: 1)))
            .toString()
            .substring(0, 19),
  );
  late final end = TextEditingController(
    text: (widget.session?.endedAt.toLocal() ?? DateTime.now())
        .toString()
        .substring(0, 19),
  );
  String? error;
  @override
  void dispose() {
    start.dispose();
    end.dispose();
    super.dispose();
  }

  DateTime? parse(String raw) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(raw)) {
      return null;
    }
    final d = DateTime.tryParse(raw);
    return d != null && d.toString().substring(0, 19) == raw ? d : null;
  }

  @override
  Widget build(BuildContext c) => AlertDialog(
    title: const Text('プレイ履歴を編集'),
    content: SizedBox(
      width: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: start,
            decoration: const InputDecoration(
              labelText: '開始 YYYY-MM-DD HH:MM:SS',
            ),
          ),
          TextField(
            controller: end,
            decoration: const InputDecoration(
              labelText: '終了 YYYY-MM-DD HH:MM:SS',
            ),
          ),
          if (error != null) Text(error!),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(c), child: const Text('キャンセル')),
      FilledButton(
        onPressed: () {
          final a = parse(start.text), b = parse(end.text);
          if (a == null ||
              b == null ||
              !b.isAfter(a) ||
              b.isAfter(DateTime.now())) {
            setState(() => error = '実在する日時を入力し、開始 < 終了 ≤ 現在にしてください。');
            return;
          }
          Navigator.pop(c, (a, b));
        },
        child: const Text('履歴を保存'),
      ),
    ],
  );
}
