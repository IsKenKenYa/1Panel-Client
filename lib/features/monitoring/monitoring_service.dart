import '../../core/services/base_component.dart';
import '../../core/services/logger/logger_service.dart';
import '../../data/repositories/monitor_repository.dart';
import '../../data/models/monitoring_runtime_models.dart';

/// 监控服务
///
/// 提供监控数据获取和处理功能
/// 使用统一的 MonitorRepository 获取数据
class MonitoringService extends BaseComponent {
  MonitoringService({
    super.clientManager,
    super.permissionResolver,
  });

  final MonitorRepository _monitorRepo = const MonitorRepository();

  /// 获取当前监控指标
  ///
  /// 返回最新的CPU、内存、磁盘、负载数据
  Future<MonitorMetricsSnapshot> getCurrentMetrics() async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();

      // 优先使用dashboard API获取当前指标，因为它更可靠
      try {
        final response = await client.get(
          '/api/v2/dashboard/current/default/default',
        );

        if (response.data != null && response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          final payload = data['data'] as Map<String, dynamic>?;

          if (payload != null) {
            // 解析磁盘数据
            double? diskPercent;
            final diskDataList = payload['diskData'] as List?;
            if (diskDataList != null && diskDataList.isNotEmpty) {
              final firstDisk = diskDataList.first as Map<String, dynamic>?;
              diskPercent = (firstDisk?['usedPercent'] as num?)?.toDouble();
            }

            return MonitorMetricsSnapshot(
              cpuPercent: (payload['cpuUsedPercent'] as num?)?.toDouble(),
              memoryPercent: (payload['memoryUsedPercent'] as num?)?.toDouble(),
              diskPercent: diskPercent,
              load1: (payload['load1'] as num?)?.toDouble(),
              load5: (payload['load5'] as num?)?.toDouble(),
              load15: (payload['load15'] as num?)?.toDouble(),
              memoryUsed: payload['memoryUsed'] as int?,
              memoryTotal: payload['memoryTotal'] as int?,
              uptime: payload['uptime'] as int?,
              timestamp: DateTime.now(),
            );
          }
        }
      } catch (e) {
        // 如果dashboard API失败，降级使用monitor API
        appLogger.wWithPackage(
          'monitoring.service',
          'Dashboard API failed, fallback to monitor API',
          error: e,
        );
      }

      // 降级方案：使用monitor API
      return _monitorRepo.getCurrentMetrics(client);
    });
  }

  /// 获取CPU时间序列数据
  Future<MonitorTimeSeries> getCPUTimeSeries({
    Duration duration = const Duration(hours: 1),
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      // API返回的是base数据，包含cpu字段
      return _monitorRepo.getTimeSeries(client, 'base', 'cpu',
          duration: duration);
    });
  }

  /// 获取内存时间序列数据
  Future<MonitorTimeSeries> getMemoryTimeSeries({
    Duration duration = const Duration(hours: 1),
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      // API返回的是base数据，包含memory字段
      return _monitorRepo.getTimeSeries(client, 'base', 'memory',
          duration: duration);
    });
  }

  /// 获取负载时间序列数据
  Future<MonitorTimeSeries> getLoadTimeSeries({
    Duration duration = const Duration(hours: 1),
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      // API返回的是base数据，包含cpuLoad1字段
      return _monitorRepo.getTimeSeries(client, 'base', 'cpuLoad1',
          duration: duration);
    });
  }

  /// 获取IO时间序列数据
  Future<MonitorTimeSeries> getIOTimeSeries({
    String? io,
    Duration duration = const Duration(hours: 1),
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getTimeSeries(
        client,
        'io',
        'ioThroughput',
        io: io,
        duration: duration,
      );
    });
  }

  /// 获取网络时间序列数据
  Future<MonitorTimeSeries> getNetworkTimeSeries({
    String? network,
    Duration duration = const Duration(hours: 1),
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getTimeSeries(
        client,
        'network',
        'networkThroughput',
        network: network,
        duration: duration,
      );
    });
  }

  /// 获取监控设置
  Future<MonitorSetting?> getSetting() async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getSetting(client);
    });
  }

  /// 更新监控设置
  Future<bool> updateSetting({
    int? interval,
    int? retention,
    bool? enabled,
    String? defaultIO,
    String? defaultNetwork,
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.updateSetting(
        client,
        interval: interval,
        retention: retention,
        enabled: enabled,
        defaultIO: defaultIO,
        defaultNetwork: defaultNetwork,
      );
    });
  }

  /// 清理监控数据
  Future<bool> cleanData() async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.cleanData(client);
    });
  }

  /// 获取GPU监控数据
  Future<List<MonitorGpuInfo>> getGPUInfo() async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getGPUInfo(client);
    });
  }

  /// 批量获取监控数据（含当前指标与趋势图）
  Future<MonitorDataPackage> getMonitorData({
    String? io,
    String? network,
    Duration duration = const Duration(hours: 1),
    DateTime? startTime,
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();

      // 获取时间序列数据
      final package = await _monitorRepo.getMonitorData(
        client,
        io: io,
        network: network,
        duration: duration,
        startTime: startTime,
      );

      // 优先使用dashboard API获取当前指标
      MonitorMetricsSnapshot? currentMetrics;
      try {
        final response = await client.get(
          '/api/v2/dashboard/current/default/default',
        );

        if (response.data != null && response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          final payload = data['data'] as Map<String, dynamic>?;

          if (payload != null) {
            // 解析磁盘数据
            double? diskPercent;
            final diskDataList = payload['diskData'] as List?;
            if (diskDataList != null && diskDataList.isNotEmpty) {
              final firstDisk = diskDataList.first as Map<String, dynamic>?;
              diskPercent = (firstDisk?['usedPercent'] as num?)?.toDouble();
            }

            currentMetrics = MonitorMetricsSnapshot(
              cpuPercent: (payload['cpuUsedPercent'] as num?)?.toDouble(),
              memoryPercent: (payload['memoryUsedPercent'] as num?)?.toDouble(),
              diskPercent: diskPercent,
              load1: (payload['load1'] as num?)?.toDouble(),
              load5: (payload['load5'] as num?)?.toDouble(),
              load15: (payload['load15'] as num?)?.toDouble(),
              memoryUsed: payload['memoryUsed'] as int?,
              memoryTotal: payload['memoryTotal'] as int?,
              uptime: payload['uptime'] as int?,
              timestamp: DateTime.now(),
            );
          }
        }
      } catch (e) {
        // 如果dashboard API失败，使用monitor API的结果
        appLogger.wWithPackage(
          'monitoring.service',
          'Dashboard API failed in getMonitorData, using monitor API result',
          error: e,
        );
      }

      // 如果dashboard API成功，使用它的结果；否则使用monitor API的结果
      return MonitorDataPackage(
        current: currentMetrics ?? package.current,
        timeSeries: package.timeSeries,
      );
    });
  }

  /// 获取网络接口列表
  Future<List<String>> getNetworkOptions() async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getNetworkOptions(client);
    });
  }

  /// 获取IO设备列表
  Future<List<String>> getIOOptions() async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getIOOptions(client);
    });
  }
}
