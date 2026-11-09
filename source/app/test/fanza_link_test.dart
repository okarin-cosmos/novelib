import 'package:flutter_test/flutter_test.dart';
import 'package:chronovel/services/fanza_link.dart';

void main() {
  test('only approved affiliate hosts and merchant destinations are accepted', () {
    const valid =
        'https://al.fanza.co.jp/?lurl=https%3A%2F%2Fdlsoft.dmm.co.jp%2Fdetail%2Fx&af_id=test-990';
    expect(parseFanzaLink(valid), isNotNull);
    for (final input in [
      null,
      '',
      'javascript:alert(1)',
      valid.replaceAll('dlsoft.dmm.co.jp', 'evil.test'),
      valid.replaceAll('al.fanza.co.jp', 'al.fanza.co.jp.evil.test'),
    ]) {
      expect(parseFanzaLink(input), isNull);
    }
  });
}
