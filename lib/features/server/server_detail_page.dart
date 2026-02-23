import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/core/theme/app_design_tokens.dart';
import 'package:onepanelapp_app/features/server/server_models.dart';
import 'package:onepanelapp_app/config/app_router.dart';

class ServerDetailPage extends StatelessWidget {
  const ServerDetailPage({
    super.key,
    required this.server,
  });

  final ServerCardViewModel server;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final moduleItems = [
      _ModuleItem(
        title: l10n.serverModuleDashboard,
        icon: Icons.dashboard_outlined,
        route: '/dashboard',
      ),
      _ModuleItem(
        title: l10n.serverModuleApps,
        icon: Icons.apps_outlined,
        route: '/apps',
      ),
      _ModuleItem(
        title: l10n.serverModuleContainers,
        icon: Icons.inventory_2_outlined,
        route: '/containers',
      ),
      _ModuleItem(
        title: l10n.serverModuleWebsites,
        icon: Icons.language_outlined,
        route: '/websites',
      ),
      _ModuleItem(
        title: l10n.serverModuleDatabases,
        icon: Icons.storage_outlined,
        route: '/databases',
      ),
      _ModuleItem(
        title: l10n.serverModuleFirewall,
        icon: Icons.shield_outlined,
        route: '/firewall',
      ),
      _ModuleItem(
        title: l10n.serverModuleTerminal,
        icon: Icons.terminal_outlined,
        route: '/terminal',
      ),
      _ModuleItem(
        title: l10n.serverModuleMonitoring,
        icon: Icons.monitor_heart_outlined,
        route: '/monitoring',
      ),
      _ModuleItem(
        title: l10n.serverModuleFiles,
        icon: Icons.folder_outlined,
        route: '/files',
      ),
      _ModuleItem(
        title: l10n.serverModuleSystemSettings,
        icon: Icons.settings_applications_outlined,
        route: '/system-settings',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serverDetailTitle),
      ),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: AppDesignTokens.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(server.config.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppDesignTokens.spacingSm),
                  Text(server.config.url),
                  const SizedBox(height: AppDesignTokens.spacingLg),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                          label: l10n.serverCpuLabel,
                          value: _percent(server.metrics.cpuPercent)),
                      _InfoChip(
                          label: l10n.serverMemoryLabel,
                          value: _percent(server.metrics.memoryPercent)),
                      _InfoChip(
                          label: l10n.serverLoadLabel,
                          value: _decimal(server.metrics.load)),
                      _InfoChip(
                          label: l10n.serverDiskLabel,
                          value: _percent(server.metrics.diskPercent)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingLg),
          Text(l10n.serverModulesTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDesignTokens.spacingSm),
          GridView.builder(
            itemCount: moduleItems.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final module = moduleItems[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                  onTap: () => _navigateToModule(context, module),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(module.icon),
                        const SizedBox(height: 6),
                        Text(
                          module.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDesignTokens.spacingLg),
          Text(l10n.serverActionsTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppDesignTokens.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.commonRefresh)),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.serverActionRefresh),
              ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.swap_horiz),
                label: Text(l10n.serverActionSwitch),
              ),
              FilledButton.tonalIcon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/security-verification'),
                icon: const Icon(Icons.verified_user_outlined),
                label: Text(l10n.serverActionSecurity),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToModule(BuildContext context, _ModuleItem module) {
    switch (module.route) {
      case '/dashboard':
        Navigator.pushNamed(context, '/dashboard');
        break;
      case '/apps':
        Navigator.pushNamed(context, '/apps');
        break;
      case '/containers':
        Navigator.pushNamed(context, '/containers');
        break;
      case '/websites':
        Navigator.pushNamed(context, '/websites');
        break;
      case '/databases':
        Navigator.pushNamed(context, '/databases');
        break;
      case '/firewall':
        Navigator.pushNamed(context, '/firewall');
        break;
      case '/terminal':
        Navigator.pushNamed(context, '/terminal');
        break;
      case '/monitoring':
        Navigator.pushNamed(context, '/monitoring');
        break;
      case '/files':
        Navigator.pushNamed(context, '/files');
        break;
      case '/system-settings':
        Navigator.pushNamed(context, AppRoutes.systemSettings);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${module.title} - ${context.l10n.commonComingSoon}')),
        );
    }
  }

  String _percent(double? value) {
    if (value == null) {
      return '--';
    }
    return '${value.toStringAsFixed(1)}%';
  }

  String _decimal(double? value) {
    if (value == null) {
      return '--';
    }
    return value.toStringAsFixed(2);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _ModuleItem {
  final String title;
  final IconData icon;
  final String route;

  _ModuleItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}
