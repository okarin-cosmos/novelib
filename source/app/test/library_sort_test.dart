import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/models/game.dart';
import 'package:chronovel/models/library_sort.dart';
import 'package:chronovel/features/library/library_page.dart';

GameEntry game(
  String id,
  String title, {
  String? romaji,
  String brand = 'ブランド',
  int? rating,
  double hours = 0,
  String? released,
}) => GameEntry(
  id: id,
  title: title,
  brand: brand,
  titleRomaji: romaji,
  rating: rating,
  playHours: hours,
  released: released,
  status: GameStatus.notPlayed,
  routeCurrent: 0,
  routeTotal: 0,
  coverColors: const [Colors.blue, Colors.black],
);

void main() {
  test('かな・カタカナ・漢字の推定読みで並び、不明な読みは末尾', () {
    final games = [
      game('1', '星の物語', romaji: 'Hoshi no Monogatari'),
      game('2', 'アオナツライン'),
      game('3', 'あかつき'),
      game('4', '漢字のみ'),
    ];
    expect(sortLibraryGames(games, LibrarySort.reading).map((g) => g.id), [
      '2',
      '3',
      '1',
      '4',
    ]);
    expect(games.first.id, '1');
    expect(libraryReadingKey(game('5', 'がくえん')), startsWith('0かくえん'));
  });
  test('ブランド、評価、時間、発売日と逆順、不明値の末尾配置', () {
    final games = [
      game('1', 'い', brand: 'B', rating: 4, hours: 2, released: '2020-01-01'),
      game('2', 'あ', brand: 'A', rating: 9, hours: 4, released: '2024-01-01'),
      game('3', 'う', brand: 'ローカル作品'),
    ];
    for (final sort in [
      LibrarySort.brand,
      LibrarySort.rating,
      LibrarySort.playTime,
      LibrarySort.released,
    ]) {
      expect(sortLibraryGames(games, sort).map((g) => g.id), ['2', '1', '3']);
    }
    expect(
      sortLibraryGames(
        games,
        LibrarySort.rating,
        reversed: true,
      ).map((g) => g.id),
      ['1', '2', '3'],
    );
    expect(sortLibraryGames(games, LibrarySort.original).map((g) => g.id), [
      '1',
      '2',
      '3',
    ]);
  });
  testWidgets('並び替えと反転が画面に反映され、選択したIDを維持する', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Set<String>? deleted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [game('1', 'い'), game('2', 'あ')],
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
    await tester.tap(find.byType(GameGridCard).first);
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<LibrarySort>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LibrarySort.reading.label).last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<GameGridCard>(find.byType(GameGridCard).first).game.id,
      '2',
    );
    expect(
      tester.widget<GameGridCard>(find.byType(GameGridCard).last).isSelected,
      isTrue,
    );
    await tester.tap(find.byTooltip('並び順を反転'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<GameGridCard>(find.byType(GameGridCard).first).game.id,
      '1',
    );
    await tester.tap(find.text('まとめて削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'まとめて削除').last);
    await tester.pumpAndSettle();
    expect(deleted, {'1'});
  });
}
