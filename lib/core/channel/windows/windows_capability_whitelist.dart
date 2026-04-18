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
}

class WindowsCapabilityWhitelist {
  const WindowsCapabilityWhitelist._();

  static const Set<WindowsNativeCapability> _bridgeOwnedCapabilities = {
    WindowsNativeCapability.windowCommands,
    WindowsNativeCapability.alwaysOnTop,
  };

  static bool isCapabilityBridgeOwned(WindowsNativeCapability capability) {
    return _bridgeOwnedCapabilities.contains(capability);
  }

  static bool canInvokeWindowCommand(WindowsWindowCommand command) {
    return switch (command) {
      WindowsWindowCommand.minimize ||
      WindowsWindowCommand.maximize ||
      WindowsWindowCommand.restore ||
      WindowsWindowCommand.close ||
      WindowsWindowCommand.setAlwaysOnTop => true,
    };
  }

  static String commandName(WindowsWindowCommand command) {
    return switch (command) {
      WindowsWindowCommand.minimize => 'minimize',
      WindowsWindowCommand.maximize => 'maximize',
      WindowsWindowCommand.restore => 'restore',
      WindowsWindowCommand.close => 'close',
      WindowsWindowCommand.setAlwaysOnTop => 'set_always_on_top',
    };
  }
}
