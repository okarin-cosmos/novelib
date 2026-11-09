import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/features/settings/help_dialogs.dart';
import 'package:chronovel/features/settings/maintenance_dialogs.dart';

void main() {
  testWidgets('主要な設定ダイアログを狭い画面で表示', (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> show(Widget dialog, String title) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () =>
                    showDialog<void>(context: context, builder: (_) => dialog),
                child: const Text('開く'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }

    await show(const ImageManagementDialog(games: []), '画像キャッシュ管理');
    await show(
      ManualRegistrationDialog(onSave: (_, _, _) async {}),
      '実行ファイルを指定して登録',
    );
    await show(
      ScanDiagnosticsDialog(
        games: const [],
        reports: const [],
        onOpen: (_) {},
        onRegister: (_) {},
      ),
      '未検出・未照合の確認',
    );
    await show(const AppInformationDialog(), 'データ出典・プライバシー');
    await show(const LicenseTextDialog(name: 'ODBL'), 'ODBL ライセンス全文');
  });
}
