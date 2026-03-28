import '../../core/services/base_component.dart';
import '../../data/repositories/monitor_repository.dart';
import '../../api/v2/monitor_v2.dart';

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
    Duration duration = const Duration(hours: 1),
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getTimeSeries(client, 'io', 'disk',
          duration: duration);
    });
  }

  /// 获取网络时间序列数据
  Future<MonitorTimeSeries> getNetworkTimeSeries({
    Duration duration = const Duration(hours: 1),
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getTimeSeries(client, 'network', 'networkIn',
          duration: duration);
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
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.updateSetting(
        client,
        interval: interval,
        retention: retention,
        enabled: enabled,
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
  Future<List<GPUInfo>> getGPUInfo() async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getGPUInfo(client);
    });
  }

  /// 批量获取监控数据（含当前指标与趋势图）
  Future<MonitorDataPackage> getMonitorData({
    Duration duration = const Duration(hours: 1),
    DateTime? startTime,
  }) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _monitorRepo.getMonitorData(client,
          duration: duration, startTime: startTime);
    });
  }
}
