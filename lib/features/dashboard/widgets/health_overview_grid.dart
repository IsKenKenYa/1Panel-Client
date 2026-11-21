import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/metric_card.dart';

import '../dashboard_provider.dart';

class HealthOverviewGrid extends StatelessWidget {
  const HealthOverviewGrid({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return MetricOverviewGrid(
      cpuPercent: data.cpuPercent,
      memoryPercent: data.memoryPercent,
      diskPercent: data.diskPercent,
      load: data.load,
    );
  }
}
