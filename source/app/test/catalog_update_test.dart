import 'dart:io';

import 'package:chronovel/catalog/catalog_database.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('検証済みカタログへ切り替え、次回起動用の選択を保存する', () async {
    final dir = await Directory.systemTemp.createTemp('chronovel_catalog_');
    addTearDown(() => dir.delete(recursive: true));
    final current = await File('assets/catalog/chronovel_catalog.sqlite')
        .copy(p.join(dir.path, 'current.sqlite'));
    final update = await current.copy(p.join(dir.path, 'update.sqlite'));
    final writable = sqlite3.open(update.path);
    writable.execute(
      "UPDATE metadata SET value = '2099-01-02-test' "
      "WHERE key = 'source_timestamp'",
    );
    writable.close();
    final digest = await sha256.bind(update.openRead()).first;
    await File('${update.path}.sha256')
        .writeAsString('${digest.toString()}  update.sqlite');

    final catalog = CatalogDatabase.openExisting(current.path);
    addTearDown(catalog.close);
    final preview = catalog.inspectUpdate(update.path);
    await catalog.verifyOfficialUpdate(update.path);
    expect(preview.workCount, greaterThan(30000));
    expect(preview.sourceTimestamp, '2099-01-02-test');

    final installed = await catalog.installUpdate(update.path);
    expect(installed.sourceTimestamp, '2099-01-02-test');
    expect(catalog.sourceTimestamp, '2099-01-02-test');
    expect(catalog.fileName, startsWith('catalog-update-'));
    expect(
      await File(p.join(dir.path, 'active-catalog.txt')).readAsString(),
      catalog.fileName,
    );
    expect(catalog.isUsingUpdate, isTrue);
    final restored = await catalog.restoreBundled();
    expect(restored.workCount, preview.workCount);
    expect(catalog.isUsingUpdate, isFalse);
    expect(
      await File(p.join(dir.path, 'active-catalog.txt')).exists(),
      isFalse,
    );
  });

  test('壊れたファイルと別形式のSQLiteを拒否する', () async {
    final dir = await Directory.systemTemp.createTemp('chronovel_bad_catalog_');
    addTearDown(() => dir.delete(recursive: true));
    final current = await File('assets/catalog/chronovel_catalog.sqlite')
        .copy(p.join(dir.path, 'current.sqlite'));
    final catalog = CatalogDatabase.openExisting(current.path);
    addTearDown(catalog.close);
    final broken = await File(p.join(dir.path, 'broken.sqlite'))
        .writeAsString('not a sqlite database');
    expect(
      () => catalog.inspectUpdate(broken.path),
      throwsA(isA<CatalogUpdateException>()),
    );
    final other = p.join(dir.path, 'other.sqlite');
    sqlite3.open(other).close();
    expect(
      () => catalog.inspectUpdate(other),
      throwsA(isA<CatalogUpdateException>()),
    );
  });

  test('更新カタログはSHA-256不足・不一致を拒否する', () async {
    final dir = await Directory.systemTemp.createTemp('novelib_hash_');
    addTearDown(() => dir.delete(recursive: true));
    final source = await File('assets/catalog/chronovel_catalog.sqlite')
        .copy(p.join(dir.path, 'official.sqlite'));
    final catalog = CatalogDatabase.openExisting(source.path);
    addTearDown(catalog.close);
    expect(
      () => catalog.verifyOfficialUpdate(source.path),
      throwsA(isA<CatalogUpdateException>()),
    );
    final wrongHash = List.filled(64, '0').join();
    await File('${source.path}.sha256')
        .writeAsString('$wrongHash  official.sqlite');
    expect(
      () => catalog.verifyOfficialUpdate(source.path),
      throwsA(isA<CatalogUpdateException>()),
    );
  });
}
