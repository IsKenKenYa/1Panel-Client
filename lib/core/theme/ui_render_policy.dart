import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:glass/glass.dart';

import '../platform/platform_capabilities.dart';
import 'ui_render_mode.dart';

/// 原生宿主与 Flutter 界面的启动策略。
class UIRenderPolicy {
  const UIRenderPolicy._();

  /// 当前是否渲染液态玻璃铬件。
  ///
  /// 启动时由 `main` 写入；运行期由 `AppSettingsController.updateUIRenderMode`
  /// 刷新并通知监听者，界面用 [glassEnabledOf] 读取以自动重建，
  /// 因此切换渲染模式不需要重启应用。
  static bool liquidGlassEnabled = false;

  static void setLiquidGlassEnabled(UIRenderMode mode) {
    liquidGlassEnabled = mode == UIRenderMode.liquidGlass;
  }

  /// 玻璃模式是否生效（纯函数，便于测试与主题配置复用）。
  static bool glassEnabledFor(UIRenderMode mode) =>
      mode == UIRenderMode.liquidGlass;

  /// 记录当前生效模式，供无 Provider 上下文的构建期调用读取。
  static void applyMode(UIRenderMode mode) {
    _currentMode = mode;
    setLiquidGlassEnabled(mode);
  }

  static UIRenderMode _currentMode = UIRenderMode.md3;

  /// 最近一次生效的渲染模式。
  static UIRenderMode get currentMode => _currentMode;

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
    if (PlatformCapabilities.current().isOhos) return UIRenderMode.native;
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

    return isAppleHost ||
        Platform.isWindows ||
        PlatformCapabilities.current().isOhos;
  }

  static bool shouldUseFlutterUI(UIRenderMode configuredMode) {
    if (PlatformCapabilities.current().isOhos) return true;
    return configuredMode != UIRenderMode.native || !supportsNativeHost();
  }

  static bool isNativeModeFallback(UIRenderMode configuredMode) {
    return configuredMode == UIRenderMode.native &&
        !supportsNativeHost();
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
