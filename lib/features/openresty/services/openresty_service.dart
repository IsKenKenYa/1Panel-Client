import 'package:onepanel_client/api/v2/openresty_v2.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/data/repositories/openresty_repository.dart';

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
  OpenRestyService({
    OpenRestyV2Api? api,
    OpenRestyRepository? repository,
  }) : _repository = repository ?? OpenRestyRepository(api: api);

  final OpenRestyRepository _repository;

  Future<OpenRestySnapshot> loadSnapshot() async {
    final results = await Future.wait([
      _repository.getStatus(),
      _repository.getModules(),
      _repository.getHttps(),
      _repository.getConfig(),
    ]);

    final status =
        (results[0] as OpenrestyStatus?)?.toJson() ?? const <String, dynamic>{};
    final modules = (results[1] as OpenrestyBuildConfig?)?.toJson() ??
        const <String, dynamic>{};
    final https = (results[2] as OpenrestyHttpsConfig?)?.toJson() ??
        const <String, dynamic>{};
    final configContent = (results[3] as OpenrestyFile?)?.content ?? '';

    return OpenRestySnapshot(
      status: status,
      modules: modules,
      https: https,
      configContent: configContent,
    );
  }

  Future<void> updateHttps(Map<String, dynamic> request) async {
    await _repository.updateHttps(
      OpenrestyDefaultHttpsUpdateRequest.fromJson(request),
    );
  }

  Future<void> updateModules(Map<String, dynamic> request) async {
    await _repository.updateModules(
      OpenrestyModuleUpdateRequest.fromJson(request),
    );
  }

  Future<void> updateConfigSource(String content) async {
    await _repository.updateConfig(
      OpenrestyConfigFileUpdateRequest(content: content),
    );
  }

  Future<void> buildOpenResty({
    required String mirror,
    required String taskId,
  }) async {
    await _repository.build(
      OpenrestyBuildRequest(mirror: mirror, taskId: taskId),
    );
  }

  Future<List<OpenrestyParam>> loadScope({
    required NginxKey scope,
    int? websiteId,
  }) async {
    return _repository.getScope(
      OpenrestyScopeRequest(scope: scope, websiteId: websiteId),
    );
  }
}
