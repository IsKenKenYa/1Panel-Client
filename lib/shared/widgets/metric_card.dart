import 'package:flutter/material.dart';

import '../../core/i18n/l10n_x.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../data/models/monitoring_models.dart';
import 'app_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.metrics,
    required this.currentLabel,
    required this.minLabel,
    required this.avgLabel,
    required this.maxLabel,
  });

  final String title;
  final SystemMetrics? metrics;
  final String currentLabel;
  final String minLabel;
  final String avgLabel;
  final String maxLabel;

  @override
  Widget build(BuildContext context) {
    final unit = metrics?.unit;
    final current = _formatMetricValue(metrics?.current, unit);
    final minValue = _formatMetricValue(metrics?.min, unit);
    final avgValue = _formatMetricValue(metrics?.avg, unit);
    final maxValue = _formatMetricValue(metrics?.max, unit);
    final values =
        metrics?.dataPoints
            ?.map((point) => point.value)
            .whereType<double>()
            .toList() ??
        const [];
    return AppCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(current, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppDesignTokens.spacingSm),
          if (values.length > 1) ...[
            SizedBox(
              height: 64,
              child: CustomPaint(
                painter: MetricSparklinePainter(
                  values: values,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppDesignTokens.spacingSm),
          ],
          Wrap(
            spacing: AppDesignTokens.spacingSm,
            runSpacing: AppDesignTokens.spacingSm,
            children: [
              MetricStatChip(label: currentLabel, value: current),
              MetricStatChip(label: minLabel, value: minValue),
              MetricStatChip(label: avgLabel, value: avgValue),
              MetricStatChip(label: maxLabel, value: maxValue),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMetricValue(double? value, String? unit) {
    if (value == null) {
      return '--';
    }
    final fixed = value.toStringAsFixed(2);
    if (unit == null || unit.isEmpty) {
      return fixed;
    }
    return '$fixed $unit';
  }
}

class MetricStatChip extends StatelessWidget {
  const MetricStatChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class MetricOverviewGrid extends StatelessWidget {
  const MetricOverviewGrid({
    super.key,
    required this.cpuPercent,
    required this.memoryPercent,
    required this.diskPercent,
    required this.load,
  });

  final double? cpuPercent;
  final double? memoryPercent;
  final double? diskPercent;
  final double? load;

  @override
  Widget build(BuildContext context) {
    const gap = AppDesignTokens.spacingSm;
    final l10n = context.l10n;
    final tiles = [
      for (final (label, percent, icon) in [
        (l10n.dashboardCpuUsage, cpuPercent, Icons.developer_board_outlined),
        (l10n.dashboardMemoryUsage, memoryPercent, Icons.memory_outlined),
        (l10n.dashboardDiskUsage, diskPercent, Icons.storage_outlined),
      ])
        MetricOverviewTile(
          label: label,
          percent: percent,
          icon: icon,
          value: percent == null ? '--' : '${percent.toStringAsFixed(1)}%',
        ),
      MetricOverviewTile(
        label: l10n.serverLoadLabel,
        percent: null,
        icon: Icons.speed_outlined,
        value: load?.toStringAsFixed(2) ?? '--',
      ),
    ];
    final textScaler = MediaQuery.textScalerOf(context);
    final minTileWidth = 130 * textScaler.scale(12) / 12;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileWidth = width >= minTileWidth * 2 + gap
            ? (width - gap) / 2
            : width;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}

class MetricOverviewTile extends StatelessWidget {
  const MetricOverviewTile({
    super.key,
    required this.label,
    required this.value,
    required this.percent,
    required this.icon,
  });

  final String label;
  final String value;
  final double? percent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final statusColor = _statusColor(scheme);
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppDesignTokens.spacingMd),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppDesignTokens.spacingXs),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppDesignTokens.spacingXs),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingXs),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (percent != null) ...[
              const SizedBox(height: AppDesignTokens.spacingXs),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
                  child: LinearProgressIndicator(
                    value: percent! / 100,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: statusColor,
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme scheme) {
    final usage = percent;
    if (usage == null) return scheme.onSurfaceVariant.withValues(alpha: 0.4);
    if (usage >= 90) return scheme.error;
    if (usage >= 70) return AppDesignTokens.warning;
    return scheme.primary;
  }
}

class MetricSparklinePainter extends CustomPainter {
  MetricSparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final span = maxValue - minValue == 0 ? 1 : maxValue - minValue;
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final dx = size.width * i / (values.length - 1);
      final normalized = (values[i] - minValue) / span;
      final dy = size.height - normalized * size.height;
      points.add(Offset(dx, dy));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MetricSparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
