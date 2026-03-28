import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/file/file_info.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';

class WebsiteConfigRepository {
  WebsiteConfigRepository({WebsiteV2Api? api}) : _api = api;

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

  Future<Map<String, dynamic>> loadScope({
    required int websiteId,
    required NginxKey scope,
  }) async {
    final api = await _ensureApi();
    return api.loadWebsiteNginxConfig({
      'scope': scope.value,
      'websiteId': websiteId,
    });
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
    await api.updateWebsitePhpVersion(
      websiteId: websiteId,
      runtimeId: runtimeId,
    );
  }

  Future<Map<String, dynamic>> getRewrite({
    required int websiteId,
    required String name,
  }) async {
    final api = await _ensureApi();
    return api.getWebsiteRewrite(websiteId: websiteId, name: name);
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

  Future<Map<String, dynamic>> getProxy({
    required int websiteId,
  }) async {
    final api = await _ensureApi();
    return api.getWebsiteProxy(id: websiteId);
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

  Future<Map<String, dynamic>> getDirectoryConfig(
    Map<String, dynamic> request,
  ) async {
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

  Future<WebsiteHttpsConfig> getHttpsConfig(int websiteId) async {
    final api = await _ensureApi();
    return api.getWebsiteHttps(websiteId);
  }

  Future<WebsiteHttpsConfig> updateHttpsConfig({
    required int websiteId,
    required WebsiteHttpsUpdateRequest request,
  }) async {
    final api = await _ensureApi();
    return api.updateWebsiteHttps(websiteId: websiteId, request: request);
  }
}
