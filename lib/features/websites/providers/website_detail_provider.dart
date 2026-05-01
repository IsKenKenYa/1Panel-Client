import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';

import '../../../data/models/website_models.dart';
import '../services/website_service.dart';

class WebsiteDetailProvider extends ChangeNotifier with SafeChangeNotifier {
  final int websiteId;
  final WebsiteService _service;

  WebsiteDetailProvider({
    required this.websiteId,
    WebsiteService? service,
  }) : _service = service ?? WebsiteService();

  bool isLoading = false;
  String? error;
  WebsiteInfo? website;

  Future<void> loadDetail() async {
    if (isDisposed) return;
    
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      website = await _service.getWebsiteDetail(websiteId);
      if (isDisposed) return;
    } catch (e) {
      if (!isDisposed) {
        error = e.toString();
      }
    } finally {
      if (!isDisposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> operate(String action) async {
    if (isDisposed) return;
    await _service.operateWebsite(websiteId: websiteId, action: action);
    await loadDetail();
  }

  Future<void> setDefaultServer() async {
    if (isDisposed) return;
    await _service.changeDefaultServer(websiteId);
    await loadDetail();
  }

  Future<void> deleteWebsite() async {
    if (isDisposed) return;
    await _service.deleteWebsite(websiteId);
  }
}
