import 'package:flutter/services.dart';
import 'package:onepanelapp_app/core/services/logger/logger_service.dart';

import 'macos_appearance_context_model.dart';

class MacosAppearanceChannel {
  const MacosAppearanceChannel._();

  static const String channelName = 'onepanel/macos_appearance';
  static const MethodChannel _channel = MethodChannel(channelName);

  static Future<MacosAppearanceContextModel> getAppearanceContext() async {
    try {
      final data = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getAppearanceContext',
      );
      if (data == null) {
        return MacosAppearanceContextModel.fallback;
      }
      return MacosAppearanceContextModel.fromMap(data);
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        'features.shell.platform.macos',
        'Failed to read macOS appearance context from native bridge',
        error: error,
        stackTrace: stackTrace,
      );
      return MacosAppearanceContextModel.fallback;
    }
  }
}
