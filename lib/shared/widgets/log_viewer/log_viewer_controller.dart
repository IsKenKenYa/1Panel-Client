import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'log_parser.dart';
import 'log_theme.dart';

export 'log_parser.dart';
export 'log_theme.dart';

enum LogTimestampFormat {
  absolute,
  relative,
}

class LogSettings {
  final double fontSize;
  final bool isWrap;
  final bool showTimestamp;
  final LogTimestampFormat timestampFormat;
  final ThemeMode themeMode;
  final LogTheme theme;

  LogSettings({
    this.fontSize = 14.0,
    this.isWrap = false,
    this.showTimestamp = true,
    this.timestampFormat = LogTimestampFormat.absolute,
    this.themeMode = ThemeMode.system,
    LogTheme? theme,
  }) : theme = theme ?? LogTheme.defaultTheme;

  LogSettings copyWith({
    double? fontSize,
    bool? isWrap,
    bool? showTimestamp,
    LogTimestampFormat? timestampFormat,
    ThemeMode? themeMode,
    LogTheme? theme,
  }) {
    return LogSettings(
      fontSize: fontSize ?? this.fontSize,
      isWrap: isWrap ?? this.isWrap,
      showTimestamp: showTimestamp ?? this.showTimestamp,
      timestampFormat: timestampFormat ?? this.timestampFormat,
      themeMode: themeMode ?? this.themeMode,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'isWrap': isWrap,
      'showTimestamp': showTimestamp,
      'timestampFormat': timestampFormat.index,
      'themeMode': themeMode.index,
      'theme': theme.toJson(),
    };
  }

  factory LogSettings.fromJson(Map<String, dynamic> json) {
    return LogSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      isWrap: json['isWrap'] as bool? ?? false,
      showTimestamp: json['showTimestamp'] as bool? ?? true,
      timestampFormat: LogTimestampFormat.values[json['timestampFormat'] as int? ?? 0],
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
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
      debugPrint('Failed to load log settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_settings.toJson());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Failed to save log settings: $e');
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
        final isMatch = log.originalContent.toLowerCase().contains(_searchQuery.toLowerCase());
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
