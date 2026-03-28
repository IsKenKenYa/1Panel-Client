import 'package:onepanel_client/api/v2/toolbox_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
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

  Future<ClamBaseInfo> getClamBaseInfo() async {
    final api = await _ensureApi();
    return (await api.getClamBaseInfo()).data ?? const ClamBaseInfo();
  }

  Future<List<ClamBaseInfo>> searchClamTasks({
    int page = 1,
    int pageSize = 20,
  }) async {
    final api = await _ensureApi();
    final response = await api.searchClam(
      PageRequest(page: page, pageSize: pageSize),
    );
    return response.data?.items ?? const <ClamBaseInfo>[];
  }

  Future<List<ClamLogInfo>> searchClamRecords({
    required int clamId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final api = await _ensureApi();
    final response = await api.searchClamRecords(
      ClamLogSearch(
        clamId: clamId,
        page: page,
        pageSize: pageSize,
      ),
    );
    return response.data?.items ?? const <ClamLogInfo>[];
  }

  Future<Fail2banBaseInfo> getFail2banBaseInfo() async {
    final api = await _ensureApi();
    return (await api.getFail2banBaseInfo()).data ?? const Fail2banBaseInfo();
  }

  Future<String> loadFail2banConf() async {
    final api = await _ensureApi();
    return (await api.loadFail2banConf()).data ?? '';
  }

  Future<List<Fail2banRecord>> searchFail2banRecords({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final api = await _ensureApi();
    final response = await api.searchFail2ban(
      Fail2banSearch(
        page: page,
        pageSize: pageSize,
        status: status,
      ),
    );
    return response.data?.items ?? const <Fail2banRecord>[];
  }

  Future<void> updateFail2ban(Fail2banUpdate request) async {
    final api = await _ensureApi();
    await api.updateFail2ban(request);
  }

  Future<FtpBaseInfo> getFtpBaseInfo() async {
    final api = await _ensureApi();
    return (await api.getFtpBaseInfo()).data ?? const FtpBaseInfo();
  }

  Future<List<FtpInfo>> searchFtpUsers({
    int page = 1,
    int pageSize = 50,
    String? keyword,
  }) async {
    final api = await _ensureApi();
    final response = await api.searchFtp(
      FtpSearch(
        info: keyword,
        page: page,
        pageSize: pageSize,
      ),
    );
    return response.data?.items ?? const <FtpInfo>[];
  }

  Future<void> syncFtp() async {
    final api = await _ensureApi();
    await api.syncFtp();
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
