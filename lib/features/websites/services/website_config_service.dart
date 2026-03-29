import '../../../data/models/file/file_info.dart';
import '../../../data/models/openresty_models.dart';
import '../../../data/models/ssl_models.dart';
import '../../../data/models/website_models.dart';
import '../../../data/repositories/website_config_repository.dart';

class WebsiteConfigService {
  WebsiteConfigService({WebsiteConfigRepository? repository})
      : _repository = repository ?? WebsiteConfigRepository();

  final WebsiteConfigRepository _repository;

  Future<FileInfo> getConfigFile({
    required int websiteId,
    String type = 'nginx',
  }) async {
    return _repository.getConfigFile(websiteId: websiteId, type: type);
  }

  Future<void> saveConfigFile({
    required int websiteId,
    required String content,
  }) async {
    await _repository.saveConfigFile(websiteId: websiteId, content: content);
  }

  Future<FileInfo> fetchNginxConfigFile(int websiteId) {
    return getConfigFile(websiteId: websiteId);
  }

  Future<void> saveNginxConfigFile({
    required int websiteId,
    required String content,
  }) {
    return saveConfigFile(websiteId: websiteId, content: content);
  }

  Future<WebsiteNginxScopeResponse> loadScope({
    required int websiteId,
    required NginxKey scope,
  }) async {
    final data = await _repository.loadScope(
      websiteId: websiteId,
      scope: scope,
    );
    return WebsiteNginxScopeResponse.fromJson(data);
  }

  Future<void> updateScope({
    required int websiteId,
    required NginxKey scope,
    required List<WebsiteNginxParam> params,
  }) async {
    await _repository.updateScope(
      websiteId: websiteId,
      scope: scope,
      params: params,
    );
  }

  Future<void> updatePhpVersion({
    required int websiteId,
    int? runtimeId,
  }) async {
    await _repository.updatePhpVersion(
      websiteId: websiteId,
      runtimeId: runtimeId,
    );
  }

  Future<String> loadRewrite({
    required int websiteId,
    required String name,
  }) async {
    final data = await _repository.getRewrite(websiteId: websiteId, name: name);
    final content = data['content'];
    if (content is String) {
      return content;
    }
    return data.toString();
  }

  Future<void> updateRewrite({
    required int websiteId,
    required String name,
    required String content,
  }) async {
    await _repository.updateRewrite(
      websiteId: websiteId,
      name: name,
      content: content,
    );
  }

  Future<String> loadProxy({
    required int websiteId,
    required String name,
  }) async {
    final data = await _repository.getProxy(websiteId: websiteId);
    final content = data['content'];
    if (content is String) {
      return content;
    }
    return data.toString();
  }

  Future<void> updateProxy({
    required int websiteId,
    required String name,
    required String content,
  }) async {
    await _repository.updateProxy(
      websiteId: websiteId,
      name: name,
      content: content,
    );
  }

  Future<void> deleteProxy(Map<String, dynamic> request) async {
    await _repository.deleteProxy(request);
  }

  Future<void> updateProxyStatus(Map<String, dynamic> request) async {
    await _repository.updateProxyStatus(request);
  }

  Future<void> updateRedirectFile(Map<String, dynamic> request) async {
    await _repository.updateRedirectFile(request);
  }

  Future<void> updateLoadBalancerFile(Map<String, dynamic> request) async {
    await _repository.updateLoadBalancerFile(request);
  }

  Future<Map<String, dynamic>> getResource(int websiteId) async {
    return _repository.getResource(websiteId);
  }

  Future<List<Map<String, dynamic>>> getDatabases() async {
    return _repository.getDatabases();
  }

  Future<void> changeDatabase(Map<String, dynamic> request) async {
    await _repository.changeDatabase(request);
  }

  Future<Map<String, dynamic>> getDirectoryConfig(
      Map<String, dynamic> request) async {
    return _repository.getDirectoryConfig(request);
  }

  Future<void> updateDirectory(Map<String, dynamic> request) async {
    await _repository.updateDirectory(request);
  }

  Future<void> updateDirectoryPermission(Map<String, dynamic> request) async {
    await _repository.updateDirectoryPermission(request);
  }

  Future<Map<String, dynamic>> getHttpsConfig(int websiteId) async {
    final config = await _repository.getHttpsConfig(websiteId);
    return config.toJson();
  }

  Future<WebsiteHttpsConfig> updateHttpsConfig({
    required int websiteId,
    required WebsiteHttpsUpdateRequest request,
  }) async {
    return _repository.updateHttpsConfig(
      websiteId: websiteId,
      request: request,
    );
  }
}
