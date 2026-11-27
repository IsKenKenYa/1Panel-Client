import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/controllers/pinned_modules_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/mobile_pinned_modules_customizer_sheet.dart';

class OnePanelModuleSections extends StatelessWidget {
  const OnePanelModuleSections({super.key, required this.serverId});

  final String serverId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pins = context.select((PinnedModulesController p) => p.pins);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: l10n.shellPinnedModulesTitle,
          description: l10n.shellPinnedModulesDescription,
          action: TextButton.icon(
            onPressed: () => showMobilePinnedModulesCustomizerSheet(context),
            icon: const Icon(Icons.tune),
            label: Text(l10n.shellPinnedModulesCustomize),
          ),
          child: _AdaptiveModuleGrid(
            items: [
              for (final module in pins) _buildClientModuleItem(context, module),
            ],
          ),
        ),
        const SizedBox(height: AppDesignTokens.spacingLg),
        SectionCard(
          title: l10n.serverModulesTitle,
          child: _AdaptiveModuleGrid(
            items: [
              for (final module in kPinnableClientModules)
                if (!pins.contains(module))
                  _buildClientModuleItem(context, module),
            ],
          ),
        ),
        const SizedBox(height: AppDesignTokens.spacingLg),
        SectionCard(
          title: l10n.commonMore,
          child: _AdaptiveModuleGrid(items: _buildServerModuleItems(context)),
        ),
      ],
    );
  }

  SectionEntryItem _buildClientModuleItem(
    BuildContext context,
    ClientModule module,
  ) {
    return SectionEntryItem(
      title: module.label(context.l10n),
      icon: module.icon,
      onTap: () => _openRoute(context, _routeForClientModule(module)),
    );
  }

  List<SectionEntryItem> _buildServerModuleItems(BuildContext context) {
    final l10n = context.l10n;
    return [
      SectionEntryItem(
        title: l10n.dashboardTitle,
        icon: Icons.dashboard_outlined,
        onTap: () => _openRoute(context, AppRoutes.dashboard),
      ),
      SectionEntryItem(
        title: l10n.operationsCenterServerEntryTitle,
        icon: Icons.space_dashboard_outlined,
        subtitle: l10n.operationsCenterServerEntrySubtitle,
        onTap: () => _openRoute(context, AppRoutes.operations),
      ),
      SectionEntryItem(
        title: l10n.serverModuleDatabases,
        icon: Icons.storage_outlined,
        onTap: () => _openRoute(context, AppRoutes.databases),
      ),
      SectionEntryItem(
        title: l10n.alertPageTitle,
        icon: Icons.notifications_active_outlined,
        onTap: () => _openRoute(context, AppRoutes.alert),
      ),
      SectionEntryItem(
        title: l10n.serverModuleFirewall,
        icon: Icons.shield_outlined,
        onTap: () => _openRoute(context, AppRoutes.firewall),
      ),
      SectionEntryItem(
        title: l10n.serverModuleTerminal,
        icon: Icons.terminal_outlined,
        onTap: () => _openRoute(context, AppRoutes.terminal),
      ),
      SectionEntryItem(
        title: l10n.serverModuleMonitoring,
        icon: Icons.monitor_heart_outlined,
        onTap: () => _openRoute(context, AppRoutes.monitoring),
      ),
      SectionEntryItem(
        title: l10n.openrestyPageTitle,
        icon: Icons.tune_outlined,
        onTap: () => _openRoute(context, AppRoutes.openrestyCenter),
      ),
      SectionEntryItem(
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
      case ClientModule.vm:
        return AppRoutes.vm;
      case ClientModule.verification:
        return AppRoutes.securityVerification;
      case ClientModule.servers:
        return AppRoutes.server;
      case ClientModule.settings:
        return AppRoutes.settings;
    }
  }

  Future<void> _openRoute(BuildContext context, String route) async {
    final controller = context.read<CurrentServerController>();
    final detail = ModalRoute.of(context);
    if (controller.currentServerId != serverId) {
      try {
        await controller.selectServer(serverId);
      } catch (error) {
        if (context.mounted && detail?.isCurrent != false) {
          SnackBarUtils.showError(
            context,
            ErrorMessageUtils.userFacingMessage(error),
          );
        }
        return;
      }
    }
    if (!context.mounted ||
        controller.currentServerId != serverId ||
        detail?.isCurrent == false) {
      return;
    }
    openRouteRespectingShell(context, route);
  }
}

class _AdaptiveModuleGrid extends StatelessWidget {
  const _AdaptiveModuleGrid({required this.items});

  final List<SectionEntryItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = textScale >= 1.35 || width < 360
            ? 1
            : width >= 720
            ? 3
            : 2;

        if (columns == 1) {
          return Column(
            children: [
              for (final (index, item) in items.indexed) ...[
                _buildTile(theme, scheme, item, compact: false),
                if (index < items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: AppDesignTokens.spacingLg,
                    endIndent: AppDesignTokens.spacingLg,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
              ],
            ],
          );
        }

        final rows = <List<SectionEntryItem>>[];
        for (var i = 0; i < items.length; i += columns) {
          final end = (i + columns).clamp(0, items.length);
          rows.add(items.sublist(i, end));
        }

        return Padding(
          padding: const EdgeInsets.all(AppDesignTokens.spacingSm),
          child: Column(
            children: [
              for (final (rowIndex, row) in rows.indexed) ...[
                if (rowIndex > 0)
                  const SizedBox(height: AppDesignTokens.spacingSm),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < columns; col++) ...[
                        if (col > 0)
                          const SizedBox(width: AppDesignTokens.spacingSm),
                        Expanded(
                          child: col < row.length
                              ? Material(
                                  color: scheme.surfaceContainerLow,
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppDesignTokens.radiusMd,
                                    ),
                                    side: BorderSide(
                                      color: scheme.outlineVariant.withValues(
                                        alpha: 0.45,
                                      ),
                                    ),
                                  ),
                                  child: _buildTile(
                                    theme,
                                    scheme,
                                    row[col],
                                    compact: true,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTile(
    ThemeData theme,
    ColorScheme scheme,
    SectionEntryItem item, {
    required bool compact,
  }) {
    return ListTile(
      key: item.key,
      minTileHeight: compact ? 52 : 56,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact
            ? AppDesignTokens.spacingMd
            : AppDesignTokens.spacingLg,
        vertical: AppDesignTokens.spacingXs,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
        ),
        alignment: Alignment.center,
        child: Icon(item.icon, size: 20),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: !compact && item.subtitle != null
          ? Text(
              item.subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: compact
          ? null
          : item.trailing ??
                (item.onTap == null
                    ? null
                    : Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      )),
      onTap: item.onTap,
    );
  }
}
