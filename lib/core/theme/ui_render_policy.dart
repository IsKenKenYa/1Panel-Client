import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:glass/glass.dart';

import 'ui_render_mode.dart';

/// Runtime policy for choosing native host UI vs Flutter-rendered MDUI3.
///
/// Current strategy:
/// - Non-web platforms default to native mode.
/// - If a platform native host is unavailable, fallback to Flutter MDUI3.
/// - Web always uses Flutter UI.
/// - liquidGlass renders Flutter UI with Liquid Glass navigation floats
///   (glass package works on iOS/macOS/Android via Impeller; Skia falls
///   back to plain blur automatically).
class UIRenderPolicy {
  const UIRenderPolicy._();

  /// Whether Liquid Glass navigation floats are currently rendered.
  ///
  /// Static by design: the mode is a boot-time choice (the settings dialog
  /// already asks the user to restart after switching), so no reactive
  /// plumbing is needed and glass surfaces can read it without context.
  static bool liquidGlassEnabled = false;

  static void setLiquidGlassEnabled(UIRenderMode mode) {
    liquidGlassEnabled = mode == UIRenderMode.liquidGlass;
  }

  /// 全局统一玻璃配置（Apple `Glass.regular` 参数复刻）：磨砂为主、
  /// 边缘折射掰弯背景、饱和度提升、柔和阴影——供 AppBar 与桌面侧栏使用。
  static const LiquidGlass glassStyle = LiquidGlass.regular;

  /// 是否允许 premium 多 pass 折射：Apple Metal 平台（iOS/macOS）按官方
  /// 标准走 premium；Android GLES / Skia / Web 用轻量 standard。
  /// 实测 GLES 模拟器上 premium 会阻塞主线程并丢失 GPU 上下文。
  static bool get premiumGlassAllowed {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

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
    if (configuredMode == UIRenderMode.md3 ||
        configuredMode == UIRenderMode.liquidGlass) {
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