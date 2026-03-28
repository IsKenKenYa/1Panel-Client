import 'package:flutter/foundation.dart';
import '../../../data/models/file/file_info.dart';
import '../../../data/models/openresty_models.dart';
import '../../../data/models/website_models.dart';
import '../services/website_config_service.dart';
import '../services/website_service.dart';

class WebsiteConfigCenterProvider extends ChangeNotifier {
  WebsiteConfigCenterProvider({
    required this.websiteId,
    WebsiteConfigService? service,
    WebsiteService? websiteService,
  })  : _service = service,
        _websiteService = websiteService;

  final int websiteId;
  WebsiteConfigService? _service;
  WebsiteService? _websiteService;

  bool isLoading = false;
  String? error;
  FileInfo? configFile;
  WebsiteNginxScopeResponse? scopeResponse;
  WebsiteInfo? website;
  Map<String, dynamic>? resource;
  Map<String, dynamic>? httpsSummary;

  Future<void> _ensureService() async {
    _service ??= WebsiteConfigService();
    _websiteService ??= WebsiteService();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      final results = await Future.wait<dynamic>([
        _websiteService!.getWebsiteDetail(websiteId),
        _service!.getConfigFile(websiteId: websiteId),
        _service!.loadScope(websiteId: websiteId, scope: NginxKey.indexKey),
        _service!.getResource(websiteId),
        _service!.getHttpsConfig(websiteId),
      ]);
      website = results[0] as WebsiteInfo;
      configFile = results[1] as FileInfo;
      scopeResponse = results[2] as WebsiteNginxScopeResponse;
      resource = results[3] as Map<String, dynamic>;
      httpsSummary = results[4] as Map<String, dynamic>;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
