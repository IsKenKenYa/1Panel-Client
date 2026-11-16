import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.modules,
    required this.selectedModule,
    required this.hasServer,
    required this.onSelect,
    this.width = 300,
    this.backgroundColor,
  });

  final List<ClientModule> modules;
  final ClientModule selectedModule;
  final bool hasServer;
  final ValueChanged<ClientModule> onSelect;
  final double width;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        modules.indexOf(selectedModule).clamp(0, modules.length - 1);
    final scheme = Theme.of(context).colorScheme;
    final disabledColor = scheme.onSurfaceVariant.withValues(alpha: 0.42);
    final bgColor = backgroundColor ?? scheme.surface;

    return SafeArea(
      right: false,
      child: Container(
        width: width,
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
            extended: true,
            backgroundColor: Colors.transparent,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => onSelect(modules[index]),
            labelType: NavigationRailLabelType.none,
            useIndicator: true,
            indicatorColor: scheme.primaryContainer,
            minExtendedWidth: width,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                context.l10n.appName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            destinations: [
              for (final module in modules)
                NavigationRailDestination(
                  icon: Icon(
                    module.icon,
                    color: !module.requiresServer || hasServer
                        ? null
                        : disabledColor,
                  ),
                  selectedIcon: Icon(
                    module.selectedIcon,
                    color: !module.requiresServer || hasServer
                        ? null
                        : disabledColor,
                  ),
                  label: Text(module.label(context.l10n)),
                ),
            ],
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

