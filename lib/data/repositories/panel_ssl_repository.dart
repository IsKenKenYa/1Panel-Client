import 'package:onepanel_client/api/v2/setting_v2.dart' as api;
import 'package:onepanel_client/core/network/api_client_manager.dart';

class PanelSslRepository {
  PanelSslRepository({api.SettingV2Api? apiClient}) : _api = apiClient;

  api.SettingV2Api? _api;

  Future<api.SettingV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getSettingApi();
    return _api!;
  }

  Future<dynamic> getSslInfo() async {
    final apiClient = await _ensureApi();
    return (await apiClient.getSSLInfo()).data;
  }

  Future<void> updateSsl(api.SSLUpdate request) async {
    final apiClient = await _ensureApi();
    await apiClient.updateSSL(request);
  }

  Future<List<int>> downloadSsl() async {
    final apiClient = await _ensureApi();
    return (await apiClient.downloadSSL()).data ?? const <int>[];
  }
}
