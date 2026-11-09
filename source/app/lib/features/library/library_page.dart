import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/game.dart';
import '../../models/library_sort.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cover_image.dart';

enum LibraryViewMode {
  grid('表紙'),
  list('リスト'),
  shelf('本棚');

  const LibraryViewMode(this.label);
  final String label;
}

@immutable
class ShelfPlacement {
  const ShelfPlacement({required this.x, required this.row});

  final double x;
  final int row;

  Map<String, Object> toJson() => {'x': x, 'row': row};

  static ShelfPlacement? fromJson(Object? value) {
    if (value is! Map) return null;
    final x = value['x'];
    final row = value['row'];
    if (x is! num || row is! num) return null;
    return ShelfPlacement(
      x: x.toDouble().clamp(0.0, 1.0),
      row: row.toInt().clamp(0, 99),
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.games,
    required this.onStatusChanged,
    required this.onDeleteRequested,
    required this.onDeleteManyRequested,
    required this.onGameOpened,
    this.onScanRequested,
    this.onReviewImages,
    this.isScanning = false,
    this.initialFilter,
    this.onFilterChanged,
    this.initialViewMode = LibraryViewMode.grid,
    this.onViewModeChanged,
    this.onGamesReordered,
    this.initialShelfPlacements = const {},
    this.onShelfPlacementsChanged,
    this.initialShelfRows,
    this.onShelfRowsChanged,
  });

