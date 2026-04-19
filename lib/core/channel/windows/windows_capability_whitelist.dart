enum WindowsNativeCapability {
  windowCommands,
  alwaysOnTop,
  systemBackdrop,
  tray,
  jumpList,
  toast,
  fileAssociation,
}

enum WindowsWindowCommand {
  minimize,
  maximize,
  restore,
  close,
  setAlwaysOnTop,
  setSystemBackdrop,
}

enum WindowsSystemBackdropMode {
  auto,
  none,
  mica,
  acrylic,
  tabbed,
}

enum WindowsTrayCommand {
  initialize,
  show,
  hide,
  dispose,
}

class WindowsCapabilityWhitelist {
  const WindowsCapabilityWhitelist._();

  static const Set<WindowsNativeCapability> _bridgeOwnedCapabilities = {
    WindowsNativeCapability.windowCommands,
    WindowsNativeCapability.alwaysOnTop,
    WindowsNativeCapability.tray,
    WindowsNativeCapability.toast,
  };

  static const Set<String> _windowCommandNames = {
    'minimize',
    'maximize',
    'restore',
    'close',
    'set_always_on_top',
    'set_system_backdrop',
  };

  static const Set<String> _systemBackdropModeNames = {
    'auto',
    'none',
    'mica',
    'acrylic',
    'tabbed',
  };

  static const Set<String> _trayCommandNames = {
    'initialize',
    'show',
    'hide',
    'dispose',
  };

  static bool isCapabilityBridgeOwned(WindowsNativeCapability capability) {
    return _bridgeOwnedCapabilities.contains(capability);
  }

  static bool canInvokeWindowCommand(WindowsWindowCommand command) {
    return canInvokeRawWindowCommand(commandName(command));
  }

  static bool canInvokeRawWindowCommand(String command) {
    return _windowCommandNames.contains(command);
  }

  static bool canInvokeSystemBackdropMode(WindowsSystemBackdropMode mode) {
    return canInvokeRawSystemBackdropMode(systemBackdropModeName(mode));
  }

  static bool canInvokeRawSystemBackdropMode(String mode) {
    return _systemBackdropModeNames.contains(mode);
  }

  static bool canInvokeTrayCommand(WindowsTrayCommand command) {
    return canInvokeRawTrayCommand(trayCommandName(command));
  }

  static bool canInvokeRawTrayCommand(String command) {
    return _trayCommandNames.contains(command);
  }

  static String commandName(WindowsWindowCommand command) {
    return switch (command) {
      WindowsWindowCommand.minimize => 'minimize',
      WindowsWindowCommand.maximize => 'maximize',
      WindowsWindowCommand.restore => 'restore',
      WindowsWindowCommand.close => 'close',
      WindowsWindowCommand.setAlwaysOnTop => 'set_always_on_top',
      WindowsWindowCommand.setSystemBackdrop => 'set_system_backdrop',
    };
  }

  static String systemBackdropModeName(WindowsSystemBackdropMode mode) {
    return switch (mode) {
      WindowsSystemBackdropMode.auto => 'auto',
      WindowsSystemBackdropMode.none => 'none',
      WindowsSystemBackdropMode.mica => 'mica',
      WindowsSystemBackdropMode.acrylic => 'acrylic',
      WindowsSystemBackdropMode.tabbed => 'tabbed',
    };
  }

  static String trayCommandName(WindowsTrayCommand command) {
    return switch (command) {
      WindowsTrayCommand.initialize => 'initialize',
      WindowsTrayCommand.show => 'show',
      WindowsTrayCommand.hide => 'hide',
      WindowsTrayCommand.dispose => 'dispose',
    };
  }
}
