import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/server/server_models.dart';

class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onDelete,
  });

  final ServerCardViewModel data;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.maxHeight.isFinite;

        return Card(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
            child: Padding(
              padding: AppDesignTokens.pagePadding,
              child: Column(
                mainAxisSize:
                    hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.config.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (data.isCurrent) ...[
                        const SizedBox(width: 8),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(l10n.serverCurrent),
                        ),
                      ],
                      IconButton(
                        tooltip: l10n.commonDelete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSm),
                  Text('${l10n.serverIpLabel}: ${_extractHost(data.config.url)}'),
                  const SizedBox(height: AppDesignTokens.spacingMd),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricPill(
                          label: l10n.serverCpuLabel,
                          value: _percent(data.metrics.cpuPercent)),
                      _MetricPill(
                          label: l10n.serverMemoryLabel,
                          value: _percent(data.metrics.memoryPercent)),
                      _MetricPill(
                          label: l10n.serverLoadLabel,
                          value: _decimal(data.metrics.load)),
                      _MetricPill(
                          label: l10n.serverDiskLabel,
                          value: _percent(data.metrics.diskPercent)),
                    ],
                  ),
                  if (hasBoundedHeight) const Spacer(),
                  if (!hasBoundedHeight)
                    const SizedBox(height: AppDesignTokens.spacingLg),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        _hasMetrics(data.metrics)
                            ? l10n.serverMetricsAvailable
                            : l10n.serverMetricsUnavailable,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      Text(
                        l10n.serverOpenDetail,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _extractHost(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host.isNotEmpty == true ? uri!.host : url;
  }

  String _percent(double? value) {
    if (value == null) {
      return '--';
    }
    return '${value.toStringAsFixed(1)}%';
  }

  String _decimal(double? value) {
    if (value == null) {
      return '--';
    }
    return value.toStringAsFixed(2);
  }

  bool _hasMetrics(ServerMetricsSnapshot metrics) {
    return metrics.cpuPercent != null ||
        metrics.memoryPercent != null ||
        metrics.diskPercent != null ||
        metrics.load != null;
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      ),
      child: Text('$label $value'),
    );
  }
}
