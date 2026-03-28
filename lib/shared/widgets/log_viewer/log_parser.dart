import 'package:flutter/foundation.dart';

enum LogLevel {
  error,
  warn,
  info,
  debug,
  trace,
  unknown;

  static LogLevel fromString(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
      case 'ERR':
      case 'EXCEPTION':
      case 'FATAL':
        return LogLevel.error;
      case 'WARN':
      case 'WARNING':
        return LogLevel.warn;
      case 'INFO':
        return LogLevel.info;
      case 'DEBUG':
        return LogLevel.debug;
      case 'TRACE':
        return LogLevel.trace;
      default:
        return LogLevel.unknown;
    }
  }
}

class LogLine {
  final String originalContent;
  final String displayContent;
  final LogLevel level;
  final DateTime? timestamp;
  final int? timestampEndIndex;
  final bool isMatch;

  LogLine({
    required this.originalContent,
    required this.displayContent,
    required this.level,
    this.timestamp,
    this.timestampEndIndex,
    this.isMatch = false,
  });

  LogLine copyWith({
    String? originalContent,
    String? displayContent,
    LogLevel? level,
    DateTime? timestamp,
    int? timestampEndIndex,
    bool? isMatch,
  }) {
    return LogLine(
      originalContent: originalContent ?? this.originalContent,
      displayContent: displayContent ?? this.displayContent,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      timestampEndIndex: timestampEndIndex ?? this.timestampEndIndex,
      isMatch: isMatch ?? this.isMatch,
    );
  }
}

class LogParser {
  // Typical log format: "2023-01-01 12:00:00 [INFO] Message"
  static final RegExp _logPattern = RegExp(
    r'^(\d{4}-\d{2}-\d{2}[T\s]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?)\s*(?:\[?(\w+)\]?)?\s*(.*)$',
  );

  static Future<List<LogLine>> parse(String rawLogs) async {
    if (rawLogs.isEmpty) return [];
    return compute(_parseInBackground, rawLogs);
  }

  static List<LogLine> _parseInBackground(String rawLogs) {
    return rawLogs
        .trimRight()
        .split('\n')
        .map((line) => _parseLogLine(line))
        .toList();
  }

  static LogLine _parseLogLine(String line) {
    // Try to match the timestamp at the beginning of the line
    // We use a more generic pattern to capture the timestamp part
    final match = _logPattern.firstMatch(line);
    DateTime? timestamp;
    LogLevel level = LogLevel.unknown;
    int? timestampEndIndex;

    if (match != null) {
      final timeStr = match.group(1);
      final levelStr = match.group(2);

      if (timeStr != null) {
        try {
          timestamp = DateTime.parse(timeStr);
          timestampEndIndex = match.start + timeStr.length;
        } catch (_) {
          // Ignore parsing errors
        }
      }

      if (levelStr != null) {
        level = LogLevel.fromString(levelStr);
      }
    }

    // Fallback level detection
    if (level == LogLevel.unknown) {
      final upperLine = line.toUpperCase();
      if (upperLine.contains('ERROR') ||
          upperLine.contains('ERR') ||
          upperLine.contains('EXCEPTION') ||
          upperLine.contains('FATAL')) {
        level = LogLevel.error;
      } else if (upperLine.contains('WARN') || upperLine.contains('WARNING')) {
        level = LogLevel.warn;
      } else if (upperLine.contains('INFO')) {
        level = LogLevel.info;
      } else if (upperLine.contains('DEBUG')) {
        level = LogLevel.debug;
      } else if (upperLine.contains('TRACE')) {
        level = LogLevel.trace;
      }
    }

    return LogLine(
      originalContent: line,
      displayContent: line,
      level: level,
      timestamp: timestamp,
      timestampEndIndex: timestampEndIndex,
    );
  }
}
