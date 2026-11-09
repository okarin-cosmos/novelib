import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/catalog/catalog_database.dart';

void main() {
  late CatalogDatabase catalog;

  setUp(() {
    catalog = CatalogDatabase.openExisting(
      'assets/catalog/chronovel_catalog.sqlite',
    );
  });

  tearDown(() => catalog.close());

  test('確認済み表記を照合し曖昧な短縮名は候補提示に留める', () {
    expect(catalog.matchTitle('ランス９')?.vndbId, 'v13802');
    expect(catalog.matchTitle('Rance6')?.vndbId, 'v2047');
    expect(catalog.matchTitle('ランス６')?.vndbId, 'v2047');
    expect(catalog.matchingCandidates('Fate').take(2).map((w) => w.vndbId), [
      'v11',
      'v50',
    ]);
    expect(catalog.matchTitle('Rance10')?.vndbId, 'v20802');
    expect(catalog.matchTitle('素晴らしき日々HD')?.vndbId, 'v3144');
    expect(catalog.matchTitle('Fate'), isNull);
    expect(catalog.matchTitle('Aozora'), isNull);
    expect(
      catalog.matchingCandidates('Aozora').map((w) => w.vndbId),
      contains('v182'),
    );
    expect(
      catalog.matchingCandidates('ParfaitRO').map((w) => w.vndbId),
      contains('v683'),
    );
    expect(
      catalog.matchingCandidates('Fate').map((w) => w.vndbId),
      containsAll(['v11', 'v50']),
    );
  });

  test('正式な日本語名の完全一致を短縮名より優先する', () {
    expect(catalog.matchTitles(['アオナツライン', 'Aonatsu'])?.titleJa, 'アオナツライン');
    expect(catalog.matchTitles(['zz_no_such_work_zz']), isNull);
  });

  test('国内作品カタログをSQLiteから読み込める', () {
    expect(catalog.workCount, 37493);
    expect(catalog.sourceTimestamp, '2026-09-03 08:00:10+00');
  });

  test('R18区分を保持し非表示検索では成人向け作品を除外する', () {
    expect(catalog.findById('v11')?.isAdult, isTrue);
    expect(catalog.findById('v2002')?.isAdult, isFalse);
    final safeResults = catalog.search('', showAdult: false);
    expect(safeResults, isNotEmpty);
    expect(safeResults.every((work) => !work.isAdult), isTrue);
  });

  test('公開投票数を考慮した評価ランキングを取得できる', () {
    final ranking = catalog.topRated(
      limit: 20,
      minimumVotes: 100,
      showAdult: false,
    );
    expect(ranking, hasLength(20));
    expect(ranking.every((work) => !work.isAdult), isTrue);
    expect(ranking.every((work) => work.voteCount >= 100), isTrue);
    for (var index = 1; index < ranking.length; index++) {
      expect(
        ranking[index - 1].rating!,
        greaterThanOrEqualTo(ranking[index].rating!),
      );
    }
  });

  test('FANZA・DLsiteの商品IDを複数保持できるカタログ表を利用できる', () {
    expect(catalog.storeProductsFor('v11'), isEmpty);
    expect(catalog.storeProductsFor('v11', store: 'dlsite'), isEmpty);
  });

  test('作品IDから対応する表紙画像URLを取得できる', () {
    final work = catalog.findById('v23740');

    expect(work, isNotNull);
    expect(work!.titleJa, '9-nine-はるいろはるこいはるのかぜ');
    expect(work.imageUrl, 'https://t.vndb.org/cv/31/95131.jpg');
  });

  test('多数の作品IDをまとめて取得でき未登録IDを除外する', () {
    final works = catalog.findByIds(['v11', 'v50', 'v999999999', 'v11']);
    expect(works.keys, containsAll(['v11', 'v50']));
    expect(works, isNot(contains('v999999999')));
    expect(works['v11']?.titleJa, isNotEmpty);
  });

  test('9-nine-を正式名称と別名から検索できる', () {
    final results = catalog.search('はるいろはるこい');
    expect(results, isNotEmpty);
    expect(
      results.any((work) => work.titleJa.contains('はるいろはるこいはるのかぜ')),
      isTrue,
    );

    final match = catalog.matchTitle('9-nine-はるいろはるこいはるのかぜ');
    expect(match, isNotNull);
    expect(match!.vndbId, startsWith('v'));
    expect(match.titleJa, contains('はるいろはるこいはるのかぜ'));
  });

  test('全角英数字や記号の違いを吸収して照合する', () {
    expect(
      normalizeCatalogTitle('戦国†恋姫Ｘ ～乙女絢爛☆戦国絵巻～ DL版'),
      normalizeCatalogTitle('戦国恋姫X乙女絢爛戦国絵巻'),
    );
  });

  test('版表記、短縮名、軽微な表記差から一意の作品を照合する', () {
    final expectations = {
      'ディメンション凸ラバース!! 豪華版': 'v60663',
      '双天恋姫': 'v50113',
      '巨乳大魔王のドスケベクエスト': 'v18722',
      '戦国†恋姫Ｘ ～乙女絢爛☆戦国絵巻～': 'v13188',
    };
    for (final entry in expectations.entries) {
      expect(catalog.matchTitle(entry.key)?.vndbId, entry.value);
    }
  });

  test('リメイク版表記と英字・日本語表記ゆれを照合する', () {
    expect(catalog.matchTitle('カルタグラFHD')?.vndbId, 'v515');
    expect(catalog.matchTitle('カルタグラ FHD版')?.vndbId, 'v515');
    expect(catalog.matchTitle('Sennagi')?.vndbId, 'v44199');
    expect(catalog.matchTitle('戦凪')?.vndbId, 'v44199');
  });

  test('複数の版・配信・バージョン表記を段階的に除去する', () {
    expect(
      catalogTitleVariants('カルタグラ FHD パッケージ版 Ver1.02'),
      contains(normalizeCatalogTitle('カルタグラ')),
    );
    expect(catalog.matchTitle('カルタグラ FHD パッケージ版 Ver1.02')?.vndbId, 'v515');
    expect(
      catalog.matchTitle('Astronautssirius_ryorankawarazak')?.vndbId,
      'v22180',
    );
    expect(
      catalog.matchTitle('KanojyoNoAnetonolkenaiKankei')?.vndbId,
      'v36134',
    );
    expect(catalog.matchTitle('素晴らしき日々HD Windows10対応版')?.vndbId, 'v3144');
  });

  test('カタログ別名の途中表記も一意な場合だけ照合する', () {
    expect(catalog.matchTitle('Aonatsu Lin')?.titleJa, 'アオナツライン');
  });
}
