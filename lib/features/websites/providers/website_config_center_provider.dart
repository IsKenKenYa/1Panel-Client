import 'package:flutter/foundation.dart';
import '../../../data/models/file/file_info.dart';
import '../../../data/models/openresty_models.dart';
import '../../../data/models/website_models.dart';
import '../services/website_config_service.dart';

class WebsiteConfigCenterProvider extends ChangeNotifier {
  WebsiteConfigCenterProvider({
    required this.websiteId,
    WebsiteConfigService? service,
  }) : _service = service;

  final int websiteId;
  WebsiteConfigService? _service;

  bool isLoading = false;
  String? error;
  FileInfo? configFile;
  WebsiteNginxScopeResponse? scopeResponse;

  Future<void> _ensureService() async {
    _service ??= WebsiteConfigService();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      final results = await Future.wait<dynamic>([
        _service!.getConfigFile(websiteId: websiteId),
        _service!.loadScope(websiteId: websiteId, scope: NginxKey.indexKey),
      ]);
      configFile = results[0] as FileInfo;
      scopeResponse = results[1] as WebsiteNginxScopeResponse;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
