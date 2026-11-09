import 'package:chronovel/features/library/library_page.dart';
import 'package:chronovel/models/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('5000作品でも表示範囲のカードだけを生成して検索できる', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final games = List.generate(
      5000,
      (index) => GameEntry(
        id: '${index + 1}',
        title: '作品${index + 1}',
        brand: 'ブランド${index % 20}',
        status: index.isEven ? GameStatus.notPlayed : GameStatus.playing,
        playHours: index / 10,
        routeCurrent: 0,
        routeTotal: 0,
        coverColors: const [Colors.blue, Colors.black],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: games,
            onStatusChanged: (_, _) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (_) async => 0,
            onGameOpened: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GameGridCard).evaluate().length, lessThan(100));
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), '作品4999');
    await tester.pumpAndSettle();
    expect(find.byType(GameGridCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GameGridCard),
        matching: find.text('作品4999'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
