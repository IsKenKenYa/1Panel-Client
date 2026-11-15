import '../../../api/v2/firewall_v2.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/firewall_v2_models.dart';

class FirewallV2Service {
  FirewallV2Service({FirewallV2Api? api}) : _api = api;

  FirewallV2Api? _api;

  Future<FirewallV2Api> _ensureApi() async {
    _api ??= FirewallV2Api(await ApiClientManager.instance.getCurrentClient());
    return _api!;
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final api = await _ensureApi();
    return (await api.loadFirewallV2Settings()).data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loadRuleBackups(String subsystem) async {
    final api = await _ensureApi();
    return (await api.loadFirewallRuleBackups(subsystem)).data ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> searchRuleInventory({
    int page = 1,
    int pageSize = 20,
    String? info,
  }) async {
    final api = await _ensureApi();
    return (await api.searchFirewallRuleInventory(
      FirewallRuleInventoryRequest(page: page, pageSize: pageSize, info: info),
    )).data ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loadForwardBase() async {
    final api = await _ensureApi();
    return (await api.loadFirewallForwardBase()).data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> searchForwardRules({
    int page = 1,
    int pageSize = 20,
  }) async {
    final api = await _ensureApi();
    return (await api.searchFirewallForwardRules(
      FirewallForwardSearchRequest(page: page, pageSize: pageSize),
    )).data ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> loadDockerPorts() async {
    final api = await _ensureApi();
    return (await api.loadFirewallDockerPorts()).data ?? <String, dynamic>{};
  }

  Future<List<dynamic>> loadDockerEndpoints() async {
    final api = await _ensureApi();
    return (await api.loadFirewallDockerEndpoints()).data ?? <dynamic>[];
  }
}
