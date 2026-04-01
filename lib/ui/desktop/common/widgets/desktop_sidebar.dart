import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
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
    final scheme = Theme.of(context).colorScheme;
    final disabledColor = scheme.onSurfaceVariant.withValues(alpha: 0.42);

    return SafeArea(
      right: false,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            right: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: NavigationRail(
          extended: true,
          backgroundColor: scheme.surface,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => onSelect(modules[index]),
          labelType: NavigationRailLabelType.none,
          useIndicator: true,
          indicatorColor: scheme.primaryContainer,
          minExtendedWidth: 300,
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
                  color: !module.requiresServer || hasServer ? null : disabledColor,
                ),
                selectedIcon: Icon(
                  module.selectedIcon,
                  color: !module.requiresServer || hasServer ? null : disabledColor,
                ),
                label: Text(module.label(context.l10n)),
              ),
          ],
        ),
      ),
    );
  }
}

