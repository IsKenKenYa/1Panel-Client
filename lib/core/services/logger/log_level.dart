import 'package:logger/logger.dart';

enum AppLogLevel {
  trace,
  debug,
  info,
  warning,
  error,
  fatal;

  String get storageValue => name;

  static AppLogLevel fromStorage(String? value) {
    return AppLogLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => AppLogLevel.trace,
    );
  }
}

extension AppLogLevelX on AppLogLevel {
  int get weight {
    switch (this) {
      case AppLogLevel.trace:
        return 0;
      case AppLogLevel.debug:
        return 1;
      case AppLogLevel.info:
        return 2;
      case AppLogLevel.warning:
        return 3;
      case AppLogLevel.error:
        return 4;
      case AppLogLevel.fatal:
        return 5;
    }
  }

  Level toLoggerLevel() {
    switch (this) {
      case AppLogLevel.trace:
        return Level.trace;
      case AppLogLevel.debug:
        return Level.debug;
      case AppLogLevel.info:
        return Level.info;
      case AppLogLevel.warning:
        return Level.warning;
      case AppLogLevel.error:
        return Level.error;
      case AppLogLevel.fatal:
        return Level.fatal;
    }
  }

  static AppLogLevel fromLoggerLevel(Level level) {
    switch (level) {
      case Level.trace:
        return AppLogLevel.trace;
      case Level.debug:
        return AppLogLevel.debug;
      case Level.info:
        return AppLogLevel.info;
      case Level.warning:
        return AppLogLevel.warning;
      case Level.error:
        return AppLogLevel.error;
      case Level.fatal:
        return AppLogLevel.fatal;
      default:
        return AppLogLevel.info;
    }
  }
}
