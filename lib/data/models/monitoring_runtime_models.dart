class MonitorGpuInfo {
  final String? name;
  final double? utilization;
  final double? memory;
  final double? temperature;

  const MonitorGpuInfo({
    this.name,
    this.utilization,
    this.memory,
    this.temperature,
  });

  @override
  bool operator ==(Object other) =>
      other is MonitorGpuInfo &&
      other.name == name &&
      other.utilization == utilization &&
      other.memory == memory &&
      other.temperature == temperature;

  @override
  int get hashCode => Object.hash(name, utilization, memory, temperature);

  factory MonitorGpuInfo.fromJson(Map<String, dynamic> json) {
    return MonitorGpuInfo(
      name: json['name'] as String?,
      utilization: (json['utilization'] as num?)?.toDouble(),
      memory: (json['memory'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
    );
  }

  /// 从 /ai/gpu/search 的 MonitorGPUData 时间序列 Map 还原当前 GPU 状态。
  ///
  /// V2 契约（上游 ai.ts MonitorGPUData）：data 为 Map，gpuValue /
  /// memoryPercent / temperatureValue 等字段均为采样点数组，而非 GPU 列表。
  /// 这里取各序列最后一个数值型采样点作为当前值；兼容 data 为空或字段
  /// 缺失：序列全空时返回空列表。
  static List<MonitorGpuInfo> listFromGpuSearchData(Map<String, dynamic> data) {
    final utilization = _lastSample(data['gpuValue']);
    final memory = _lastSample(data['memoryPercent']);
    final temperature = _lastSample(data['temperatureValue']);
    if (utilization == null && memory == null && temperature == null) {
      return const [];
    }
    return [
      MonitorGpuInfo(
        utilization: utilization,
        memory: memory,
        temperature: temperature,
      ),
    ];
  }

  static double? _lastSample(dynamic raw) {
    if (raw is List) {
      for (final value in raw.reversed) {
        if (value is num) return value.toDouble();
      }
    }
    return null;
  }
}

class MonitorSetting {
  final int? interval;
  final int? retention;
  final bool? enabled;
  final String? defaultNetwork;
  final String? defaultIO;

  const MonitorSetting({
    this.interval,
    this.retention,
    this.enabled,
    this.defaultNetwork,
    this.defaultIO,
  });

  factory MonitorSetting.fromJson(Map<String, dynamic> json) {
    final intervalRaw = json['monitorInterval'] ?? json['MonitorInterval'];
    final retentionRaw = json['monitorStoreDays'] ?? json['MonitorStoreDays'];
    final statusRaw = json['monitorStatus'] ?? json['MonitorStatus'];
    final defaultNetworkRaw = json['defaultNetwork'] ?? json['DefaultNetwork'];
    final defaultIORaw = json['defaultIO'] ?? json['DefaultIO'];

    bool? enabled;
    if (statusRaw is bool) {
      enabled = statusRaw;
    } else if (statusRaw != null) {
      final normalized = statusRaw.toString().toLowerCase();
      if (normalized == 'enable' ||
          normalized == 'enabled' ||
          normalized == 'true' ||
          normalized == '1') {
        enabled = true;
      } else if (normalized == 'disable' ||
          normalized == 'disabled' ||
          normalized == 'false' ||
          normalized == '0') {
        enabled = false;
      }
    }

    return MonitorSetting(
      interval: int.tryParse(intervalRaw?.toString() ?? ''),
      retention: int.tryParse(retentionRaw?.toString() ?? ''),
      enabled: enabled,
      defaultNetwork: defaultNetworkRaw?.toString(),
      defaultIO: defaultIORaw?.toString(),
    );
  }
}
