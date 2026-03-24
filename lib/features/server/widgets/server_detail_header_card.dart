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
                  label: l10n.serverCpuLabel,
                  value: _formatPercent(server.metrics.cpuPercent),
                ),
                _MetricChip(
                  label: l10n.serverMemoryLabel,
                  value: _formatPercent(server.metrics.memoryPercent),
                ),
                _MetricChip(
                  label: l10n.serverLoadLabel,
                  value: _formatDecimal(server.metrics.load),
                ),
                _MetricChip(
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
                icon: const Icon(Icons.refresh),
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
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}
