import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const appReleaseVersion = '0.46.3';
const releaseNotesAsset = 'assets/release_notes/v$appReleaseVersion.txt';

class ReleaseNotesDialog extends StatefulWidget {
  const ReleaseNotesDialog({super.key, this.loadNotes});

  final Future<String> Function()? loadNotes;

  @override
  State<ReleaseNotesDialog> createState() => _ReleaseNotesDialogState();
}

class _ReleaseNotesDialogState extends State<ReleaseNotesDialog> {
  late final Future<String> _notes =
      widget.loadNotes?.call() ?? rootBundle.loadString(releaseNotesAsset);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('変更履歴 — v$appReleaseVersion'),
    content: SizedBox(
      width: 640,
      child: FutureBuilder<String>(
        future: _notes,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('変更履歴を読み込めませんでした。配布ZIP内のパッチノートをご確認ください。');
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return SingleChildScrollView(child: SelectableText(snapshot.data!));
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('閉じる'),
      ),
    ],
  );
}
