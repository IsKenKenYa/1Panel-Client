import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import '../../../../core/services/logger/logger_service.dart';
import '../../../../core/storage/hive_storage_service.dart';
import '../../../../data/repositories/monitor_repository.dart';
import '../models/monitor_hive_adapters.dart';

/// 监控数据本地数据源
///
/// 负责监控数据的本地持久化、压缩和清理
/// 使用通用的 [HiveStorageService] 实现
class MonitorLocalDataSource {
  static const String _boxName = 'monitor_data';
  static const String _uploadQueueBoxName = 'monitor_upload_queue';

  final HiveStorageService _storage;
  final HiveStorageService _queueStorage;
  bool _isInitialized = false;

  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  MonitorLocalDataSource()
      : _storage = HiveStorageService(boxName: _boxName, isEncrypted: true),
        _queueStorage =
            HiveStorageService(boxName: _uploadQueueBoxName, isEncrypted: true);

  Future<void> init() async {
    if (_isInitialized) return;

    // 注册适配器（需在打开Box前完成）
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MonitorDataPointAdapter());
    }

    await _storage.init();
    await _queueStorage.init();
    _isInitialized = true;

    // 启动后台任务
    _startBackgroundTasks();
  }

  void _startBackgroundTasks() {
    // 每小时执行一次清理和压缩
    Timer.periodic(const Duration(hours: 1), (_) {
      cleanAndCompressData();
    });

    // 每10分钟尝试上传一次
    Timer.periodic(const Duration(minutes: 10), (_) {
      uploadColdData();
    });
  }

  /// 生成存储键: metric_yyyyMMddHH
  String _generateKey(String metric, DateTime time) {
    final formatter = DateFormat('yyyyMMddHH');
    return '${metric}_${formatter.format(time)}';
  }

  /// 保存数据点
  Future<void> savePoints(String metric, List<MonitorDataPoint> points) async {
    if (!_isInitialized) await init();
    if (points.isEmpty) return;

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

      if (currentList.isNotEmpty) {
        final lastTime = currentList.last.time;
        final filteredNew =
            newPoints.where((p) => p.time.isAfter(lastTime)).toList();
        if (filteredNew.isNotEmpty) {
          currentList.addAll(filteredNew);
          await _storage.put(key, currentList);
        }
      } else {
        await _storage.put(key, newPoints);
      }
    }
  }

  /// 获取指定时间范围的数据
  Future<List<MonitorDataPoint>> getPoints(
      String metric, DateTime start, DateTime end) async {
    if (!_isInitialized) await init();

    final points = <MonitorDataPoint>[];

    // 计算涉及的小时key
    // 简单遍历：从start到end每小时生成一个key
    DateTime current = DateTime(start.year, start.month, start.day, start.hour);
    while (current.isBefore(end.add(const Duration(hours: 1)))) {
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
    if (!_isInitialized) await init();

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
        date = DateFormat('yyyyMMddHH').parse(parts[1]);
      } catch (e) {
        continue;
      }

      // 90天前数据删除
      if (date.isBefore(day90)) {
        keysToDelete.add(key);
        continue;
      }

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
      else if (date.isBefore(day7)) {
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

  /// 上传冷数据
  Future<void> uploadColdData() async {
    if (!_isInitialized) await init();

    // 检查网络（仅Wi-Fi）
    final connectivityResult = await _connectivity.checkConnectivity();
    if (!connectivityResult.contains(ConnectivityResult.wifi)) {
      appLogger.dWithPackage(
        'features.monitoring.local_data_source',
        'Upload skipped: Not on Wi-Fi',
      );
      return;
    }

    // 检查电量 (>30%)
    final batteryLevel = await _battery.batteryLevel;
    if (batteryLevel <= 30) {
      appLogger.dWithPackage(
        'features.monitoring.local_data_source',
        'Upload skipped: Battery low ($batteryLevel%)',
      );
      return;
    }

    // 处理重试队列
    await _processUploadQueue();

    final now = DateTime.now();
    final coldThreshold = now.subtract(const Duration(hours: 24));

    final keys = _storage.keys.cast<String>();
    final keysToUpload = <String>[];

    for (var key in keys) {
      final parts = key.split('_');
      if (parts.length != 2) continue;

      try {
        final date = DateFormat('yyyyMMddHH').parse(parts[1]);
        if (date.isBefore(coldThreshold)) {
          keysToUpload.add(key);
        }
      } catch (e) {
        continue;
      }
    }

    for (var key in keysToUpload) {
      final List? rawList = _storage.get(key);
      if (rawList == null || rawList.isEmpty) continue;

      try {
        await _mockUpload(key, rawList.cast<MonitorDataPoint>().toList());
        await _storage.delete(key);
        appLogger.iWithPackage(
          'features.monitoring.local_data_source',
          'Uploaded and deleted $key',
        );
      } catch (e) {
        appLogger.wWithPackage(
          'features.monitoring.local_data_source',
          'Failed to upload $key',
          error: e,
        );
        // 加入重试队列
        await _queueStorage.put(key, {
          'key': key,
          'data': rawList,
          'time': DateTime.now().millisecondsSinceEpoch
        });
        // 本地仍删除，避免重复占用（已移入队列）
        await _storage.delete(key);
      }
    }
  }

  Future<void> _processUploadQueue() async {
    final keys = _queueStorage.keys.cast<String>();
    for (var key in keys) {
      final Map? item = _queueStorage.get(key);
      if (item == null) continue;

      try {
        final data = (item['data'] as List).cast<MonitorDataPoint>();
        await _mockUpload(item['key'], data);
        await _queueStorage.delete(key);
      } catch (e) {
        // Keep in queue
      }
    }
  }

  /// 模拟上传数据
  Future<void> _mockUpload(String key, List<MonitorDataPoint> data) async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    // 模拟随机失败
    if (DateTime.now().second % 10 == 0) {
      throw Exception('Upload failed (simulated)');
    }
    appLogger.dWithPackage(
      'features.monitoring.local_data_source',
      'Uploaded ${data.length} points for $key',
    );
  }
}
