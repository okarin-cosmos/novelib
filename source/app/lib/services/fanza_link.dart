Uri? parseFanzaLink(Object? value) {
  if (value is! String) return null;
  final uri = Uri.tryParse(value);
  const hosts = {'al.fanza.co.jp', 'al.dmm.co.jp', 'al.dmm.com'};
  if (uri == null ||
      uri.scheme != 'https' ||
      !hosts.contains(uri.host) ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort) {
    return null;
  }
  final landing = Uri.tryParse(uri.queryParameters['lurl'] ?? '');
  if (landing == null ||
      landing.scheme != 'https' ||
      landing.userInfo.isNotEmpty ||
      landing.hasPort) {
    return null;
  }
  if (![
    'dmm.co.jp',
    'fanza.co.jp',
    'dmm.com',
  ].any((h) => landing.host == h || landing.host.endsWith('.$h'))) {
    return null;
  }
  if ((uri.queryParameters['af_id'] ?? '').isEmpty) return null;
  return uri;
}
