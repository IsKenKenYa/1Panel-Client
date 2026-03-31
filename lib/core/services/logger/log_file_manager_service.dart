import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../config/logger_config.dart';
import 'log_level.dart';

class LogFileManagerService {
  static final LogFileManagerService _instance =
      LogFileManagerService._internal();
  factory LogFileManagerService() => _instance;
  LogFileManagerService._internal();
  Future<void> _writeQueue = Future<void>.value();
  static final RegExp _levelPattern =
      RegExp(r'\b(TRACE|DEBUG|INFO|WARNING|ERROR|FATAL)\b');

  Future<Directory> getLogDirectory() async {
    final baseDir = await getApplicationSupportDirectory();
    final logDir = Directory('${baseDir.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    return logDir;
  }

  Future<File> getCurrentLogFile() async {
    final dir = await getLogDirectory();
    return File('${dir.path}/${LoggerConfig.logFileName}');
  }

  Future<void> appendLine(String line) async {
    if (!LoggerConfig.enableFileOutput) return;
    _writeQueue = _writeQueue.then((_) => _appendLineInternal(line));
    return _writeQueue;
  }

  Future<void> _appendLineInternal(String line) async {
    final file = await getCurrentLogFile();
    await _rotateIfNeeded(file);
    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
  }

  Future<void> _rotateIfNeeded(File current) async {
    if (!await current.exists()) return;
    final length = await current.length();
    if (length < LoggerConfig.maxLogFileSize) return;
    final dir = await getLogDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rotated = File('${dir.path}/app_logs_$timestamp.txt');
    await current.rename(rotated.path);
    await _enforceMaxFiles();
  }

  Future<void> _enforceMaxFiles() async {
    final dir = await getLogDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.txt'))
        .toList()
      ..sort((a, b) =>
          b.lastModifiedSync().millisecondsSinceEpoch -
          a.lastModifiedSync().millisecondsSinceEpoch);
    if (files.length <= LoggerConfig.maxLogFiles) return;
    for (final file in files.skip(LoggerConfig.maxLogFiles)) {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> cleanupExpired() async {
    final dir = await getLogDirectory();
    final expireAt =
        DateTime.now().subtract(Duration(days: LoggerConfig.logRetentionDays));
    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.txt')) continue;
      final modified = await entity.lastModified();
      if (modified.isBefore(expireAt)) {
        await entity.delete();
      }
    }
    await _enforceMaxFiles();
  }

  Future<List<File>> listLogFiles() async {
    final dir = await getLogDirectory();
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.txt'))
        .toList()
      ..sort((a, b) =>
          b.lastModifiedSync().millisecondsSinceEpoch -
          a.lastModifiedSync().millisecondsSinceEpoch);
  }

  Future<String> readAllLogs({AppLogLevel? minLevel}) async {
    final files = await listLogFiles();
    final buffer = StringBuffer();
    for (final file in files.reversed) {
      if (!await file.exists()) continue;
      buffer.writeln('===== ${file.uri.pathSegments.last} =====');
      final content = await file.readAsString();
      if (minLevel == null) {
        buffer.writeln(content);
      } else {
        buffer.writeln(_filterLogsByLevel(content, minLevel));
      }
    }
    return buffer.toString();
  }

  String _filterLogsByLevel(String raw, AppLogLevel minLevel) {
    if (raw.isEmpty) return raw;
    final lines = raw.split('\n');
    final kept = <String>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        kept.add(line);
        continue;
      }
      final match = _levelPattern.firstMatch(line.toUpperCase());
      if (match == null) {
        kept.add(line);
        continue;
      }
      final level = AppLogLevel.fromStorage(match.group(1)?.toLowerCase());
      if (level.weight >= minLevel.weight) {
        kept.add(line);
      }
    }

    return kept.join('\n');
  }

  Future<void> clearLogs() async {
    final files = await listLogFiles();
    for (final f in files) {
      if (await f.exists()) await f.delete();
    }
  }
}
