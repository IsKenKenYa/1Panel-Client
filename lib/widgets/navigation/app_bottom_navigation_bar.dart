import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
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
    )
        // 导航浮层液态玻璃：内容从栏下滚动穿透（Apple Liquid Glass 语义）。
        // 仅 liquidGlass 渲染模式启用；md3 模式保持实色。
        // Impeller 下 GPU 折射着色器；Web/Skia 与低端设备由包内自动回退纯模糊。
        .asGlass(
          enabled: UIRenderPolicy.liquidGlassEnabled,
          tintColor: Theme.of(context).colorScheme.surface,
          frosted: true,
        );
  }
}
