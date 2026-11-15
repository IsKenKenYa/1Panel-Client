import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
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
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppDesignTokens.spacingMd),
              child: Column(
                mainAxisSize:
                    hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 服务器标识容器：M3 avatar 惯例，与文件列表图标体系一致。
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppDesignTokens.radiusSm),
                          color: data.isCurrent
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.dns_outlined,
                          color: data.isCurrent
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDesignTokens.spacingMd),
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
                          visualDensity:
                              AdaptiveLayoutSpec.of(context).adaptiveDensity,
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
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 52), // 40 容器 + 12 间距对齐
                    child: Text(
                      '${l10n.serverIpLabel}: ${_extractHost(data.config.url)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.spacingSm),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
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
                    const SizedBox(height: AppDesignTokens.spacingMd),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        _hasMetrics(data.metrics)
                            ? l10n.serverMetricsAvailable
                            : l10n.serverMetricsUnavailable,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        l10n.serverOpenDetail,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
