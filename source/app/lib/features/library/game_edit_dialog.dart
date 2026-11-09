import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/game.dart';
import '../../widgets/cover_image.dart';

class GameEditDialog extends StatefulWidget {
  const GameEditDialog({super.key, required this.game, required this.onSave});
  final GameEntry game;
  final Future<void> Function(GameEdits) onSave;
  @override
  State<GameEditDialog> createState() => _GameEditDialogState();
}

class _GameEditDialogState extends State<GameEditDialog> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.game.title);
  late final _brand = TextEditingController(
    text: widget.game.developers ?? widget.game.brand,
  );
  late final _released = TextEditingController(text: widget.game.released);
  late String? _imagePath = widget.game.localCoverPath;
  late String _blurMode = switch (widget.game.coverBlurOverride) {
    true => 'blur',
    false => 'show',
    null => 'global',
  };
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _brand.dispose();
    _released.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: '画像',
            extensions: ['jpg', 'jpeg', 'png', 'webp'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 20 * 1024 * 1024) {
        throw const FormatException('画像は20MB以下にしてください。');
      }
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      codec.dispose();
      if (mounted) setState(() => _imagePath = file.path);
    } catch (_) {
      if (mounted) setState(() => _error = '画像を読み込めませんでした。20MB以下の画像を選んでください。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    File? copied;
    try {
      var path = _imagePath;
      if (path != null && path != widget.game.localCoverPath) {
        final support = await getApplicationSupportDirectory();
        final directory = Directory(
          p.join(support.path, 'Chronovel', 'covers', 'custom'),
        );
        await directory.create(recursive: true);
        copied = await File(path).copy(
          p.join(
            directory.path,
            '${DateTime.now().microsecondsSinceEpoch}${p.extension(path)}',
          ),
        );
        path = copied.path;
      }
      await widget.onSave(
        GameEdits(
          title: _title.text.trim(),
          brand: _brand.text.trim(),
          released: _released.text.trim(),
          imagePath: path,
          blurCover: switch (_blurMode) {
            'blur' => true,
            'show' => false,
            _ => null,
          },
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (copied != null && await copied.exists()) await copied.delete();
      if (mounted) {
        setState(() => _error = '保存できませんでした。内容は保持されています。もう一度お試しください。');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('作品情報を編集'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('このライブラリ内の情報だけを変更します。再スキャン後も修正内容を保持します。'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'タイトル'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'タイトルを入力してください' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _brand,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'ブランド／開発元'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _released,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: '発売日（YYYY-MM-DD／空欄可）',
                  ),
                  validator: (v) => GameEdits.validDate(v!.trim())
                      ? null
                      : '実在する日付を YYYY-MM-DD 形式で入力してください',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _blurMode,
                  decoration: const InputDecoration(labelText: 'この作品の表紙ぼかし'),
                  items: const [
                    DropdownMenuItem(value: 'global', child: Text('全体設定に従う')),
                    DropdownMenuItem(value: 'blur', child: Text('この作品だけぼかす')),
                    DropdownMenuItem(value: 'show', child: Text('この作品だけぼかさない')),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _blurMode = value!),
                ),
                const SizedBox(height: 16),
                if (_imagePath != null)
                  CoverPrivacyFilter(
                    blurOverride: switch (_blurMode) {
                      'blur' => true,
                      'show' => false,
                      _ => null,
                    },
                    child: Image.file(
                      File(_imagePath!),
                      height: 120,
                      errorBuilder: (_, error, stack) =>
                          const Text('画像を表示できません'),
                    ),
                  ),
                Text(
                  _imagePath == null ? 'カタログの表紙を使用' : p.basename(_imagePath!),
                ),
                Wrap(
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : _pickImage,
                      child: const Text('画像を選択'),
                    ),
                    if (_imagePath != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _imagePath = null),
                        child: const Text('カタログの表紙に戻す'),
                      ),
                  ],
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '処理中…' : '保存'),
        ),
      ],
    ),
  );
}
