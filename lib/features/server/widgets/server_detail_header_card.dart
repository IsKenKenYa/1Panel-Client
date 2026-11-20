import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/server/server_models.dart';

class ServerDetailHeaderCard extends StatelessWidget {
  const ServerDetailHeaderCard({
    super.key,
    required this.server,
    required this.onRefresh,
  });

  final ServerCardViewModel server;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppDesignTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.config.name,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppDesignTokens.spacingSm),
                      Text(
                        server.config.url,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (server.isCurrent)
                  Chip(
                    label: Text(l10n.serverCurrent),
                  ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingLg),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.memory_outlined,
                  label: l10n.serverCpuLabel,
                  value: _formatPercent(server.metrics.cpuPercent),
                ),
                _MetricChip(
                  icon: Icons.storage_outlined,
                  label: l10n.serverMemoryLabel,
                  value: _formatPercent(server.metrics.memoryPercent),
                ),
                _MetricChip(
                  icon: Icons.speed_outlined,
                  label: l10n.serverLoadLabel,
                  value: _formatDecimal(server.metrics.load),
                ),
                _MetricChip(
                  icon: Icons.sd_card_outlined,
                  label: l10n.serverDiskLabel,
                  value: _formatPercent(server.metrics.diskPercent),
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_outlined),
                label: Text(l10n.serverActionRefresh),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPercent(double? value) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(1)}%';
  }

  String _formatDecimal(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(2);
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Chip 的 avatar 槽会额外插入左右不对称的间距；自绘容器保证
    // 图标与文字两侧内边距一致。
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.spacingMd,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppDesignTokens.spacingSm),
          Text(
            '$label: $value',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
