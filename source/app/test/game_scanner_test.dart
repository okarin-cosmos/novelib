import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:chronovel/scanner/game_scanner.dart';

void main() {
  test('親のEXEや別のUnityデータに影響されず同名別登録とセット内作品を検出する', () async {
    final root = await Directory.systemTemp.createTemp(
      'chronovel_scan_regression_',
    );
    addTearDown(() => root.delete(recursive: true));
    Future<void> files(String subdir, List<String> names) async {
      final dir = Directory(p.join(root.path, subdir));
      await dir.create(recursive: true);
      for (final name in names) {
        await File(p.join(dir.path, name)).writeAsString('');
      }
    }

    await files('', ['tool.exe']);
    await Directory(p.join(root.path, 'unrelated_Data')).create();
    await files('BaseSon/A/同名作品', [
      'game.exe',
      'data.xp3',
      'curl.exe',
      'setup.exe',
    ]);
    await files('BaseSon/B/同名作品', ['game.exe', 'data.xp3']);
    await files('日本語セット/LEYLINE1', ['LEYLINE1.exe', 'script.pac']);
    await files('日本語セット/LEYLINE2', ['LEYLINE2.exe', 'script.pac']);
    await files('本体Unity', ['real.exe', 'UnityCrashHandler64.exe']);
    await Directory(p.join(root.path, '本体Unity/real_Data')).create();
    await files('インストール専用', [
      'autorun.exe',
      'setup.exe',
      'inst.exe',
      'script.pac',
    ]);
    final results = await GameScanner().scan(root.path);
    expect(results, hasLength(5));
    expect(results.where((g) => g.title == '同名作品'), hasLength(2));
    expect(results.any((g) => g.installDir == root.path), isFalse);
    expect(
      results.singleWhere((g) => g.engine == 'unity').exePath,
      endsWith('real.exe'),
    );
    final unity = results.singleWhere((g) => g.engine == 'unity');
    expect(unity.requiresCatalogMatch, isTrue);
    expect(
      shouldAutoRegisterDetectedGame(unity, hasCatalogMatch: false),
      isFalse,
    );
    expect(
      shouldAutoRegisterDetectedGame(unity, hasCatalogMatch: true),
      isTrue,
    );
    expect(
      results.singleWhere((g) => g.exePath.endsWith('LEYLINE1.exe')).title,
      'LEYLINE1',
    );
    expect(results.any((g) => g.titleCandidates.contains('日本語セット')), isFalse);
  });

  test('追加エンジンのデータを認識し補助ツールを除外する', () async {
    final root = await Directory.systemTemp.createTemp(
      'chronovel_scan_engines_',
    );
    addTearDown(() => root.delete(recursive: true));
    final signatures = {
      'System4': ['System40.exe', 'game.ain', 'game.afa'],
      'Exhibit': ['main.exe', 'acmp.exe', 'ExHIBIT.ini'],
      'Script': ['main.exe', 'セーブデータフォルダを開く.exe', 'scr.pak'],
      'Dat': ['main.exe', 'script.dat', 'image.dat'],
      'Paz': ['main.exe', 'data.paz'],
      'BGI': ['BGI.exe', 'data.arc'],
      'War': ['game.exe', 'rio.ini', 'script.war'],
      'Bin': ['game.exe', 'script.bin', 'bg.bin', 'voc.bin'],
      'Npk': ['game.exe', 'patch_install.exe', 'script.npk'],
      'Suf': ['game.exe', 'game.suf', 'DATA', 'VOICE'],
    };
    for (final item in signatures.entries) {
      final dir = await Directory(p.join(root.path, item.key)).create();
      for (final file in item.value) {
        await File(p.join(dir.path, file)).writeAsString('');
      }
      if (item.key == 'Exhibit') {
        await Directory(p.join(dir.path, 'rld')).create();
      }
    }
    final results = await GameScanner().scan(root.path);
    expect(results, hasLength(10));
    expect(
      results.map((g) => g.engine),
      containsAll(['system4', 'exhibit', 'ethornell']),
    );
    expect(
      results.any(
        (g) => g.exePath.contains('セーブデータ') || g.exePath.endsWith('acmp.exe'),
      ),
      isFalse,
    );
  });
  test('エンジン指紋のある作品だけを検出する', () async {
    final root = await Directory.systemTemp.createTemp('vn_manager_scan_');
    addTearDown(() => root.delete(recursive: true));

    final kirikiri = Directory(p.join(root.path, 'RJ123456_霧の物語'));
    await kirikiri.create();
    await File(p.join(kirikiri.path, 'story.exe')).writeAsString('');
    await File(p.join(kirikiri.path, 'config.exe')).writeAsString('');
    await File(p.join(kirikiri.path, 'data.xp3')).writeAsString('');

    final renpy = Directory(p.join(root.path, '星の物語'));
    await renpy.create();
    await File(p.join(renpy.path, 'hoshi.exe')).writeAsString('');
    await Directory(p.join(renpy.path, 'game')).create();
    await Directory(p.join(renpy.path, 'renpy')).create();

    final unrelated = Directory(p.join(root.path, '普通のツール'));
    await unrelated.create();
    await File(p.join(unrelated.path, 'tool.exe')).writeAsString('');

    final results = await GameScanner().scan(root.path);

    expect(results, hasLength(2));
    final detectedKirikiri = results.singleWhere(
      (game) => game.engine == 'kirikiri',
    );
    expect(detectedKirikiri.rjCode, 'RJ123456');
    expect(p.basename(detectedKirikiri.exePath), 'story.exe');
    expect(detectedKirikiri.title, '霧の物語');
    expect(results.singleWhere((game) => game.engine == 'renpy').title, '星の物語');
    expect(detectedKirikiri.requiresCatalogMatch, isFalse);
    expect(
      shouldAutoRegisterDetectedGame(detectedKirikiri, hasCatalogMatch: false),
      isTrue,
    );
  });

  test('入れ子の本体、汎用データ形式、重複インストーラーを正しく整理する', () async {
    final root = await Directory.systemTemp.createTemp('chronovel_scan_');
    addTearDown(() => root.delete(recursive: true));

    final nine = Directory(p.join(root.path, '9-nine- はるいろはるこいはるのかぜ- DL版'));
    final nineBody = Directory(p.join(nine.path, 'dl_image', 'nine_haruiro'));
    await nineBody.create(recursive: true);
    await File(p.join(nine.path, 'dl_image', 'setup.exe')).writeAsString('');
    await File(p.join(nineBody.path, 'nine_haruiro.exe')).writeAsString('');
    await File(p.join(nineBody.path, 'data.xp3')).writeAsString('');

    final pacGame = Directory(p.join(root.path, 'アオナツライン'));
    await pacGame.create();
    await File(p.join(pacGame.path, 'Aonatsu.exe')).writeAsString('');
    await File(p.join(pacGame.path, 'Setup.exe')).writeAsString('');
    await File(p.join(pacGame.path, 'Script.pac')).writeAsString('');

    final installed = Directory(
      p.join(root.path, 'BaseSon', '戦国†恋姫Ｘ ～乙女絢爛☆戦国絵巻～ ダウンロード版'),
    );
    await installed.create(recursive: true);
    await File(p.join(installed.path, 'sengokux.exe')).writeAsString('');
    await File(p.join(installed.path, 'config.int')).writeAsString('');

    final installer = Directory(
      p.join(root.path, '戦国†恋姫X ～乙女絢爛☆戦国絵巻～', 'data', 'setup'),
    );
    await installer.create(recursive: true);
    await File(p.join(installer.path, 'sengokuX.exe')).writeAsString('');
    await File(p.join(installer.path, 'config.int')).writeAsString('');

    final results = await GameScanner().scan(root.path);

    expect(results, hasLength(3));
    expect(
      results
          .singleWhere((game) => game.exePath.endsWith('nine_haruiro.exe'))
          .title,
      '9-nine-はるいろはるこいはるのかぜ',
    );
    expect(
      results.singleWhere((game) => game.title == 'アオナツライン').engine,
      'unknown',
    );
    final sengoku = results.singleWhere((game) => game.title.contains('戦国†恋姫'));
    expect(sengoku.installDir, installed.path);
    expect(results.any((game) => game.title.toLowerCase() == 'setup'), isFalse);
  });
}
