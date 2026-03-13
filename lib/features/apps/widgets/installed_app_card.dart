import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onepanelapp_app/config/app_router.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import '../../../data/models/app_models.dart';
import '../../../shared/widgets/app_card.dart';
import 'app_icon.dart';

/// 已安装应用卡片
class InstalledAppCard extends StatelessWidget {
  final AppInstallInfo app;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onUninstall;

  const InstalledAppCard({
    super.key,
    required this.app,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isRunning = app.status?.toLowerCase() == 'running';
    final statusColor = isRunning ? colorScheme.tertiary : colorScheme.secondary;
    final unknownLabel = l10n.systemSettingsUnknown;

    final List<String> ports = [];
    if (app.httpPort != null && app.httpPort != 0) {
      ports.add('${app.httpPort} (${l10n.commonHttp})');
    }
    if (app.httpsPort != null && app.httpsPort != 0) {
      ports.add('${app.httpsPort} (${l10n.commonHttps})');
    }
    final portsString = ports.join(', ');

    return AppCard(
      leading: AppIcon(
        appId: app.appId,
        appKey: app.appKey,
        iconUrl: app.icon,
        size: 56,
      ),
      title: app.appName ?? app.name ?? unknownLabel,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (app.name != null && app.name != app.appName)
            Text(
              app.name!,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _InfoTag(
                label: app.version ?? unknownLabel,
                icon: Icons.info_outline,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ],
      ),
      trailing: _StatusChip(
        status: isRunning ? l10n.appStatusRunning : l10n.appStatusStopped,
        color: statusColor,
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.installedAppDetail,
          arguments: app,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          if (app.container != null && app.container!.isNotEmpty) ...[
            _InfoRow(
              label: l10n.appInstallContainerName,
              value: app.container!,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 8),
          ],
          if (portsString.isNotEmpty) ...[
            _InfoRow(
              label: l10n.appInstallPorts,
              value: portsString,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
          ],
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (app.webUI != null && app.webUI!.isNotEmpty) ...[
                _ActionButton(
                  icon: Icons.web,
                  label: l10n.appActionWeb,
                  color: colorScheme.secondary,
                  onTap: () => _openWeb(context, app.webUI!),
                ),
                const SizedBox(width: 8),
              ],
              if (isRunning) ...[
                _ActionButton(
                  icon: Icons.stop,
                  label: l10n.appActionStop,
                  color: colorScheme.error,
                  onTap: onStop,
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.restart_alt,
                  label: l10n.appActionRestart,
                  color: colorScheme.primary,
                  onTap: onRestart,
                ),
              ] else ...[
                _ActionButton(
                  icon: Icons.play_arrow,
                  label: l10n.appActionStart,
                  color: colorScheme.tertiary,
                  onTap: onStart,
                ),
              ],
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.delete_outline,
                label: l10n.appActionUninstall,
                color: colorScheme.error,
                onTap: onUninstall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openWeb(BuildContext context, String urlString) async {
    final l10n = context.l10n;
    final Uri? url = Uri.tryParse(urlString);
    if (url != null) {
      try {
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.appOperateFailed(l10n.commonUnknownError))),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.appOperateFailed(e.toString()))),
          );
        }
      }
    }
  }
}

class _InfoTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;

  const _InfoTag({
    required this.label,
    required this.icon,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          // const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 状态标签
class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusChip({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
