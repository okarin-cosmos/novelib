import 'package:chronovel/app.dart';
import 'package:chronovel/features/library/library_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('主要画面をショートカットで移動し詳細からEscで戻る', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ChronovelApp());
    await tester.pump();

    Future<void> control(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
    }

    bool selected(String title) => tester
        .widgetList<SidebarItem>(find.byType(SidebarItem))
        .singleWhere((item) => item.title == title)
        .selected;

    await control(LogicalKeyboardKey.digit2);
    expect(selected('プレイ状況'), isTrue);
    await control(LogicalKeyboardKey.digit3);
    expect(selected('評価ランキング'), isTrue);
    await control(LogicalKeyboardKey.digit4);
    expect(selected('統計'), isTrue);
    await control(LogicalKeyboardKey.digit5);
    expect(selected('ウィッシュリスト'), isTrue);
    await control(LogicalKeyboardKey.digit6);
    expect(selected('設定'), isTrue);
    await tester.tap(find.byTooltip('ホーム（ライブラリ）へ戻る'));
    await tester.pump();
    expect(selected('ライブラリ'), isTrue);
    await control(LogicalKeyboardKey.comma);
    expect(selected('設定'), isTrue);
    await control(LogicalKeyboardKey.digit1);
    expect(selected('ライブラリ'), isTrue);

    await tester.tap(find.byType(GameGridCard).first);
    await tester.pump();
    expect(find.text('作品詳細'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('作品詳細'), findsNothing);
    expect(selected('ライブラリ'), isTrue);
  });

  testWidgets('サイドバーは選択状態と件数を読み上げられる', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const ChronovelApp());
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(r'^ライブラリ、\d+件$')), findsOneWidget);
    semantics.dispose();
  });
}
