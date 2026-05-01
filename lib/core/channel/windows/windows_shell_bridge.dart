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
    required this.toastPermissionGranted,
    required this.trayPermissionGranted,
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
    toastPermissionGranted: false,
    trayPermissionGranted: false,
  );

  final bool nativeHostAvailable;
  final bool supportsWindowCommands;
  final bool supportsAlwaysOnTop;
  final bool supportsSystemBackdrop;
  final bool supportsTray;
  final bool supportsJumpList;
  final bool supportsToast;
  final bool supportsFileAssociation;
  final bool toastPermissionGranted;
  final bool trayPermissionGranted;

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
      toastPermissionGranted: readBool('toastPermissionGranted', false),
      trayPermissionGranted: readBool('trayPermissionGranted', false),
    );
  }
}

class WindowsWindowState {
  const WindowsWindowState({
    required this.isMinimized,
    required this.isMaximized,
    required this.isAlwaysOnTop,
    required this.isVisible,
    required this.systemBackdropMode,
  });

  static const fallback = WindowsWindowState(
    isMinimized: false,
    isMaximized: false,
    isAlwaysOnTop: false,
    isVisible: false,
    systemBackdropMode: 'unknown',
  );

  final bool isMinimized;
  final bool isMaximized;
  final bool isAlwaysOnTop;
  final bool isVisible;
  final String systemBackdropMode;

  factory WindowsWindowState.fromMap(Map<Object?, Object?> map) {
    bool readBool(String key, bool fallback) {
      final value = map[key];
      return value is bool ? value : fallback;
    }

    String readString(String key, String fallback) {
      final value = map[key];
      return value is String ? value : fallback;
    }

    return WindowsWindowState(
      isMinimized: readBool('isMinimized', false),
      isMaximized: readBool('isMaximized', false),
      isAlwaysOnTop: readBool('isAlwaysOnTop', false),
      isVisible: readBool('isVisible', false),
      systemBackdropMode: readString('systemBackdropMode', 'unknown'),
    );
  }
}

typedef SupportedPlatformResolver = bool Function();

class WindowsShellBridge {
  WindowsShellBridge({
    MethodChannel? channel,
    SupportedPlatformResolver? isSupportedPlatform,
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _platformResolver =
            isSupportedPlatform ?? _defaultSupportedPlatformResolver;

  static const String _channelName = 'onepanel/windows_bridge';
  static const String _package = 'core.channel.windows.shell_bridge';

  static bool _defaultSupportedPlatformResolver() {
    return !kIsWeb && Platform.isWindows;
  }

  final MethodChannel _channel;
  final SupportedPlatformResolver _platformResolver;

  bool get _isSupportedPlatform => _platformResolver();

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

  Future<WindowsWindowState> getWindowState() async {
    if (!_isSupportedPlatform) {
      return WindowsWindowState.fallback;
    }

    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getWindowState',
      );
      if (raw == null) {
        return WindowsWindowState.fallback;
      }
      return WindowsWindowState.fromMap(raw);
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _package,
        'Failed to fetch Windows window state.',
        error: error,
        stackTrace: stackTrace,
      );
      return WindowsWindowState.fallback;
    }
  }

  Future<bool> performWindowCommand(
    WindowsWindowCommand command, {
    bool? enabled,
  }) async {
    return performWindowCommandRaw(
      WindowsCapabilityWhitelist.commandName(command),
      enabled: enabled,
    );
  }

  Future<bool> setSystemBackdrop(WindowsSystemBackdropMode mode) async {
    if (!WindowsCapabilityWhitelist.canInvokeSystemBackdropMode(mode)) {
      return false;
    }

    return performWindowCommandRaw(
      WindowsCapabilityWhitelist.commandName(
        WindowsWindowCommand.setSystemBackdrop,
      ),
      backdrop: WindowsCapabilityWhitelist.systemBackdropModeName(mode),
    );
  }

  @visibleForTesting
  Future<bool> performWindowCommandRaw(
    String command, {
    bool? enabled,
    String? backdrop,
  }) async {
    if (!_isSupportedPlatform) {
      return false;
    }

    if (!WindowsCapabilityWhitelist.canInvokeRawWindowCommand(command)) {
      appLogger.wWithPackage(
        _package,
        'Blocked non-whitelisted window command: $command',
      );
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'performWindowCommand',
        {
          'command': command,
          if (enabled != null) 'enabled': enabled,
          if (backdrop != null) 'backdrop': backdrop,
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

  Future<bool> performTrayCommand(WindowsTrayCommand command) async {
    return performTrayCommandRaw(
      WindowsCapabilityWhitelist.trayCommandName(command),
    );
  }

  @visibleForTesting
  Future<bool> performTrayCommandRaw(String command) async {
    if (!_isSupportedPlatform) {
      return false;
    }
    if (!WindowsCapabilityWhitelist.canInvokeRawTrayCommand(command)) {
      appLogger.wWithPackage(
        _package,
        'Blocked non-whitelisted tray command: $command',
      );
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'performTrayCommand',
        {'command': command},
      );
      return result ?? false;
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _package,
        'Failed to execute tray command.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> showToast({
    required String title,
    required String message,
    bool allowTrayFallback = true,
  }) async {
    if (!_isSupportedPlatform) {
      return false;
    }

    final capabilities = await getCapabilities();
    if (!capabilities.supportsToast || !capabilities.toastPermissionGranted) {
      return _showTrayFallbackIfAllowed(
        title: title,
        message: message,
        capabilities: capabilities,
        allowTrayFallback: allowTrayFallback,
      );
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'showToast',
        {
          'title': title,
          'message': message,
        },
      );
      if (result == true) {
        return true;
      }
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _package,
        'Native toast failed, trying fallback strategy.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return _showTrayFallbackIfAllowed(
      title: title,
      message: message,
      capabilities: capabilities,
      allowTrayFallback: allowTrayFallback,
    );
  }

  Future<bool> setNotificationPermission({
    bool? toastAllowed,
    bool? trayAllowed,
  }) async {
    if (!_isSupportedPlatform) {
      return false;
    }
    if (toastAllowed == null && trayAllowed == null) {
      return true;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'setNotificationPermission',
        {
          if (toastAllowed != null) 'toastAllowed': toastAllowed,
          if (trayAllowed != null) 'trayAllowed': trayAllowed,
        },
      );
      return result ?? false;
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _package,
        'Failed to set notification permissions.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> _showTrayFallbackIfAllowed({
    required String title,
    required String message,
    required WindowsCapabilitySnapshot capabilities,
    required bool allowTrayFallback,
  }) async {
    if (!allowTrayFallback) {
      return false;
    }
    if (!capabilities.supportsTray || !capabilities.trayPermissionGranted) {
      return false;
    }

    final initialized = await performTrayCommand(WindowsTrayCommand.initialize);
    if (!initialized) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>(
        'showTrayBalloon',
        {
          'title': title,
          'message': message,
        },
      );
      return result ?? false;
    } catch (error, stackTrace) {
      appLogger.wWithPackage(
        _package,
        'Failed to show tray fallback notification.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
