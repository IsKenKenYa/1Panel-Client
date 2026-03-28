import 'package:onepanel_client/api/v2/setting_v2.dart' as api;
import 'package:onepanel_client/data/repositories/panel_ssl_repository.dart';

class PanelSslService {
  PanelSslService({
    api.SettingV2Api? apiClient,
    PanelSslRepository? repository,
  }) : _repository = repository ?? PanelSslRepository(apiClient: apiClient);

  final PanelSslRepository _repository;

  Future<Map<String, dynamic>> getSslInfo() async {
    return _normalizeToMap(await _repository.getSslInfo());
  }

  Future<void> updateSsl({
    required String domain,
    required String sslType,
    required String cert,
    required String key,
  }) async {
    await _repository.updateSsl(
      api.SSLUpdate(
        domain: domain,
        sslType: sslType,
        cert: cert,
        key: key,
      ),
    );
  }

  Future<List<int>> downloadSsl() async {
    return _repository.downloadSsl();
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
