import 'package:flutter/foundation.dart';

import '../services/website_config_service.dart';

class WebsiteRoutingRulesProvider extends ChangeNotifier {
  final int websiteId;
  final WebsiteConfigService _service;

  WebsiteRoutingRulesProvider({
    required this.websiteId,
    WebsiteConfigService? service,
  }) : _service = service ?? WebsiteConfigService();

  bool isLoading = false;
  String? error;
  String rewriteName = 'default';
  String proxyName = 'default';
  String rewriteContent = '';
  String proxyContent = '';

  Future<void> loadAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final rewrite =
          _service.loadRewrite(websiteId: websiteId, name: rewriteName);
      final proxy = _service.loadProxy(websiteId: websiteId, name: proxyName);
      final result = await Future.wait([rewrite, proxy]);
      rewriteContent = result[0];
      proxyContent = result[1];
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveRewrite(String content) async {
    await _service.updateRewrite(
      websiteId: websiteId,
      name: rewriteName,
      content: content,
    );
    rewriteContent = content;
    notifyListeners();
  }

  Future<void> saveProxy(String content) async {
    await _service.updateProxy(
      websiteId: websiteId,
      name: proxyName,
      content: content,
    );
    proxyContent = content;
    notifyListeners();
  }
}
