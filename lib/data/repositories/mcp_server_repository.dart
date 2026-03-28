import 'package:onepanel_client/api/v2/ai_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/mcp_models.dart';

class McpServerRepository {
  McpServerRepository({
    ApiClientManager? clientManager,
    AIV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  AIV2Api? _api;

  Future<AIV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getAiApi();
  }

  Future<List<McpServerDTO>> searchServers({String? name}) async {
    final api = await _ensureApi();
    final response = await api.searchMcpServers(
      McpServerSearch(
        page: 1,
        pageSize: 100,
        name: name,
      ),
    );
    return response.data?.items ?? const <McpServerDTO>[];
  }

  Future<void> createServer(McpServerCreate request) async {
    final api = await _ensureApi();
    await api.createMcpServer(request);
  }

  Future<void> updateServer(McpServerUpdate request) async {
    final api = await _ensureApi();
    await api.updateMcpServer(request);
  }

  Future<void> deleteServer(int id) async {
    final api = await _ensureApi();
    await api.deleteMcpServer(McpServerDelete(id: id));
  }

  Future<void> operateServer({
    required int id,
    required String operate,
  }) async {
    final api = await _ensureApi();
    await api.operateMcpServer(McpServerOperate(id: id, operate: operate));
  }

  Future<McpBindDomainRes> getDomainBinding() async {
    final api = await _ensureApi();
    final response = await api.getMcpBindDomain();
    return response.data ?? const McpBindDomainRes();
  }

  Future<void> bindDomain(McpBindDomain request) async {
    final api = await _ensureApi();
    await api.bindMcpDomain(request);
  }

  Future<void> updateDomain(McpBindDomainUpdate request) async {
    final api = await _ensureApi();
    await api.updateMcpDomain(request);
  }
}
