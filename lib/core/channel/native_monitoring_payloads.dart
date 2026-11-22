import '../../data/models/monitor_models.dart';
import '../../data/models/monitoring_runtime_models.dart';

/// 监控中心通道返回结构。
///
/// 时序数据裁剪成时间戳与数值点，设置字段统一为界面可直接消费的形状。

Map<String, Object?> monitoringHistoryPayload(MonitorDataPackage package) {
  return <String, Object?>{
    'cpu': _series(package.timeSeries['cpu']),
    'memory': _series(package.timeSeries['memory']),
    'load': _series(package.timeSeries['load']),
    'io': _series(package.timeSeries['io']),
    'network': _series(package.timeSeries['network']),
  };
}

Map<String, Object?> monitoringSeriesPayload(MonitorTimeSeries? series) {
  return _series(series);
}

Map<String, Object?> _series(MonitorTimeSeries? series) {
  if (series == null) {
    return <String, Object?>{'points': const <Object?>[], 'count': 0};
  }
  return <String, Object?>{
    'name': series.name,
    'min': series.min,
    'max': series.max,
    'avg': series.avg,
    'count': series.data.length,
    'points': series.data
        .map((point) => <String, Object?>{
              'time': point.time.millisecondsSinceEpoch,
              'value': point.value,
            })
        .toList(growable: false),
  };
}

Map<String, Object?> monitoringSettingsPayload(MonitorSetting? setting) {
  return <String, Object?>{
    'enabled': setting?.enabled ?? false,
    'interval': setting?.interval ?? 0,
    'retention': setting?.retention ?? 0,
    'defaultNetwork': setting?.defaultNetwork ?? '',
    'defaultIO': setting?.defaultIO ?? '',
  };
}

Map<String, Object?> monitoringOptionsPayload({
  required List<String> networks,
  required List<String> ios,
}) {
  return <String, Object?>{
    'networks': networks,
    'ios': ios,
  };
}