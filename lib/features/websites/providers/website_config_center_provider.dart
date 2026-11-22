import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import '../../../data/models/file/file_info.dart';
import '../../../data/models/openresty_models.dart';
import '../../../data/models/website_models.dart';
import '../../../data/repositories/website_repository.dart';
import 'website_detail_store.dart';
import '../services/website_config_service.dart';

class WebsiteConfigCenterProvider extends ChangeNotifier
    with SafeChangeNotifier {
  WebsiteConfigCenterProvider({
    required this.websiteId,
    WebsiteConfigService? service,
    WebsiteRepository? websiteRepository,
    WebsiteDetailStore? store,
  })  : _service = service,
        _websiteRepository = websiteRepository,
        _store = store;

  final int websiteId;
  WebsiteConfigService? _service;
  WebsiteRepository? _websiteRepository;
  final WebsiteDetailStore? _store;

  bool isLoading = false;
  String? error;
  FileInfo? configFile;
  WebsiteNginxScopeResponse? scopeResponse;
  WebsiteInfo? website;
  Map<String, dynamic>? resource;
  Map<String, dynamic>? httpsSummary;

  Future<void> _ensureService() async {
    _service ??= WebsiteConfigService();
    _websiteRepository ??= WebsiteRepository();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _ensureService();
      final detailFuture = _store != null
          ? _store.load()
          : _websiteRepository!.getWebsiteDetail(websiteId);
      final results = await Future.wait<dynamic>([
        detailFuture,
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
      error = ErrorMessageUtils.userFacingMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
