import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/models/game.dart';
import 'package:chronovel/features/library/library_page.dart';
import 'package:chronovel/features/library/game_detail_page.dart';

GameEntry entry(
  String id,
  String? catalog, {
  String title = '同じ作品',
  double hours = 1,
  int rating = 8,
  GameStatus status = GameStatus.notPlayed,
}) => GameEntry(
  id: id,
  title: title,
  brand: 'ブランド',
  status: status,
  playHours: hours,
  routeCurrent: 0,
  routeTotal: 0,
  coverColors: const [Colors.blue, Colors.black],
  vndbId: catalog,
  rating: rating,
  installDir: 'D:/games/$id',
  exePath: 'D:/games/$id/game.exe',
);

void main() {
  testWidgets('全選択・全解除と検索変更での解除、表示中だけの削除', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Set<String>? deleted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [
              entry('1', 'v1', title: '対象作品'),
              entry('2', 'v1', title: '対象作品'),
              entry('3', 'v3', title: '別作品'),
            ],
            onStatusChanged: (_, status) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (ids) async {
              deleted = ids;
              return ids.length;
            },
            onGameOpened: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('選択'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('表示中を全選択'));
    await tester.pump();
    expect(find.text('3 本選択'), findsOneWidget);
    await tester.tap(find.text('全解除'));
    await tester.pump();
    expect(find.text('0 本選択'), findsOneWidget);
    await tester.tap(find.textContaining('表示中を全選択'));
    await tester.enterText(find.byType(TextField), '対象');
    await tester.pump();
    expect(find.text('0 本選択'), findsOneWidget);
    expect(find.byType(GameGridCard), findsNWidgets(2));
    await tester.tap(find.textContaining('表示中を全選択'));
    await tester.pump();
    expect(find.text('2 本選択'), findsOneWidget);
    await tester.tap(find.text('まとめて削除'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('キャンセル'),
      ),
    );
    await tester.pumpAndSettle();
    expect(deleted, isNull);
    await tester.tap(find.text('まとめて削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'まとめて削除').last);
    await tester.pumpAndSettle();
    expect(deleted, {'1', '2'});
  });
  test('同じ有効なカタログIDだけをまとめ元の評価・状態・時間を保持する', () {
    final a = entry('1', 'v1', hours: 2, rating: 7);
    final b = entry('2', 'v1', hours: 3, rating: 9, status: GameStatus.playing);
    final grouped = groupLibraryGames([
      b,
      a,
      entry('3', 'v2'),
      entry('4', null),
      entry('5', null),
      entry('6', ''),
    ]);
    expect(grouped, hasLength(5));
    final group = grouped.first;
    expect(group.id, '1');
    expect(group.playHours, 5);
    expect(group.rating, isNull);
    expect(group.members.map((e) => e.rating), [7, 9]);
    expect(group.members.last.status, GameStatus.playing);
    expect(a.playHours, 2);
    expect(a.installations, isEmpty);
    expect(groupLibraryGames([a, b]).single.id, group.id);
  });

  testWidgets('選択時は登録先別に表示し選択した登録だけ削除する', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Set<String>? deleted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [entry('1', 'v1'), entry('2', 'v1')],
            onStatusChanged: (_, status) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (ids) async {
              deleted = ids;
              return ids.length;
            },
            onGameOpened: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(GameGridCard), findsOneWidget);
    expect(find.text('合計 2.0h · 登録先 2 件'), findsOneWidget);
    await tester.tap(find.text('選択'));
    await tester.pumpAndSettle();
    expect(find.byType(GameGridCard), findsNWidgets(2));
    expect(find.text('D:/games/2'), findsOneWidget);
    await tester.tap(find.byType(GameGridCard).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('まとめて削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'まとめて削除').last);
    await tester.pumpAndSettle();
    expect(deleted, {'2'});
  });

  testWidgets('別登録の名前でも検索でき合計時間を維持する', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [
              entry('1', 'v1'),
              entry('2', 'v1', title: '別名'),
            ],
            onStatusChanged: (_, status) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (_) async => 0,
            onGameOpened: (_) {},
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '別名');
    await tester.pump();
    expect(find.byType(GameGridCard), findsOneWidget);
    expect(find.text('合計 2.0h · 登録先 2 件'), findsOneWidget);
  });

  testWidgets('登録先の切り替えで評価と起動先が切り替わる', (tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final installs = [entry('1', 'v1', rating: 7), entry('2', 'v1', rating: 9)];
    var selected = installs.first;
    String? launched, rated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => GameDetailPage(
              game: selected,
              installations: installs,
              onInstallationSelected: (id) => setState(
                () => selected = installs.firstWhere((e) => e.id == id),
              ),
              onBack: () {},
              onStatusChanged: (_, status) {},
              onRatingChanged: (id, rating) => rated = id,
              onMetadataChanged: (_) async {},
              onLaunchRequested: (id) => launched = id,
              isRunning: false,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('D:/games/2 ·').last);
    await tester.pumpAndSettle();
    expect(find.text('9 / 10'), findsWidgets);
    await tester.tap(find.text('ゲームを起動'));
    expect(launched, '2');
    await tester.tap(find.text('評価を解除'));
    expect(rated, '2');
  });
}
