/// Disk usage data for a single mount point.
class DiskData {
  final String path;
  final String type;
  final String device;
  final int total;
  final int used;
  final int free;
  final double usedPercent;

  const DiskData({
    required this.path,
    required this.type,
    required this.device,
    required this.total,
    required this.used,
    required this.free,
    required this.usedPercent,
  });

  factory DiskData.fromJson(Map<String, dynamic> json) {
    return DiskData(
      path: json['path'] as String? ?? '/',
      type: json['type'] as String? ?? '',
      device: json['device'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      used: json['used'] as int? ?? 0,
      free: json['free'] as int? ?? 0,
      usedPercent: (json['usedPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Snapshot of the latest monitoring metrics extracted from API responses.
class MonitorMetricsSnapshot {
  final double? cpuPercent;
  final double? memoryPercent;
  final double? diskPercent;
  final double? load1;
  final double? load5;
  final double? load15;
  final int? memoryUsed;
  final int? memoryTotal;
  final List<DiskData> diskData;
  final int? uptime;
  final DateTime? timestamp;

  const MonitorMetricsSnapshot({
    this.cpuPercent,
    this.memoryPercent,
    this.diskPercent,
    this.load1,
    this.load5,
    this.load15,
    this.memoryUsed,
    this.memoryTotal,
    this.diskData = const [],
    this.uptime,
    this.timestamp,
  });

  bool get hasData =>
      cpuPercent != null ||
      memoryPercent != null ||
      diskPercent != null ||
      load1 != null;

  factory MonitorMetricsSnapshot.empty() => const MonitorMetricsSnapshot();

  factory MonitorMetricsSnapshot.fromDashboard(Map<String, dynamic> data) {
    final disks = (data['diskData'] as List<dynamic>? ?? const [])
        .map((item) => DiskData.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return MonitorMetricsSnapshot(
      cpuPercent: (data['cpuUsedPercent'] as num?)?.toDouble(),
      memoryPercent: (data['memoryUsedPercent'] as num?)?.toDouble(),
      diskPercent: disks.firstOrNull?.usedPercent,
      load1: (data['load1'] as num?)?.toDouble(),
      load5: (data['load5'] as num?)?.toDouble(),
      load15: (data['load15'] as num?)?.toDouble(),
      memoryUsed: data['memoryUsed'] as int?,
      memoryTotal: data['memoryTotal'] as int?,
      diskData: disks,
      uptime: data['uptime'] as int?,
      timestamp: data['shotTime'] == null
          ? DateTime.now()
          : DateTime.parse(data['shotTime'] as String).toLocal(),
    );
  }
}

/// A single monitoring data point (timestamp + value).
class MonitorDataPoint {
  final DateTime time;
  final double value;

  const MonitorDataPoint({
    required this.time,
    required this.value,
  });
}

/// 合并新增采样，保留时间顺序并补齐历史查询覆盖的空缺。
bool mergeMonitorPoints(
  List<MonitorDataPoint> points,
  List<MonitorDataPoint> incoming,
) {
  if (incoming.isEmpty) return false;
  final size = points.length;
  var latest = points.isEmpty ? null : points.last.time.millisecondsSinceEpoch;
  Set<int>? timestamps;
  var needsSort = false;
  for (final point in incoming) {
    final time = point.time.millisecondsSinceEpoch;
    if (time == latest) continue;
    if (latest != null && time < latest) {
      timestamps ??= points.map((p) => p.time.millisecondsSinceEpoch).toSet();
      if (!timestamps.add(time)) continue;
      needsSort = true;
    } else {
      latest = time;
      timestamps?.add(time);
    }
    points.add(point);
  }
  if (needsSort) points.sort((a, b) => a.time.compareTo(b.time));
  return points.length != size;
}

/// A named time series of monitoring data points with aggregate stats.
class MonitorTimeSeries {
  final String name;
  final List<MonitorDataPoint> data;
  final double? min;
  final double? max;
  final double? avg;

  const MonitorTimeSeries({
    required this.name,
    required this.data,
    this.min,
    this.max,
    this.avg,
  });

  factory MonitorTimeSeries.empty(String name) =>
      MonitorTimeSeries(name: name, data: []);

  factory MonitorTimeSeries.fromPoints(
      String name, List<MonitorDataPoint> points,
      {int? limit}) {
    if (limit != null && limit < 2) throw RangeError.range(limit, 2, null);
    if (points.isEmpty) return MonitorTimeSeries.empty(name);
    var min = points.first.value;
    var max = min;
    var sum = 0.0;
    for (final point in points) {
      if (point.value < min) min = point.value;
      if (point.value > max) max = point.value;
      sum += point.value;
    }
    final samples = limit == null || points.length <= limit
        ? List<MonitorDataPoint>.of(points, growable: false)
        : List.generate(limit,
            (i) => points[(i * (points.length - 1) / (limit - 1)).round()],
            growable: false);
    return MonitorTimeSeries(
        name: name,
        data: samples,
        min: min,
        max: max,
        avg: sum / points.length);
  }
}

/// A complete monitoring data package: current snapshot + time series.
class MonitorDataPackage {
  final MonitorMetricsSnapshot current;
  final Map<String, MonitorTimeSeries> timeSeries;

  const MonitorDataPackage({
    required this.current,
    required this.timeSeries,
  });
}

/// Arguments for [parseMonitorDataPackage] (used with `compute`).
class MonitorDataParseArgs {
  final dynamic data;
  final DateTime timestamp;

  MonitorDataParseArgs(this.data, this.timestamp);
}

/// Top-level parse function - parses a complete monitoring data package
/// (suitable for `compute` isolate execution).
MonitorDataPackage parseMonitorDataPackage(MonitorDataParseArgs args) {
  final data = args.data;
  final now = args.timestamp;

  final current = parseMetricsResponse(data, now);

  final timeSeries = {
    'cpu': parseTimeSeriesResponse(data, 'base', 'cpu'),
    'memory': parseTimeSeriesResponse(data, 'base', 'memory'),
    'load': parseTimeSeriesResponse(data, 'base', 'cpuLoad1'),
    'io': parseTimeSeriesResponse(data, 'io', 'ioThroughput'),
    'network': parseTimeSeriesResponse(data, 'network', 'networkThroughput'),
  };

  return MonitorDataPackage(current: current, timeSeries: timeSeries);
}

/// Parses the current metrics snapshot from the API response.
MonitorMetricsSnapshot parseMetricsResponse(dynamic data, DateTime timestamp) {
  if (data == null || data is! Map) {
    return const MonitorMetricsSnapshot();
  }

  final responseData = data as Map<String, dynamic>;
  final dataList = responseData['data'] as List?;

  if (dataList == null) {
    return const MonitorMetricsSnapshot();
  }

  double? cpuPercent;
  double? memoryPercent;
  double? diskPercent;
  double? load1;
  double? load5;
  double? load15;
  int? memoryUsed;
  int? memoryTotal;
  List<DiskData> diskDataList = [];
  int? uptime;

  for (final item in dataList) {
    if (item is! Map<String, dynamic>) continue;

    final param = item['param'] as String?;
    final values = item['value'] as List?;

    if (values == null || values.isEmpty) continue;

    final lastValue = values.last;
    if (lastValue is! Map<String, dynamic>) continue;

    switch (param) {
      case 'base':
        cpuPercent = (lastValue['cpu'] as num?)?.toDouble();
        memoryPercent = (lastValue['memory'] as num?)?.toDouble();
        load1 = (lastValue['cpuLoad1'] as num?)?.toDouble();
        load5 = (lastValue['cpuLoad5'] as num?)?.toDouble();
        load15 = (lastValue['cpuLoad15'] as num?)?.toDouble();
        memoryUsed = lastValue['memoryUsed'] as int?;
        memoryTotal = lastValue['memoryTotal'] as int?;
        uptime = lastValue['uptime'] as int?;

        final diskDataRaw = lastValue['diskData'] as List?;
        if (diskDataRaw != null) {
          diskDataList = diskDataRaw
              .map((d) => DiskData.fromJson(d as Map<String, dynamic>))
              .toList();
          if (diskDataList.isNotEmpty) {
            diskPercent = diskDataList.first.usedPercent;
          }
        }
        break;
      case 'cpu':
        cpuPercent ??= (lastValue['cpu'] as num?)?.toDouble();
        break;
      case 'memory':
        memoryPercent ??= (lastValue['memory'] as num?)?.toDouble();
        break;
      case 'load':
        load1 ??= (lastValue['cpuLoad1'] as num?)?.toDouble();
        load5 ??= (lastValue['cpuLoad5'] as num?)?.toDouble();
        load15 ??= (lastValue['cpuLoad15'] as num?)?.toDouble();
        break;
      case 'io':
        diskPercent ??= (lastValue['disk'] as num?)?.toDouble();
        break;
    }
  }

  return MonitorMetricsSnapshot(
    cpuPercent: cpuPercent,
    memoryPercent: memoryPercent,
    diskPercent: diskPercent,
    load1: load1,
    load5: load5,
    load15: load15,
    memoryUsed: memoryUsed,
    memoryTotal: memoryTotal,
    diskData: diskDataList,
    uptime: uptime,
    timestamp: timestamp,
  );
}

/// Parses a time series from the API response for a given param/valueKey.
MonitorTimeSeries parseTimeSeriesResponse(
  dynamic data,
  String param,
  String valueKey,
) {
  if (data == null || data is! Map) {
    return MonitorTimeSeries.empty(param);
  }

  final responseData = data as Map<String, dynamic>;
  final dataList = responseData['data'] as List?;

  if (dataList == null || dataList.isEmpty) {
    return MonitorTimeSeries.empty(param);
  }

  Map<String, dynamic>? item;
  Map<String, dynamic>? base;
  for (final group in dataList.whereType<Map<String, dynamic>>()) {
    if (group['param'] == param) {
      item = group;
      break;
    }
    if (group['param'] == 'base') base ??= group;
  }
  item ??= base;
  if (item == null) {
    return MonitorTimeSeries.empty(param);
  }

  final itemMap = item;
  final dates = itemMap['date'] as List?;
  final values = itemMap['value'] as List?;

  if (values == null || values.isEmpty) {
    return MonitorTimeSeries.empty(param);
  }

  final dataPoints = <MonitorDataPoint>[];
  double? min;
  double? max;
  double sum = 0;
  int count = 0;
  final now = DateTime.now();

  for (var i = 0; i < values.length; i++) {
    final valueMap = values[i] as Map<String, dynamic>?;
    if (valueMap == null) continue;

    final value = _extractMetricValue(valueMap, valueKey);
    if (value == null) {
      continue;
    }

    DateTime time;
    final createdAt = valueMap['createdAt'] as String?;
    if (createdAt != null) {
      time = DateTime.tryParse(createdAt) ?? now;
    } else if (dates != null && i < dates.length) {
      time = DateTime.tryParse(dates[i].toString()) ?? now;
    } else {
      time = now;
    }

    dataPoints.add(MonitorDataPoint(time: time, value: value));

    if (min == null || value < min) min = value;
    if (max == null || value > max) max = value;
    sum += value;
    count++;
  }

  return MonitorTimeSeries(
    name: param,
    data: dataPoints,
    min: min,
    max: max,
    avg: count > 0 ? sum / count : null,
  );
}

double? _extractMetricValue(Map<String, dynamic> valueMap, String valueKey) {
  final directValue = (valueMap[valueKey] as num?)?.toDouble();
  if (directValue != null) {
    return directValue;
  }

  switch (valueKey) {
    case 'ioThroughput':
      final read = (valueMap['read'] as num?)?.toDouble();
      final write = (valueMap['write'] as num?)?.toDouble();
      if (read != null || write != null) {
        return ((read ?? 0) + (write ?? 0)) / 1024;
      }

      final fallback = (valueMap['diskRead'] as num?)?.toDouble() ??
          (valueMap['diskWrite'] as num?)?.toDouble() ??
          (valueMap['ioRead'] as num?)?.toDouble() ??
          (valueMap['ioWrite'] as num?)?.toDouble();
      return fallback != null ? fallback / 1024 : null;
    case 'networkThroughput':
      final up = (valueMap['up'] as num?)?.toDouble();
      final down = (valueMap['down'] as num?)?.toDouble();
      if (up != null || down != null) {
        return (up ?? 0) + (down ?? 0);
      }

      return (valueMap['networkIn'] as num?)?.toDouble() ??
          (valueMap['networkOut'] as num?)?.toDouble();
    case 'disk':
      return (valueMap['diskRead'] as num?)?.toDouble() ??
          (valueMap['diskWrite'] as num?)?.toDouble() ??
          (valueMap['ioRead'] as num?)?.toDouble() ??
          (valueMap['ioWrite'] as num?)?.toDouble();
    case 'networkIn':
      return (valueMap['up'] as num?)?.toDouble() ??
          (valueMap['down'] as num?)?.toDouble() ??
          (valueMap['networkOut'] as num?)?.toDouble();
    default:
      return null;
  }
}
