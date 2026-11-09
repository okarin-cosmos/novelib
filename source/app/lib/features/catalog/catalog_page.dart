import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../catalog/catalog_database.dart';
import '../../theme/app_theme.dart';
import '../../database/app_database.dart';
import 'catalog_review_dialog.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    required this.catalog,
    this.showAdult = true,
    this.database,
    this.sharingEnabled = false,
    this.onReviewSaved,
  });
  final AppDatabase? database;
  final bool sharingEnabled;
  final VoidCallback? onReviewSaved;

  final CatalogDatabase? catalog;
  final bool showAdult;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _pageFocus = FocusNode();
  Timer? _debounce;
  List<CatalogWork> _works = const [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void didUpdateWidget(CatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.catalog != widget.catalog ||
        oldWidget.showAdult != widget.showAdult) {
      _search();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _pageFocus.dispose();
    super.dispose();
  }

  void _scheduleSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), _search);
  }

  void _search() {
    final catalog = widget.catalog;
    if (catalog == null) return;
    setState(
      () => _works = catalog.search(
        _searchController.text,
        showAdult: widget.showAdult,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _debounce?.cancel();
          _searchController.clear();
          _search();
          _pageFocus.requestFocus();
        },
      },
      child: Focus(
        autofocus: true,
        focusNode: _pageFocus,
        child: ColoredBox(
          color: context.appColors.canvas,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(30, 24, 30, 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: context.appColors.border),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final heading = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '作品カタログ',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          catalog == null
                              ? '作品マスターを読み込めませんでした。'
                              : '国内ビジュアルノベル ${catalog.workCount} 作品を収録',
                          style: TextStyle(
                            color: context.appColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                    final search = TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: _scheduleSearch,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        hintText: '作品名・別名・ブランドで検索',
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: '検索を消去',
                                onPressed: () {
                                  _debounce?.cancel();
                                  _searchController.clear();
                                  _search();
                                  _searchFocus.requestFocus();
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                      ),
                    );
                    if (constraints.maxWidth < 760) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [heading, const SizedBox(height: 14), search],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: heading),
                        SizedBox(width: 420, child: search),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: catalog == null
                    ? const Center(child: Text('作品カタログを利用できません。'))
                    : _works.isEmpty
                    ? Center(
                        child: Text(
                          '該当する作品がありません',
                          style: TextStyle(color: context.appColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(30, 22, 30, 26),
                        itemCount: _works.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: context.appColors.border),
                        itemBuilder: (context, index) => CatalogWorkRow(
                          work: _works[index],
                          onReview: widget.database == null
                              ? null
                              : () async {
                                  final saved = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => CatalogReviewDialog(
                                      database: widget.database!,
                                      work: _works[index],
                                      sharingEnabled: widget.sharingEnabled,
                                    ),
                                  );
                                  if (saved == true) {
                                    widget.onReviewSaved?.call();
                                  }
                                },
                        ),
                      ),
              ),
              if (catalog != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 16),
                  child: Text(
                    '作品データ: VNDB（ODbL 1.0 / DbCL 1.0）  '
                    '更新: ${catalog.sourceTimestamp}',
                    style: TextStyle(
                      color: context.appColors.textFaint,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatalogWorkRow extends StatelessWidget {
  const CatalogWorkRow({super.key, required this.work, this.onReview});
  final VoidCallback? onReview;

  final CatalogWork work;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.panel,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final cover = Container(
            width: 42,
            height: 54,
            decoration: BoxDecoration(
              color: context.appColors.panelLight,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: context.appColors.border),
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              color: AppColors.accent,
              size: 20,
            ),
          );
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onReview != null)
                TextButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text('評価する・編集'),
                ),
              Text(
                work.titleJa,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (work.titleRomaji != null &&
                  work.titleRomaji != work.titleJa) ...[
                const SizedBox(height: 3),
                Text(
                  work.titleRomaji!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
              if (work.developers != null) ...[
                const SizedBox(height: 5),
                Text(
                  work.developers!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          );
          final released = Text(
            work.released ?? '発売日不明',
            style: TextStyle(color: context.appColors.textMuted, fontSize: 11),
          );
          final rating = Text(
            work.rating == null ? '-' : work.rating!.toStringAsFixed(1),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accentWarm,
              fontWeight: FontWeight.w800,
            ),
          );
          final id = Text(
            work.vndbId,
            textAlign: TextAlign.right,
            style: TextStyle(color: context.appColors.textFaint, fontSize: 10),
          );
          if (compact) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cover,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title,
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 18,
                        runSpacing: 5,
                        children: [released, rating, id],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              cover,
              const SizedBox(width: 15),
              Expanded(child: title),
              const SizedBox(width: 20),
              SizedBox(width: 92, child: released),
              SizedBox(width: 72, child: rating),
              SizedBox(width: 70, child: id),
            ],
          );
        },
      ),
    );
  }
}
