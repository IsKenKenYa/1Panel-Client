import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../config/logger_config.dart';
import 'log_file_manager_service.dart';

class _AppLogOutput extends LogOutput {
  final ConsoleOutput _consoleOutput = ConsoleOutput();
  final LogFileManagerService _fileManager = LogFileManagerService();

  @override
  void output(OutputEvent event) {
    if (LoggerConfig.enableConsoleOutput) {
      _consoleOutput.output(event);
    }
    if (LoggerConfig.enableFileOutput) {
      for (final line in event.lines) {
        unawaited(_fileManager.appendLine(line));
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

  /// 初始化日志服务
  void init() {
    final filter = kReleaseMode ? ProductionFilter() : DevelopmentFilter();
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: LoggerConfig.maxMethodCount,
        errorMethodCount: LoggerConfig.maxErrorMethodCount,
        lineLength: LoggerConfig.lineLength,
        colors: LoggerConfig.enableColors,
        printEmojis: LoggerConfig.enableEmojis,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      filter: _AppLoggerFilter(filter),
      output: _AppLogOutput(),
    );
    unawaited(LogFileManagerService().cleanupExpired());
  }

  void _ensureInitialized() {
    try {
      _logger.log(Level.trace, '');
    } catch (_) {
      init();
    }
  }

  void t(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.t('【Open1PanelMobile】$message',
        error: error, stackTrace: stackTrace);
  }

  void d(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.d('【Open1PanelMobile】$message',
        error: error, stackTrace: stackTrace);
  }

  void i(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.i('【Open1PanelMobile】$message',
        error: error, stackTrace: stackTrace);
  }

  void w(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.w('【Open1PanelMobile】$message',
        error: error, stackTrace: stackTrace);
  }

  void e(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.e('【Open1PanelMobile】$message',
        error: error, stackTrace: stackTrace);
  }

  void f(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.f('【Open1PanelMobile】$message',
        error: error, stackTrace: stackTrace);
  }

  void tWithPackage(String packageName, dynamic message,
      {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.t('[$packageName] $message', error: error, stackTrace: stackTrace);
  }

  void dWithPackage(String packageName, dynamic message,
      {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.d('[$packageName] $message', error: error, stackTrace: stackTrace);
  }

  void iWithPackage(String packageName, dynamic message,
      {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.i('[$packageName] $message', error: error, stackTrace: stackTrace);
  }

  void wWithPackage(String packageName, dynamic message,
      {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.w('[$packageName] $message', error: error, stackTrace: stackTrace);
  }

  void eWithPackage(String packageName, dynamic message,
      {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.e('[$packageName] $message', error: error, stackTrace: stackTrace);
  }

  void fWithPackage(String packageName, dynamic message,
      {dynamic error, StackTrace? stackTrace}) {
    _ensureInitialized();
    _logger.f('[$packageName] $message', error: error, stackTrace: stackTrace);
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
    return true;
  }
}
