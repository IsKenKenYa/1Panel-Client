import 'dart:async';

import 'package:dio/dio.dart';

import '../../api/v2/dashboard_v2.dart';
import '../../core/services/base_component.dart';
import '../../core/config/api_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/network_exceptions.dart';
import '../../data/repositories/monitor_repository.dart';
import '../../data/models/monitoring_runtime_models.dart';
import '../../data/models/monitor_models.dart';

/// 监控服务
///
/// 提供监控数据获取和处理功能
/// 使用统一的 MonitorRepository 获取数据
class MonitoringService extends BaseComponent {
  MonitoringService({
    super.clientManager,
    super.permissionResolver,
  })  : _server = null,
        _requireSettings = false;

  MonitoringService.forServer(ApiConfig server, {bool requireSettings = false})
      : _server = server,
        _requireSettings = requireSettings;

  final ApiConfig? _server;
  final bool _requireSettings;
  Future<DioClient>? _monitorClient;
  Future<DioClient> _getClient() {
    final server = _server;
    if (server == null) return clientManager.getCurrentClient();
    if (_requireSettings) return clientManager.getClientForServer(server);
    return _monitorClient ??= clientManager.getClientForServer(server).onError(
      (Object error, StackTrace trace) {
        _monitorClient = null;
        Error.throwWithStackTrace(error, trace);
      },
    );
  }

  final MonitorRepository _monitorRepo = const MonitorRepository();

  /// 获取当前监控指标
  ///
  /// 返回最新的CPU、内存、磁盘、负载数据
  Future<MonitorMetricsSnapshot> getCurrentMetrics() async {
    return runGuarded(() async {
      final client = await _getClient();
      return await _dashboardMetrics(client) ??
          await _monitorRepo.getCurrentMetrics(client);
    });
  }

  /// 获取CPU时间序列数据
  Future<MonitorTimeSeries> getCPUTimeSeries({
    Duration duration = const Duration(hours: 1),
  }) async {
    return runGuarded(() async {
      final client = await _getClient();
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
      final client = await _getClient();
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
      final client = await _getClient();
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
      final client = await _getClient();
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
      final client = await _getClient();
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
      final client = await _getClient();
      return _monitorRepo.getSetting(client, requireResponse: _requireSettings);
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
      final client = await _getClient();
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
      final client = await _getClient();
      return _monitorRepo.cleanData(client);
    });
  }

  /// 获取GPU监控数据
  Future<List<MonitorGpuInfo>> getGPUInfo() async {
    return runGuarded(() async {
      final client = await _getClient();
      return _monitorRepo.getGPUInfo(client);
    });
  }

  /// 批量获取监控数据（含当前指标与趋势图）
  Future<MonitorDataPackage> getMonitorData({
    CancelToken? cancelToken,
    String? io,
    String? network,
    Duration duration = const Duration(hours: 1),
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    return runGuarded(() async {
      final client = await _getClient();
      final results = (
        _monitorRepo.getMonitorData(
          client,
          cancelToken: cancelToken,
          io: io,
          network: network,
          duration: duration,
          startTime: startTime,
          endTime: endTime,
        ),
        _dashboardMetrics(client),
      );
      try {
        final (package, current) = await results.wait;
        return MonitorDataPackage(
          current: current ?? package.current,
          timeSeries: package.timeSeries,
        );
      } on ParallelWaitError<(MonitorDataPackage?, MonitorMetricsSnapshot?),
          (AsyncError?, AsyncError?)> catch (error) {
        final cause = error.errors.$1 ?? error.errors.$2!;
        Error.throwWithStackTrace(cause.error, cause.stackTrace);
      }
    });
  }

  Future<MonitorMetricsSnapshot?> _dashboardMetrics(DioClient client) async {
    try {
      final snapshot = await DashboardV2Api(client).getCurrentSnapshot();
      return snapshot.hasData ? snapshot : null;
    } on NetworkException {
      // 历史查询同时包含最近一次采样，连接错误由 HTTP 客户端记录。
      return null;
    }
  }

  /// 获取网络接口列表
  Future<List<String>> getNetworkOptions() async {
    return runGuarded(() async {
      final client = await _getClient();
      return _monitorRepo.getNetworkOptions(client,
          requireResponse: _requireSettings);
    });
  }

  /// 获取IO设备列表
  Future<List<String>> getIOOptions() async {
    return runGuarded(() async {
      final client = await _getClient();
      return _monitorRepo.getIOOptions(client,
          requireResponse: _requireSettings);
    });
  }
}
