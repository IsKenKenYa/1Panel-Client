import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/dashboard_models.dart';
import 'package:onepanel_client/data/repositories/dashboard_repository.dart';
import 'package:onepanel_client/features/dashboard/models/dashboard_view_models.dart';

class DashboardService {
  DashboardService({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository();

  final DashboardRepository _repository;

  Future<DashboardData> loadDashboardData() async {
    appLogger.dWithPackage(
        'features.dashboard.dashboard_service', 'loadDashboardData');
    final baseData = await _repository.getDashboardBase();
    final currentInfo = baseData['currentInfo'] as Map<String, dynamic>?;
    final diskDataList = currentInfo?['diskData'] as List?;

    double? diskPercent;
    String? diskUsage;
    if (diskDataList != null && diskDataList.isNotEmpty) {
      final mainDisk = diskDataList.first as Map<String, dynamic>;
      diskPercent = (mainDisk['usedPercent'] as num?)?.toDouble();
      final used = mainDisk['used'] as int?;
      final total = mainDisk['total'] as int?;
      if (used != null && total != null) {
        diskUsage = '${_formatBytes(used)} / ${_formatBytes(total)}';
      }
    }

    final uptime = currentInfo?['uptime'] as int?;
    final memoryPercent =
        (currentInfo?['memoryUsedPercent'] as num?)?.toDouble();
    final memoryUsed = currentInfo?['memoryUsed'] as int?;
    final memoryTotal = currentInfo?['memoryTotal'] as int?;

    return DashboardData(
      systemInfo: SystemInfo(
        hostname: baseData['hostname'] as String?,
        os: baseData['os'] as String?,
        platform: baseData['platform'] as String?,
        platformVersion: baseData['platformVersion'] as String?,
        kernelVersion: baseData['kernelVersion'] as String?,
        cpuCores: baseData['cpuCores'] as int?,
      ),
      metrics: DashboardMetrics.fromJson(baseData),
      cpuPercent: (currentInfo?['cpuUsedPercent'] as num?)?.toDouble(),
      memoryPercent: memoryPercent,
      diskPercent: diskPercent,
      memoryUsage: memoryPercent != null
          ? '${memoryPercent.toStringAsFixed(1)}%'
          : (memoryUsed != null && memoryTotal != null
              ? '${_formatBytes(memoryUsed)} / ${_formatBytes(memoryTotal)}'
              : '--'),
      diskUsage: diskUsage ??
          (diskPercent != null ? '${diskPercent.toStringAsFixed(1)}%' : '--'),
      uptime: uptime != null ? _formatUptime(uptime) : '--',
      lastUpdated: DateTime.now(),
    );
  }

  Future<({List<ProcessInfo> cpu, List<ProcessInfo> memory})>
      loadTopProcesses() async {
    appLogger.dWithPackage(
        'features.dashboard.dashboard_service', 'loadTopProcesses');
    final responses = await Future.wait<dynamic>([
      _repository.getTopCpuProcesses(),
      _repository.getTopMemoryProcesses(),
    ]);
    return (
      cpu: _parseProcessList(responses[0]),
      memory: _parseProcessList(responses[1]),
    );
  }

  Future<List<AppLauncherItem>> loadAppLaunchers() async {
    final items = await _repository.getAppLaunchers();
    return items
        .whereType<Map<String, dynamic>>()
        .map(AppLauncherItem.fromJson)
        .toList(growable: false);
  }

  Future<List<AppLauncherOption>> loadAppLauncherOptions() async {
    final items = await _repository.getAppLauncherOptions();
    return items
        .whereType<Map<String, dynamic>>()
        .map(AppLauncherOption.fromJson)
        .toList(growable: false);
  }

  Future<NodeInfo?> loadCurrentNode() async {
    final data = await _repository.getCurrentNode();
    if (data.isEmpty) return null;
    return NodeInfo.fromJson(data);
  }

  Future<void> updateAppLauncherShow({
    required String key,
    required bool show,
  }) {
    return _repository.updateAppLauncherShow(key: key, show: show);
  }

  Future<List<QuickJumpOption>> loadQuickOptions() async {
    final items = await _repository.getQuickOptions();
    return items
        .whereType<Map<String, dynamic>>()
        .map(QuickJumpOption.fromJson)
        .toList(growable: false);
  }

  Future<void> updateQuickChange(List<String> enabledKeys) {
    return _repository.updateQuickChange(enabledKeys);
  }

  Future<void> restartSystem() => _repository.runSystemCommand('restart');

  Future<void> shutdownSystem() => _repository.runSystemCommand('shutdown');

  Future<void> upgradeSystem() => _repository.runSystemCommand('restart');

  List<ProcessInfo> _parseProcessList(dynamic data) {
    if (data == null) return const <ProcessInfo>[];

    if (data is List<ProcessInfo>) {
      return data;
    }

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(ProcessInfo.fromJson)
          .toList(growable: false);
    }

    if (data is Map<String, dynamic>) {
      final list = data['list'] as List<dynamic>? ??
          data['processes'] as List<dynamic>? ??
          data['items'] as List<dynamic>?;
      if (list == null) return const <ProcessInfo>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ProcessInfo.fromJson)
          .toList(growable: false);
    }

    return const <ProcessInfo>[];
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (days > 0) return '$days天 $hours小时';
    if (hours > 0) return '$hours小时 $minutes分钟';
    return '$minutes分钟';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
