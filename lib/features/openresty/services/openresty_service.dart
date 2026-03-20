import 'package:onepanelapp_app/api/v2/openresty_v2.dart';
import 'package:onepanelapp_app/core/network/api_client_manager.dart';
import 'package:onepanelapp_app/data/models/openresty_models.dart';

class OpenRestySnapshot {
  final Map<String, dynamic> status;
  final Map<String, dynamic> modules;
  final Map<String, dynamic> https;
  final String configContent;

  const OpenRestySnapshot({
    this.status = const <String, dynamic>{},
    this.modules = const <String, dynamic>{},
    this.https = const <String, dynamic>{},
    this.configContent = '',
  });
}

class OpenRestyService {
  OpenRestyV2Api? _api;

  OpenRestyService({OpenRestyV2Api? api}) : _api = api;

  Future<OpenRestyV2Api> _ensureApi() async {
    if (_api != null) {
      return _api!;
    }
    _api = await ApiClientManager.instance.getOpenRestyApi();
    return _api!;
  }

  Future<OpenRestySnapshot> loadSnapshot() async {
    final api = await _ensureApi();
    final results = await Future.wait([
      api.getOpenRestyStatus(),
      api.getOpenRestyModules(),
      api.getOpenRestyHttps(),
      api.getOpenRestyConfig(),
    ]);

    final status = (results[0].data as OpenrestyStatus?)?.toJson() ?? const <String, dynamic>{};
    final modules = (results[1].data as OpenrestyBuildConfig?)?.toJson() ?? const <String, dynamic>{};
    final https = (results[2].data as OpenrestyHttpsConfig?)?.toJson() ?? const <String, dynamic>{};
    final configContent = (results[3].data as OpenrestyFile?)?.content ?? '';

    return OpenRestySnapshot(
      status: status,
      modules: modules,
      https: https,
      configContent: configContent,
    );
  }

  Future<void> updateHttps(Map<String, dynamic> request) async {
    final api = await _ensureApi();
    await api.updateOpenRestyHttps(OpenrestyDefaultHttpsUpdateRequest.fromJson(request));
  }

  Future<void> updateModules(Map<String, dynamic> request) async {
    final api = await _ensureApi();
    await api.updateOpenRestyModules(OpenrestyModuleUpdateRequest.fromJson(request));
  }

  Future<void> updateConfigSource(String content) async {
    final api = await _ensureApi();
    await api.updateOpenRestyConfigByFile(OpenrestyConfigFileUpdateRequest(content: content));
  }

  Future<void> buildOpenResty({
    required String mirror,
    required String taskId,
  }) async {
    final api = await _ensureApi();
    await api.buildOpenResty(OpenrestyBuildRequest(mirror: mirror, taskId: taskId));
  }

  Future<List<OpenrestyParam>> loadScope({
    required NginxKey scope,
    int? websiteId,
  }) async {
    final api = await _ensureApi();
    final response = await api.getOpenRestyScope(
      OpenrestyScopeRequest(scope: scope, websiteId: websiteId),
    );
    return response.data ?? const [];
  }
}
