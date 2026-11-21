import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/adaptive_shell_navigation_widget.dart';

enum DesktopNavigationPlacement {
  drawer,
  rail,
  sidebar;

  static DesktopNavigationPlacement of(BuildContext context) {
    final spec = AdaptiveLayoutSpec.of(context);
    if (spec.isPhone ||
        PlatformUtils.inputDeviceKinds(context) == InputDeviceKind.touch) {
      return drawer;
    }
    return spec.width < PlatformUtils.tabletWidthBreakpoint ? rail : sidebar;
  }
}

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.modules,
    required this.selectedModule,
    required this.hasServer,
    required this.onSelect,
    this.extended = true,
    this.width = 300,
    this.backgroundColor,
  });

  final List<ClientModule> modules;
  final ClientModule selectedModule;
  final bool hasServer;
  final ValueChanged<ClientModule> onSelect;
  final bool extended;
  final double width;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        modules.indexOf(selectedModule).clamp(0, modules.length - 1);
    final scheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? scheme.surface;

    return SafeArea(
      right: false,
      child: Container(
        width: extended ? width : null,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        // 桌面导航浮层液态玻璃：Container 不设背景色（玻璃 tint 承担底色），
        // NavigationRail backgroundColor 本就 transparent；md3 模式玻璃禁用
        // 后由 asGlass(enabled:false) 直通，需还原实色底。
        child: Container(
          color: UIRenderPolicy.liquidGlassEnabled ? null : bgColor,
          child: NavigationRail(
            extended: extended,
            scrollable: true,
            backgroundColor: Colors.transparent,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              Scaffold.maybeOf(context)?.closeDrawer();
              onSelect(modules[index]);
            },
            labelType: NavigationRailLabelType.none,
            useIndicator: true,
            indicatorColor: scheme.primaryContainer,
            minExtendedWidth: width,
            leading: extended
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      context.l10n.appName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  )
                : null,
            destinations: shellRailDestinations(
              context, modules, hasServer: hasServer,
            ),
          ),
        ),
      ).asGlass(
        // 仅 liquidGlass 渲染模式启用玻璃；md3 模式保持实色侧栏。
        // Glass.regular 预设与移动端浮层观感一致。
        enabled: UIRenderPolicy.liquidGlassEnabled,
        liquid: UIRenderPolicy.glassStyle,
        tintColor: bgColor,
      ),
    );
  }
}

