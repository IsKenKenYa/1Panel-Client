import 'dart:io';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/logger_config.dart';
import 'log_format.dart';
import 'log_level.dart';

class LogFileManagerService {
  static final LogFileManagerService _instance =
      LogFileManagerService._internal();
  factory LogFileManagerService() => _instance;
  LogFileManagerService._internal();
  Future<void> _writeQueue = Future<void>.value();
  final _browserLines = ListQueue<String>();
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
    if (kIsWeb) {
      _browserLines.addLast(line);
      while (_browserLines.length > 2000) {
        _browserLines.removeFirst();
      }
      return;
    }
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
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.txt')) {
        files.add(entity);
      }
    }
    final entries = <({File file, DateTime modified})>[];
    for (final file in files) {
      entries.add((file: file, modified: await file.lastModified()));
    }
    entries.sort((a, b) =>
        b.modified.millisecondsSinceEpoch - a.modified.millisecondsSinceEpoch);
    if (files.length <= LoggerConfig.maxLogFiles) return;
    for (final entry in entries.skip(LoggerConfig.maxLogFiles)) {
      if (await entry.file.exists()) {
        await entry.file.delete();
      }
    }
  }

  Future<void> cleanupExpired() async {
    if (kIsWeb) return;
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
    if (kIsWeb) return [];
    final dir = await getLogDirectory();
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.txt')) {
        files.add(entity);
      }
    }
    final entries = <({File file, DateTime modified})>[];
    for (final file in files) {
      entries.add((file: file, modified: await file.lastModified()));
    }
    entries.sort((a, b) =>
        b.modified.millisecondsSinceEpoch - a.modified.millisecondsSinceEpoch);
    return entries.map((entry) => entry.file).toList();
  }

  /// 读取所有日志文件并按指定格式返回。
  ///
  /// - `LogFormat.aiAgent`（默认）：直接返回文件原文（单行结构化，节省 token）
  /// - `LogFormat.humanReadable`：解析 AI Agent 格式后转为 emoji 风格
  Future<String> readAllLogs({
    AppLogLevel? minLevel,
    LogFormat format = LogFormat.aiAgent,
  }) async {
    if (kIsWeb) {
      final raw = _browserLines.join('\n');
      final filtered = minLevel == null ? raw : _filterLogsByLevel(raw, minLevel);
      return format == LogFormat.aiAgent
          ? filtered
          : reformatAiAgentToHumanReadable(filtered);
    }
    final files = await listLogFiles();
    final buffer = StringBuffer();
    for (final file in files.reversed) {
      if (!await file.exists()) continue;
      buffer.writeln('===== ${file.uri.pathSegments.last} =====');
      final content = await file.readAsString();
      final filtered = minLevel == null
          ? content
          : _filterLogsByLevel(content, minLevel);
      if (format == LogFormat.aiAgent) {
        buffer.writeln(filtered);
      } else {
        buffer.writeln(reformatAiAgentToHumanReadable(filtered));
      }
    }
    return buffer.toString();
  }

  /// 仅读取当前日志文件的**最后 N 行**，用于预览。
  ///
  /// 不读取全部文件，避免大文件（如 43MB）卡 UI。
  Future<String> tailCurrentLog(int maxLines) async {
    if (kIsWeb) {
      return _browserLines.skip((_browserLines.length - maxLines).clamp(0,
          _browserLines.length)).join('\n');
    }
    final file = await getCurrentLogFile();
    if (!await file.exists()) return '';
    final length = await file.length();
    if (length == 0) return '';
    // 简单实现：从文件末尾向前读取最多 256KB，找出最近 N 行
    const chunkSize = 256 * 1024;
    final readSize = length < chunkSize ? length : chunkSize;
    final raf = await file.open();
    try {
      await raf.setPosition(length - readSize);
      final bytes = await raf.read(readSize);
      final text = String.fromCharCodes(bytes);
      final lines = text.split('\n');
      if (lines.length <= maxLines) return text;
      return lines.sublist(lines.length - maxLines).join('\n');
    } finally {
      await raf.close();
    }
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
    if (kIsWeb) {
      _browserLines.clear();
      return;
    }
    final files = await listLogFiles();
    for (final f in files) {
      if (await f.exists()) await f.delete();
    }
  }
}
