import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../database/app_database.dart';

class RunningProcessInfo {
  const RunningProcessInfo({
    required this.pid,
    required this.path,
    required this.startedAt,
  });

  final int pid;
  final String path;
  final DateTime startedAt;
}

typedef ProcessSnapshotLoader = Future<List<RunningProcessInfo>> Function();

class GameProcessMonitor {
  GameProcessMonitor({
    required this.database,
    required this.onRunningChanged,
    ProcessSnapshotLoader? loadProcesses,
    this.interval = const Duration(seconds: 10),
  }) : _loadProcesses = loadProcesses ?? loadWindowsProcesses;

  final AppDatabase database;
  final ProcessRunningChanged onRunningChanged;
  final ProcessSnapshotLoader _loadProcesses;
  final Duration interval;

  Timer? _timer;
  bool _polling = false;
  Set<String> _lastRunning = const {};

  Future<void> start() async {
    await pollNow();
    _timer ??= Timer.periodic(interval, (_) => unawaited(pollNow()));
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> pollNow() async {
    if (_polling) return;
    _polling = true;
    try {
      final processes = await _loadProcesses();
      final games = await database.getGames();
      final active = await database.getActivePlaySessions();
      final activeIds = {for (final row in active) row.gameId};
      final activeByGame = {for (final row in active) row.gameId: row};
      final running = <int>{};
      final now = DateTime.now().toUtc();

      for (final process in processes) {
        final game = _bestMatch(process.path, games);
        if (game == null) continue;
        final previous = activeByGame[game.id];
        if (previous != null &&
            process.startedAt.isAfter(previous.lastSeenAt.add(interval * 2))) {
          await database.finishActivePlaySession(game.id);
          activeByGame.remove(game.id);
        }
        running.add(game.id);
        if (game.status == 'not_played') {
          await database.changeGameStatus(game.id, 'playing');
        }
        await database.touchActivePlaySession(
          gameId: game.id,
          startedAt: process.startedAt,
          seenAt: now,
        );
      }
      for (final gameId in activeIds.difference(running)) {
        await database.finishActivePlaySession(gameId);
      }

      final next = running.map((id) => '$id').toSet();
      final previouslyActive = activeIds.map((id) => '$id').toSet();
      if (!_sameIds(_lastRunning, next) || !_sameIds(previouslyActive, next)) {
        _lastRunning = Set.unmodifiable(next);
        onRunningChanged(_lastRunning);
      }
    } catch (_) {
      // Process inspection can temporarily fail for protected Windows
      // processes. Keep the previous state and retry on the next interval.
    } finally {
      _polling = false;
    }
  }

  static GameRecord? _bestMatch(String executablePath, List<GameRecord> games) {
    final processPath = p.normalize(executablePath).toLowerCase();
    GameRecord? result;
    var bestLength = -1;
    for (final game in games) {
      final exe = p.normalize(game.exePath).toLowerCase();
      final directory = p.normalize(game.installDir).toLowerCase();
      final exact = processPath == exe;
      final inside = processPath.startsWith('$directory${p.separator}');
      if ((exact || inside) && directory.length > bestLength) {
        result = game;
        bestLength = directory.length;
      }
    }
    return result;
  }

  static bool _sameIds(Set<String> left, Set<String> right) =>
      left.length == right.length && left.containsAll(right);

  static Future<List<RunningProcessInfo>> loadWindowsProcesses() async {
    if (!Platform.isWindows) return const [];
    const command = r'''
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
Get-Process | ForEach-Object {
  try {
    if ($_.Path) {
      "$($_.Id)`t$($_.StartTime.ToUniversalTime().ToString('o'))`t$($_.Path)"
    }
  } catch {}
}
''';
    final result = await Process.run(
      'powershell.exe',
      const ['-NoProfile', '-NonInteractive', '-Command', command],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) return const [];
    final processes = <RunningProcessInfo>[];
    for (final line in const LineSplitter().convert(result.stdout as String)) {
      final fields = line.split('\t');
      if (fields.length < 3) continue;
      final pid = int.tryParse(fields[0]);
      final startedAt = DateTime.tryParse(fields[1]);
      final path = fields.sublist(2).join('\t').trim();
      if (pid == null || startedAt == null || path.isEmpty) continue;
      processes.add(
        RunningProcessInfo(pid: pid, path: path, startedAt: startedAt.toUtc()),
      );
    }
    return processes;
  }
}

typedef ProcessRunningChanged = void Function(Set<String> value);
