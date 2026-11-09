import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../models/game.dart';
import 'data_transfer.dart';

class TransferDialog extends StatefulWidget {
  const TransferDialog({
    super.key,
    required this.db,
    required this.games,
    required this.onRestored,
    this.readBackup,
    this.writeBackup,
  });
  final AppDatabase db;
  final List<GameEntry> games;
  final Future<void> Function() onRestored;
  // Injectable I/O also keeps restore confirmation tests away from user files.
  final Future<String?> Function()? readBackup;
  final Future<String?> Function(String, String, String)? writeBackup;
  @override
  State<TransferDialog> createState() => _TransferState();
}

class _TransferState extends State<TransferDialog> {
  bool busy = false;
  bool restored = false;
  String? message;
  Future<String?> write(
    String contents,
    String prefix,
    String extension,
  ) async {
    if (widget.writeBackup != null) {
      return widget.writeBackup!(contents, prefix, extension);
    }
    final location = await getSaveLocation(
      suggestedName:
          '$prefix-${DateTime.now().millisecondsSinceEpoch}.$extension',
      acceptedTypeGroups: [
        XTypeGroup(label: extension, extensions: [extension]),
      ],
    );
    if (location == null) return null;
    final file = File(location.path);
    if (await file.exists()) throw StateError('既存ファイルは上書きしません。別の名前を指定してください。');
    await file.writeAsString(contents, encoding: utf8, flush: true);
    return file.path;
  }

  Future<void> perform(Future<void> Function() operation) async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await operation();
    } catch (e) {
      if (mounted) setState(() => message = '処理できませんでした: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> export(bool csv) async {
    final text = csv
        ? libraryCsv(widget.games)
        : (await LibraryBackup.capture(widget.db)).encode();
    final path = await write(
      text,
      csv ? 'novelib-library' : 'novelib-backup',
      csv ? 'csv' : 'json',
    );
    if (path != null && mounted) setState(() => message = '保存しました: $path');
  }

  Future<void> restore() async {
    String? text;
    if (widget.readBackup != null) {
      text = await widget.readBackup!();
    } else {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'NoveLibバックアップ', extensions: ['json']),
        ],
      );
      if (file == null) return;
      if (await File(file.path).length() > 100 * 1024 * 1024) {
        throw const FormatException('バックアップは100MB以内にしてください。');
      }
      text = await file.readAsString();
    }
    if (text == null) return;
    final backup = await LibraryBackup.parse(text);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('バックアップから復元しますか？'),
        content: Text(
          '${backup.games.length} 件の登録と履歴・設定、および ${backup.catalogReviews.length} 件のカタログ評価に置き換えます。\n現在のデータは自動では合流しません。ゲーム本体・画像ファイルには触れません。\n\n続けると、まず現在のデータの退避先を選択します。退避に成功した場合のみ復元します。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('現在のデータを退避して復元'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final current = await LibraryBackup.capture(widget.db);
    final path = await write(
      current.encode(),
      'novelib-before-restore',
      'json',
    );
    if (path == null) return;
    await backup.restore(widget.db);
    restored = true;
    await widget.onRestored();
    if (mounted) {
      setState(
        () => message =
            '${backup.games.length} 件の登録と ${backup.catalogReviews.length} 件のカタログ評価を復元しました。復元前のデータ: $path',
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: const Text('エクスポート・バックアップ'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CSV：表示名・評価・時間・タグなどの作品一覧。\nJSON：SQLiteの全ユーザーデータを移行できる論理バックアップ。\n作品、履歴、評価、タグ、攻略、予定、スキャン設定を含みます。\n\nゲーム本体・画像ファイル・初期カタログは含みません。手動画像と実行ファイルは元のパスを参照します。パスやメモを含むため共有時は注意してください。',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: busy || restored
                      ? null
                      : () => perform(() => export(true)),
                  child: const Text('CSVを保存'),
                ),
                OutlinedButton(
                  onPressed: busy || restored
                      ? null
                      : () => perform(() => export(false)),
                  child: const Text('JSONバックアップを保存'),
                ),
                OutlinedButton(
                  onPressed: busy || restored ? null : () => perform(restore),
                  child: const Text('JSONから復元'),
                ),
              ],
            ),
            if (busy) const LinearProgressIndicator(),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SelectableText(message!),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}
