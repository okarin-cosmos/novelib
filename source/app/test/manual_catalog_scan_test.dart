import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/catalog/catalog_database.dart';
import 'package:chronovel/scanner/game_scanner.dart';

void main() {
  test('指定された実フォルダを作品マスターへ照合する', () async {
    const folder = String.fromEnvironment('CHRONOVEL_SCAN_FOLDER');
    if (folder.isEmpty || !await Directory(folder).exists()) {
      return;
    }

    final catalog = CatalogDatabase.openExisting(
      'assets/catalog/chronovel_catalog.sqlite',
    );
    addTearDown(catalog.close);
    final games = await GameScanner().scan(folder);
    final matches = {
      for (final game in games) game.title: catalog.matchTitle(game.title),
    };

    for (final entry in matches.entries) {
      // Printed only for an explicitly requested local verification run.
      // ignore: avoid_print
      print(
        '${entry.key} -> '
        '${entry.value?.titleJa ?? "未照合"} '
        '(${entry.value?.vndbId ?? "-"})',
      );
      if (entry.value == null) {
        var candidates = catalog.search(entry.key, limit: 5);
        if (candidates.isEmpty) {
          final shortQuery = entry.key.contains('乙女絢爛')
              ? '乙女絢爛'
              : entry.key.length <= 6
              ? entry.key
              : entry.key.substring(0, 6);
          candidates = catalog.search(shortQuery, limit: 5);
        }
        // ignore: avoid_print
        print(
          '  候補: ${candidates.map((work) => "${work.titleJa} (${work.vndbId})").join(", ")}',
        );
      }
    }

    expect(games, hasLength(7));
    expect(matches.values.whereType<CatalogWork>(), hasLength(7));
  });
}
