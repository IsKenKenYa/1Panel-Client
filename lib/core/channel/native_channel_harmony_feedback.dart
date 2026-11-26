import 'package:flutter/services.dart';

import '../config/release_channel_config.dart';
import '../platform/services/platform_diagnostics_service.dart';
import '../services/logger/log_export_service.dart';
import '../services/logger/log_file_manager_service.dart';
import '../services/logger/log_format.dart';
import '../services/logger/log_level.dart';
import '../services/logger/logger_service.dart';

class NativeChannelHarmonyFeedback {
  static Future<Map<String, Object>> getHarmonyFeedback(
    dynamic arguments,
  ) async {
    final minimum = switch (AppReleaseChannelConfig.current) {
      AppReleaseChannel.preview ||
      AppReleaseChannel.alpha ||
      AppReleaseChannel.beta => AppLogLevel.debug,
      AppReleaseChannel.preRelease => AppLogLevel.info,
      AppReleaseChannel.release => AppLogLevel.warning,
    };
    return {
      'logLevel': appLogger.minLogLevel.name,
      'levelLocked': AppReleaseChannelConfig.forceDebugLogLevel,
      'levels': AppLogLevel.values
          .where((level) => level.weight >= minimum.weight)
          .map((level) => level.name)
          .toList(growable: false),
      'channelTitleKey': switch (AppReleaseChannelConfig.current) {
        AppReleaseChannel.preview => 'releaseChannelPreview',
        AppReleaseChannel.alpha => 'releaseChannelAlpha',
        AppReleaseChannel.beta => 'releaseChannelBeta',
        AppReleaseChannel.preRelease => 'releaseChannelPreRelease',
        AppReleaseChannel.release => 'releaseChannelRelease',
      },
    };
  }

  static Future<String> getHarmonyLogPreview(dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    return LogExportService().tailRecentLogs(
      200,
      format: LogFormat.values.byName(args['format'] as String),
    );
  }

  static Future<void> updateHarmonyLogLevel(dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    await appLogger.setMinLogLevel(
      AppLogLevel.values.byName(args['level'] as String),
    );
    await appLogger.applyReleaseChannelPolicy();
  }

  static Future<void> copyHarmonyFeedbackTemplate(dynamic arguments) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    final platformTemplate = await PlatformDiagnosticsService()
        .buildFeedbackTemplate();
    await Clipboard.setData(
      ClipboardData(text: '${args['template']}\n\n---\n$platformTemplate'),
    );
  }

  static Future<Map<String, Object?>> exportHarmonyLogs(
    dynamic arguments,
  ) async {
    final args = Map<String, dynamic>.from(arguments as Map);
    final result = await LogExportService().exportLogs(
      minLevel: appLogger.minLogLevel,
      format: LogFormat.values.byName(args['format'] as String),
    );
    return {
      'success': result.success,
      'wasCancelled': result.wasCancelled,
      'privateFallbackUsed': result.privateFallbackUsed,
      'displayName': result.displayName ?? result.filePath,
      'errorMessage': result.errorMessage,
    };
  }

  static Future<void> clearHarmonyLogs(dynamic arguments) =>
      LogFileManagerService().clearLogs();
}
