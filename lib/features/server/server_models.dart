import 'package:onepanel_client/core/config/api_config.dart';

class ServerMetricsSnapshot {
  const ServerMetricsSnapshot({
    this.cpuPercent,
    this.memoryPercent,
    this.diskPercent,
    this.load,
  });

  final double? cpuPercent;
  final double? memoryPercent;
  final double? diskPercent;
  final double? load;
}

class ServerCardViewModel {
  const ServerCardViewModel({
    required this.config,
    required this.isCurrent,
    required this.metrics,
  });

  final ApiConfig config;
  final bool isCurrent;
  final ServerMetricsSnapshot metrics;
}
