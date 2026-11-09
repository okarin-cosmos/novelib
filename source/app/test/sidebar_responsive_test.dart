import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/app.dart';

void main() {
  Future<void> showAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const ChronovelApp());
    await tester.pumpAndSettle();
  }

  testWidgets('狭いウィンドウではサイドバーを76pxに縮小して遷移', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showAt(tester, const Size(800, 700));
    expect(tester.getSize(find.byKey(const Key('app-sidebar'))).width, 76);
    expect(find.byTooltip('設定'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('設定'));
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsWidgets);
  });

  testWidgets('低いウィンドウでもサイドバーを縮小', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showAt(tester, const Size(1300, 600));
    expect(tester.getSize(find.byKey(const Key('app-sidebar'))).width, 76);
    expect(find.byTooltip('設定'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('通常サイズでは250pxの詳細サイドバーを維持', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showAt(tester, const Size(1400, 900));
    expect(tester.getSize(find.byKey(const Key('app-sidebar'))).width, 250);
    expect(find.text('NoveLib'), findsOneWidget);
    expect(find.text('作品カタログ'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
