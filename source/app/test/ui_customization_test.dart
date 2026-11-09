import 'package:chronovel/app.dart';
import 'package:chronovel/features/library/library_page.dart';
import 'package:chronovel/models/game.dart';
import 'package:chronovel/widgets/cover_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

GameEntry _game(String id, String title) => GameEntry(
  id: id,
  title: title,
  brand: 'テストブランド',
  status: GameStatus.notPlayed,
  playHours: 0,
  routeCurrent: 0,
  routeTotal: 0,
  coverColors: const [Color(0xFF4B82C3), Color(0xFF16243A)],
);

void main() {
  testWidgets('表紙ぼかしは設定が有効な場合だけ適用する', (tester) async {
    Future<void> pump(bool enabled, {bool? override}) => tester.pumpWidget(
      MaterialApp(
        home: CoverPrivacy(
          blurEnabled: enabled,
          child: CoverPrivacyFilter(
            blurOverride: override,
            child: const SizedBox.square(dimension: 40),
          ),
        ),
      ),
    );

    await pump(false);
    expect(find.byType(ImageFiltered), findsNothing);
    await pump(true);
    expect(find.byType(ImageFiltered), findsOneWidget);
    await pump(true, override: false);
    expect(find.byType(ImageFiltered), findsNothing);
    await pump(false, override: true);
    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('初期状態はダークで設定からライトへ変更できる', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChronovelApp());
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('ライト'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('ライト'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ライト'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
  });

  testWidgets('表紙・リスト・本棚を切り替えられる', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LibraryViewMode? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [_game('1', 'あかつき'), _game('2', '星の物語')],
            onStatusChanged: (_, _) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (_) async => 0,
            onGameOpened: (_) {},
            onViewModeChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('背表紙の本棚'));
    await tester.pumpAndSettle();
    expect(changed, LibraryViewMode.shelf);
    expect(find.byType(BookSpineCard), findsNWidgets(2));
    await tester.tap(find.byTooltip('リスト'));
    await tester.pumpAndSettle();
    expect(changed, LibraryViewMode.list);
    expect(find.byType(GameListCard), findsNWidgets(2));
  });

  testWidgets('作品をドラッグすると手動順として並び替える', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    List<String>? reordered;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [_game('1', '一冊目'), _game('2', '二冊目'), _game('3', '三冊目')],
            onStatusChanged: (_, _) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (_) async => 0,
            onGameOpened: (_) {},
            onGamesReordered: (ids) => reordered = ids,
          ),
        ),
      ),
    );

    final draggables = find.byType(Draggable<String>);
    expect(draggables, findsNWidgets(3));
    await tester.drag(
      draggables.first,
      tester.getCenter(draggables.last) - tester.getCenter(draggables.first),
    );
    await tester.pumpAndSettle();
    expect(reordered, ['2', '3', '1']);
    await tester.tap(find.byTooltip('背表紙の本棚'));
    await tester.pumpAndSettle();
    expect(find.byType(BookSpineCard), findsNWidgets(3));
  });

  testWidgets('ドラッグ中は作品カードを持ち上げたプレビューを表示する', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [_game('1', '持ち上げる作品'), _game('2', '移動先の作品')],
            onStatusChanged: (_, _) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (_) async => 0,
            onGameOpened: (_) {},
            onGamesReordered: (_) {},
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Draggable<String>).first),
    );
    await gesture.moveBy(const Offset(50, 30));
    await tester.pump();
    expect(find.byType(GameDragPreview), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(GameDragPreview), findsNothing);
  });

  testWidgets('本棚では棚背景上の自由な位置へ作品を移動できる', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Map<String, ShelfPlacement>? placements;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [_game('1', '自由配置する作品'), _game('2', '別の作品')],
            onStatusChanged: (_, _) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (_) async => 0,
            onGameOpened: (_) {},
            initialViewMode: LibraryViewMode.shelf,
            onShelfPlacementsChanged: (value) => placements = value,
          ),
        ),
      ),
    );

    expect(find.byType(ShelfBackgroundPainter), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is ShelfBackgroundPainter,
      ),
      findsOneWidget,
    );
    final first = find.byType(Draggable<String>).first;
    await tester.drag(first, const Offset(360, 250));
    await tester.pumpAndSettle();

    expect(placements, isNotNull);
    expect(placements, contains('1'));
    expect(placements!['1']!.x, inInclusiveRange(0.0, 1.0));
    expect(placements!['1']!.row, greaterThanOrEqualTo(0));
  });

  testWidgets('本棚の段数を自動または指定段数へ変更できる', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? changedRows;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryPage(
            games: [_game('1', '棚の作品')],
            onStatusChanged: (_, _) {},
            onDeleteRequested: (_) async {},
            onDeleteManyRequested: (_) async => 0,
            onGameOpened: (_) {},
            initialViewMode: LibraryViewMode.shelf,
            onShelfRowsChanged: (value) => changedRows = value,
          ),
        ),
      ),
    );

    expect(find.text('棚の段数'), findsOneWidget);
    await tester.tap(find.text('自動'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 段').last);
    await tester.pumpAndSettle();
    expect(changedRows, 3);
    expect(find.text('3 段'), findsOneWidget);
  });
}
