import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/features/server/server_models.dart';

class DashboardRepository {
  DashboardRepository({DashboardV2Api? api}) : _api = api;

  DashboardV2Api? _api;

  Future<DashboardV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getDashboardApi();
    return _api!;
  }

  Future<Map<String, dynamic>> getDashboardBase() async {
    final api = await _ensureApi();
    return (await api.getDashboardBase()).data ?? const <String, dynamic>{};
  }

  Future<dynamic> getTopCpuProcesses() async {
    final api = await _ensureApi();
    return (await api.getTopCPUProcesses()).data;
  }

  Future<dynamic> getTopMemoryProcesses() async {
    final api = await _ensureApi();
    return (await api.getTopMemoryProcesses()).data;
  }

  Future<List<dynamic>> getAppLaunchers() async {
    final api = await _ensureApi();
    return (await api.getAppLauncher()).data ?? const <dynamic>[];
  }

  Future<List<dynamic>> getAppLauncherOptions() async {
    final api = await _ensureApi();
    return (await api.getAppLauncherOption()).data ?? const <dynamic>[];
  }

  Future<Map<String, dynamic>> getCurrentNode() async {
    final api = await _ensureApi();
    return (await api.getCurrentNode()).data ?? const <String, dynamic>{};
  }

  Future<void> updateAppLauncherShow({
    required String key,
    required bool show,
  }) async {
    final api = await _ensureApi();
    await api.updateAppLauncherShow(request: <String, dynamic>{
      'key': key,
      'show': show,
    });
  }

  Future<List<dynamic>> getQuickOptions() async {
    final api = await _ensureApi();
    return (await api.getQuickOption()).data ?? const <dynamic>[];
  }

  Future<void> updateQuickChange(List<String> enabledKeys) async {
    final api = await _ensureApi();
    await api
        .updateQuickChange(request: <String, dynamic>{'keys': enabledKeys});
  }

  Future<void> runSystemCommand(String operation) async {
    final api = await _ensureApi();
    await api.systemRestart(operation);
  }

  /// 获取当前服务器指标
  ///
  /// 从 Dashboard API 获取服务器的当前快照数据，包括 CPU、内存、磁盘、负载等指标。
  /// 这个方法专门用于服务器详情页面显示当前状态。
  ///
  /// 返回 [ServerMetricsSnapshot] 包含：
  /// - cpuPercent: CPU 使用百分比
  /// - memoryPercent: 内存使用百分比
  /// - diskPercent: 磁盘使用百分比（从 diskData 数组的第一个磁盘提取）
  /// - load: 系统负载（load1）
  ///
  /// 如果 API 调用失败或数据格式异常，返回空的 ServerMetricsSnapshot。
  Future<ServerMetricsSnapshot> getCurrentServerMetrics() async {
    try {
      appLogger.dWithPackage(
        'data.repositories.dashboard_repository',
        'getCurrentServerMetrics',
      );

      // 调用 Dashboard API 获取基础数据
      final baseData = await getDashboardBase();

      // 从 currentInfo 中提取指标数据
      final currentInfo = baseData['currentInfo'] as Map<String, dynamic>?;

      if (currentInfo == null) {
        appLogger.wWithPackage(
          'data.repositories.dashboard_repository',
          'currentInfo is null in Dashboard API response',
        );
        return const ServerMetricsSnapshot();
      }

      // 提取 CPU 使用率
      final cpuPercent = (currentInfo['cpuUsedPercent'] as num?)?.toDouble();

      // 提取内存使用率
      final memoryPercent =
          (currentInfo['memoryUsedPercent'] as num?)?.toDouble();

      // 提取磁盘使用率（从 diskData 数组的第一个磁盘）
      double? diskPercent;
      final diskDataList = currentInfo['diskData'] as List?;
      if (diskDataList != null && diskDataList.isNotEmpty) {
        final mainDisk = diskDataList.first as Map<String, dynamic>;
        diskPercent = (mainDisk['usedPercent'] as num?)?.toDouble();
      }

      // 提取系统负载
      final load = (currentInfo['load1'] as num?)?.toDouble();

      appLogger.dWithPackage(
        'data.repositories.dashboard_repository',
        'Extracted metrics: cpu=$cpuPercent%, memory=$memoryPercent%, disk=$diskPercent%, load=$load',
      );

      return ServerMetricsSnapshot(
        cpuPercent: cpuPercent,
        memoryPercent: memoryPercent,
        diskPercent: diskPercent,
        load: load,
      );
    } catch (e, stack) {
      appLogger.eWithPackage(
        'data.repositories.dashboard_repository',
        'Error getting current server metrics',
        error: e,
        stackTrace: stack,
      );
      return const ServerMetricsSnapshot();
    }
  }
}
