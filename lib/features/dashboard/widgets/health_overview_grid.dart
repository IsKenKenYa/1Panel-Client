import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/shared/widgets/metric_card.dart';

import '../dashboard_provider.dart';

class HealthOverviewGrid extends StatelessWidget {
  const HealthOverviewGrid({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MetricOverviewGrid(
      children: [
        MetricOverviewTile(
          label: l10n.dashboardCpuUsage,
          value: _percent(data.cpuPercent),
          percent: data.cpuPercent,
          icon: Icons.developer_board_outlined,
        ),
        MetricOverviewTile(
          label: l10n.dashboardMemoryUsage,
          value: _percent(data.memoryPercent),
          percent: data.memoryPercent,
          icon: Icons.memory_outlined,
        ),
        MetricOverviewTile(
          label: l10n.dashboardDiskUsage,
          value: _percent(data.diskPercent),
          percent: data.diskPercent,
          icon: Icons.storage_outlined,
        ),
        MetricOverviewTile(
          label: l10n.serverLoadLabel,
          value: data.load?.toStringAsFixed(2) ?? '--',
          percent: null,
          icon: Icons.speed_outlined,
        ),
      ],
    );
  }

  String _percent(double? value) =>
      value != null ? '${value.toStringAsFixed(1)}%' : '--';
}
