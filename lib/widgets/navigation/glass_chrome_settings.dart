import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';

/// 液态玻璃模式下壳层铬件（顶栏/底栏）共享的玻璃参数。
///
/// iOS 27 预设按 premium 路径标定：方向光与菲涅尔为 0，rimLight 由
/// premium 的 rim band 承担。standard 路径（Android GLES / Web）没有
/// rim band，包文档指明以 specular highlight 替代 rimLight，而 specular
/// 由 lightIntensity 驱动——预设的 0 会让 standard 玻璃失去高光，观感
/// 偏平。此处按包内 ios26Dark 的标定三元组（lightIntensity 0.18、
/// ambientStrength 0.05、fresnelStrength 0.30）为 standard 补齐方向光
/// 与菲涅尔；Apple 侧 premium 保持预设原值，维持 iOS 27 复刻。
/// chromaticAberration 0.18 沿用安卓玻璃增强既有取值。
LiquidGlassSettings chromeGlassSettings(Brightness brightness, Color tint) {
  final base = brightness == Brightness.dark
      ? LiquidGlassSettings.ios27Dark
      : LiquidGlassSettings.ios27Light;
  final tinted = base.copyWith(
    bodyMode: GlassBodyMode.clear,
    glassColor: tint,
    chromaticAberration: 0.18,
  );
  if (UIRenderPolicy.premiumGlassAllowed) {
    return tinted;
  }
  return tinted.copyWith(
    lightIntensity: brightness == Brightness.dark ? 0.18 : 0.22,
    ambientStrength: 0.05,
    fresnelStrength: 0.30,
  );
}
