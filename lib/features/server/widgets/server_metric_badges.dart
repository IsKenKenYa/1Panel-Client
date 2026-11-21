import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/server/server_models.dart';

/// 服务器列表的紧凑指标。
class ServerMetricBadges extends StatelessWidget {
  const ServerMetricBadges({super.key, required this.metrics});

  final ServerMetricsSnapshot metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String percent(double? value) =>
        value == null ? '--' : '${value.toStringAsFixed(1)}%';
    final entries = [
      (l10n.serverCpuLabel, percent(metrics.cpuPercent)),
      (l10n.serverMemoryLabel, percent(metrics.memoryPercent)),
      (l10n.serverLoadLabel, metrics.load?.toStringAsFixed(2) ?? '--'),
      (l10n.serverDiskLabel, percent(metrics.diskPercent)),
    ];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (label, value) in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
              color: scheme.surfaceContainerHighest,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '$label $value',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }
}

class ServerConnectionStatus extends StatelessWidget {
  const ServerConnectionStatus({super.key, required this.metrics});

  final ServerMetricsSnapshot metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hasMetrics =
        metrics.cpuPercent != null ||
        metrics.memoryPercent != null ||
        metrics.diskPercent != null ||
        metrics.load != null;
    final label = switch ((metrics.isReachable, metrics.latencyMs)) {
      (false, _) => l10n.serverUnreachable,
      (true, final int latency) => l10n.serverLatencyLabel(latency),
      _ =>
        hasMetrics
            ? l10n.serverMetricsAvailable
            : l10n.serverMetricsUnavailable,
    };
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: metrics.isReachable == false
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
