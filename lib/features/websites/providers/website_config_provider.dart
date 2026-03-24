import 'package:flutter/foundation.dart';

import '../../../data/models/file/file_info.dart';
import '../../../data/models/openresty_models.dart';
import '../../../data/models/website_models.dart';
import '../services/website_config_service.dart';

class WebsiteConfigProvider extends ChangeNotifier {
  final int websiteId;
  final WebsiteConfigService _service;

  WebsiteConfigProvider({
    required this.websiteId,
    WebsiteConfigService? service,
  }) : _service = service ?? WebsiteConfigService();

  bool isLoading = false;
  String? error;
  FileInfo? nginxConfigFile;
  WebsiteNginxScopeResponse? scopeResponse;
  NginxKey scope = NginxKey.indexKey;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadConfigFile(),
        loadScope(scope),
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConfigFile() async {
    nginxConfigFile = await _service.fetchNginxConfigFile(websiteId);
    notifyListeners();
  }

  Future<void> saveConfigFile(String content) async {
    await _service.saveNginxConfigFile(websiteId: websiteId, content: content);
    await loadConfigFile();
  }

  Future<void> loadScope(NginxKey key) async {
    scope = key;
    scopeResponse = await _service.loadScope(websiteId: websiteId, scope: key);
    notifyListeners();
  }

  Future<void> updateScope(List<WebsiteNginxParam> params) async {
    await _service.updateScope(
      websiteId: websiteId,
      scope: scope,
      params: params,
    );
    await loadScope(scope);
  }

  Future<void> updatePhpVersion(int? runtimeId) {
    return _service.updatePhpVersion(websiteId: websiteId, runtimeId: runtimeId);
  }
}
