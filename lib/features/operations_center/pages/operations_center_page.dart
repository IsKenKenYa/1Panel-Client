import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/operations_center/widgets/server_operation_entry_card_widget.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';

class OperationsCenterPage extends StatelessWidget {
  const OperationsCenterPage({super.key});

  static const String automationSectionKey = 'operations-section-automation';
  static const String runtimeSectionKey = 'operations-section-runtime';
  static const String systemSectionKey = 'operations-section-system';
  static const String commandsEntryKey = 'operations-entry-commands';
  static const String runtimesEntryKey = 'operations-entry-runtimes';
  static const String groupsEntryKey = 'operations-entry-groups';
  static const String hostAssetsEntryKey = 'operations-entry-host-assets';
  static const String toolboxEntryKey = 'operations-entry-toolbox';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = <_OperationsSection>[
      _OperationsSection(
        id: 'automation',
        title: l10n.operationsCenterAutomationSectionTitle,
        description: l10n.operationsCenterAutomationSectionDescription,
        entries: [
          _OperationEntry(
            routeId: 'cronjobs',
            title: l10n.operationsCronjobsTitle,
            route: AppRoutes.cronjobs,
            icon: Icons.schedule_outlined,
          ),
          _OperationEntry(
            routeId: 'scripts',
            title: l10n.operationsScriptsTitle,
            route: AppRoutes.scripts,
            icon: Icons.code_outlined,
          ),
          _OperationEntry(
            routeId: 'commands',
            title: l10n.operationsCommandsTitle,
            route: AppRoutes.commands,
            icon: Icons.terminal_outlined,
          ),
          _OperationEntry(
            routeId: 'backups',
            title: l10n.operationsBackupsTitle,
            route: AppRoutes.backups,
            icon: Icons.backup_outlined,
          ),
        ],
      ),
      _OperationsSection(
        id: 'runtime',
        title: l10n.operationsCenterRuntimeSectionTitle,
        description: l10n.operationsCenterRuntimeSectionDescription,
        entries: [
          _OperationEntry(
            routeId: 'runtimes',
            title: l10n.operationsRuntimesTitle,
            route: AppRoutes.runtimes,
            icon: Icons.memory_outlined,
          ),
        ],
      ),
      _OperationsSection(
        id: 'system',
        title: l10n.operationsCenterSystemSectionTitle,
        description: l10n.operationsCenterSystemSectionDescription,
        entries: [
          _OperationEntry(
            routeId: 'groups',
            title: l10n.operationsGroupCenterTitle,
            route: AppRoutes.groupCenter,
            icon: Icons.folder_copy_outlined,
          ),
          _OperationEntry(
            routeId: 'host-assets',
            title: l10n.operationsHostAssetsTitle,
            route: AppRoutes.hostAssets,
            icon: Icons.dns_outlined,
          ),
          _OperationEntry(
            routeId: 'ssh',
            title: l10n.operationsSshTitle,
            route: AppRoutes.ssh,
            icon: Icons.key_outlined,
          ),
          _OperationEntry(
            routeId: 'processes',
            title: l10n.operationsProcessesTitle,
            route: AppRoutes.processes,
            icon: Icons.monitor_heart_outlined,
          ),
          _OperationEntry(
            routeId: 'logs',
            title: l10n.operationsLogsTitle,
            route: AppRoutes.logs,
            icon: Icons.article_outlined,
          ),
          _OperationEntry(
            routeId: 'toolbox',
            title: l10n.operationsToolboxTitle,
            route: AppRoutes.toolbox,
            icon: Icons.handyman_outlined,
          ),
        ],
      ),
    ];

    return ServerAwarePageScaffold(
      title: l10n.operationsCenterPageTitle,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final cardWidth =
              isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.operationsCenterIntro,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final section in sections) ...[
                Text(
                  key: Key('operations-section-${section.id}'),
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  section.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in section.entries)
                      SizedBox(
                        width: cardWidth,
                        child: ServerOperationEntryCardWidget(
                          key: Key('operations-entry-${entry.routeId}'),
                          title: entry.title,
                          icon: entry.icon,
                          onTap: () =>
                              Navigator.pushNamed(context, entry.route),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OperationsSection {
  const _OperationsSection({
    required this.id,
    required this.title,
    required this.description,
    required this.entries,
  });

  final String id;
  final String title;
  final String description;
  final List<_OperationEntry> entries;
}

class _OperationEntry {
  const _OperationEntry({
    required this.routeId,
    required this.title,
    required this.route,
    required this.icon,
  });

  final String routeId;
  final String title;
  final String route;
  final IconData icon;
}
