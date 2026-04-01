import 'package:flutter/services.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

/// Bridge for macOS native shell (Sidebar/Toolbar) -> Flutter content pane.
class MacosShellChannel {
  MacosShellChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'onepanel/macos_shell';

  final MethodChannel _channel;

  static const String _package = 'ui.desktop.macos.shell';

  Future<void> setTitle(String title) async {
    try {
      await _channel.invokeMethod<void>('setTitle', {'title': title});
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _package,
        'Failed to set native window title',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void setHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) {
    _channel.setMethodCallHandler(handler);
  }
}

