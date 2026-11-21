import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/settings/upgrade_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import '../../../core/i18n/l10n_x.dart';
import '../../../shared/widgets/app_card.dart';
import '../dashboard_provider.dart';

import '../../../core/utils/snackbar_utils.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      title: l10n.dashboardQuickActionsTitle,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _QuickActionItem(
            icon: Icons.restart_alt,
            label: l10n.dashboardActionRestart,
            color: Theme.of(context).colorScheme.error,
            onTap: () => _showRestartDialog(context),
          ),
          _QuickActionItem(
            icon: Icons.update,
            label: l10n.dashboardActionUpdate,
            color: Theme.of(context).colorScheme.primary,
            onTap: () => _openUpgrade(context),
          ),
          _QuickActionItem(
            icon: Icons.backup,
            label: l10n.dashboardActionBackup,
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () => openRouteRespectingShell(context, AppRoutes.backups),
          ),
          _QuickActionItem(
            icon: Icons.security,
            label: l10n.dashboardActionSecurity,
            color: Theme.of(context).colorScheme.secondary,
            onTap: () => openRouteRespectingShell(
              context,
              AppRoutes.securityVerification,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestartDialog(BuildContext context) async {
    final l10n = context.l10n;
    final provider = context.read<DashboardProvider>();
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.dashboardRestartTitle,
      message: l10n.dashboardRestartDesc,
      confirmIcon: Icons.restart_alt,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted || provider.isDisposed) return;
    try {
      await provider.restartSystem();
      if (context.mounted && !provider.isDisposed) {
        SnackBarUtils.showSuccess(context, l10n.dashboardRestartSuccess);
      }
    } catch (error) {
      if (context.mounted && !provider.isDisposed) {
        SnackBarUtils.showError(
            context, l10n.dashboardRestartFailed(error.toString()));
      }
    }
  }

  void _openUpgrade(BuildContext context) {
    final server = context.read<CurrentServerController>().currentServer;
    if (server == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => SettingsProvider.forServer(server)..loadSystemSettings(),
        child: const UpgradePage(),
      ),
    ));
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
