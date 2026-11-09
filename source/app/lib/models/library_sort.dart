import 'game.dart';

enum LibrarySort {
  original('手動順'),
  reading('五十音順（推定読み）'),
  brand('ブランド順'),
  rating('評価順'),
  playTime('プレイ時間順'),
  released('発売日順');

  const LibrarySort(this.label);
  final String label;
}

String _widthAndKana(String text) => String.fromCharCodes(
  text.runes.map((r) {
    if (r >= 0xff01 && r <= 0xff5e) return r - 0xfee0;
    if (r >= 0x30a1 && r <= 0x30f6) return r - 0x60;
    return r;
  }),
).toLowerCase();

final _romaji = <String, String>{
  for (final row in [
    'a:あ i:い u:う e:え o:お',
    'ka:か ki:き ku:く ke:け ko:こ ga:が gi:ぎ gu:ぐ ge:げ go:ご',
    'sa:さ shi:し si:し su:す se:せ so:そ za:ざ ji:じ zi:じ zu:ず ze:ぜ zo:ぞ',
    'ta:た chi:ち ti:ち tsu:つ tu:つ te:て to:と da:だ di:ぢ du:づ de:で do:ど',
    'na:な ni:に nu:ぬ ne:ね no:の ha:は hi:ひ fu:ふ hu:ふ he:へ ho:ほ',
    'ba:ば bi:び bu:ぶ be:べ bo:ぼ pa:ぱ pi:ぴ pu:ぷ pe:ぺ po:ぽ',
    'ma:ま mi:み mu:む me:め mo:も ya:や yu:ゆ yo:よ',
    'ra:ら ri:り ru:る re:れ ro:ろ wa:わ wo:を',
    'kya:きゃ kyu:きゅ kyo:きょ gya:ぎゃ gyu:ぎゅ gyo:ぎょ',
    'sha:しゃ shu:しゅ sho:しょ sya:しゃ syu:しゅ syo:しょ',
    'cha:ちゃ chu:ちゅ cho:ちょ tya:ちゃ tyu:ちゅ tyo:ちょ',
    'ja:じゃ ju:じゅ jo:じょ jya:じゃ jyu:じゅ jyo:じょ',
    'nya:にゃ nyu:にゅ nyo:にょ hya:ひゃ hyu:ひゅ hyo:ひょ',
    'bya:びゃ byu:びゅ byo:びょ pya:ぴゃ pyu:ぴゅ pyo:ぴょ',
    'mya:みゃ myu:みゅ myo:みょ rya:りゃ ryu:りゅ ryo:りょ',
    'fa:ふぁ fi:ふぃ fe:ふぇ fo:ふぉ va:ゔぁ vi:ゔぃ vu:ゔ ve:ゔぇ vo:ゔぉ',
  ])
    for (final pair in row.split(' ')) pair.split(':')[0]: pair.split(':')[1],
};

String? _toKana(String source) {
  var text = _widthAndKana(source);
  for (final entry in {
    'ā': 'aa',
    'ī': 'ii',
    'ū': 'uu',
    'ē': 'ee',
    'ō': 'ou',
  }.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  text = text.replaceAll(RegExp(r"[^a-z0-9']"), '');
  if (text.isEmpty) return null;
  final result = StringBuffer();
  for (var i = 0; i < text.length;) {
    final char = text[i];
    if (RegExp(r'[0-9]').hasMatch(char)) {
      result.write(char);
      i++;
      continue;
    }
    if (char == "'") {
      i++;
      continue;
    }
    if (char == 'n' &&
        (i + 1 == text.length || !'aiueoy'.contains(text[i + 1]))) {
      result.write('ん');
      i++;
      continue;
    }
    if (i + 1 < text.length &&
        char == text[i + 1] &&
        !'aiueon'.contains(char)) {
      result.write('っ');
      i++;
      continue;
    }
    var matched = false;
    for (final length in [3, 2, 1]) {
      if (i + length > text.length) continue;
      final kana = _romaji[text.substring(i, i + length)];
      if (kana == null) continue;
      result.write(kana);
      i += length;
      matched = true;
      break;
    }
    if (!matched) return null;
  }
  return result.toString();
}

/// Kana first, then Latin/numbers, then titles without a usable reading.
String libraryReadingKey(GameEntry game) {
  var value = _widthAndKana(game.title);
  if (RegExp(r'[一-龯々]').hasMatch(value)) {
    final reading = game.titleRomaji == null
        ? null
        : _toKana(game.titleRomaji!);
    if (reading == null) return '2$value';
    value = reading;
  }
  value = value.replaceAll(RegExp(r'[^ぁ-ゖa-z0-9]'), '');
  const from = 'がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉゃゅょっ';
  const to = 'かきくけこさしすせそたちつてとはひふへほはひふへほあいうえおやゆよつ';
  final base = String.fromCharCodes(
    value.runes.map((r) {
      final index = from.indexOf(String.fromCharCode(r));
      return index < 0 ? r : to.codeUnitAt(index);
    }),
  );
  return '${RegExp(r'^[ぁ-ゖ]').hasMatch(value) ? '0' : '1'}$base\u0000$value';
}

List<GameEntry> sortLibraryGames(
  Iterable<GameEntry> games,
  LibrarySort sort, {
  bool reversed = false,
}) {
  final result = games.toList();
  if (sort == LibrarySort.original) {
    return reversed ? result.reversed.toList() : result;
  }
  final keys = {for (final g in result) g.id: libraryReadingKey(g)};
  double? score(GameEntry g) {
    final values = g.members.map((m) => m.rating).whereType<int>().toList();
    return values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
  }

  int compareNullable<T extends Comparable>(
    T? a,
    T? b, {
    bool descending = false,
  }) {
    if (a == null || b == null) {
      return a == b
          ? 0
          : a == null
          ? 1
          : -1;
    }
    final order = a.compareTo(b);
    return (descending != reversed) ? -order : order;
  }

  result.sort((a, b) {
    final int order;
    switch (sort) {
      case LibrarySort.reading:
        order = (reversed ? -1 : 1) * keys[a.id]!.compareTo(keys[b.id]!);
      case LibrarySort.brand:
        String? brand(GameEntry g) =>
            g.brand.isEmpty || g.brand == g.engine || g.brand == 'ローカル作品'
            ? null
            : _widthAndKana(g.brand);
        order = compareNullable(brand(a), brand(b));
      case LibrarySort.rating:
        order = compareNullable(score(a), score(b), descending: true);
      case LibrarySort.playTime:
        order = compareNullable(a.playHours, b.playHours, descending: true);
      case LibrarySort.released:
        order = compareNullable(
          DateTime.tryParse(a.released ?? ''),
          DateTime.tryParse(b.released ?? ''),
          descending: true,
        );
      case LibrarySort.original:
        order = 0;
    }
    if (order != 0) return order;
    final name = keys[a.id]!.compareTo(keys[b.id]!);
    return name != 0 ? name : a.id.compareTo(b.id);
  });
  return result;
}
