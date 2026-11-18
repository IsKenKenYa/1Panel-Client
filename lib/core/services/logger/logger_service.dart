import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../config/logger_config.dart';
import '../../config/release_channel_config.dart';
import 'app_log_printer.dart';
import 'log_category.dart';
import 'log_file_manager_service.dart';
import 'log_format.dart';
import 'log_level.dart';
import 'log_preferences_service.dart';

class _AppLogOutput extends LogOutput {
  final ConsoleOutput _consoleOutput = ConsoleOutput();
  final LogFileManagerService _fileManager = LogFileManagerService();

  static final _ipv4Regex = RegExp(
    r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b',
  );

  bool _isPrivateIp(String ip) {
    if (ip == '0.0.0.0' || ip == '255.255.255.255') return true;
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final p1 = int.tryParse(parts[0]);
    final p2 = int.tryParse(parts[1]);
    if (p1 == null || p2 == null) return false;

    // 10.0.0.0/8
    if (p1 == 10) return true;
    // 172.16.0.0/12
    if (p1 == 172 && p2 >= 16 && p2 <= 31) return true;
    // 192.168.0.0/16
    if (p1 == 192 && p2 == 168) return true;
    // 127.0.0.0/8 (Loopback)
    if (p1 == 127) return true;
    // 169.254.0.0/16 (Link-local)
    if (p1 == 169 && p2 == 254) return true;

    return false;
  }

  String _maskSensitiveInfo(String text) {
    return text.replaceAllMapped(_ipv4Regex, (match) {
      final ip = match.group(0)!;
      if (_isPrivateIp(ip)) {
        return ip;
      }
      return '***.***.***.***';
    });
  }

  @override
  void output(OutputEvent event) {
    final maskedLines = event.lines.map(_maskSensitiveInfo).toList();

    // LogEvent instead of level directly, according to the logger package signature
    final maskedEvent = OutputEvent(event.origin, maskedLines);

    if (LoggerConfig.enableConsoleOutput) {
      _consoleOutput.output(maskedEvent);
    }
    if (LoggerConfig.enableFileOutput) {
      for (final line in maskedLines) {
        unawaited(
          _fileManager
              .appendLine(line)
              .catchError((Object error, StackTrace stackTrace) {
            if (LoggerConfig.enableConsoleOutput) {
              _consoleOutput.output(maskedEvent);
            }
          }),
        );
      }
    }
  }
}

/// 统一日志服务类
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late final Logger _logger;
  bool _initialized = false;
  AppLogLevel _minLogLevel = AppLogLevel.trace;
  final LogPreferencesService _preferencesService = LogPreferencesService();

  /// 初始化日志服务
  void init() {
    if (_initialized) return;

    final filter = kReleaseMode ? ProductionFilter() : DevelopmentFilter();
    _logger = Logger(
      printer: AppLogPrinter(
        format: LogFormat.defaultRuntime,
        maxStackFrames: LoggerConfig.maxStackFrames,
        colors: LoggerConfig.enableColors,
      ),
      filter: _AppLoggerFilter(filter),
      output: _AppLogOutput(),
    );
    _initialized = true;
    unawaited(
      LogFileManagerService()
          .cleanupExpired()
          .catchError((Object _, StackTrace __) {}),
    );
  }

  Future<void> loadPreferences() async {
    _minLogLevel = await _preferencesService.loadMinLogLevel();
  }

  AppLogLevel get minLogLevel => _minLogLevel;

  Future<void> setMinLogLevel(AppLogLevel level) async {
    _minLogLevel = level;
    await _preferencesService.saveMinLogLevel(level);
  }

  Future<void> applyReleaseChannelPolicy() async {
    if (AppReleaseChannelConfig.forceDebugLogLevel) {
      if (_minLogLevel != AppLogLevel.debug) {
        await setMinLogLevel(AppLogLevel.debug);
      }
      return;
    }

    final AppLogLevel floor = switch (AppReleaseChannelConfig.current) {
      AppReleaseChannel.preview => AppLogLevel.debug,
      AppReleaseChannel.alpha => AppLogLevel.debug,
      AppReleaseChannel.beta => AppLogLevel.debug,
      AppReleaseChannel.preRelease => AppLogLevel.info,
      AppReleaseChannel.release => AppLogLevel.warning,
    };

    if (_minLogLevel.weight < floor.weight) {
      await setMinLogLevel(floor);
    }
  }

  void _ensureInitialized() {
    if (!_initialized) init();
  }

  /// 将 `category` 与 `packageName` 拼成内部前缀。
  ///
  /// - 未传 `category` → 走 `LoggerConfig.defaultCategoryForPackage` 推断
  /// - 显式 `category` → 使用其 `shortTag`，便于在文件/控制台识别
  String _prefix(String packageName, LogCategory? category) {
    final effective = category ?? LoggerConfig.defaultCategoryForPackage(packageName);
    return '[${effective.shortTag}:$packageName]';
  }

  void t(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  void d(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void i(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void w(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void e(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void f(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  void tWithPackage(
    String packageName,
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    LogCategory? category,
  }) {
    _ensureInitialized();
    _logger.t(
      '${_prefix(packageName, category)} $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void dWithPackage(
    String packageName,
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    LogCategory? category,
  }) {
    _ensureInitialized();
    _logger.d(
      '${_prefix(packageName, category)} $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void iWithPackage(
    String packageName,
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    LogCategory? category,
  }) {
    _ensureInitialized();
    _logger.i(
      '${_prefix(packageName, category)} $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void wWithPackage(
    String packageName,
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    LogCategory? category,
  }) {
    _ensureInitialized();
    _logger.w(
      '${_prefix(packageName, category)} $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void eWithPackage(
    String packageName,
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    LogCategory? category,
  }) {
    _ensureInitialized();
    _logger.e(
      '${_prefix(packageName, category)} $message',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fWithPackage(
    String packageName,
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    LogCategory? category,
  }) {
    _ensureInitialized();
    _logger.f(
      '${_prefix(packageName, category)} $message',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

final AppLogger appLogger = AppLogger();

class _AppLoggerFilter extends LogFilter {
  _AppLoggerFilter(this._delegate);
  final LogFilter _delegate;

  @override
  bool shouldLog(LogEvent event) {
    if (!_delegate.shouldLog(event)) return false;
    final message = event.message?.toString() ?? '';
    if (LoggerConfig.shouldFilterLog(message)) return false;
    final currentLevel = AppLogLevelX.fromLoggerLevel(event.level);
    if (currentLevel.weight < appLogger.minLogLevel.weight) return false;
    return true;
  }
}
