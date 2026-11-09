import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/features/library/library_page.dart';

import 'library_sort_test.dart' show game;

void main() {
  testWidgets('狭いライブラリで検索と選択操作が収まる', (tester) async {
    tester.view.physicalSize = const Size(774, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [game('1', 'テスト作品')],
            onStatusChanged: (_, _) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (_) async => 0,
            onGameOpened: (_) {},
            onScanRequested: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
    await tester.enterText(find.byType(TextField), '検索');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.tap(find.text('選択'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('まとめて削除'), findsNothing);
  });

  testWidgets('作品カードはEnterで開きSpaceで選択する', (tester) async {
    var opened = 0;
    var selected = 0;
    var selection = false;
    Widget build() => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 220,
          height: 390,
          child: GameGridCard(
            game: game('1', 'テスト作品'),
            onStatusChanged: (_, _) {},
            onDeleteRequested: (_) async {},
            selectionMode: selection,
            isSelected: false,
            onSelected: () => selected++,
            onOpened: () => opened++,
          ),
        ),
      ),
    );
    await tester.pumpWidget(build());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, 1);
    selection = true;
    await tester.pumpWidget(build());
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(selected, 1);
    expect(opened, 1);
  });
}
