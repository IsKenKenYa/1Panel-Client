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
    final currentServerId =
        context.watch<CurrentServerController>().currentServerId;
    final serverProvider = context.watch<ServerProvider>();
    final pinnedController = context.watch<PinnedModulesController>();
    final activeServer = serverProvider.servers.firstWhere(
      (item) => item.config.id == currentServerId,
      orElse: () => server,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.serverDetailTitle),
        actions: [
          ServerSwitcherAction(onChanged: () => serverProvider.load()),
        ],
      ),
      body: ListView(
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
              onPressed: () => showMobilePinnedModulesCustomizerSheet(context),
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
      subtitle: module.experimental ? context.l10n.commonExperimental : null,
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
        title: l10n.serverModuleWebsites,
        icon: Icons.language_outlined,
        subtitle: l10n.commonExperimental,
        onTap: () => _openRoute(context, '/websites'),
      ),
      ServerDetailSectionItem(
        title: l10n.serverModuleDatabases,
        icon: Icons.storage_outlined,
        subtitle: l10n.commonExperimental,
        onTap: () => _openRoute(context, '/databases'),
      ),
      ServerDetailSectionItem(
        title: l10n.serverModuleFirewall,
        icon: Icons.shield_outlined,
        subtitle: l10n.commonExperimental,
        onTap: () => _openRoute(context, '/firewall'),
      ),
      ServerDetailSectionItem(
        title: l10n.serverModuleTerminal,
        icon: Icons.terminal_outlined,
        subtitle: l10n.commonExperimental,
        onTap: () => _openRoute(context, '/terminal'),
      ),
      ServerDetailSectionItem(
        title: l10n.serverModuleMonitoring,
        icon: Icons.monitor_heart_outlined,
        subtitle: l10n.commonExperimental,
        onTap: () => _openRoute(context, '/monitoring'),
      ),
      ServerDetailSectionItem(
        title: l10n.openrestyPageTitle,
        icon: Icons.tune_outlined,
        subtitle: l10n.commonExperimental,
        onTap: () => _openRoute(context, AppRoutes.openrestyCenter),
            ),
            ServerDetailSectionItem(
        title: l10n.serverModuleAi,
        icon: Icons.smart_toy_outlined,
        subtitle: l10n.commonExperimental,
        onTap: () => _openRoute(context, AppRoutes.ai),
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
        return '/containers';
      case ClientModule.apps:
        return '/apps';
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
    Navigator.pushNamed(context, route);
  }
}
