import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/theme/app_design_tokens.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanelapp_app/features/shell/controllers/recent_modules_controller.dart';
import 'package:onepanelapp_app/features/shell/models/client_module.dart';
import 'package:onepanelapp_app/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanelapp_app/l10n/generated/app_localizations.dart';

class WorkbenchPage extends StatelessWidget {
  const WorkbenchPage({
    super.key,
    required this.onOpenModule,
  });

  final ValueChanged<ClientModule> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ServerAwarePageScaffold(
      title: l10n.navWorkbench,
      body: Consumer3<CurrentServerController, PinnedModulesController,
          RecentModulesController>(
        builder: (context, currentServer, pinnedModules, recentModules, _) {
          final server = currentServer.currentServer;
          if (server == null) {
            return const SizedBox.shrink();
          }

          final quickModules = <ClientModule>{
            ...pinnedModules.pins,
            ClientModule.apps,
          }.toList(growable: false);
          final recent = recentModules.recent;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;

              final summaryCard =
                  _ServerSummaryCard(serverName: server.name, serverUrl: server.url);
              final recentCard = _RecentModulesCard(
                recentModules: recent,
                onOpenModule: onOpenModule,
              );
              final quickAccess = Column(
                key: const ValueKey('workbench-quick-access'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.workbenchQuickAccessTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSm),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final module in quickModules)
                        _ModuleShortcutCard(
                          module: module,
                          onTap: () => onOpenModule(module),
                        ),
                    ],
                  ),
                ],
              );
              final toolsSection = Column(
                key: const ValueKey('workbench-tools'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.workbenchToolsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSm),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ModuleShortcutCard(
                        module: ClientModule.verification,
                        onTap: () => onOpenModule(ClientModule.verification),
                      ),
                    ],
                  ),
                ],
              );
              final pinCard = Card(
                child: Padding(
                  padding: AppDesignTokens.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.shellPinnedModulesTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppDesignTokens.spacingSm),
                      Text(
                        l10n.shellPinnedModulesDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: AppDesignTokens.spacingMd),
                      FilledButton.tonalIcon(
                        onPressed: () => _showPinCustomizer(context, pinnedModules),
                        icon: const Icon(Icons.tune),
                        label: Text(l10n.shellPinnedModulesCustomize),
                      ),
                    ],
                  ),
                ),
              );

              if (!isDesktop) {
                return ListView(
                  padding: AppDesignTokens.pagePadding,
                  children: [
                    summaryCard,
                    const SizedBox(height: AppDesignTokens.spacingLg),
                    recentCard,
                    const SizedBox(height: AppDesignTokens.spacingLg),
                    quickAccess,
                    const SizedBox(height: AppDesignTokens.spacingLg),
                    toolsSection,
                    const SizedBox(height: AppDesignTokens.spacingLg),
                    pinCard,
                  ],
                );
              }

              return SingleChildScrollView(
                padding: AppDesignTokens.pagePadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        key: const ValueKey('workbench-left-column'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          summaryCard,
                          const SizedBox(height: AppDesignTokens.spacingLg),
                          recentCard,
                          const SizedBox(height: AppDesignTokens.spacingLg),
                          pinCard,
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDesignTokens.spacingXl),
                    Expanded(
                      child: Column(
                        key: const ValueKey('workbench-right-column'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          quickAccess,
                          const SizedBox(height: AppDesignTokens.spacingLg),
                          toolsSection,
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showPinCustomizer(
    BuildContext context,
    PinnedModulesController controller,
  ) async {
    final l10n = AppLocalizations.of(context);
    var first = controller.primaryPin;
    var second = controller.secondaryPin;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shellPinnedModulesCustomize,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _PinField(
                      title: l10n.shellPinnedModulesPrimary,
                      value: first,
                      options: controller.options,
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => first = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _PinField(
                      title: l10n.shellPinnedModulesSecondary,
                      value: second,
                      options: controller.options,
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => second = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await controller.reset();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(l10n.commonReset),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            await controller.setPin(0, first);
                            await controller.setPin(1, second);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(l10n.commonSave),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ServerSummaryCard extends StatelessWidget {
  const _ServerSummaryCard({
    required this.serverName,
    required this.serverUrl,
  });

  final String serverName;
  final String serverUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: AppDesignTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.serverCurrent,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              serverName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              serverUrl,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentModulesCard extends StatelessWidget {
  const _RecentModulesCard({
    required this.recentModules,
    required this.onOpenModule,
  });

  final List<ClientModule> recentModules;
  final ValueChanged<ClientModule> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: const ValueKey('workbench-recent-card'),
      child: Padding(
        padding: AppDesignTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workbenchRecentModulesTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
            if (recentModules.isEmpty)
              Text(
                l10n.workbenchRecentModulesEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final module in recentModules)
                    _ModuleShortcutCard(
                      module: module,
                      onTap: () => onOpenModule(module),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleShortcutCard extends StatelessWidget {
  const _ModuleShortcutCard({
    required this.module,
    required this.onTap,
  });

  final ClientModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 156,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(module.icon),
                const SizedBox(height: 12),
                Text(
                  module.label(l10n),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final ClientModule value;
  final List<ClientModule> options;
  final ValueChanged<ClientModule?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: title,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClientModule>(
          value: value,
          isExpanded: true,
          items: [
            for (final option in options)
              DropdownMenuItem<ClientModule>(
                value: option,
                child: Text(option.label(l10n)),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
