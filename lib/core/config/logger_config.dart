import 'dart:io' as io;
import 'package:flutter/foundation.dart';

/// 日志配置常量
class LoggerConfig {
  LoggerConfig._();

  /// 是否为桌面平台（有终端）
  static bool get _isDesktopPlatform {
    return !kIsWeb &&
        (io.Platform.isLinux || io.Platform.isMacOS || io.Platform.isWindows);
  }

  /// 日志格式配置
  static bool get enableColors {
    if (kIsWeb) return false;
    if (_isDesktopPlatform) {
      try {
        return io.stdout.supportsAnsiEscapes;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  static const bool enableEmojis = true;
  static const int maxMethodCount = 0;
  static const int maxErrorMethodCount = 8;

  static int get lineLength {
    if (kIsWeb) return 120;
    if (_isDesktopPlatform) {
      try {
        final columns = io.stdout.terminalColumns;
        return columns > 0 ? columns : 120;
      } catch (_) {
        return 120;
      }
    }
    return 120;
  }

  /// 日志输出配置
  static const bool enableConsoleOutput = true;
  /// 开启文件日志以支持用户在遇到问题时导出反馈
  static const bool enableFileOutput = true;
  static const String logFileName = 'app_logs.txt';
  static const int maxLogFileSize = 10 * 1024 * 1024;
  static const int maxLogFiles = 5;
  static const int logRetentionDays = 30;

  /// 日志过滤配置
  static const List<String> excludedLogTags = [
    'MESA',
    'exportSyncFdForQSRILocked',
  ];

  static bool shouldFilterLog(String message) {
    for (final tag in excludedLogTags) {
      if (message.contains(tag)) {
        return true;
      }
    }
    return false;
  }
}
