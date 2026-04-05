import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';

import '../../../data/models/ssl_models.dart';
import '../../../data/models/website_models.dart';
import '../services/website_detail_service.dart';
import '../services/website_ssl_service.dart';

class WebsiteSecurityAccessProvider extends ChangeNotifier
    with SafeChangeNotifier {
  final int websiteId;
  final WebsiteDetailService _detailService;
  final WebsiteSslService _sslService;

  WebsiteSecurityAccessProvider({
    required this.websiteId,
    WebsiteDetailService? detailService,
    WebsiteSslService? sslService,
  })  : _detailService = detailService ?? WebsiteDetailService(),
        _sslService = sslService ?? WebsiteSslService();

  bool isLoading = false;
  bool isUpdating = false;
  String? error;
  WebsiteInfo? website;
  WebsiteHttpsConfig? httpsConfig;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await Future.wait([
        _detailService.fetchWebsiteDetail(websiteId),
        _sslService.fetchHttpsConfig(websiteId),
      ]);
      website = result[0] as WebsiteInfo;
      httpsConfig = result[1] as WebsiteHttpsConfig;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateHttps({
    bool? enable,
    String? httpConfig,
  }) async {
    final current = httpsConfig;
    if (current == null) return;

    isUpdating = true;
    notifyListeners();
    try {
      httpsConfig = await _sslService.updateHttpsConfig(
        websiteId: websiteId,
        request: WebsiteHttpsUpdateRequest(
          websiteId: websiteId,
          enable: enable ?? current.enable,
          httpConfig: httpConfig ?? current.httpConfig,
          type: 'existed',
          websiteSSLId: current.ssl?.id,
          hsts: current.hsts,
          hstsIncludeSubDomains: current.hstsIncludeSubDomains,
          http3: current.http3,
          sslProtocol: current.sslProtocol,
        ),
      );
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }
}
