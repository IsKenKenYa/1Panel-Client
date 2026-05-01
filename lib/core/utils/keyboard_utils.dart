import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';

class KeyboardUtils {
  /// Returns the modifier key (Meta for macOS, Control for others)
  static LogicalKeyboardKey get modifierKey {
    return PlatformUtils.isMacOS
        ? LogicalKeyboardKey.meta
        : LogicalKeyboardKey.control;
  }

  /// Returns a [ShortcutActivator] for the modifier + [key] combination
  static ShortcutActivator modifierPlus(LogicalKeyboardKey key) {
    if (PlatformUtils.isMacOS) {
      return SingleActivator(key, meta: true);
    } else {
      return SingleActivator(key, control: true);
    }
  }

  /// Returns a [ShortcutActivator] for modifier + shift + [key]
  static ShortcutActivator modifierShiftPlus(LogicalKeyboardKey key) {
    if (PlatformUtils.isMacOS) {
      return SingleActivator(key, meta: true, shift: true);
    } else {
      return SingleActivator(key, control: true, shift: true);
    }
  }

  /// Check if the main modifier is pressed (Cmd on Mac, Ctrl on Windows/Linux)
  static bool isModifierPressed() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (PlatformUtils.isMacOS) {
      return keys.contains(LogicalKeyboardKey.metaLeft) ||
          keys.contains(LogicalKeyboardKey.metaRight);
    } else {
      return keys.contains(LogicalKeyboardKey.controlLeft) ||
          keys.contains(LogicalKeyboardKey.controlRight);
    }
  }

  /// Check if Shift is pressed
  static bool isShiftPressed() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
  }
}