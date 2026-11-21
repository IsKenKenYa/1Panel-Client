import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../data/models/monitor_models.dart';
import '../models/monitor_hive_adapters.dart';

/// 监控数据本地数据源
///
/// 负责监控数据的本地持久化、压缩和清理
/// 使用通用的 [HiveStorageService] 实现
class MonitorLocalDataSource {
  final HiveStorageService _storage;
  final _hourFormat = DateFormat('yyyyMMddHH');
  Future<void>? _opening;
  Future<void>? _maintenance;

  MonitorLocalDataSource({ApiConfig? server})
      : _storage = HiveStorageService(
          boxName: server == null ? 'monitor_data' : boxNameFor(server),
          isEncrypted: true,
        );

  static String boxNameFor(ApiConfig server) {
    final identity = jsonEncode([server.id, server.panelType, server.url]);
    return 'monitor_data_${sha256.convert(utf8.encode(identity))}';
  }

  Future<void> init() => _opening ??= _open();

  Future<void> _open() async {
    // 注册适配器（需在打开Box前完成）
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MonitorDataPointAdapter());
    }

    try {
      await _storage.init();
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  /// 生成存储键: metric_yyyyMMddHH
  String _generateKey(String metric, DateTime time) {
    return '${metric}_${_hourFormat.format(time.toUtc())}';
  }

  /// 保存数据点
  Future<void> savePoints(String metric, List<MonitorDataPoint> points) async {
    await init();
    if (points.isEmpty) return;
    final lastCleanup = _storage.get<int>('lastCleanupMs') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - lastCleanup >=
        const Duration(hours: 1).inMilliseconds) {
      await (_maintenance ??= cleanAndCompressData().whenComplete(() {
        _maintenance = null;
      }));
    }

    // 按小时分组
    final Map<String, List<MonitorDataPoint>> grouped = {};
    for (var point in points) {
      final key = _generateKey(metric, point.time);
      grouped.putIfAbsent(key, () => []).add(point);
    }

    // 批量保存
    for (var entry in grouped.entries) {
      final key = entry.key;
      final newPoints = entry.value;

      final List existing = _storage.get(key, defaultValue: []) ?? [];
      final List<MonitorDataPoint> currentList =
          existing.cast<MonitorDataPoint>().toList();

      if (mergeMonitorPoints(currentList, newPoints)) await _storage.put(key, currentList);
    }
  }

  /// 获取指定时间范围的数据
  Future<List<MonitorDataPoint>> getPoints(
      String metric, DateTime start, DateTime end) async {
    await init();

    final points = <MonitorDataPoint>[];

    final utc = start.toUtc();
    var current = DateTime.utc(utc.year, utc.month, utc.day, utc.hour);
    while (!current.isAfter(end)) {
      final key = _generateKey(metric, current);
      final List? rawList = _storage.get(key);

      if (rawList != null && rawList.isNotEmpty) {
        final list = rawList.cast<MonitorDataPoint>();
        // 过滤时间范围
        points.addAll(list.where((p) =>
            p.time.isAfter(start.subtract(const Duration(seconds: 1))) &&
            p.time.isBefore(end.add(const Duration(seconds: 1)))));
      }

      current = current.add(const Duration(hours: 1));
    }

    // 排序
    points.sort((a, b) => a.time.compareTo(b.time));
    return points;
  }

  /// 数据清理与压缩
  Future<void> cleanAndCompressData() async {
    await init();

    final now = DateTime.now();
    final day7 = now.subtract(const Duration(days: 7));
    final day30 = now.subtract(const Duration(days: 30));
    final day90 = now.subtract(const Duration(days: 90));

    final keys = _storage.keys.cast<String>();
    final keysToDelete = <String>[];

    for (var key in keys) {
      final parts = key.split('_');
      if (parts.length != 2) continue;

      DateTime date;
      try {
        date = _hourFormat.parseUtc(parts[1]);
      } catch (e) {
        continue;
      }

      // Tiered retention: delete >90d, downsample 30-90d to hourly averages,
      // downsample 7-30d to 5-minute averages. Keeps local storage bounded.
      if (date.isBefore(day90)) {
        keysToDelete.add(key);
        continue;
      }
      if (!date.isBefore(day7)) continue;

      final List? rawList = _storage.get(key);
      if (rawList == null || rawList.isEmpty) continue;

      final list = rawList.cast<MonitorDataPoint>().toList();
      List<MonitorDataPoint> compressedList = list;
      bool changed = false;

      // 30-90天：1小时粒度（保留均值）
      if (date.isBefore(day30)) {
        if (list.length > 1) {
          final avg =
              list.map((e) => e.value).reduce((a, b) => a + b) / list.length;
          compressedList = [
            MonitorDataPoint(time: list.first.time, value: avg)
          ];
          changed = true;
        }
      }
      // 7-30天：5分钟粒度
      else {
        if (list.length > 12) {
          // 1小时有12个5分钟
          compressedList = _downsample(list, const Duration(minutes: 5));
          changed = true;
        }
      }

      if (changed) {
        await _storage.put(key, compressedList);
        appLogger.dWithPackage(
          'features.monitoring.local_data_source',
          'Compressed $key: ${list.length} -> ${compressedList.length}',
        );
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _storage.deleteAll(keysToDelete);
      appLogger.iWithPackage(
        'features.monitoring.local_data_source',
        'Deleted ${keysToDelete.length} old keys',
      );
    }
    await _storage.put('lastCleanupMs', now.millisecondsSinceEpoch);
  }

  /// 降采样
  List<MonitorDataPoint> _downsample(
      List<MonitorDataPoint> data, Duration interval) {
    if (data.isEmpty) return [];

    final result = <MonitorDataPoint>[];
    var currentBatch = <double>[];
    var batchStartTime = data.first.time;

    for (var point in data) {
      if (point.time.difference(batchStartTime) >= interval) {
        if (currentBatch.isNotEmpty) {
          final avg =
              currentBatch.reduce((a, b) => a + b) / currentBatch.length;
          result.add(MonitorDataPoint(time: batchStartTime, value: avg));
        }
        batchStartTime = point.time;
        currentBatch = [point.value];
      } else {
        currentBatch.add(point.value);
      }
    }

    if (currentBatch.isNotEmpty) {
      final avg = currentBatch.reduce((a, b) => a + b) / currentBatch.length;
      result.add(MonitorDataPoint(time: batchStartTime, value: avg));
    }

    return result;
  }

}
