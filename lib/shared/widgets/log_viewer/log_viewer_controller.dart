import 'package:flutter/material.dart';

class LogSettings {
  final double fontSize;
  final bool isWrap;
  final bool showTimestamp;
  final ThemeMode themeMode;

  LogSettings({
    this.fontSize = 14.0,
    this.isWrap = false,
    this.showTimestamp = true,
    this.themeMode = ThemeMode.system,
  });

  LogSettings copyWith({
    double? fontSize,
    bool? isWrap,
    bool? showTimestamp,
    ThemeMode? themeMode,
  }) {
    return LogSettings(
      fontSize: fontSize ?? this.fontSize,
      isWrap: isWrap ?? this.isWrap,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

enum LogLevel {
  error,
  warn,
  info,
  debug,
  unknown;

  static LogLevel fromString(String level) {
    switch (level.toUpperCase()) {
      case 'ERROR':
      case 'ERR':
        return LogLevel.error;
      case 'WARN':
      case 'WARNING':
        return LogLevel.warn;
      case 'INFO':
        return LogLevel.info;
      case 'DEBUG':
        return LogLevel.debug;
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
  final bool isMatch;

  LogLine({
    required this.originalContent,
    required this.displayContent,
    required this.level,
    this.timestamp,
    this.isMatch = false,
  });

  LogLine copyWith({
    String? originalContent,
    String? displayContent,
    LogLevel? level,
    DateTime? timestamp,
    bool? isMatch,
  }) {
    return LogLine(
      originalContent: originalContent ?? this.originalContent,
      displayContent: displayContent ?? this.displayContent,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      isMatch: isMatch ?? this.isMatch,
    );
  }
}

class LogViewerController extends ChangeNotifier {
  List<LogLine> _logs = [];
  List<LogLine> _filteredLogs = [];
  LogSettings _settings = LogSettings();
  String _searchQuery = '';
  int _currentMatchIndex = -1;

  List<LogLine> get logs => _logs;
  List<LogLine> get filteredLogs => _filteredLogs;
  LogSettings get settings => _settings;
  String get searchQuery => _searchQuery;
  int get currentMatchIndex => _currentMatchIndex;

  // Typical log format: "2023-01-01 12:00:00 [INFO] Message"
  static final RegExp _logPattern = RegExp(
    r'^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?)\s*(?:\[?(\w+)\]?)?\s*(.*)$',
  );

  void setLogs(String rawLogs) {
    if (rawLogs.isEmpty) {
      _logs = [];
      _filteredLogs = [];
      notifyListeners();
      return;
    }
    _logs = rawLogs.trimRight().split('\n').map((line) => parseLogLine(line)).toList();
    _applyFilters();
  }

  void search(String query) {
    _searchQuery = query;
    _currentMatchIndex = -1;
    _applyFilters();
  }

  void updateSettings(LogSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  LogLine parseLogLine(String line) {
    final match = _logPattern.firstMatch(line);
    DateTime? timestamp;
    LogLevel level = LogLevel.unknown;

    if (match != null) {
      final timeStr = match.group(1);
      final levelStr = match.group(2);

      if (timeStr != null) {
        try {
          timestamp = DateTime.parse(timeStr);
        } catch (_) {
          // Ignore parsing errors
        }
      }

      if (levelStr != null) {
        level = LogLevel.fromString(levelStr);
      }
    }

    // Fallback level detection if regex didn't catch it or for lines that don't match typical format
    if (level == LogLevel.unknown) {
      if (line.contains('ERROR') || line.contains('ERR')) {
        level = LogLevel.error;
      } else if (line.contains('WARN') || line.contains('WARNING')) {
        level = LogLevel.warn;
      } else if (line.contains('INFO')) {
        level = LogLevel.info;
      } else if (line.contains('DEBUG')) {
        level = LogLevel.debug;
      }
    }

    return LogLine(
      originalContent: line,
      displayContent: line,
      level: level,
      timestamp: timestamp,
    );
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredLogs = List.from(_logs);
    } else {
      // Start simple: just mark matches. 
      // If we want to filter the list to only show matches, we would do that here.
      // But typically a log viewer shows all logs and highlights matches.
      // The requirement says "filteredLogs", which implies a subset or processed list.
      // Let's assume for now it returns all logs but with isMatch set.
      
      _filteredLogs = _logs.map((log) {
        final isMatch = log.originalContent.toLowerCase().contains(_searchQuery.toLowerCase());
        return log.copyWith(isMatch: isMatch);
      }).toList();
      
      // If we strictly want "filtered" to mean "only showing matching lines", we would use where().
      // However, usually log viewers highlight. 
      // Given the properties `currentMatchIndex`, it implies navigation through matches, 
      // which usually happens in the full list. 
      // But let's check if the user meant "search results".
      // "filteredLogs" name suggests filtering.
      // Let's implement highlighting in _filteredLogs (which is the list being displayed).
    }
    notifyListeners();
  }
}
