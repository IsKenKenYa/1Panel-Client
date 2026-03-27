import 'package:onepanel_client/api/v2/setting_v2.dart' as api;
import 'package:onepanel_client/core/network/api_client_manager.dart';

class PanelSslService {
  api.SettingV2Api? _api;

  PanelSslService({api.SettingV2Api? apiClient}) : _api = apiClient;

  Future<api.SettingV2Api> _ensureApi() async {
    if (_api != null) {
      return _api!;
    }
    _api = await ApiClientManager.instance.getSettingApi();
    return _api!;
  }

  Future<Map<String, dynamic>> getSslInfo() async {
    final apiClient = await _ensureApi();
    final response = await apiClient.getSSLInfo();
    return _normalizeToMap(response.data);
  }

  Future<void> updateSsl({
    required String domain,
    required String sslType,
    required String cert,
    required String key,
  }) async {
    final apiClient = await _ensureApi();
    await apiClient.updateSSL(api.SSLUpdate(
      domain: domain,
      sslType: sslType,
      cert: cert,
      key: key,
    ));
  }

  Future<List<int>> downloadSsl() async {
    final apiClient = await _ensureApi();
    final response = await apiClient.downloadSSL();
    return response.data ?? const <int>[];
  }

  Map<String, dynamic> _normalizeToMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value != null) {
      try {
        final dynamic data = value;
        final json = data.toJson();
        if (json is Map<String, dynamic>) {
          return json;
        }
        if (json is Map) {
          return Map<String, dynamic>.from(json);
        }
      } catch (_) {
        // fallthrough: unknown response shape
      }
    }
    return const <String, dynamic>{};
  }
}
