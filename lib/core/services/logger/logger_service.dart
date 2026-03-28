import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../config/logger_config.dart';

/// 统一日志服务类
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late final Logger _logger;

  /// 初始化日志服务
  void init() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: LoggerConfig.maxMethodCount,
        errorMethodCount: LoggerConfig.maxErrorMethodCount,
        lineLength: LoggerConfig.lineLength,
        colors: LoggerConfig.enableColors,
        printEmojis: LoggerConfig.enableEmojis,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      filter: kReleaseMode ? ProductionFilter() : DevelopmentFilter(),
    );
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
