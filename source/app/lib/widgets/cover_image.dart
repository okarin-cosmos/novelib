import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/cover_image_cache.dart';

class CoverPrivacy extends InheritedWidget {
  const CoverPrivacy({
    super.key,
    required this.blurEnabled,
    required super.child,
  });

  final bool blurEnabled;

  static bool blurOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CoverPrivacy>()?.blurEnabled ??
      false;

  @override
  bool updateShouldNotify(CoverPrivacy oldWidget) =>
      blurEnabled != oldWidget.blurEnabled;
}

class CoverPrivacyFilter extends StatelessWidget {
  const CoverPrivacyFilter({super.key, required this.child, this.blurOverride});

  final Widget child;
  final bool? blurOverride;

  @override
  Widget build(BuildContext context) {
    if (!(blurOverride ?? CoverPrivacy.blurOf(context))) return child;
    return ClipRect(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Transform.scale(scale: 1.08, child: child),
      ),
    );
  }
}

class CachedCoverImage extends StatefulWidget {
  const CachedCoverImage({
    super.key,
    required this.vndbId,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.cache,
    this.cacheWidth = 600,
    this.blurOverride,
  });

  final String vndbId;
  final String imageUrl;
  final BoxFit fit;
  final CoverImageCache? cache;
  final int cacheWidth;
  final bool? blurOverride;

  @override
  State<CachedCoverImage> createState() => _CachedCoverImageState();
}

class _CachedCoverImageState extends State<CachedCoverImage> {
  late Future<File?> _file;
  CoverImageCache get _cache => widget.cache ?? CoverImageCache.instance;

  void _cacheChanged() {
    if (!mounted || !_cache.changedIds.contains(widget.vndbId)) return;
    setState(() {
      if (_cache.removed) {
        _file = Future.value(null);
      } else {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _cache.removeListener(_cacheChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cache.addListener(_cacheChanged);
    _load();
  }

  @override
  void didUpdateWidget(CachedCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cache != widget.cache) {
      (oldWidget.cache ?? CoverImageCache.instance).removeListener(
        _cacheChanged,
      );
      _cache.addListener(_cacheChanged);
    }
    if (oldWidget.vndbId != widget.vndbId ||
        oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.cache != widget.cache) {
      _load();
    }
  }

  void _load({bool refresh = false}) {
    _file = (widget.cache ?? CoverImageCache.instance)
        .get(widget.vndbId, widget.imageUrl, refresh: refresh)
        .then((file) async {
          if (refresh && file != null) await CoverImageCache.evictFile(file);
          return file;
        });
  }

  Widget _retry() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _cache.failureFor(widget.vndbId, widget.imageUrl) ?? '画像未取得',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        Tooltip(
          message: '画像を取得できませんでした。クリックして再試行',
          child: IconButton.filledTonal(
            onPressed: () => setState(() => _load(refresh: true)),
            icon: const Icon(Icons.refresh),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return snapshot.connectionState == ConnectionState.waiting
              ? const Center(
                  child: Text('画像読込中・順番待ち', style: TextStyle(fontSize: 11)),
                )
              : _retry();
        }
        return CoverPrivacyFilter(
          blurOverride: widget.blurOverride,
          child: Image.file(
            file,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => _retry(),
          ),
        );
      },
    );
  }
}
