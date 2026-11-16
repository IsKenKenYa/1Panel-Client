import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';

class AppNavigationBarItem {
  const AppNavigationBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.enabled = true,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
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

  @override
  Widget build(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, items.length - 1);

    if (!UIRenderPolicy.liquidGlassEnabled) {
      // md3 模式：Material NavigationBar 实色底栏。
      final disabledColor =
          Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.42);
      return NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: onTap,
        animationDuration: const Duration(milliseconds: 400),
        destinations: [
          for (var index = 0; index < items.length; index++)
            NavigationDestination(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  items[index].icon,
                  key: ValueKey('${index}_unselected'),
                  color: items[index].enabled ? null : disabledColor,
                ),
              ),
              selectedIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  items[index].selectedIcon,
                  key: ValueKey('${index}_selected'),
                  color: items[index].enabled ? null : disabledColor,
                ),
              ),
              label: items[index].label,
              enabled: items[index].enabled,
            ),
        ],
      );
    }

    // 液态玻璃模式：官方 GlassTabBar.bottom 悬浮胶囊——
    // SDF 圆角边缘折射 + 圆形衰减 + 果冻指示器物理动效，
    // 圆角 = 胶囊高度一半自动匹配（barBorderRadius 由包内按高度推导）。
    final scheme = Theme.of(context).colorScheme;
    final disabledColor = scheme.onSurfaceVariant.withValues(alpha: 0.42);
    return GlassTabBar.bottom(
      tabs: [
        for (final item in items)
          GlassTab(
            icon: Icon(
              item.icon,
              color: item.enabled ? null : disabledColor,
            ),
            activeIcon: Icon(
              item.selectedIcon,
              color: item.enabled ? null : disabledColor,
            ),
            label: item.label,
          ),
      ],
      selectedIndex: safeIndex,
      onTabSelected: (index) {
        if (index >= 0 && index < items.length && items[index].enabled) {
          onTap(index);
        }
      },
      barHeight: 64,
      horizontalPadding: 16,
      verticalPadding: 12,
      iconSize: 24,
      selectedIconColor: scheme.primary,
      unselectedIconColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.primaryContainer,
      // Apple Metal 走 premium（iOS 官方标准折射）；GLES/Skia 用轻量单 pass。
      quality: UIRenderPolicy.premiumGlassAllowed
          ? GlassQuality.premium
          : GlassQuality.standard,
      backgroundQuality: UIRenderPolicy.premiumGlassAllowed
          ? GlassQuality.premium
          : GlassQuality.standard,
    );
  }
}
