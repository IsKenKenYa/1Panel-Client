import 'package:onepanel_client/core/config/api_config.dart';

class ServerMetricsSnapshot {
  const ServerMetricsSnapshot({
    this.cpuPercent,
    this.memoryPercent,
    this.diskPercent,
    this.load,
    this.isReachable,
    this.latencyMs,
  });

  final double? cpuPercent;
  final double? memoryPercent;
  final double? diskPercent;
  final double? load;

  /// `GET /health/check` 是否成功；null 表示本次探测尚未返回。
  final bool? isReachable;

  /// 健康探测往返耗时（毫秒）；探测失败时为 null。
  final int? latencyMs;

  bool get hasLatency => latencyMs != null;

  ServerMetricsSnapshot copyWith({
    double? cpuPercent,
    double? memoryPercent,
    double? diskPercent,
    double? load,
    bool? isReachable,
    int? latencyMs,
  }) {
    return ServerMetricsSnapshot(
      cpuPercent: cpuPercent ?? this.cpuPercent,
      memoryPercent: memoryPercent ?? this.memoryPercent,
      diskPercent: diskPercent ?? this.diskPercent,
      load: load ?? this.load,
      isReachable: isReachable ?? this.isReachable,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }
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
