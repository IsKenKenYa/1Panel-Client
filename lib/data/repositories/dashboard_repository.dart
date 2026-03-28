import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';

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
}
