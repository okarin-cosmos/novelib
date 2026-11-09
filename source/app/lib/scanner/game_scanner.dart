import 'dart:io';

import 'package:path/path.dart' as p;

import 'executable_titles.dart';

class DetectedGame {
  const DetectedGame({
    required this.title,
    required this.installDir,
    required this.exePath,
    required this.engine,
    this.rjCode,
    this.titleCandidates = const [],
    this.requiresCatalogMatch = false,
  });
  final String title, installDir, exePath, engine;
  final String? rjCode;
  final List<String> titleCandidates;

  /// True for engines also widely used by non-visual-novel games.
  final bool requiresCatalogMatch;
}

bool shouldAutoRegisterDetectedGame(
  DetectedGame game, {
  required bool hasCatalogMatch,
}) => !game.requiresCatalogMatch || hasCatalogMatch;

class GameScanner {
  static final _excludedExecutable = RegExp(
    r'^(unins.*|.*config.*|setup.*|install.*|patch_install.*|checking|setting|autorun.*|inst|epuninst|acmp|bhvc|kmsdll|update.*|autoupdate.*|launcher.*|startup.*|startmenu|supporttools?.*|filechk.*|filecheck.*|alphacheck.*|bootmenu.*|dxsetup.*|vcredist.*|curl|wget|unitycrashhandler.*|crashreport.*|notification_helper|chrome|cef.*|.*設定.*|.*環境設定.*|.*破損チェック.*|.*セーブデータ.*|.*認証.*)\.exe$',
    caseSensitive: false,
  );
  static const _excludedDirectories = {
    'directx',
    'redist',
    '_redist',
    '_commonredist',
    'support',
    'manual',
    'マニュアル',
    'savedata',
    'save',
    'saves',
    '豪華版特典',
    'setup',
    'installer',
    'uninstaller',
    'renpy',
    'node_modules',
    '.git',
    'gameguard',
    'plugins',
    'plugin',
    'cache',
  };
  static final _genericDirectory = RegExp(
    r'^(ゲームソフト\d*|games?|soft(ware)?|downloads?|dl_image|data|bin|win32|win64|x86|x64|baseson|giga|waffle|frontwing|clockup|sagaplanets|perseus)$',
    caseSensitive: false,
  );
  final List<String> warnings = [];

