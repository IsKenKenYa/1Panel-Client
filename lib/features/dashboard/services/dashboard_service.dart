import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/dashboard_models.dart';
import 'package:onepanel_client/data/models/monitor_models.dart';
import 'package:onepanel_client/data/repositories/dashboard_repository.dart';
import 'package:onepanel_client/features/dashboard/models/dashboard_view_models.dart';

class DashboardService {
  DashboardService({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository();

  final DashboardRepository _repository;

  Future<DashboardData> loadDashboardData() async {
    final baseData = await _repository.getDashboardBase();
    return _snapshotData(
      MonitorMetricsSnapshot.fromDashboard(
        baseData['currentInfo'] as Map<String, dynamic>? ?? const {},
      ),
      systemInfo: SystemInfo(
        hostname: baseData['hostname'] as String?,
        os: baseData['os'] as String?,
        platform: baseData['platform'] as String?,
        platformVersion: baseData['platformVersion'] as String?,
        kernelVersion: baseData['kernelVersion'] as String?,
        cpuCores: baseData['cpuCores'] as int?,
      ),
      metrics: DashboardMetrics.fromJson(baseData),
    );
  }

  Future<DashboardData> loadLiveData(DashboardData previous) async {
    return _snapshotData(
      await _repository.getCurrentSnapshot(),
      systemInfo: previous.systemInfo,
      metrics: previous.metrics,
    );
  }

  DashboardData _snapshotData(
    MonitorMetricsSnapshot snapshot, {
    required SystemInfo? systemInfo,
    required DashboardMetrics? metrics,
  }) {
    final memoryPercent = snapshot.memoryPercent;
    final memoryUsed = snapshot.memoryUsed;
    final memoryTotal = snapshot.memoryTotal;
    final disk = snapshot.diskData.firstOrNull;
    final uptime = snapshot.uptime;
    return DashboardData(
      systemInfo: systemInfo,
      metrics: metrics,
      cpuPercent: snapshot.cpuPercent,
      memoryPercent: memoryPercent,
      diskPercent: snapshot.diskPercent,
      load: snapshot.load1,
      memoryUsage: memoryPercent != null
          ? '${memoryPercent.toStringAsFixed(1)}%'
          : (memoryUsed != null && memoryTotal != null
              ? '${_formatBytes(memoryUsed)} / ${_formatBytes(memoryTotal)}'
              : '--'),
      diskUsage: disk == null
          ? '--'
          : '${_formatBytes(disk.used)} / ${_formatBytes(disk.total)}',
      uptime: uptime != null ? _formatUptime(uptime) : '--',
      uptimeSeconds: uptime,
      lastUpdated: snapshot.timestamp,
    );
  }

  Future<({List<ProcessInfo> cpu, List<ProcessInfo> memory})>
      loadTopProcesses() async {
    final responses = await Future.wait([
      _repository.getTopCpuProcesses(),
      _repository.getTopMemoryProcesses(),
    ]);
    return (cpu: responses[0], memory: responses[1]);
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

  Future<void> restartSystem() => _repository.runSystemCommand('system');

  Future<void> shutdownSystem() => _repository.runSystemCommand('shutdown');

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
