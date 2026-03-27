import 'package:flutter/foundation.dart';

import '../../../data/models/website_models.dart';
import '../services/website_service.dart';

class WebsiteDetailProvider extends ChangeNotifier {
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
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      website = await _service.getWebsiteDetail(websiteId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> operate(String action) async {
    await _service.operateWebsite(websiteId: websiteId, action: action);
    await loadDetail();
  }

  Future<void> setDefaultServer() async {
    await _service.changeDefaultServer(websiteId);
    await loadDetail();
  }

  Future<void> deleteWebsite() async {
    await _service.deleteWebsite(websiteId);
  }
}