  Future<List<DetectedGame>> scan(String rootPath) async {
    warnings.clear();
    final root = Directory(p.normalize(rootPath));
    if (!await root.exists()) {
      throw FileSystemException('選択したフォルダが見つかりません。', rootPath);
    }
    final pending = <Directory>[root];
    final candidates = <DetectedGame>[];
    final topLevel = <String>[];
    while (pending.isNotEmpty) {
      final directory = pending.removeLast();
      final entries = <FileSystemEntity>[];
      try {
        entries.addAll(await directory.list(followLinks: false).toList());
      } on FileSystemException {
        warnings.add('読取不可: ${directory.path}');
        continue;
      }
      final files = entries.whereType<File>().toList();
      final names = files.map((f) => p.basename(f.path).toLowerCase()).toSet();
      final children = entries.whereType<Directory>().toList();
      if (p.equals(directory.path, root.path)) {
        topLevel.addAll(children.map((d) => d.path));
      }
      final dirNames = children
          .map((d) => p.basename(d.path).toLowerCase())
          .toSet();
      for (final child in children) {
        final name = p.basename(child.path).toLowerCase();
        // Engine resources are not independent installs. Never follow links.
        if (!_excludedDirectories.contains(name) && !name.endsWith('_data')) {
          pending.add(child);
        }
      }
      final executables = files
          .where(
            (f) =>
                p.extension(f.path).toLowerCase() == '.exe' &&
                !_excludedExecutable.hasMatch(p.basename(f.path)),
          )
          .toList();
      // Only inspect this known resource location, not arbitrary descendants.
      if (executables.isNotEmpty &&
          dirNames.contains('files') &&
          await File(p.join(directory.path, 'files', 'SCRIPT.PAK')).exists()) {
        names.add('script.pak');
      }
      final scored =
          <
            ({File file, String engine, int score, bool requiresCatalogMatch})
          >[];
      for (final exe in executables) {
        final stem = p.basenameWithoutExtension(exe.path).toLowerCase();
        final engine = _engine(names, dirNames, stem);
        if (engine == null) continue;
        var score = 0;
        if (dirNames.contains('${stem}_data')) score += 500;
        if (stem == p.basename(directory.path).toLowerCase()) score += 200;
        if (RegExp(r'[ぁ-んァ-ヶ一-龯]').hasMatch(stem)) score += 100;
        if (stem == 'game' || stem == 'siglusengine' || stem == 'system40') {
          score += 50;
        }
        try {
          score += ((await exe.length()) ~/ (1024 * 1024)).clamp(0, 40);
        } on FileSystemException {
          /* Tie breaker only. */
        }
        scored.add((
          file: exe,
          engine: engine,
          score: score,
          requiresCatalogMatch: _requiresCatalogMatch(names, engine),
        ));
      }
      if (scored.isEmpty) {
        if (executables.isNotEmpty) warnings.add('対応データ未確認: ${directory.path}');
        if (executables.isEmpty &&
            files.any((f) => p.extension(f.path).toLowerCase() == '.exe')) {
          warnings.add('補助ツール・インストーラーのみ（自動登録から除外）: ${directory.path}');
        }
        continue;
      }
      scored.sort((a, b) {
        final score = b.score.compareTo(a.score);
        return score != 0 ? score : a.file.path.compareTo(b.file.path);
      });
      final best = scored.first;
      final titles = _titles(root, directory, best.file);
      final rjCode = RegExp(
        r'RJ\d{6,8}',
        caseSensitive: false,
      ).firstMatch(directory.path)?.group(0)?.toUpperCase();
      candidates.add(
        DetectedGame(
          title: titles.first,
          titleCandidates: titles,
          installDir: directory.path,
          exePath: best.file.path,
          engine: best.engine,
          rjCode: rjCode,
          requiresCatalogMatch: best.requiresCatalogMatch,
        ),
      );
    }
    for (final dir in topLevel) {
      if (!candidates.any(
            (g) => p.equals(dir, g.installDir) || p.isWithin(dir, g.installDir),
          ) &&
          !warnings.any((w) => w.endsWith(': $dir'))) {
        warnings.add('本体を未検出（実行ファイルなし・未対応形式・除外対象など）: $dir');
      }
    }
    if (candidates.isEmpty && topLevel.isEmpty && warnings.isEmpty) {
      warnings.add('実行ファイルを検出できません: ${root.path}');
    }
    final ancestorCounts = <String, int>{};
    for (final game in candidates) {
      var parent = Directory(game.installDir).parent;
      while (p.isWithin(root.path, parent.path) ||
          p.equals(root.path, parent.path)) {
        ancestorCounts.update(
          parent.path,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        if (p.equals(parent.path, root.path)) break;
        parent = parent.parent;
      }
    }
    final collections = ancestorCounts.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toSet();
    final metadata = await executableTitles(
      candidates.map((g) => g.exePath).toList(),
    );
    final results = candidates.map((game) {
      final titles = <String>{
        ...?metadata[game.exePath],
        ..._titles(
          root,
          Directory(game.installDir),
          File(game.exePath),
          collections,
        ),
      }.where(_usefulTitle).toList();
      return DetectedGame(
        title: titles.isEmpty ? game.title : titles.first,
        titleCandidates: titles,
        installDir: game.installDir,
        exePath: game.exePath,
        engine: game.engine,
        rjCode: game.rjCode,
        requiresCatalogMatch: game.requiresCatalogMatch,
      );
    }).toList()..sort((a, b) => a.installDir.compareTo(b.installDir));
    return results;
  }

  String? _engine(Set<String> names, Set<String> dirs, String exe) {
    bool ext(String value) => names.any((name) => name.endsWith(value));
    if (dirs.contains('${exe}_data')) return 'unity';
    if (ext('.xp3')) return 'kirikiri';
    if (names.contains('arc.nsa') ||
        names.contains('nscript.dat') ||
        names.contains('0.txt') && ext('.nsa')) {
      return 'nscripter';
    }
    if (dirs.contains('game') && dirs.contains('renpy')) return 'renpy';
    if (ext('.ypf')) return 'yu-ris';
    if (ext('.int')) return 'catsystem2';
    if (names.any((n) => RegExp(r'^data0\d+\.arc$').hasMatch(n))) {
      return 'ethornell';
    }
    if (ext('.arc') && (ext('.hvl') || exe == 'bgi')) return 'ethornell';
    if (names.contains('exhibit.ini') && dirs.contains('rld')) return 'exhibit';
    if (names.contains('rio.ini') && ext('.war')) return 'unknown';
    if (names.contains('script.bin') &&
        names.contains('bg.bin') &&
        names.contains('voc.bin')) {
      return 'unknown';
    }
    if (names.contains('script.dat') && names.contains('arc0.dat')) {
      return 'unknown';
    }
    if (names.contains('script.dat') && names.contains('image.dat')) {
      return 'unknown';
    }
    if (names.contains('scr.pak') || names.contains('script.pak')) {
      return 'unknown';
    }
    if (exe == 'ai5win' && ext('.arc')) return 'unknown';
    if (ext('.ain') && (ext('.ald') || ext('.afa'))) return 'system4';
    if (ext('.ald')) return 'system3';
    if (ext('.pck') &&
        (exe.contains('siglus') || names.contains('siglusengine.exe'))) {
      return 'siglus';
    }
    if (names.contains('tyrano.exe') ||
        names.contains('package.json') && dirs.contains('data')) {
      return 'tyrano';
    }
    if (ext('.gesl') && names.contains('gecorelibrary.dll')) return 'unknown';
    if (ext('.suf') &&
        (dirs.contains('data') || names.contains('data')) &&
        (dirs.contains('voice') || names.contains('voice'))) {
      return 'unknown';
    }
    if ([
      '.paz',
      '.npa',
      '.npk',
      '.xfl',
      '.pac',
      '.pfs',
      '.rgssad',
      '.rgss2a',
      '.rgss3a',
      '.wolf',
      '.iga',
      '.noa',
      '.mjo',
      '.mrg',
      '.dxa',
    ].any(ext)) {
      return 'unknown';
    }
    if (names.contains('scenario.arc') || names.contains('script.arc')) {
      return 'unknown';
    }
    return null;
  }

  bool _requiresCatalogMatch(Set<String> names, String engine) {
    if (engine == 'unity') return true;
    return names.any(
      (name) =>
          const ['.rgssad', '.rgss2a', '.rgss3a', '.wolf'].any(name.endsWith),
    );
  }

  List<String> _titles(
    Directory root,
    Directory dir,
    File exe, [
    Set<String> collections = const {},
  ]) {
    final titles = <String>[];
    final stem = cleanDetectedTitle(p.basenameWithoutExtension(exe.path));
    if (RegExp(r'[ぁ-んァ-ヶ一-龯]').hasMatch(stem) && _usefulTitle(stem)) {
      titles.add(stem);
    }
    var current = dir;
    while (p.isWithin(root.path, current.path) ||
        p.equals(root.path, current.path)) {
      final name = p.basename(current.path);
      if (!_genericDirectory.hasMatch(name) &&
          (p.equals(current.path, dir.path) ||
              !collections.contains(current.path))) {
        titles.add(cleanDetectedTitle(name));
      }
      if (p.equals(root.path, current.path)) break;
      current = current.parent;
    }
    // A Japanese wrapper name is more informative than an internal English folder.
    final japanese = titles
        .where((t) => RegExp(r'[ぁ-んァ-ヶ一-龯]').hasMatch(t))
        .toList();
    final result = <String>{
      ...japanese,
      ...titles,
      stem,
    }.where(_usefulTitle).toList();
    return result.isEmpty ? [stem] : result;
  }

  bool _usefulTitle(String title) =>
      title.isNotEmpty &&
      !_genericDirectory.hasMatch(title) &&
      !RegExp(
        r'^(game|siglusengine|system40?|application|タイトル未設定)$',
        caseSensitive: false,
      ).hasMatch(title);
}

String cleanDetectedTitle(String value) => value
    .replaceAll(RegExp(r'RJ\d{6,8}', caseSensitive: false), '')
    .replaceFirst(
      RegExp(r'\s*[-ー]?\s*(DL版|ダウンロード版)\s*$', caseSensitive: false),
      '',
    )
    .replaceAll(RegExp(r'_+'), ' ')
    .replaceAll(RegExp(r'\s*-\s*'), '-')
    .replaceAll(RegExp(r'[\s　]+'), ' ')
    .trim();
