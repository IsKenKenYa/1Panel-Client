import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:glass/glass.dart';

import 'ui_render_mode.dart';

/// 原生宿主与 Flutter 界面的启动策略。
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
    return isAppleHost;
  }

  static bool get isAppleHost =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  static UIRenderMode defaultMode({required bool appLockEnabled}) {
    if (!kIsWeb && Platform.isIOS && appLockEnabled) {
      return UIRenderMode.liquidGlass;
    }
    if (isAppleHost) return UIRenderMode.native;
    if (!kIsWeb && Platform.isAndroid) return UIRenderMode.md3;
    return UIRenderMode.liquidGlass;
  }

  static bool canSelectNativeMode() {
    return supportsNativeHost();
  }

  static bool supportsNativeHost() {
    if (kIsWeb) {
      return false;
    }

    return isAppleHost || Platform.isWindows;
  }

  static bool shouldUseFlutterUI(UIRenderMode configuredMode) {
    return configuredMode != UIRenderMode.native || !supportsNativeHost();
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
