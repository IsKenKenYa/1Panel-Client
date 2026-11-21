import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/dashboard_models.dart';
import 'package:onepanel_client/data/models/monitor_models.dart';
import 'package:onepanel_client/data/models/server_metrics_snapshot.dart';

class DashboardRepository {
  DashboardRepository({DashboardV2Api? api})
      : _api = api,
        _server = null;
  DashboardRepository.forServer(ApiConfig server) : _server = server;

  final ApiConfig? _server;
  DashboardV2Api? _api;
  Future<DashboardV2Api>? _opening;

  Future<DashboardV2Api> _ensureApi() {
    final api = _api;
    if (api != null) return Future.value(api);
    return _opening ??= _openApi().whenComplete(() {
      _opening = null;
    });
  }

  Future<DashboardV2Api> _openApi() async {
    try {
      final server = _server;
      return _api = server == null
          ? await ApiClientManager.instance.getDashboardApi()
          : DashboardV2Api(
              await ApiClientManager.instance.getClientForServer(server));
    } catch (e) {
      if (e is StateError && e.message == 'No API config available') {
        throw const NetworkConnectionException('未配置服务器连接');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDashboardBase() async {
    final api = await _ensureApi();
    return (await api.getDashboardBase()).data ?? const <String, dynamic>{};
  }

  Future<List<ProcessInfo>> getTopCpuProcesses() async {
    final api = await _ensureApi();
    return (await api.getTopCPUProcesses()).data ?? const <ProcessInfo>[];
  }

  Future<List<ProcessInfo>> getTopMemoryProcesses() async {
    final api = await _ensureApi();
    return (await api.getTopMemoryProcesses()).data ?? const <ProcessInfo>[];
  }

  Future<List<Map<String, dynamic>>> getAppLaunchers() async {
    final api = await _ensureApi();
    return (await api.getAppLauncher()).data ?? const <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getAppLauncherOptions() async {
    final api = await _ensureApi();
    return (await api.getAppLauncherOption()).data ??
        const <Map<String, dynamic>>[];
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

  Future<List<Map<String, dynamic>>> getQuickOptions() async {
    final api = await _ensureApi();
    return (await api.getQuickOption()).data ?? const <Map<String, dynamic>>[];
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

  Future<MonitorMetricsSnapshot> getCurrentSnapshot() async {
    return (await _ensureApi()).getCurrentSnapshot();
  }

  Future<ServerMetricsSnapshot> getCurrentServerMetrics() async {
    try {
      final snapshot = await getCurrentSnapshot();
      return ServerMetricsSnapshot(
        cpuPercent: snapshot.cpuPercent,
        memoryPercent: snapshot.memoryPercent,
        diskPercent: snapshot.diskPercent,
        load: snapshot.load1,
      );
    } on NetworkException {
      return const ServerMetricsSnapshot();
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
