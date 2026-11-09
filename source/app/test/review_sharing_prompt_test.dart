import 'package:chronovel/app.dart';
import 'package:chronovel/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('初回の評価共有案内はおすすめを選択済みで明示確認する', (tester) async {
    tester.view.physicalSize = const Size(1100, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ChronovelApp(
        database: database,
        reviewApiEndpoint: 'https://example.test/review-api/',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('評価ランキングへの共有'), findsOneWidget);
    expect(find.text('匿名で評価を共有する（おすすめ）'), findsOneWidget);
    final checkbox = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(checkbox.value, isTrue);

    await tester.tap(find.text('今回は共有しない'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(await database.readSetting('cloud.reviewSharingEnabled'), 'false');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });
}
