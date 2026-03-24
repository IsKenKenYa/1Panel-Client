import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/shell/models/client_module.dart';

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
    final disabledColor =
        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.42);

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => onSelect(modules[index]),
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final module in modules)
          NavigationRailDestination(
            icon: Icon(
              module.icon,
              color: !module.requiresServer || hasServer ? null : disabledColor,
            ),
            selectedIcon: Icon(
              module.selectedIcon,
              color: !module.requiresServer || hasServer ? null : disabledColor,
            ),
            label: Text(module.label(context.l10n)),
          ),
      ],
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
    return Container(
      width: 264,
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Icon(module.icon),
                title: Text(module.label(context.l10n)),
                selected: module == selectedModule,
                enabled: !module.requiresServer || hasServer,
                onTap: () => onSelect(module),
              ),
            ),
        ],
      ),
    );
  }
}
