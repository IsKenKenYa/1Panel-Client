import 'package:onepanel_client/api/v2/toolbox_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';

class ToolboxRepository {
  ToolboxRepository({ToolboxV2Api? apiClient}) : _api = apiClient;

  ToolboxV2Api? _api;

  Future<ToolboxV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getToolboxApi();
    return _api!;
  }

  Future<DeviceBaseInfo> getDeviceBaseInfo() async {
    final api = await _ensureApi();
    return (await api.getDeviceBaseInfo()).data ?? const DeviceBaseInfo();
  }

  Future<Map<String, dynamic>> getDeviceConf() async {
    final api = await _ensureApi();
    final raw = (await api.getDeviceConf()).data;
    return _normalizeToMap(raw);
  }

  Future<void> updateDeviceConf(DeviceConfUpdate request) async {
    final api = await _ensureApi();
    await api.updateDeviceConf(request);
  }

  Future<void> checkDns(String dns) async {
    final api = await _ensureApi();
    await api.checkDNS(dns);
  }

  Future<List<String>> getDeviceUsers() async {
    final api = await _ensureApi();
    return (await api.getDeviceUsers()).data ?? const <String>[];
  }

  Future<List<String>> getDeviceZoneOptions() async {
    final api = await _ensureApi();
    return (await api.getDeviceZoneOptions()).data ?? const <String>[];
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
        // Ignore unknown response shape and fallback to empty map.
      }
    }

    return const <String, dynamic>{};
  }
}
