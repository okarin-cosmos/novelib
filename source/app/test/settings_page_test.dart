import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/features/settings/settings_page.dart';

void main() {
  testWidgets('フォルダごとの再スキャン・対象解除は正しいパスを渡す', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? rescanned, removed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            scanFolders: const ['folder-a', 'folder-b'],
            isScanning: false,
            scanMessage: null,
            onAddFolder: () {},
            onRescanFolder: (path) => rescanned = path,
            onRemoveFolder: (path) => removed = path,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('再スキャン').last);
    expect(rescanned, 'folder-b');
    await tester.tap(find.byTooltip('スキャン対象から外す').first);
    expect(removed, 'folder-a');
  });
  testWidgets('スキャン中は追加・再スキャン・解除を無効化する', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            scanFolders: const ['folder'],
            isScanning: true,
            scanMessage: '処理中',
            onAddFolder: () => calls++,
            onRescanFolder: (_) => calls++,
            onRemoveFolder: (_) => calls++,
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == '再スキャン',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'スキャン対象から外す',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox());
  });

  for (final width in [320.0, 600.0, 1000.0]) {
    testWidgets('設定 幅$width でフォルダ管理と下部項目を表示', (tester) async {
      tester.view.physicalSize = Size(width, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsPage(
              scanFolders: const [r'D:\game\とても長いゲームソフトのフォルダ名\さらに長い登録先'],
              isScanning: false,
              scanMessage: '前回のスキャンは正常に完了しました。',
              onAddFolder: () {},
              onRescanFolder: (_) {},
              onRemoveFolder: (_) {},
              onInformation: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('再スキャン'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('データ出典・プライバシー'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('データ出典・プライバシー'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('狭い設定画面で未登録フォルダ案内を折り返す', (tester) async {
    tester.view.physicalSize = const Size(320, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            scanFolders: const [],
            isScanning: false,
            scanMessage: null,
            onAddFolder: () {},
            onRescanFolder: (_) {},
            onRemoveFolder: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('まだスキャン対象フォルダがありません'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('作品カタログの更新ボタンを呼び出し処理中は無効にする', (tester) async {
    var calls = 0;
    Future<void> pump({required bool updating}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettingsPage(
              scanFolders: const [],
              isScanning: false,
              scanMessage: null,
              isUpdatingCatalog: updating,
              onAddFolder: () {},
              onRescanFolder: (_) {},
              onRemoveFolder: (_) {},
              onUpdateCatalog: () => calls++,
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text(updating ? '更新中…' : 'ローカル更新ファイルを選択'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }

    await pump(updating: false);
    await tester.tap(find.text('ローカル更新ファイルを選択'));
    expect(calls, 1);
    await pump(updating: true);
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '更新中…'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('タスクトレイとR18表示の設定を変更できる', (tester) async {
    bool? closeToTray;
    bool? showAdult;
    bool? blurCovers;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            scanFolders: const [],
            isScanning: false,
            scanMessage: null,
            onAddFolder: () {},
            onRescanFolder: (_) {},
            onRemoveFolder: (_) {},
            closeToTray: true,
            onCloseToTrayChanged: (value) => closeToTray = value,
            showAdult: true,
            onShowAdultChanged: (value) => showAdult = value,
            blurCovers: false,
            onBlurCoversChanged: (value) => blurCovers = value,
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('閉じたときにタスクトレイへ格納'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('閉じたときにタスクトレイへ格納'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('表紙画像をぼかす'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('表紙画像をぼかす'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('R18作品を表示'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('R18作品を表示'));
    expect(closeToTray, isFalse);
    expect(blurCovers, isTrue);
    expect(showAdult, isFalse);
    expect(find.text('Windowsログイン時に起動'), findsNothing);
  });

  testWidgets('評価共有は接続前には初期オフで有効化できない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            scanFolders: const [],
            isScanning: false,
            scanMessage: null,
            onAddFolder: () {},
            onRescanFolder: (_) {},
            onRemoveFolder: (_) {},
            reviewSyncStatus: '評価サーバーはまだ接続されていません。',
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('匿名で評価を共有する'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    final tile = tester.widget<SwitchListTile>(
      find.ancestor(
        of: find.text('匿名で評価を共有する'),
        matching: find.byType(SwitchListTile),
      ),
    );
    expect(tile.value, isFalse);
    expect(tile.onChanged, isNull);
    expect(find.byKey(const Key('review-sync-status')), findsOneWidget);
  });
}
