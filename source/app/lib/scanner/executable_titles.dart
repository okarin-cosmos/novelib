import 'dart:convert';
import 'dart:io';

/// Reads version resources only. Never launches the inspected executables.
Future<Map<String, List<String>>> executableTitles(List<String> paths) async {
  if (!Platform.isWindows || paths.isEmpty) return {};
  Process? process;
  try {
    process = await Process.start('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      r'''
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$paths = [Console]::In.ReadToEnd() | ConvertFrom-Json
$rows = foreach ($path in $paths) {
  try {
    $info = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($path)
    [pscustomobject]@{path=$path; names=@($info.ProductName, $info.FileDescription)}
  } catch { }
}
ConvertTo-Json -InputObject @($rows) -Compress -Depth 3
''',
    ]);
    final stdout = process.stdout.transform(utf8.decoder).join();
    final stderr = process.stderr.drain<void>();
    process.stdin.add(utf8.encode(jsonEncode(paths)));
    await process.stdin.close();
    final output = await stdout.timeout(const Duration(seconds: 15));
    await stderr;
    if (await process.exitCode != 0) return {};
    final rows = jsonDecode(output) as List;
    final ignored = RegExp(
      r'(kirikiri|吉里吉里|unity|ethornell|siglus|bgi|catsystem|application|アプリケーション|実行ファイル|microsoft|エンジン|engine|^system\d|^game$)',
      caseSensitive: false,
    );
    return {
      for (final row in rows)
        row['path'] as String: (row['names'] as List)
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.length >= 3 && !ignored.hasMatch(s))
            .toSet()
            .toList(),
    };
  } catch (_) {
    return {};
  } finally {
    process?.kill();
  }
}
