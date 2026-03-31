import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_parser.dart';
import 'log_theme.dart';

export 'log_parser.dart';
export 'log_theme.dart';

enum LogTimestampFormat {
  absolute,
  relative,
}

enum LogViewMode {
  wrap,
  scrollLine,
  scrollPage,
}

class LogSettings {
  final double fontSize;
  final double lineHeight;
  final LogViewMode? _viewMode;
  final bool showTimestamp;
  final LogTimestampFormat? _timestampFormat;
  final ThemeMode? _themeMode;
  final LogTheme theme;

  LogViewMode get viewMode => _viewMode ?? LogViewMode.scrollLine;
  LogTimestampFormat get timestampFormat =>
      _timestampFormat ?? LogTimestampFormat.absolute;
  ThemeMode get themeMode => _themeMode ?? ThemeMode.system;

  LogSettings({
    this.fontSize = 14.0,
    this.lineHeight = 1.2,
    LogViewMode? viewMode,
    this.showTimestamp = true,
    LogTimestampFormat? timestampFormat,
    ThemeMode? themeMode,
    LogTheme? theme,
  })  : _viewMode = viewMode ?? LogViewMode.scrollLine,
        _timestampFormat = timestampFormat ?? LogTimestampFormat.absolute,
        _themeMode = themeMode ?? ThemeMode.system,
        theme = theme ?? LogTheme.defaultTheme;

  // Backward compatibility for isWrap
  bool get isWrap => viewMode == LogViewMode.wrap;

  LogSettings copyWith({
    double? fontSize,
    double? lineHeight,
    LogViewMode? viewMode,
    bool? showTimestamp,
    LogTimestampFormat? timestampFormat,
    ThemeMode? themeMode,
    LogTheme? theme,
  }) {
    return LogSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      viewMode: viewMode ?? this.viewMode,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      timestampFormat: timestampFormat ?? this.timestampFormat,
      themeMode: themeMode ?? this.themeMode,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'viewMode': viewMode.index,
      'showTimestamp': showTimestamp,
      'timestampFormat': timestampFormat.index,
      'themeMode': themeMode.index,
      'theme': theme.toJson(),
    };
  }

  factory LogSettings.fromJson(Map<String, dynamic> json) {
    // Handle migration from isWrap
    LogViewMode mode = LogViewMode.scrollLine;
    if (json.containsKey('viewMode')) {
      final idx = json['viewMode'] as int?;
      if (idx != null && idx >= 0 && idx < LogViewMode.values.length) {
        mode = LogViewMode.values[idx];
      }
    } else if (json.containsKey('isWrap')) {
      mode = (json['isWrap'] as bool? ?? false)
          ? LogViewMode.wrap
          : LogViewMode.scrollLine;
    }

    LogTimestampFormat timestampFormat = LogTimestampFormat.absolute;
    if (json.containsKey('timestampFormat')) {
      final idx = json['timestampFormat'] as int?;
      if (idx != null && idx >= 0 && idx < LogTimestampFormat.values.length) {
        timestampFormat = LogTimestampFormat.values[idx];
      }
    }

    ThemeMode themeMode = ThemeMode.system;
    if (json.containsKey('themeMode')) {
      final idx = json['themeMode'] as int?;
      if (idx != null && idx >= 0 && idx < ThemeMode.values.length) {
        themeMode = ThemeMode.values[idx];
      }
    }

    return LogSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.2,
      viewMode: mode,
      showTimestamp: json['showTimestamp'] as bool? ?? true,
      timestampFormat: timestampFormat,
      themeMode: themeMode,
      theme: json['theme'] != null ? LogTheme.fromJson(json['theme']) : null,
    );
  }
}

class LogViewerController extends ChangeNotifier {
  static const _storageKey = 'log_viewer_settings';

  List<LogLine> _logs = [];
  List<LogLine> _filteredLogs = [];
  LogSettings _settings = LogSettings();
  String _searchQuery = '';
  int _currentMatchIndex = -1;
  final List<int> _matchIndices = [];
  DateTime? _firstLogTimestamp;

  LogViewerController() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr);
        _settings = LogSettings.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      appLogger.wWithPackage(
        'shared.widgets.log_viewer',
        'Failed to load log settings',
        error: e,
      );
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_settings.toJson());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      appLogger.wWithPackage(
        'shared.widgets.log_viewer',
        'Failed to save log settings',
        error: e,
      );
    }
  }

  List<LogLine> get logs => _logs;
  List<LogLine> get filteredLogs => _filteredLogs;
  LogSettings get settings => _settings;
  String get searchQuery => _searchQuery;
  int get currentMatchIndex => _currentMatchIndex;
  int get totalMatches => _matchIndices.length;
  int get currentMatchCount => _currentMatchIndex + 1;
  DateTime? get firstLogTimestamp => _firstLogTimestamp;

  Future<void> setLogs(String rawLogs) async {
    if (rawLogs.isEmpty) {
      _logs = [];
      _filteredLogs = [];
      _firstLogTimestamp = null;
      notifyListeners();
      return;
    }
    _logs = await LogParser.parse(rawLogs);

    // Find first timestamp
    _firstLogTimestamp = null;
    for (final log in _logs) {
      if (log.timestamp != null) {
        _firstLogTimestamp = log.timestamp;
        break;
      }
    }

    _applyFilters();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void updateSettings(LogSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
    _saveSettings();
  }

  void _applyFilters() {
    _matchIndices.clear();
    _currentMatchIndex = -1;

    if (_searchQuery.isEmpty) {
      _filteredLogs = List.from(_logs);
    } else {
      _filteredLogs = _logs.map((log) {
        final isMatch = log.originalContent
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        return log.copyWith(isMatch: isMatch);
      }).toList();

      for (int i = 0; i < _filteredLogs.length; i++) {
        if (_filteredLogs[i].isMatch) {
          _matchIndices.add(i);
        }
      }
    }
    notifyListeners();
  }

  int? nextMatch() {
    if (_matchIndices.isEmpty) return null;
    if (_currentMatchIndex < _matchIndices.length - 1) {
      _currentMatchIndex++;
    } else {
      _currentMatchIndex = 0; // Wrap around
    }
    notifyListeners();
    return _matchIndices[_currentMatchIndex];
  }

  int? previousMatch() {
    if (_matchIndices.isEmpty) return null;
    if (_currentMatchIndex > 0) {
      _currentMatchIndex--;
    } else {
      _currentMatchIndex = _matchIndices.length - 1; // Wrap around
    }
    notifyListeners();
    return _matchIndices[_currentMatchIndex];
  }
}
