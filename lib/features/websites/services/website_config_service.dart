import '../../../api/v2/website_v2.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/file/file_info.dart';
import '../../../data/models/openresty_models.dart';
import '../../../data/models/ssl_models.dart';
import '../../../data/models/website_models.dart';

class WebsiteConfigService {
  WebsiteConfigService({WebsiteV2Api? api}) : _api = api;

  WebsiteV2Api? _api;

  Future<WebsiteV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getWebsiteApi();
    return _api!;
  }

  Future<FileInfo> getConfigFile({
    required int websiteId,
    String type = 'nginx',
  }) async {
    final api = await _ensureApi();
    return api.getWebsiteConfigFile(id: websiteId, type: type);
  }

  Future<void> saveConfigFile({
    required int websiteId,
    required String content,
  }) async {
    final api = await _ensureApi();
    await api.updateWebsiteNginxConfig(id: websiteId, content: content);
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
    final api = await _ensureApi();
    final data = await api.loadWebsiteNginxConfig({
      'scope': scope.value,
      'websiteId': websiteId,
    });
    return WebsiteNginxScopeResponse.fromJson(data);
  }

  Future<void> updateScope({
    required int websiteId,
    required NginxKey scope,
    required List<WebsiteNginxParam> params,
  }) async {
    final api = await _ensureApi();
    await api.updateWebsiteNginxConfigByRequest({
      'operate': 'update',
      'scope': scope.value,
      'websiteId': websiteId,
      'params': params.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> updatePhpVersion({
    required int websiteId,
    int? runtimeId,
  }) async {
    final api = await _ensureApi();
    await api.updateWebsitePhpVersion(websiteId: websiteId, runtimeId: runtimeId);
  }

  Future<String> loadRewrite({
    required int websiteId,
    required String name,
  }) async {
    final api = await _ensureApi();
    final data = await api.getWebsiteRewrite(websiteId: websiteId, name: name);
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
    final api = await _ensureApi();
    await api.updateWebsiteRewrite(
      websiteId: websiteId,
      name: name,
      content: content,
    );
  }

  Future<String> loadProxy({
    required int websiteId,
    required String name,
  }) async {
    final api = await _ensureApi();
    final data = await api.getWebsiteProxy(id: websiteId);
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
    final api = await _ensureApi();
    await api.updateWebsiteProxy(
      websiteId: websiteId,
      name: name,
      content: content,
    );
  }

  Future<Map<String, dynamic>> getResource(int websiteId) async {
    final api = await _ensureApi();
    return api.getWebsiteResource(websiteId);
  }

  Future<List<Map<String, dynamic>>> getDatabases() async {
    final api = await _ensureApi();
    return api.getWebsiteDatabases();
  }

  Future<void> changeDatabase(Map<String, dynamic> request) async {
    final api = await _ensureApi();
    await api.changeWebsiteDatabase(request);
  }

  Future<Map<String, dynamic>> getDirectoryConfig(Map<String, dynamic> request) async {
    final api = await _ensureApi();
    return api.getWebsiteDirectory(request);
  }

  Future<void> updateDirectory(Map<String, dynamic> request) async {
    final api = await _ensureApi();
    await api.updateWebsiteDirectory(request);
  }

  Future<void> updateDirectoryPermission(Map<String, dynamic> request) async {
    final api = await _ensureApi();
    await api.updateWebsiteDirectoryPermission(request);
  }

  Future<Map<String, dynamic>> getHttpsConfig(int websiteId) async {
    final api = await _ensureApi();
    final config = await api.getWebsiteHttps(websiteId);
    return config.toJson();
  }

  Future<WebsiteHttpsConfig> updateHttpsConfig({
    required int websiteId,
    required WebsiteHttpsUpdateRequest request,
  }) async {
    final api = await _ensureApi();
    return api.updateWebsiteHttps(websiteId: websiteId, request: request);
  }

  Future<String> loadRewrite({
    required int websiteId,
    required String name,
  }) async {
    final api = await _ensureApi();
    final data = await api.getWebsiteRewrite(websiteId: websiteId, name: name);
    return (data['content'] ?? data['value'] ?? '').toString();
  }

  Future<void> updateRewrite({
    required int websiteId,
    required String name,
    required String content,
  }) async {
    final api = await _ensureApi();
    await api.updateWebsiteRewrite(websiteId: websiteId, name: name, content: content);
  }

  Future<String> loadProxy({
    required int websiteId,
    required String name,
  }) async {
    final api = await _ensureApi();
    final data = await api.getWebsiteProxy(id: websiteId);
    final list = data['items'];
    if (list is List) {
      final match = list.whereType<Map>().firstWhere(
            (item) => item['name']?.toString() == name,
            orElse: () => const <String, dynamic>{},
          );
      return (match['content'] ?? '').toString();
    }
    return (data['content'] ?? '').toString();
  }

  Future<void> updateProxy({
    required int websiteId,
    required String name,
    required String content,
  }) async {
    final api = await _ensureApi();
    await api.updateWebsiteProxy(websiteId: websiteId, name: name, content: content);
  }
}
