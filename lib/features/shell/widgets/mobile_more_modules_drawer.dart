import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/mobile_pinned_modules_customizer_sheet.dart';

class MobileMoreModulesDrawer extends StatelessWidget {
  const MobileMoreModulesDrawer({
    super.key,
    required this.modules,
    required this.pinnedModules,
    required this.selectedModule,
    required this.hasServer,
    required this.onModuleTap,
    required this.onClose,
    required this.onManageServers,
  });

  final List<ClientModule> modules;
  final List<ClientModule> pinnedModules;
  final ClientModule selectedModule;
  final bool hasServer;
  final ValueChanged<ClientModule> onModuleTap;
  final VoidCallback onClose;
  final VoidCallback onManageServers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Drawer(
      width: math.min(360, MediaQuery.sizeOf(context).width * 0.86),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.commonMore,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.shellPinnedModulesDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    tooltip: l10n.commonClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                children: [
                  Text(
                    l10n.shellPinnedModulesTitle,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final module in pinnedModules)
                        InputChip(
                          label: Text(module.label(l10n)),
                          selected: module == selectedModule,
                          onPressed: () => onModuleTap(module),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.serverModulesTitle,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  if (modules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.commonEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...modules.map((module) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _ModuleTile(
                            module: module,
                            selectedModule: selectedModule,
                            hasServer: hasServer,
                            onTap: onModuleTap,
                          ),
                        )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          showMobilePinnedModulesCustomizerSheet(context),
                      icon: const Icon(Icons.tune),
                      label: Text(l10n.shellPinnedModulesCustomize),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onManageServers,
                      icon: const Icon(Icons.dns_outlined),
                      label: Text(l10n.serverPageTitle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.selectedModule,
    required this.hasServer,
    required this.onTap,
  });

  final ClientModule module;
  final ClientModule selectedModule;
  final bool hasServer;
  final ValueChanged<ClientModule> onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = !module.requiresServer || hasServer;
    final disabledColor =
        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.72);
    final l10n = context.l10n;

    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(
        enabled ? module.icon : Icons.lock_outline,
        color: enabled ? null : disabledColor,
      ),
      title: Text(module.label(l10n)),
      subtitle: enabled ? null : Text(l10n.noServerSelectedDescription),
      selected: module == selectedModule,
      trailing: module == selectedModule
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.chevron_right),
      onTap: () => onTap(module),
    );
  }
}
