import 'package:flutter/material.dart';
import '../../../core/i18n/l10n_x.dart';
import '../../../shared/widgets/app_card.dart';
import '../dashboard_provider.dart';

class ResourceCard extends StatelessWidget {
  final DashboardData data;

  const ResourceCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      title: l10n.dashboardResourceTitle,
      child: Column(
        children: [
          _ResourceItem(
            title: l10n.dashboardCpuUsage,
            value: data.cpuPercent != null
                ? '${data.cpuPercent!.toStringAsFixed(1)}%'
                : '--',
            percent: data.cpuPercent,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _ResourceItem(
            title: l10n.dashboardMemoryUsage,
            value: data.memoryPercent != null
                ? '${data.memoryPercent!.toStringAsFixed(1)}%'
                : '--',
            subtitle: data.memoryUsage,
            percent: data.memoryPercent,
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 12),
          _ResourceItem(
            title: l10n.dashboardDiskUsage,
            value: data.diskPercent != null
                ? '${data.diskPercent!.toStringAsFixed(1)}%'
                : '--',
            subtitle: data.diskUsage,
            percent: data.diskPercent,
            color: colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _ResourceItem extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double? percent;
  final Color color;

  const _ResourceItem({
    required this.title,
    required this.value,
    this.subtitle,
    this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(context, percent),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (percent != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent! / 100,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getStatusColor(context, percent)),
              minHeight: 8,
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(BuildContext context, double? percent) {
    if (percent == null) return color;
    final colorScheme = Theme.of(context).colorScheme;
    if (percent >= 90) return colorScheme.error;
    if (percent >= 70) return colorScheme.tertiary;
    return color;
  }
}
