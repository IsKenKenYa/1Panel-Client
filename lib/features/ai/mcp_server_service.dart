import 'package:onepanel_client/data/models/mcp_models.dart';
import 'package:onepanel_client/data/repositories/mcp_server_repository.dart';

class McpServerSnapshot {
  const McpServerSnapshot({
    required this.servers,
    required this.binding,
  });

  final List<McpServerDTO> servers;
  final McpBindDomainRes binding;
}

class McpServerService {
  McpServerService({McpServerRepository? repository})
      : _repository = repository ?? McpServerRepository();

  final McpServerRepository _repository;

  Future<McpServerSnapshot> loadSnapshot({String? keyword}) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _repository.searchServers(name: keyword),
      _repository.getDomainBinding(),
    ]);
    return McpServerSnapshot(
      servers: results[0] as List<McpServerDTO>,
      binding: results[1] as McpBindDomainRes,
    );
  }

  Future<void> createServer(McpServerCreate request) {
    return _repository.createServer(request);
  }

  Future<void> updateServer(McpServerUpdate request) {
    return _repository.updateServer(request);
  }

  Future<void> deleteServer(int id) {
    return _repository.deleteServer(id);
  }

  Future<void> operateServer({
    required int id,
    required String operate,
  }) {
    return _repository.operateServer(id: id, operate: operate);
  }

  Future<void> bindDomain(McpBindDomain request) {
    return _repository.bindDomain(request);
  }

  Future<void> updateDomain(McpBindDomainUpdate request) {
    return _repository.updateDomain(request);
  }
}
