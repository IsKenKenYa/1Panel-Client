import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/channel/windows/windows_capability_whitelist.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';

class WindowsCapabilitySnapshot {
  const WindowsCapabilitySnapshot({
    required this.nativeHostAvailable,
    required this.supportsWindowCommands,
    required this.supportsAlwaysOnTop,
    required this.supportsSystemBackdrop,
    required this.supportsTray,
    required this.supportsJumpList,
    required this.supportsToast,
    required this.supportsFileAssociation,
  });

  static const fallback = WindowsCapabilitySnapshot(
    nativeHostAvailable: false,
    supportsWindowCommands: false,
    supportsAlwaysOnTop: false,
    supportsSystemBackdrop: false,
    supportsTray: false,
    supportsJumpList: false,
    supportsToast: false,
    supportsFileAssociation: false,
  );

  final bool nativeHostAvailable;
  final bool supportsWindowCommands;
  final bool supportsAlwaysOnTop;
  final bool supportsSystemBackdrop;
  final bool supportsTray;
  final bool supportsJumpList;
  final bool supportsToast;
  final bool supportsFileAssociation;

  factory WindowsCapabilitySnapshot.fromMap(Map<Object?, Object?> map) {
    bool readBool(String key, bool fallback) {
      final value = map[key];
      return value is bool ? value : fallback;
    }

    return WindowsCapabilitySnapshot(
      nativeHostAvailable: readBool('nativeHostAvailable', false),
      supportsWindowCommands: readBool('windowCommands', false),
      supportsAlwaysOnTop: readBool('alwaysOnTop', false),
      supportsSystemBackdrop: readBool('systemBackdrop', false),
      supportsTray: readBool('tray', false),
      supportsJumpList: readBool('jumpList', false),
      supportsToast: readBool('toast', false),
      supportsFileAssociation: readBool('fileAssociation', false),
    );
  }
}

class WindowsShellBridge {
  const WindowsShellBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'onepanel/windows_bridge';
  static const String _package = 'core.channel.windows.shell_bridge';

  final MethodChannel _channel;

  bool get _isSupportedPlatform => !kIsWeb && Platform.isWindows;

  Future<WindowsCapabilitySnapshot> getCapabilities() async {
    if (!_isSupportedPlatform) {
      return WindowsCapabilitySnapshot.fallback;
    }

    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getCapabilities',
      );
      if (raw == null) {
        return WindowsCapabilitySnapshot.fallback;
      }
      return WindowsCapabilitySnapshot.fromMap(raw);
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _package,
        'Failed to fetch Windows capability snapshot.',
        error: error,
        stackTrace: stackTrace,
      );
      return WindowsCapabilitySnapshot.fallback;
    }
  }

  Future<bool> performWindowCommand(
    WindowsWindowCommand command, {
    bool? enabled,
  }) async {
    if (!_isSupportedPlatform) {
      return false;
    }

    if (!WindowsCapabilityWhitelist.canInvokeWindowCommand(command)) {
      appLogger.wWithPackage(
        _package,
        'Blocked non-whitelisted window command: ${WindowsCapabilityWhitelist.commandName(command)}',
      );
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'performWindowCommand',
        {
          'command': WindowsCapabilityWhitelist.commandName(command),
          if (enabled != null) 'enabled': enabled,
        },
      );
      return result ?? false;
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _package,
        'Failed to execute Windows window command.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
