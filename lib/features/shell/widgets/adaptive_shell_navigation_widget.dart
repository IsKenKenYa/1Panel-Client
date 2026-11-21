import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/widgets/navigation/app_navigation_icon.dart';

List<NavigationRailDestination> shellRailDestinations(
  BuildContext context,
  List<ClientModule> modules, {
  required bool hasServer,
  bool animateIcons = false,
}) {
  final disabledColor =
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.42);
  Widget icon(ClientModule module, bool selected) {
    final child = Icon(
      selected ? module.selectedIcon : module.icon,
      key: ValueKey((module, selected)),
      color: module.requiresServer && !hasServer ? disabledColor : null,
    );
    return animateIcons ? AppNavigationIcon(child: child) : child;
  }

  return [
    for (final module in modules)
      NavigationRailDestination(
        icon: icon(module, false),
        selectedIcon: icon(module, true),
        label: Text(module.label(context.l10n)),
      ),
  ];
}

class ShellRailNavigation extends StatelessWidget {
  const ShellRailNavigation({
    super.key,
    required this.modules,
    required this.selectedModule,
    required this.hasServer,
    required this.onSelect,
  });

  final List<ClientModule> modules;
  final ClientModule selectedModule;
  final bool hasServer;
  final ValueChanged<ClientModule> onSelect;

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        modules.indexOf(selectedModule).clamp(0, modules.length - 1);

    return NavigationRail(
      scrollable: true,
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => onSelect(modules[index]),
      labelType: NavigationRailLabelType.all,
      destinations: shellRailDestinations(
        context, modules, hasServer: hasServer, animateIcons: true,
      ),
    );
  }
}

class ShellSidebarNavigation extends StatelessWidget {
  const ShellSidebarNavigation({
    super.key,
    required this.modules,
    required this.selectedModule,
    required this.hasServer,
    required this.onSelect,
  });

  final List<ClientModule> modules;
  final ClientModule selectedModule;
  final bool hasServer;
  final ValueChanged<ClientModule> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      right: false,
      child: Container(
        width: 264,
        color: scheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.appName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              for (final module in modules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                    ),
                    leading: AppNavigationIcon(
                      child: Icon(
                        module == selectedModule
                            ? module.selectedIcon
                            : module.icon,
                        key: ValueKey(
                          '${module.storageId}_${module == selectedModule}',
                        ),
                      ),
                    ),
                    title: Text(module.label(context.l10n)),
                    selected: module == selectedModule,
                    enabled: !module.requiresServer || hasServer,
                    onTap: () => onSelect(module),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
