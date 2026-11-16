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
    final scheme = Theme.of(context).colorScheme;
    final disabledColor = scheme.onSurfaceVariant.withValues(alpha: 0.42);
    final isGlass = UIRenderPolicy.liquidGlassEnabled;

    final bar = NavigationBar(
      selectedIndex: safeIndex,
      onDestinationSelected: onTap,
      animationDuration: const Duration(milliseconds: 400),
      // 玻璃模式下载体必须透明：不透明背景会挡住 BackdropFilter 的场景采样，
      // 玻璃模糊到的就是这块实色（视觉等于没玻璃）。md3 模式走 theme 默认底色。
      backgroundColor: isGlass ? Colors.transparent : null,
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

    if (!isGlass) {
      return bar;
    }

    // Apple Liquid Glass 悬浮胶囊形态：四周留边悬浮于内容之上，
    // StadiumBorder 全圆角与玻璃形状匹配；折射/高光/阴影由
    // [UIRenderPolicy.glassStyle]（Glass.regular 参数）承担。
    // 列表末项让位由壳页 body 的 MediaQuery 注入统一处理。
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: UIRenderPolicy.floatingPillRadius,
        child: bar.asGlass(
          liquid: UIRenderPolicy.glassStyle,
          clipBorderRadius: UIRenderPolicy.floatingPillRadius,
        ),
      ),
    );
  }
}
