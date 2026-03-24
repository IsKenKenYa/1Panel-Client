import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/features/shell/models/client_module.dart';
import 'package:onepanelapp_app/features/shell/widgets/mobile_pinned_modules_customizer_sheet.dart';

class MobileMoreModulesHandle extends StatelessWidget {
  const MobileMoreModulesHandle({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: l10n.commonMore,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.96),
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
        child: InkWell(
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(18)),
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    l10n.commonMore,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MobileMoreModulesDrawer extends StatelessWidget {
  const MobileMoreModulesDrawer({
    super.key,
    required this.modules,
    required this.selectedModule,
    required this.hasServer,
    required this.onModuleTap,
    required this.onClose,
  });

  final List<ClientModule> modules;
  final ClientModule selectedModule;
  final bool hasServer;
  final ValueChanged<ClientModule> onModuleTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                    child: Text(
                      l10n.commonMore,
                      style: Theme.of(context).textTheme.titleLarge,
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
              child: modules.isEmpty
                  ? Center(
                      child: Text(
                        l10n.commonEmpty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      itemCount: modules.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final module = modules[index];
                        final enabled = !module.requiresServer || hasServer;
                        final disabledColor = Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.72);
                        return ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: Icon(
                            enabled ? module.icon : Icons.lock_outline,
                            color: enabled ? null : disabledColor,
                          ),
                          title: Text(module.label(l10n)),
                          subtitle: enabled
                              ? null
                              : Text(l10n.noServerSelectedDescription),
                          selected: module == selectedModule,
                          trailing: module == selectedModule
                              ? Icon(
                                  Icons.chevron_right,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: () => onModuleTap(module),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    showMobilePinnedModulesCustomizerSheet(context),
                icon: const Icon(Icons.tune),
                label: Text(l10n.shellPinnedModulesCustomize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
