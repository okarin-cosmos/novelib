import 'package:chronovel/app.dart';
import 'package:chronovel/catalog/catalog_database.dart';
import 'package:chronovel/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('R18作品は初期表示し設定を切ると全ライブラリ画面から隠す', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase(NativeDatabase.memory());
    final catalog = CatalogDatabase.openExisting(
      'assets/catalog/chronovel_catalog.sqlite',
    );
    await database.writeSetting('cloud.reviewSharingEnabled', 'false');
    await database.upsertDetectedGame(
      title: '成人向けテスト作品',
      installDir: 'adult',
      exePath: 'adult.exe',
      engine: 'manual',
      vndbId: 'v11',
    );
    await database.upsertDetectedGame(
      title: '全年齢テスト作品',
      installDir: 'safe',
      exePath: 'safe.exe',
      engine: 'manual',
      vndbId: 'v2002',
    );
    await tester.pumpWidget(ChronovelApp(database: database, catalog: catalog));
    await tester.pumpAndSettle();
    expect(find.text('成人向けテスト作品'), findsOneWidget);
    expect(find.text('全年齢テスト作品'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    final adultSwitch = find.text('R18作品を表示');
    await tester.scrollUntilVisible(
      adultSwitch,
      200,
      maxScrolls: 20,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(adultSwitch);
    await tester.pumpAndSettle();
    await tester.tap(adultSwitch);
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.text('成人向けテスト作品'), findsNothing);
    expect(find.text('全年齢テスト作品'), findsOneWidget);
    expect(await database.readSetting('display.showAdult'), 'false');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
    catalog.close();
  });
}
