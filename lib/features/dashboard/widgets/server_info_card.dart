import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_x.dart';
import '../../../data/models/common_models.dart';
import '../../../shared/widgets/app_card.dart';
import '../dashboard_provider.dart';

class ServerInfoCard extends StatelessWidget {
  final DashboardData data;

  const ServerInfoCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final systemInfo = data.systemInfo;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return AppCard(
      title: l10n.dashboardServerInfoTitle,
      subtitle: Text(
        systemInfo != null
            ? l10n.dashboardServerStatusOk
            : l10n.dashboardServerStatusConnecting,
        style: TextStyle(
          color:
              systemInfo != null ? colorScheme.primary : colorScheme.tertiary,
        ),
      ),
      trailing: Icon(
        Icons.computer,
        color: systemInfo != null ? colorScheme.primary : colorScheme.tertiary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: l10n.dashboardHostNameLabel,
            value: systemInfo?.hostname ?? '--',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: l10n.dashboardOsLabel,
            value: _formatOsInfo(systemInfo),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: l10n.dashboardUptimeLabel,
            value: _formatUptime(context, data.uptime),
          ),
          if (data.lastUpdated != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.dashboardUpdatedAt(_formatTime(data.lastUpdated!)),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatOsInfo(SystemInfo? info) {
    if (info == null) return '--';
    final os = info.os ?? '--';
    final platform = info.platform ?? '';
    final platformVersion = info.platformVersion ?? '';
    final kernelVersion = info.kernelVersion ?? '';

    // 格式: Linux Ubuntu 24.04 (kernel: 6.8.0-84-generic)
    final parts = <String>[os];
    if (platform.isNotEmpty) parts.add(platform);
    if (platformVersion.isNotEmpty) parts.add(platformVersion);

    var result = parts.join(' ');
    if (kernelVersion.isNotEmpty) {
      result += ' ($kernelVersion)';
    }
    return result;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  String _formatUptime(BuildContext context, String uptime) {
    return uptime;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
