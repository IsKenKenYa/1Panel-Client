import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import '../../../core/i18n/l10n_x.dart';
import '../../../shared/widgets/app_card.dart';
import '../dashboard_provider.dart';

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
            onTap: () => _showUpdateDialog(context),
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

  void _showRestartDialog(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dashboardRestartTitle),
        content: Text(l10n.dashboardRestartDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<DashboardProvider>().restartSystem();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.dashboardRestartSuccess)),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.dashboardRestartFailed(e.toString())),
                    backgroundColor: colorScheme.error,
                  ),
                );
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dashboardUpdateTitle),
        content: Text(l10n.dashboardUpdateDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<DashboardProvider>().upgradeSystem();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.dashboardUpdateSuccess)),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.dashboardUpdateFailed(e.toString()))),
                );
              }
            },
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
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
