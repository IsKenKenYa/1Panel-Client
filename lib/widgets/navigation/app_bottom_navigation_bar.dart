import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
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

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final scheme = Theme.of(context).colorScheme;

    if (!UIRenderPolicy.liquidGlassEnabled) {
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
        indicatorColor: scheme.primaryContainer,
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
      animationDuration: const Duration(milliseconds: 400),
      height: overGlass ? _glassBarHeight : null,
      backgroundColor: overGlass ? Colors.transparent : null,
      elevation: overGlass ? 0 : null,
      indicatorColor: overGlass ? scheme.primaryContainer : null,
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
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: _animateIcon,
        child: Icon(
          item.icon,
          key: ValueKey('${index}_unselected'),
          color: iconColor,
        ),
      ),
      selectedIcon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: _animateIcon,
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

  static Widget _animateIcon(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
