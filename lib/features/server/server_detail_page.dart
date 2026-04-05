import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/widgets/server_detail_header_card.dart';
import 'package:onepanel_client/features/server/widgets/server_detail_section_card.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/mobile_pinned_modules_customizer_sheet.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';

class ServerDetailPage extends StatelessWidget {
  const ServerDetailPage({
    super.key,
    required this.server,
  });

  final ServerCardViewModel server;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final currentServerId =
        context.watch<CurrentServerController>().currentServerId;
    final serverProvider = context.watch<ServerProvider>();
    final pinnedController = context.watch<PinnedModulesController>();
    final activeServer = serverProvider.servers.firstWhere(
      (item) => item.config.id == currentServerId,
      orElse: () => server,
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.serverDetailTitle),
        actions: [
          ServerSwitcherAction(onChanged: () => serverProvider.load()),
          IconButton(
            tooltip: l10n.commonDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteServer(context, activeServer),
          ),
        ],
      ),
      body: ColoredBox(
        color: scheme.surface,
        child: ListView(
          padding: AppDesignTokens.pagePadding,
          children: [
            ServerDetailHeaderCard(
              server: activeServer,
              onRefresh: () => _refreshServer(context),
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            ServerDetailSectionCard(
              title: l10n.shellPinnedModulesTitle,
              description: l10n.shellPinnedModulesDescription,
              action: TextButton.icon(
                onPressed: () =>
                    showMobilePinnedModulesCustomizerSheet(context),
                icon: const Icon(Icons.tune),
                label: Text(l10n.shellPinnedModulesCustomize),
              ),
              items: [
                for (final module in pinnedController.pins)
                  _buildClientModuleItem(context, module),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            ServerDetailSectionCard(
              title: l10n.serverModulesTitle,
              items: [
                for (final module in kPinnableClientModules)
                  if (!pinnedController.pins.contains(module))
                    _buildClientModuleItem(context, module),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            ServerDetailSectionCard(
              title: l10n.commonMore,
              items: _buildServerModuleItems(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshServer(BuildContext context) async {
    final l10n = context.l10n;
    final provider = context.read<ServerProvider>();
    await provider.load();
    await provider.loadMetrics();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.commonRefresh)),
    );
  }

  ServerDetailSectionItem _buildClientModuleItem(
    BuildContext context,
    ClientModule module,
  ) {
    return ServerDetailSectionItem(
      title: module.label(context.l10n),
      icon: module.icon,
      onTap: () => _openRoute(context, _routeForClientModule(module)),
    );
  }

  List<ServerDetailSectionItem> _buildServerModuleItems(BuildContext context) {
    final l10n = context.l10n;
    return [
      ServerDetailSectionItem(
        title: l10n.operationsCenterServerEntryTitle,
        icon: Icons.space_dashboard_outlined,
        subtitle: l10n.operationsCenterServerEntrySubtitle,
        onTap: () => _openRoute(context, AppRoutes.operations),
      ),
      ServerDetailSectionItem(
        title: l10n.serverModuleDatabases,
        icon: Icons.storage_outlined,
        onTap: () => _openRoute(context, AppRoutes.databases),
      ),
      ServerDetailSectionItem(
        title: l10n.serverModuleFirewall,
        icon: Icons.shield_outlined,
        onTap: () => _openRoute(context, AppRoutes.firewall),
      ),
      ServerDetailSectionItem(
        title: l10n.serverModuleTerminal,
        icon: Icons.terminal_outlined,
        onTap: () => _openRoute(context, AppRoutes.terminal),
      ),
      ServerDetailSectionItem(
        title: l10n.serverModuleMonitoring,
        icon: Icons.monitor_heart_outlined,
        onTap: () => _openRoute(context, AppRoutes.monitoring),
      ),
      ServerDetailSectionItem(
        title: l10n.openrestyPageTitle,
        icon: Icons.tune_outlined,
        onTap: () => _openRoute(context, AppRoutes.openrestyCenter),
      ),
      ServerDetailSectionItem(
        title: l10n.serverModuleSystemSettings,
        icon: Icons.settings_applications_outlined,
        onTap: () => _openRoute(context, AppRoutes.systemSettings),
      ),
    ];
  }

  String _routeForClientModule(ClientModule module) {
    switch (module) {
      case ClientModule.files:
        return AppRoutes.files;
      case ClientModule.containers:
        return AppRoutes.containers;
      case ClientModule.apps:
        return AppRoutes.apps;
      case ClientModule.websites:
        return AppRoutes.websites;
      case ClientModule.ai:
        return AppRoutes.ai;
      case ClientModule.verification:
        return AppRoutes.securityVerification;
      case ClientModule.servers:
        return AppRoutes.server;
      case ClientModule.settings:
        return AppRoutes.settings;
    }
  }

  void _openRoute(BuildContext context, String route) {
    openRouteRespectingShell(context, route);
  }

  Future<void> _deleteServer(
    BuildContext context,
    ServerCardViewModel target,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.serverDeleteConfirmTitle),
            content: Text(l10n.serverDeleteConfirmMessage(target.config.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.commonDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }

    final serverProvider = context.read<ServerProvider>();
    final currentServerController = context.read<CurrentServerController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final successMessage = l10n.serverDeleteSuccess(target.config.name);

    try {
      // Close the page first to avoid widget tree issues during deletion
      navigator.pop();

      await serverProvider.delete(target.config.id);
      await currentServerController.refresh();

      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.serverDeleteFailed(error.toString())),
        ),
      );
    }
  }
}
