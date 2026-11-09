import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:chronovel/database/app_database.dart';
import 'package:chronovel/features/settings/help_dialogs.dart';
import 'package:chronovel/theme/app_theme.dart';

void main() {
  test('ガイドは新規・未完了の場合のみ自動表示する', () async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      expect(await needsWelcome(db), true);
      await db.writeSetting(welcomeSettingKey, 'true');
      expect(await needsWelcome(db), false);
      await db.writeSetting(welcomeSettingKey, 'false');
      await db.saveScanFolder('test-only');
      expect(await needsWelcome(db), false);
      await db.removeScanFolder('test-only');
      await db.upsertDetectedGame(
        title: '登録済み',
        installDir: 'test-only',
        exePath: 'test-only/game.exe',
        engine: 'manual',
      );
      expect(await needsWelcome(db), false);
    } finally {
      await db.close();
    }
  });
  void size(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget host(Future<void> Function() save) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Builder(
        builder: (c) => TextButton(
          onPressed: () => showDialog<bool>(
            context: c,
            builder: (_) => WelcomeDialog(onComplete: save),
          ),
          child: const Text('開く'),
        ),
      ),
    ),
  );
  testWidgets('ガイドを後回しにしても完了状態を保存しない', (tester) async {
    size(tester);
    var saves = 0;
    await tester.pumpWidget(
      host(() async {
        saves++;
      }),
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('あとで（設定から再表示）'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.byType(WelcomeDialog), findsNothing);
    expect(tester.takeException(), null);
  });
  testWidgets('ガイドの戻る・次へ・完了と保存失敗からの再試行', (tester) async {
    size(tester);
    var saves = 0;
    await tester.pumpWidget(
      host(() async {
        if (++saves == 1) throw StateError('test');
      }),
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    expect(find.text('作品と画像を確認する'), findsOneWidget);
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();
    expect(find.text('NoveLibへようこそ'), findsOneWidget);
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完了して設定を開く'));
    await tester.pumpAndSettle();
    expect(find.textContaining('完了状態を保存できません'), findsOneWidget);
    await tester.tap(find.text('完了して設定を開く'));
    await tester.pumpAndSettle();
    expect(saves, 2);
    expect(find.byType(WelcomeDialog), findsNothing);
    expect(tester.takeException(), null);
  });
  testWidgets('出典・通信内容と同梱ライセンス全文を開ける', (tester) async {
    size(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: AppInformationDialog()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('https://vndb.org/'), findsOneWidget);
    await tester.ensureVisible(find.text('ODBL 全文'));
    await tester.tap(find.text('ODBL 全文'));
    await tester.pumpAndSettle();
    expect(find.text('ODBL ライセンス全文'), findsOneWidget);
    expect(find.textContaining('Open Database License'), findsWidgets);
    expect(tester.takeException(), null);
  });
}
