import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../catalog/catalog_database.dart';
import '../../database/app_database.dart';
import '../../models/game.dart';

class OrganizerPage extends StatefulWidget {
  const OrganizerPage({
    super.key,
    required this.db,
    required this.games,
    required this.onOpen,
  });

  final AppDatabase db;
  final List<GameEntry> games;
  final ValueChanged<String> onOpen;

  @override
  State<OrganizerPage> createState() => _OrganizerState();
}

class _OrganizerState extends State<OrganizerPage> {
  late final settingsStream = widget.db.select(widget.db.appSettings).watch();
  final searchController = TextEditingController();
  final searchFocus = FocusNode();
  final pageFocus = FocusNode();
  String query = '';
  String? error;
  bool busy = false;

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    pageFocus.dispose();
    super.dispose();
  }

  Set<String> get _installedTitles => widget.games
      .expand(
        (game) => [game.title, if (game.titleRomaji != null) game.titleRomaji!],
      )
      .map(normalizeCatalogTitle)
      .where((title) => title.isNotEmpty)
      .toSet();

  Future<void> _editPlans(List<String> initial) async {
    final controller = TextEditingController(text: initial.join('\n'));
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ウィッシュリストを編集'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            minLines: 7,
            maxLines: 14,
            decoration: const InputDecoration(
              labelText: '1行に1作品。行を消すとリストから外れます。',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (result == null) return;
    await _act(() async {
      final installed = _installedTitles;
      final plans = result
          .split('\n')
          .map((title) => title.trim())
          .where((title) => title.isNotEmpty)
          .where((title) => !installed.contains(normalizeCatalogTitle(title)))
          .toSet()
          .toList();
      await widget.db.writeSetting('purchase.plans', jsonEncode(plans));
    });
  }

  Future<void> _remove(String title, List<String> plans) async {
    await _act(
      () => widget.db.writeSetting(
        'purchase.plans',
        jsonEncode(plans.where((item) => item != title).toList()),
      ),
    );
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (exception) {
      if (mounted) setState(() => error = '$exception');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<AppSetting>>(
    stream: settingsStream,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(child: Text('ウィッシュリストを読み込めません。'));
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      List<String> plans;
      try {
        final data = {for (final row in snapshot.data!) row.key: row.value};
        plans = (jsonDecode(data['purchase.plans'] ?? '[]') as List)
            .cast<String>()
            .where(
              (title) =>
                  !_installedTitles.contains(normalizeCatalogTitle(title)),
            )
            .toList();
      } catch (exception) {
        return Center(child: Text('記録形式を確認できません: $exception'));
      }
      final visible = plans
          .where((title) => title.toLowerCase().contains(query.toLowerCase()))
          .toList();
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, control: true):
              searchFocus.requestFocus,
          const SingleActivator(LogicalKeyboardKey.escape): () {
            searchController.clear();
            setState(() => query = '');
            pageFocus.requestFocus();
          },
        },
        child: Focus(
          autofocus: true,
          focusNode: pageFocus,
          child: ListView(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
            ),
            children: [
              Text(
                'ウィッシュリスト',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text('購入を検討している未登録作品を管理します。ライブラリへ登録された作品は自動で外れます。'),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : () => _editPlans(plans),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('リストを編集'),
                  ),
                  const Chip(
                    avatar: Icon(Icons.update_rounded, size: 18),
                    label: Text('カタログの週次更新は配信API準備後に対応予定'),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (busy) const LinearProgressIndicator(),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                focusNode: searchFocus,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: '作品名で絞り込み',
                ),
                onChanged: (value) => setState(() => query = value),
              ),
              const SizedBox(height: 18),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 42),
                  child: Center(child: Text('ウィッシュリストに作品はありません。')),
                )
              else
                for (final title in visible)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.bookmark_border_rounded),
                      title: Text(title),
                      subtitle: const Text('未登録・購入検討中'),
                      trailing: IconButton(
                        tooltip: 'リストから外す',
                        onPressed: busy ? null : () => _remove(title, plans),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  );
}
