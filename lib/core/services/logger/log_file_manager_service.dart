import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../config/logger_config.dart';

class LogFileManagerService {
  static final LogFileManagerService _instance =
      LogFileManagerService._internal();
  factory LogFileManagerService() => _instance;
  LogFileManagerService._internal();

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

  Future<String> readAllLogs() async {
    final files = await listLogFiles();
    final buffer = StringBuffer();
    for (final file in files.reversed) {
      if (!await file.exists()) continue;
      buffer.writeln('===== ${file.uri.pathSegments.last} =====');
      buffer.writeln(await file.readAsString());
    }
    return buffer.toString();
  }

  Future<void> clearLogs() async {
    final files = await listLogFiles();
    for (final f in files) {
      if (await f.exists()) await f.delete();
    }
  }
}
