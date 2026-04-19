import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ui_render_mode.dart';

/// Runtime policy for choosing native host UI vs Flutter-rendered MDUI3.
///
/// Current strategy:
/// - Non-web platforms default to native mode.
/// - If a platform native host is unavailable, fallback to Flutter MDUI3.
/// - Web always uses Flutter UI.
class UIRenderPolicy {
  const UIRenderPolicy._();

  static bool canSelectNativeMode() {
    return supportsNativeHost();
  }

  static bool supportsNativeHost() {
    if (kIsWeb) {
      return false;
    }

    // Native shell strategy: macOS (SwiftUI) and Windows (WinUI3).
    return Platform.isMacOS || Platform.isWindows;
  }

  static bool shouldUseFlutterUI(UIRenderMode configuredMode) {
    if (kIsWeb) {
      return true;
    }
    if (configuredMode == UIRenderMode.md3) {
      return true;
    }
    return !supportsNativeHost();
  }

  static bool isNativeModeFallback(UIRenderMode configuredMode) {
    return configuredMode == UIRenderMode.native &&
        shouldUseFlutterUI(configuredMode);
  }

  static UIRenderMode resolveSupportedMode(UIRenderMode configuredMode) {
    if (configuredMode == UIRenderMode.native && !supportsNativeHost()) {
      return UIRenderMode.md3;
    }
    return configuredMode;
  }

  static String fallbackReason() {
    if (kIsWeb) {
      return 'Web host uses Flutter UI only.';
    }
    return 'Native shell is not available on this platform yet, fallback to MDUI3.';
  }
}