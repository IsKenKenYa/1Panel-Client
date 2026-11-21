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

  /// 面板是否可达，null 表示尚无探测结果。
  final bool? isReachable;

  /// 健康探测往返耗时（毫秒）；探测失败时为 null。
  final int? latencyMs;

  bool get hasLatency => latencyMs != null;

  @override
  bool operator ==(Object other) =>
      other is ServerMetricsSnapshot &&
      cpuPercent == other.cpuPercent &&
      memoryPercent == other.memoryPercent &&
      diskPercent == other.diskPercent &&
      load == other.load &&
      isReachable == other.isReachable &&
      latencyMs == other.latencyMs;

  @override
  int get hashCode => Object.hash(
      cpuPercent, memoryPercent, diskPercent, load, isReachable, latencyMs);

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