  final List<GameEntry> games;
  final void Function(String gameId, GameStatus status) onStatusChanged;
  final Future<void> Function(String gameId) onDeleteRequested;
  final Future<int> Function(Set<String> gameIds) onDeleteManyRequested;
  final ValueChanged<String> onGameOpened;
  final VoidCallback? onScanRequested;
  final VoidCallback? onReviewImages;
  final bool isScanning;
  final GameStatus? initialFilter;
  final ValueChanged<GameStatus?>? onFilterChanged;
  final LibraryViewMode initialViewMode;
  final ValueChanged<LibraryViewMode>? onViewModeChanged;
  final ValueChanged<List<String>>? onGamesReordered;
  final Map<String, ShelfPlacement> initialShelfPlacements;
  final ValueChanged<Map<String, ShelfPlacement>>? onShelfPlacementsChanged;
  final int? initialShelfRows;
  final ValueChanged<int?>? onShelfRowsChanged;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _libraryFocus = FocusNode();
  GameStatus? _filter;
  late LibraryViewMode _viewMode;
  bool _selectionMode = false;
  bool _deleting = false;
  LibrarySort _sort = LibrarySort.original;
  bool _sortReversed = false;
  bool _sortRestored = false;
  final Set<String> _selectedIds = {};
  List<GameEntry>? _groupedCache;
  Map<GameStatus, int>? _statusCountCache;
  bool? _statusCountSelectionMode;
  int? _unmatchedCountCache;
  List<GameEntry>? _visibleCache;
  String? _visibleQuery;
  GameStatus? _visibleFilter;
  LibrarySort? _visibleSort;
  bool? _visibleSortReversed;
  bool? _visibleSelectionMode;
  String? _dragSourceId;
  String? _dropTargetId;
  late Map<String, ShelfPlacement> _shelfPlacements;
  late int? _shelfRows;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _viewMode = widget.initialViewMode;
    _shelfPlacements = Map.of(widget.initialShelfPlacements);
    _shelfRows = widget.initialShelfRows;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sortRestored) return;
    _sortRestored = true;
    final saved = PageStorage.maybeOf(context)
        ?.readState(context, identifier: 'library-sort');
    if (saved is (LibrarySort, bool)) {
      _sort = saved.$1;
      _sortReversed = saved.$2;
    }
  }

  void _saveSort() => PageStorage.maybeOf(context)
      ?.writeState(context, (_sort, _sortReversed), identifier: 'library-sort');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _libraryFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _filter = widget.initialFilter;
    }
    if (oldWidget.initialViewMode != widget.initialViewMode) {
      _viewMode = widget.initialViewMode;
    }
    if (!identical(
      oldWidget.initialShelfPlacements,
      widget.initialShelfPlacements,
    )) {
      _shelfPlacements = Map.of(widget.initialShelfPlacements);
    }
    if (oldWidget.initialShelfRows != widget.initialShelfRows) {
      _shelfRows = widget.initialShelfRows;
    }
    _groupedCache = null;
    _statusCountCache = null;
    _unmatchedCountCache = null;
    _visibleCache = null;
    final existingIds = widget.games.map((game) => game.id).toSet();
    _selectedIds.removeWhere((id) => !existingIds.contains(id));
  }

  void _setViewMode(LibraryViewMode value) {
    if (_dragSourceId != null) return;
    setState(() => _viewMode = value);
    widget.onViewModeChanged?.call(value);
  }

  void _moveGame(String sourceId, String targetId) {
    if (sourceId == targetId || _selectionMode) return;
    final ordered = _visibleGames.map((game) => game.id).toList();
    final oldIndex = ordered.indexOf(sourceId);
    final targetIndex = ordered.indexOf(targetId);
    if (oldIndex < 0 || targetIndex < 0) return;
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(targetIndex, moved);
    setState(() {
      _sort = LibrarySort.original;
      _sortReversed = false;
      _visibleCache = null;
      _saveSort();
    });
    widget.onGamesReordered?.call(ordered);
  }

  void _finishDrag() {
    final sourceId = _dragSourceId;
    final targetId = _dropTargetId;
    _dragSourceId = null;
    _dropTargetId = null;
    if (sourceId == null || targetId == null || sourceId == targetId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _moveGame(sourceId, targetId);
    });
  }

  void _moveShelfGame(String gameId, ShelfPlacement placement) {
    setState(() => _shelfPlacements[gameId] = placement);
    widget.onShelfPlacementsChanged?.call(Map.unmodifiable(_shelfPlacements));
  }

  void _setShelfRows(int? rows) {
    setState(() => _shelfRows = rows);
    widget.onShelfRowsChanged?.call(rows);
  }

  void _setSelectionMode(bool enabled) {
    if (_deleting) return;
    _libraryFocus.requestFocus();
    setState(() {
      _selectionMode = enabled;
      if (!enabled) _selectedIds.clear();
    });
  }

  void _toggleSelection(String gameId) {
    if (_deleting) return;
    setState(() {
      if (!_selectedIds.add(gameId)) {
        _selectedIds.remove(gameId);
      }
    });
  }

  Future<void> _confirmSelectedDeletion() async {
    if (_selectedIds.isEmpty || _deleting || widget.isScanning) return;
    final selected = Set<String>.of(_selectedIds);
    final count = selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$count 本をライブラリから削除しますか？'),
        content: const Text(
          '選択した作品の登録情報・プレイ履歴・タグ・攻略メモ・予定をNoveLibから削除します。\n\n'
          'ゲーム本体やインストールフォルダは削除されません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('まとめて削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.onDeleteManyRequested(selected);
      if (mounted) {
        setState(() {
          _selectionMode = false;
          _selectedIds.clear();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('削除できませんでした。ゲーム起動・スキャンの終了を確認して再度お試しください。'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  List<GameEntry> get _visibleGames {
    final query = _searchController.text.trim().toLowerCase();
    if (_visibleCache != null &&
        _visibleQuery == query &&
        _visibleFilter == _filter &&
        _visibleSort == _sort &&
        _visibleSortReversed == _sortReversed &&
        _visibleSelectionMode == _selectionMode) {
      return _visibleCache!;
    }
    final entries = _selectionMode ? widget.games : _groupedGames;
    _visibleQuery = query;
    _visibleFilter = _filter;
    _visibleSort = _sort;
    _visibleSortReversed = _sortReversed;
    _visibleSelectionMode = _selectionMode;
    return _visibleCache = sortLibraryGames(
      entries
          .where(
            (entry) => entry.members.any((game) {
              final matchesStatus = _filter == null || game.status == _filter;
              final matchesQuery =
                  query.isEmpty ||
                  game.title.toLowerCase().contains(query) ||
                  game.brand.toLowerCase().contains(query) ||
                  game.tags.any((tag) => tag.toLowerCase().contains(query));
              return matchesStatus && matchesQuery;
            }),
          )
          .toList(),
      _sort,
      reversed: _sortReversed,
    );
  }

  List<GameEntry> get _groupedGames =>
      _groupedCache ??= groupLibraryGames(widget.games);

  int get _unmatchedCount => _unmatchedCountCache ??= widget.games
      .where((game) => game.vndbId == null)
      .length;

  int _count(GameStatus status) {
    if (_statusCountCache == null ||
        _statusCountSelectionMode != _selectionMode) {
      _statusCountSelectionMode = _selectionMode;
      final entries = _selectionMode ? widget.games : _groupedGames;
      _statusCountCache = {
        for (final value in GameStatus.values)
          value: entries
              .where(
                (game) => game.members.any((member) => member.status == value),
              )
              .length,
      };
    }
    return _statusCountCache![status] ?? 0;
  }

  Widget _draggableGame(
    GameEntry game,
    Widget child, {
    double feedbackWidth = 190,
  }) {
    if (_selectionMode || widget.onGamesReordered == null) return child;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != game.id,
      onMove: (details) => _dropTargetId = game.id,
      onLeave: (_) {
        if (_dropTargetId == game.id) _dropTargetId = null;
      },
      onAcceptWithDetails: (_) => _dropTargetId = game.id,
      builder: (context, candidates, rejected) => AnimatedContainer(
        key: ValueKey('reorder-${game.id}'),
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: candidates.isEmpty
              ? null
              : Border.all(color: AppColors.accent, width: 2),
        ),
        child: Draggable<String>(
          data: game.id,
          onDragStarted: () {
            _dragSourceId = game.id;
            _dropTargetId = null;
          },
          onDragEnd: (_) => _finishDrag(),
          feedback: Material(
            color: Colors.transparent,
            child: IgnorePointer(
              child: GameDragPreview(
                game: game,
                viewMode: _viewMode,
                width: feedbackWidth,
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: .28, child: child),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLibraryContent(List<GameEntry> games) => switch (_viewMode) {
    LibraryViewMode.grid => GridView.builder(
      padding: const EdgeInsets.all(30),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 390,
        crossAxisSpacing: 20,
        mainAxisSpacing: 24,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _draggableGame(
          game,
          GameGridCard(
            game: game,
            onStatusChanged: widget.onStatusChanged,
            onDeleteRequested: widget.onDeleteRequested,
            selectionMode: _selectionMode,
            isSelected: _selectedIds.contains(game.id),
            onSelected: () => _toggleSelection(game.id),
            onOpened: () => widget.onGameOpened(game.id),
          ),
        );
      },
    ),
    LibraryViewMode.list => ListView.separated(
      padding: const EdgeInsets.all(30),
      itemCount: games.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final game = games[index];
        return _draggableGame(
          game,
          GameListCard(
            game: game,
            onStatusChanged: widget.onStatusChanged,
            onDeleteRequested: widget.onDeleteRequested,
            selectionMode: _selectionMode,
            isSelected: _selectedIds.contains(game.id),
            onSelected: () => _toggleSelection(game.id),
            onOpened: () => widget.onGameOpened(game.id),
          ),
          feedbackWidth: 520,
        );
      },
    ),
    LibraryViewMode.shelf => LibraryShelfView(
      games: games,
      placements: _shelfPlacements,
      preferredRows: _shelfRows,
      onPlacementChanged: _moveShelfGame,
      onStatusChanged: widget.onStatusChanged,
      onDeleteRequested: widget.onDeleteRequested,
      onGameOpened: widget.onGameOpened,
      onDragStarted: (id) => _dragSourceId = id,
      onDragEnded: () => _dragSourceId = null,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final visibleGames = _visibleGames;
    final groupedGames = _groupedGames;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          if (!_deleting) _searchFocus.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_deleting) return;
          if (_selectionMode) {
            _setSelectionMode(false);
          } else {
            setState(() {
              _searchController.clear();
              _selectedIds.clear();
            });
            _libraryFocus.requestFocus();
          }
        },
      },
      child: Focus(
        focusNode: _libraryFocus,
        autofocus: true,
        child: ColoredBox(
          color: context.appColors.canvas,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(30, 26, 30, 22),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: context.appColors.border),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LibraryToolbar(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ライブラリ',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge,
                              ),
                              const SizedBox(height: 5),
                              if (groupedGames.length != widget.games.length)
                                Text(
                                  _selectionMode
                                      ? '削除対象は登録先ごとに表示（${widget.games.length} 件）'
                                      : '同じ作品を統合表示・状態の件数は重複あり',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              Text(
                                '全 ${groupedGames.length} 本 · プレイ中 ${_count(GameStatus.playing)} · 未プレイ ${_count(GameStatus.notPlayed)}',
                                style: TextStyle(
                                  color: context.appColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 310,
                          child: TextField(
                            enabled: !_deleting,
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onChanged: (_) => setState(_selectedIds.clear),
                            decoration: InputDecoration(
                              hintText: 'タイトル・ブランド・タグで検索',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 19,
                              ),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () => setState(() {
                                        _searchController.clear();
                                        _selectedIds.clear();
                                      }),
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 17,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_selectionMode) ...[
                          Text(
                            '${_selectedIds.length} 本選択',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () => _setSelectionMode(false),
                            child: const Text('キャンセル'),
                          ),
                          const SizedBox(width: 6),
                          FilledButton.icon(
                            onPressed:
                                _selectedIds.isEmpty ||
                                    _deleting ||
                                    widget.isScanning
                                ? null
                                : _confirmSelectedDeletion,
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                            ),
                            label: const Text('まとめて削除'),
                          ),
                          const SizedBox(width: 12),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: widget.games.isEmpty
                                ? null
                                : () => _setSelectionMode(true),
                            icon: const Icon(Icons.checklist_rounded, size: 17),
                            label: const Text('選択'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (widget.onScanRequested != null) ...[
                          FilledButton.icon(
                            onPressed: widget.isScanning
                                ? null
                                : widget.onScanRequested,
                            icon: widget.isScanning
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_rounded, size: 18),
                            label: const Text('作品を登録'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        ViewToggle(
                          viewMode: _viewMode,
                          onChanged: _setViewMode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChipButton(
                          label: 'すべて',
                          count: _selectionMode
                              ? widget.games.length
                              : groupedGames.length,
                          selected: _filter == null,
                          onTap: () {
                            if (!_deleting) {
                              setState(() {
                                _filter = null;
                                _selectedIds.clear();
                              });
                              widget.onFilterChanged?.call(null);
                            }
                          },
                        ),
                        for (final status in GameStatus.values)
                          FilterChipButton(
                            label: status.label,
                            count: _count(status),
                            selected: _filter == status,
                            onTap: () {
                              if (!_deleting) {
                                setState(() {
                                  _filter = status;
                                  _selectedIds.clear();
                                });
                                widget.onFilterChanged?.call(status);
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('並び替え'),
                        DropdownButton<LibrarySort>(
                          value: _sort,
                          items: [
                            for (final value in LibrarySort.values)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value.label),
                              ),
                          ],
                          onChanged: _deleting
                              ? null
                              : (value) => setState(() {
                                  _sort = value!;
                                  _sortReversed = false;
                                  _saveSort();
                                }),
                        ),
                        IconButton(
                          tooltip: _sortReversed ? '標準の向きに戻す' : '並び順を反転',
                          onPressed: _deleting
                              ? null
                              : () => setState(() {
                                  _sortReversed = !_sortReversed;
                                  _saveSort();
                                }),
                          icon: Icon(
                            _sortReversed
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                        ),
                        Text(
                          'カタログ未照合 $_unmatchedCount 件',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appColors.textMuted,
                          ),
                        ),
                        if (widget.onReviewImages != null)
                          TextButton(
                            onPressed: widget.onReviewImages,
                            child: const Text('画像・照合を確認'),
                          ),
                        if (_viewMode == LibraryViewMode.shelf)
                          ShelfRowsControl(
                            value: _shelfRows,
                            onChanged: _setShelfRows,
                          ),
                      ],
                    ),
                    if (_selectionMode) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: _deleting || visibleGames.isEmpty
                                ? null
                                : () => setState(() {
                                    _selectedIds
                                      ..clear()
                                      ..addAll(
                                        visibleGames.map((game) => game.id),
                                      );
                                  }),
                            icon: const Icon(Icons.select_all),
                            label: Text('表示中を全選択（${visibleGames.length} 件）'),
                          ),
                          TextButton(
                            onPressed: _deleting || _selectedIds.isEmpty
                                ? null
                                : () => setState(_selectedIds.clear),
                            child: const Text('全解除'),
                          ),
                          Text(
                            '検索・状態の変更で選択を解除します',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.appColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: visibleGames.isEmpty
                    ? EmptyLibraryResult(
                        filtered:
                            _filter != null ||
                            _searchController.text.isNotEmpty,
                        canScan: widget.onScanRequested != null,
                        isScanning: widget.isScanning,
                        onScan: widget.onScanRequested,
                      )
                    : _buildLibraryContent(visibleGames),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preserve the desktop row; wrap controls when space is limited.
class _LibraryToolbar extends StatelessWidget {
  const _LibraryToolbar({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= 1050) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: children,
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final child in children)
            if (child is Expanded)
              SizedBox(width: constraints.maxWidth, child: child.child)
            else if (child is! SizedBox || child.child != null)
              child,
        ],
      );
    },
  );
}

class ViewToggle extends StatelessWidget {
  const ViewToggle({
    super.key,
    required this.viewMode,
    required this.onChanged,
  });
  final LibraryViewMode viewMode;
  final ValueChanged<LibraryViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.appColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.border),
      ),
      child: Row(
        children: [
          ToggleIcon(
            icon: Icons.grid_view_rounded,
            selected: viewMode == LibraryViewMode.grid,
            tooltip: '表紙表示',
            onTap: () => onChanged(LibraryViewMode.grid),
          ),
          ToggleIcon(
            icon: Icons.view_list_rounded,
            selected: viewMode == LibraryViewMode.list,
            tooltip: 'リスト',
            onTap: () => onChanged(LibraryViewMode.list),
          ),
          ToggleIcon(
            icon: Icons.view_week_outlined,
            selected: viewMode == LibraryViewMode.shelf,
            tooltip: '背表紙の本棚',
            onTap: () => onChanged(LibraryViewMode.shelf),
          ),
        ],
      ),
    );
  }
}

class ToggleIcon extends StatelessWidget {
  const ToggleIcon({
    super.key,
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 38,
          height: 36,
          decoration: BoxDecoration(
            color: selected ? context.appColors.selected : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected
                ? context.appColors.text
                : context.appColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? context.appColors.selected : context.appColors.panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.accentWarm : context.appColors.border,
            ),
          ),
          child: Text(
            '$label  $count',
            style: TextStyle(
              color: selected
                  ? context.appColors.text
                  : context.appColors.textMuted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class GameDragPreview extends StatelessWidget {
  const GameDragPreview({
    super.key,
    required this.game,
    required this.viewMode,
    required this.width,
  });

  final GameEntry game;
  final LibraryViewMode viewMode;
  final double width;

  Widget _artwork(BuildContext context) {
    if (game.localCoverPath != null) {
      return CoverPrivacyFilter(
        blurOverride: game.coverBlurOverride,
        child: Image.file(
          File(game.localCoverPath!),
          fit: BoxFit.cover,
          cacheWidth: 360,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    if (game.vndbId != null && game.coverImageUrl != null) {
      return CachedCoverImage(
        vndbId: game.vndbId!,
        imageUrl: game.coverImageUrl!,
        cacheWidth: 360,
        blurOverride: game.coverBlurOverride,
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isList = viewMode == LibraryViewMode.list;
    final isShelf = viewMode == LibraryViewMode.shelf;
    final height = isShelf ? 270.0 : (isList ? 86.0 : 292.0);
    return Transform.rotate(
      angle: isList ? -.008 : -.025,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: game.coverColors),
          borderRadius: BorderRadius.circular(isShelf ? 5 : 11),
          border: Border.all(color: AppColors.accent, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 22,
              offset: Offset(7, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: isList
            ? Row(
                children: [
                  SizedBox(width: 64, height: height, child: _artwork(context)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            game.brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  _artwork(context),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x22000000),
                          Colors.transparent,
                          Color(0xCC000000),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isShelf ? 7 : 12,
                      18,
                      isShelf ? 7 : 12,
                      18,
                    ),
                    child: Align(
                      alignment: isShelf
                          ? Alignment.topCenter
                          : Alignment.bottomLeft,
                      child: Text(
                        isShelf
                            ? game.title.characters.take(15).join('\n')
                            : game.title,
                        maxLines: isShelf ? 15 : 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isShelf ? TextAlign.center : TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          height: 1.05,
                          fontSize: isShelf ? 13 : 15,
                          fontWeight: FontWeight.w800,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ShelfRowsControl extends StatelessWidget {
  const ShelfRowsControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.shelves, size: 17),
      const SizedBox(width: 7),
      const Text('棚の段数'),
      const SizedBox(width: 8),
      DropdownButton<int?>(
        value: value,
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('自動')),
          for (var rows = 1; rows <= 12; rows++)
            DropdownMenuItem<int?>(value: rows, child: Text('$rows 段')),
        ],
        onChanged: onChanged,
      ),
    ],
  );
}

class LibraryShelfView extends StatefulWidget {
  const LibraryShelfView({
    super.key,
    required this.games,
    required this.placements,
    required this.preferredRows,
    required this.onPlacementChanged,
    required this.onStatusChanged,
    required this.onDeleteRequested,
    required this.onGameOpened,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  final List<GameEntry> games;
  final Map<String, ShelfPlacement> placements;
  final int? preferredRows;
  final void Function(String, ShelfPlacement) onPlacementChanged;
  final void Function(String, GameStatus) onStatusChanged;
  final Future<void> Function(String) onDeleteRequested;
  final ValueChanged<String> onGameOpened;
  final ValueChanged<String> onDragStarted;
  final VoidCallback onDragEnded;

  @override
  State<LibraryShelfView> createState() => _LibraryShelfViewState();
}

class _LibraryShelfViewState extends State<LibraryShelfView> {
  static const _rowHeight = 330.0;
  static const _sidePadding = 34.0;
  final _canvasKey = GlobalKey();

  double _bookWidth(int index) => 58.0 + (index % 4) * 4;
  double _bookHeight(int index) => 246.0 + (index % 4) * 11;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final capacity = ((width - _sidePadding * 2) / 78).floor().clamp(1, 99);
      final requiredRows = (widget.games.length / capacity).ceil();
      final savedRows = widget.placements.values.fold<int>(
        0,
        (value, placement) =>
            placement.row + 1 > value ? placement.row + 1 : value,
      );
      final automaticRows = [
        2,
        requiredRows,
        savedRows,
      ].reduce((value, element) => value > element ? value : element);
      final rows = widget.preferredRows ?? automaticRows;
      final canvasHeight = rows * _rowHeight + 24;

      return SingleChildScrollView(
        child: SizedBox(
          key: _canvasKey,
          width: width,
          height: canvasHeight,
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) =>
                widget.games.any((game) => game.id == details.data),
            onAcceptWithDetails: (details) {
              final box = _canvasKey.currentContext?.findRenderObject();
              if (box is! RenderBox) return;
              final local = box.globalToLocal(details.offset);
              final index = widget.games.indexWhere(
                (game) => game.id == details.data,
              );
              if (index < 0) return;
              final bookWidth = _bookWidth(index);
              final available = width - _sidePadding * 2 - bookWidth;
              final left = local.dx.clamp(
                _sidePadding,
                width - _sidePadding - bookWidth,
              );
              final x = available <= 0
                  ? 0.0
                  : ((left - _sidePadding) / available).clamp(0.0, 1.0);
              final row = (local.dy / _rowHeight).floor().clamp(0, rows - 1);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  widget.onPlacementChanged(
                    details.data,
                    ShelfPlacement(x: x, row: row),
                  );
                }
              });
            },
            builder: (context, candidates, rejected) => CustomPaint(
              painter: ShelfBackgroundPainter(
                rows: rows,
                rowHeight: _rowHeight,
                isDropActive: candidates.isNotEmpty,
                brightness: Theme.of(context).brightness,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var index = 0; index < widget.games.length; index++)
                    _positionedBook(
                      context,
                      widget.games[index],
                      index,
                      capacity,
                      rows,
                      width,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _positionedBook(
    BuildContext context,
    GameEntry game,
    int index,
    int capacity,
    int rows,
    double width,
  ) {
    final bookWidth = _bookWidth(index);
    final bookHeight = _bookHeight(index);
    final saved = widget.placements[game.id];
    final defaultRow = index ~/ capacity;
    final itemsInRow = (widget.games.length - defaultRow * capacity).clamp(
      1,
      capacity,
    );
    final column = index % capacity;
    final groupWidth = itemsInRow * 72.0;
    final defaultLeft = ((width - groupWidth) / 2 + column * 72).clamp(
      _sidePadding,
      width - _sidePadding - bookWidth,
    );
    final available = width - _sidePadding * 2 - bookWidth;
    final left = saved == null
        ? defaultLeft
        : _sidePadding + saved.x * (available < 0 ? 0 : available);
    final row = (saved?.row ?? defaultRow).clamp(0, rows - 1);
    final shelfTop = (row + 1) * _rowHeight - 28;
    final card = BookSpineCard(
      key: ValueKey('shelf-${game.id}'),
      game: game,
      index: index,
      onStatusChanged: widget.onStatusChanged,
      onDeleteRequested: widget.onDeleteRequested,
      onOpened: () => widget.onGameOpened(game.id),
    );

    return Positioned(
      left: left,
      top: shelfTop - bookHeight,
      width: bookWidth,
      height: bookHeight,
      child: Draggable<String>(
        data: game.id,
        onDragStarted: () => widget.onDragStarted(game.id),
        onDragEnd: (_) => widget.onDragEnded(),
        feedback: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            child: GameDragPreview(
              game: game,
              viewMode: LibraryViewMode.shelf,
              width: bookWidth,
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: .18, child: card),
        child: card,
      ),
    );
  }
}

class ShelfBackgroundPainter extends CustomPainter {
  const ShelfBackgroundPainter({
    required this.rows,
    required this.rowHeight,
    required this.isDropActive,
    required this.brightness,
  });

  final int rows;
  final double rowHeight;
  final bool isDropActive;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = brightness == Brightness.dark;
    final back = Paint()
      ..shader = LinearGradient(
        colors: dark
            ? const [Color(0xFF17120F), Color(0xFF292019)]
            : const [Color(0xFFE9D3B6), Color(0xFFD8B88F)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, back);

    final panelLine = Paint()
      ..color = dark ? const Color(0x332A0F05) : const Color(0x33744A2B)
      ..strokeWidth = 2;
    for (var x = 80.0; x < size.width; x += 110) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), panelLine);
    }

    final shadow = Paint()
      ..color = const Color(0x77000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final wood = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB67A42), Color(0xFF75421F), Color(0xFF4E2A14)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 24));
    final highlight = Paint()..color = const Color(0xFFD9A267);
    for (var row = 0; row < rows; row++) {
      final y = (row + 1) * rowHeight - 28;
      canvas.drawRect(Rect.fromLTWH(16, y + 7, size.width - 32, 25), shadow);
      canvas.drawRect(Rect.fromLTWH(13, y, size.width - 26, 24), wood);
      canvas.drawRect(Rect.fromLTWH(13, y, size.width - 26, 2), highlight);
    }
    final frame = Paint()
      ..color = const Color(0xFF5B3219)
      ..strokeWidth = 13;
    canvas.drawLine(const Offset(7, 0), Offset(7, size.height), frame);
    canvas.drawLine(
      Offset(size.width - 7, 0),
      Offset(size.width - 7, size.height),
      frame,
    );
    if (isDropActive) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = AppColors.accent.withValues(alpha: .08),
      );
    }
  }

  @override
  bool shouldRepaint(ShelfBackgroundPainter oldDelegate) =>
      rows != oldDelegate.rows ||
      isDropActive != oldDelegate.isDropActive ||
      brightness != oldDelegate.brightness;
}

class BookSpineCard extends StatelessWidget {
  const BookSpineCard({
    super.key,
    required this.game,
    required this.index,
    required this.onStatusChanged,
    required this.onDeleteRequested,
    required this.onOpened,
  });

  final GameEntry game;
  final int index;
  final void Function(String, GameStatus) onStatusChanged;
  final Future<void> Function(String) onDeleteRequested;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) {
    final title = game.title.characters.take(15).join('\n');
    return Tooltip(
      message: '${game.title}\n棚の好きな位置へドラッグ',
      child: Transform.rotate(
        angle: ((index % 5) - 2) * .003,
        child: Material(
          color: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpened,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GameCover(
                  game: game,
                  compact: true,
                  onStatusChanged: onStatusChanged,
                  onDeleteRequested: onDeleteRequested,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0x99000000),
                        Color(0x20000000),
                        Color(0xAA000000),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(7, 30, 7, 27),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 5,
                  right: 5,
                  bottom: 7,
                  child: Text(
                    game.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GameGridCard extends StatelessWidget {
  const GameGridCard({
    super.key,
    required this.game,
    required this.onStatusChanged,
    required this.onDeleteRequested,
    required this.selectionMode,
    required this.isSelected,
    required this.onSelected,
    required this.onOpened,
  });
  final GameEntry game;
  final void Function(String, GameStatus) onStatusChanged;
  final Future<void> Function(String) onDeleteRequested;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusColor: context.appColors.selected,
        onTap: selectionMode ? onSelected : onOpened,
        onLongPress: selectionMode ? onSelected : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GameCover(
                game: game,
                onStatusChanged: onStatusChanged,
                onDeleteRequested: onDeleteRequested,
                selectionMode: selectionMode,
                isSelected: isSelected,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              game.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 4),
            if (selectionMode && game.installDir != null)
              Tooltip(
                message: game.installDir!,
                child: Text(
                  game.installDir!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    game.isGroup
                        ? '合計 ${game.playHours.toStringAsFixed(1)}h · 登録先 ${game.installations.length} 件'
                        : '${game.playHours.toStringAsFixed(1)}h  ·  ${game.routeCurrent}/${game.routeTotal} ルート',
                    style: TextStyle(
                      color: context.appColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (game.rating != null) RatingBadge(value: game.rating!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GameCover extends StatelessWidget {
  const GameCover({
    super.key,
    required this.game,
    required this.onStatusChanged,
    required this.onDeleteRequested,
    this.compact = false,
    this.selectionMode = false,
    this.isSelected = false,
  });
  final GameEntry game;
  final void Function(String, GameStatus) onStatusChanged;
  final Future<void> Function(String) onDeleteRequested;
  final bool compact;
  final bool selectionMode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final highlight = game.status == GameStatus.playing;
    final hasArtwork =
        game.localCoverPath != null ||
        (game.vndbId != null && game.coverImageUrl != null);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: game.coverColors,
        ),
        border: Border.all(
          color: isSelected
              ? AppColors.accent
              : highlight
              ? AppColors.accentWarm
              : context.appColors.border,
          width: isSelected || highlight ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 7 : 9),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: CoverTexturePainter())),
            if (!hasArtwork && game.installDir != null && !compact)
              Positioned(
                left: 12,
                top: 52,
                child: Tooltip(
                  message: '作品詳細でカタログの照合先を確認するか、画像を手動指定してください。',
                  child: Text(
                    game.vndbId == null ? 'カタログ未照合' : 'カタログ画像なし',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            if (hasArtwork)
              Positioned.fill(
                child: game.localCoverPath != null
                    ? CoverPrivacyFilter(
                        blurOverride: game.coverBlurOverride,
                        child: Image.file(
                          File(game.localCoverPath!),
                          fit: BoxFit.cover,
                          cacheWidth: compact ? 160 : 600,
                          errorBuilder: (_, error, stack) =>
                              Center(child: Text(game.title)),
                        ),
                      )
                    : CachedCoverImage(
                        vndbId: game.vndbId!,
                        imageUrl: game.coverImageUrl!,
                        cacheWidth: compact ? 160 : 600,
                        blurOverride: game.coverBlurOverride,
                      ),
              ),
            if (hasArtwork)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x22000000),
                        Colors.transparent,
                        Color(0xB8000000),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: compact ? 8 : 12,
              left: compact ? 8 : 12,
              child: selectionMode
                  ? Container(
                      width: compact ? 22 : 26,
                      height: compact ? 22 : 26,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : const Color(0xCC111827),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: compact ? 15 : 18,
                        color: isSelected
                            ? context.appColors.canvas
                            : Colors.white70,
                      ),
                    )
                  : game.isGroup
                  ? const Text(
                      '複数登録',
                      style: TextStyle(
                        color: Colors.white,
                        backgroundColor: Colors.black54,
                      ),
                    )
                  : StatusBadge(status: game.status),
            ),
            if (!compact && !hasArtwork)
              Positioned(
                top: 14,
                right: 14,
                child: Text(
                  game.title.characters.join('\n'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                  ),
                ),
              ),
            if (!compact)
              Positioned(
                left: 14,
                right: 14,
                bottom: 28,
                child: Text(
                  game.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (!compact)
              Positioned(
                left: 14,
                right: 14,
                bottom: 13,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: game.progress,
                    minHeight: 4,
                    color: AppColors.accent,
                    backgroundColor: const Color(0x66000000),
                  ),
                ),
              ),
            if (!selectionMode)
              Positioned(
                right: compact ? 2 : 4,
                bottom: compact ? 2 : 4,
                child: StatusMenu(
                  game: game,
                  onStatusChanged: onStatusChanged,
                  onDeleteRequested: onDeleteRequested,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CoverTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0DFFFFFF);
    for (double y = 8; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final glow = Paint()
      ..shader =
          const RadialGradient(colors: [Color(0x22FFFFFF), Colors.transparent])
              .createShader(
                Rect.fromCircle(
                  center: Offset(size.width * .25, size.height * .2),
                  radius: size.width,
                ),
              );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final GameStatus status;

  Color get color => switch (status) {
    GameStatus.notPlayed => const Color(0xFFE9AFC7),
    GameStatus.playing => AppColors.accentWarm,
    GameStatus.cleared => AppColors.accent,
    GameStatus.completed => AppColors.accentBlue,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: context.appColors.canvas,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum _GameMenuAction { delete }

class StatusMenu extends StatelessWidget {
  const StatusMenu({
    super.key,
    required this.game,
    required this.onStatusChanged,
    required this.onDeleteRequested,
  });
  final GameEntry game;
  final void Function(String, GameStatus) onStatusChanged;
  final Future<void> Function(String) onDeleteRequested;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ライブラリから削除しますか？'),
        content: Text(
          '「${game.title}」の登録情報・プレイ履歴・タグ・攻略メモ・予定をNoveLibから削除します。\n\n'
          'ゲーム本体やインストールフォルダは削除されません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await onDeleteRequested(game.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('削除できませんでした。ゲーム起動・スキャンの終了後にお試しください。')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (game.isGroup) {
      return const Tooltip(
        message: '詳細画面で登録先を選択してください',
        child: Icon(Icons.layers_outlined, size: 18),
      );
    }
    return PopupMenuButton<Object>(
      tooltip: 'ステータスと作品操作',
      onSelected: (value) {
        if (value is GameStatus) {
          onStatusChanged(game.id, value);
        } else if (value == _GameMenuAction.delete) {
          _confirmDelete(context);
        }
      },
      color: context.appColors.panelLight,
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0x88000000),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.more_horiz_rounded, size: 16),
      ),
      itemBuilder: (context) => [
        for (final status in GameStatus.values)
          PopupMenuItem(
            value: status,
            child: Row(
              children: [
                if (status == game.status)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.accent,
                  )
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(status.label),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _GameMenuAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18),
              SizedBox(width: 8),
              Text('ライブラリから削除'),
            ],
          ),
        ),
      ],
    );
  }
}

class GameListCard extends StatelessWidget {
  const GameListCard({
    super.key,
    required this.game,
    required this.onStatusChanged,
    required this.onDeleteRequested,
    required this.selectionMode,
    required this.isSelected,
    required this.onSelected,
    required this.onOpened,
  });
  final GameEntry game;
  final void Function(String, GameStatus) onStatusChanged;
  final Future<void> Function(String) onDeleteRequested;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.panel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: selectionMode ? onSelected : onOpened,
        onLongPress: selectionMode ? onSelected : null,
        focusColor: context.appColors.selected,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 104,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : context.appColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: GameCover(
                  game: game,
                  compact: true,
                  onStatusChanged: onStatusChanged,
                  onDeleteRequested: onDeleteRequested,
                  selectionMode: selectionMode,
                  isSelected: isSelected,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectionMode
                          ? game.installDir ?? game.brand
                          : game.brand,
                      style: TextStyle(
                        color: context.appColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 5,
                      children: [
                        for (final tag in game.tags)
                          Text(
                            '#$tag',
                            style: const TextStyle(
                              color: AppColors.accentBlue,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 130,
                child: Text(
                  '${game.playHours.toStringAsFixed(1)} 時間',
                  style: TextStyle(color: context.appColors.textMuted),
                ),
              ),
              SizedBox(
                width: 130,
                child: Text(
                  game.isGroup
                      ? '登録先 ${game.installations.length} 件'
                      : '${game.routeCurrent} / ${game.routeTotal} ルート',
                  style: TextStyle(color: context.appColors.textMuted),
                ),
              ),
              SizedBox(
                width: 84,
                child: game.rating == null
                    ? Text(
                        game.isGroup ? '個別に確認' : '未評価',
                        style: TextStyle(
                          color: context.appColors.textFaint,
                          fontSize: 11,
                        ),
                      )
                    : RatingBadge(value: game.rating!),
              ),
              if (!selectionMode)
                StatusMenu(
                  game: game,
                  onStatusChanged: onStatusChanged,
                  onDeleteRequested: onDeleteRequested,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentWarm.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: AppColors.accentWarm),
          const SizedBox(width: 2),
          Text(
            '$value/10',
            style: const TextStyle(
              color: AppColors.accentWarm,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyLibraryResult extends StatelessWidget {
  const EmptyLibraryResult({
    super.key,
    required this.filtered,
    required this.canScan,
    required this.isScanning,
    required this.onScan,
  });

  final bool filtered;
  final bool canScan;
  final bool isScanning;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered ? Icons.search_off_rounded : Icons.auto_stories_outlined,
            size: 42,
            color: context.appColors.textFaint,
          ),
          const SizedBox(height: 12),
          Text(
            filtered ? '条件に合う作品がありません' : 'ライブラリはまだ空です',
            style: TextStyle(color: context.appColors.textMuted),
          ),
          if (!filtered && canScan) ...[
            const SizedBox(height: 8),
            Text(
              'ゲームを保存しているフォルダを選んで登録を始めましょう。',
              style: TextStyle(
                color: context.appColors.textFaint,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: isScanning ? null : onScan,
              icon: isScanning
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.create_new_folder_outlined, size: 18),
              label: Text(isScanning ? 'スキャン中…' : 'ゲームフォルダを選択'),
            ),
          ],
        ],
      ),
    );
  }
}
