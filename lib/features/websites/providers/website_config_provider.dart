import 'package:flutter/foundation.dart';

import '../../../data/models/file/file_info.dart';
import '../../../data/models/openresty_models.dart';
import '../../../data/models/runtime_models.dart';
import '../../../data/models/website_models.dart';
import '../services/website_config_service.dart';
import '../services/website_service.dart';

class WebsiteConfigProvider extends ChangeNotifier {
  final int websiteId;
  final WebsiteConfigService _service;
  final WebsiteService _websiteService;

  WebsiteConfigProvider({
    required this.websiteId,
    WebsiteConfigService? service,
    WebsiteService? websiteService,
  })  : _service = service ?? WebsiteConfigService(),
        _websiteService = websiteService ?? WebsiteService();

  bool isLoading = false;
  bool isUpdatingPhpVersion = false;
  String? error;
  FileInfo? nginxConfigFile;
  WebsiteNginxScopeResponse? scopeResponse;
  WebsiteInfo? website;
  List<RuntimeInfo> phpRuntimes = const [];
  int? selectedRuntimeId;
  NginxKey scope = NginxKey.indexKey;

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await Future.wait([
        loadConfigFile(),
        loadScope(scope),
        loadPhpVersionContext(),
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

  Future<void> loadPhpVersionContext() async {
    final result = await Future.wait<dynamic>([
      _websiteService.getWebsiteDetail(websiteId),
      _websiteService.listPhpRuntimes(),
    ]);
    website = result[0] as WebsiteInfo;
    phpRuntimes = result[1] as List<RuntimeInfo>;
    selectedRuntimeId = website?.runtimeId;
    notifyListeners();
  }

  void setSelectedRuntimeId(int? runtimeId) {
    selectedRuntimeId = runtimeId;
    notifyListeners();
  }

  Future<bool> updatePhpVersion() async {
    isUpdatingPhpVersion = true;
    error = null;
    notifyListeners();
    try {
      await _service.updatePhpVersion(
        websiteId: websiteId,
        runtimeId: selectedRuntimeId,
      );
      await loadPhpVersionContext();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    } finally {
      isUpdatingPhpVersion = false;
      notifyListeners();
    }
  }
}
