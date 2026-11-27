import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/widgets/navigation/app_navigation_icon.dart';
import 'package:onepanel_client/widgets/navigation/glass_chrome_settings.dart';

class AppNavigationBarItem {
  const AppNavigationBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.glassLabel,
    this.enabled = true,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? glassLabel;
  final bool enabled;
}

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.destinationKeys,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavigationBarItem> items;
  final List<GlobalKey>? destinationKeys;

  static const _glassBarHeight = 64.0;
  static const _glassBarPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  /// 悬浮玻璃底栏在页面上占据的高度。
  ///
  /// 由栏体、上下内边距与系统安全区组成；`SafeArea.minimum` 取两者较大值，
  /// 因此底部让位是 `max(垂直内边距, 安全区)`。
  /// 壳层在液态玻璃模式下启用 `extendBody`，内容会延伸到栏下方；
  /// 页面内的 FAB 与底部操作条按此值上移，避免被玻璃栏覆盖。
  /// [glass] 为 false（实色底栏）时不需要额外让位，返回 0。
  static double glassBarExtentOf(BuildContext context, {bool? glass}) {
    final enabled = glass ?? UIRenderPolicy.liquidGlassEnabled;
    if (!enabled) {
      return 0;
    }
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomGap = safeBottom > _glassBarPadding.bottom
        ? safeBottom
        : _glassBarPadding.bottom;
    return _glassBarHeight + _glassBarPadding.top + bottomGap;
  }

  /// 读取并订阅渲染模式；不在 Provider 作用域内或控制器尚未载入时，
  /// 退回策略里的当前生效值（启动期由 main 写入）。
  static bool _glassEnabled(BuildContext context) {
    final settings =
        Provider.of<AppSettingsController?>(context, listen: true);
    if (settings == null || !settings.loaded) {
      return UIRenderPolicy.liquidGlassEnabled;
    }
    return UIRenderPolicy.glassEnabledFor(settings.uiRenderMode);
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final scheme = Theme.of(context).colorScheme;
    // 订阅设置项：切换渲染模式后底栏立即换成玻璃或实色形态。
    final glass = _glassEnabled(context);

    if (!glass) {
      return _buildMaterialBar(context, safeIndex, scheme);
    }
    // 主题表面色直接混合，降低滚动内容的对比度，保留预设的模糊和折射。
    // 方向光/菲涅尔等质感参数由 chromeGlassSettings 统一给出。
    final barSettings = chromeGlassSettings(
      Theme.brightnessOf(context),
      scheme.surfaceContainer.withValues(alpha: 0.90),
    );
    final quality = UIRenderPolicy.premiumGlassAllowed
        ? GlassQuality.premium
        : GlassQuality.standard;

    final Widget bar;
    // GlassTab 不接收禁用状态。Material 目的地统一处理点击、焦点与无障碍状态。
    if (items.any((item) => !item.enabled)) {
      bar = GlassContainer(
        shape:
            const LiquidRoundedSuperellipse(borderRadius: _glassBarHeight / 2),
        settings: barSettings,
        useOwnLayer: true,
        quality: quality,
        child: _buildMaterialBar(context, safeIndex, scheme, overGlass: true),
      );
    } else {
      bar = GlassTabBar.bottom(
        tabs: [
          for (final item in items)
            GlassTab(
              icon: Icon(item.icon),
              activeIcon: Icon(item.selectedIcon),
              label: item.glassLabel ?? item.label,
              semanticLabel: item.label,
            ),
        ],
        selectedIndex: safeIndex,
        onTabSelected: onTap,
        barHeight: _glassBarHeight,
        horizontalPadding: 0,
        verticalPadding: 0,
        iconSize: 24,
        selectedIconColor: scheme.primary,
        unselectedIconColor: scheme.onSurfaceVariant,
        selectedLabelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.secondaryContainer,
        settings: barSettings,
        quality: quality,
        backgroundQuality: quality,
      );
    }

    return SafeArea(
      top: false,
      minimum: _glassBarPadding,
      child: bar,
    );
  }

  NavigationBar _buildMaterialBar(
    BuildContext context,
    int selectedIndex,
    ColorScheme scheme, {
    bool overGlass = false,
  }) {
    final disabledColor = scheme.onSurfaceVariant.withValues(
      alpha: overGlass ? 0.70 : 0.42,
    );
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onTap,
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppDesignTokens.motionNormal,
      height: overGlass ? _glassBarHeight : null,
      backgroundColor: overGlass ? Colors.transparent : null,
      elevation: overGlass ? 0 : null,
      indicatorColor: overGlass ? scheme.secondaryContainer : null,
      labelTextStyle: overGlass
          ? WidgetStateProperty.resolveWith((states) {
              final color = switch (states) {
                _ when states.contains(WidgetState.disabled) => disabledColor,
                _ when states.contains(WidgetState.selected) =>
                  scheme.onSurface,
                _ => scheme.onSurfaceVariant,
              };
              return Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                  );
            })
          : null,
      destinations: [
        for (var index = 0; index < items.length; index++)
          _buildMaterialDestination(index, disabledColor, overGlass: overGlass),
      ],
    );
  }

  Widget _buildMaterialDestination(
    int index,
    Color disabledColor, {
    required bool overGlass,
  }) {
    final item = items[index];
    final iconColor = item.enabled ? null : disabledColor;
    final destination = NavigationDestination(
      icon: AppNavigationIcon(
        child: Icon(
          item.icon,
          key: ValueKey('${index}_unselected'),
          color: iconColor,
        ),
      ),
      selectedIcon: AppNavigationIcon(
        child: Icon(
          item.selectedIcon,
          key: ValueKey('${index}_selected'),
          color: iconColor,
        ),
      ),
      label: overGlass ? item.glassLabel ?? item.label : item.label,
      tooltip: overGlass ? item.label : null,
      enabled: item.enabled,
    );

    return overGlass
        ? DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: destination,
          )
        : destination;
  }
}
