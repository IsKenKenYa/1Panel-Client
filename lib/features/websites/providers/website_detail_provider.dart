import 'package:flutter/foundation.dart';

import '../../../data/models/website_models.dart';
import '../services/website_detail_service.dart';

class WebsiteDetailProvider extends ChangeNotifier {
  final int websiteId;
  final WebsiteDetailService _service;

  WebsiteDetailProvider({
    required this.websiteId,
    WebsiteDetailService? service,
  }) : _service = service ?? WebsiteDetailService();

  bool isLoading = false;
  String? error;
  WebsiteInfo? website;

  Future<void> loadDetail() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      website = await _service.fetchWebsiteDetail(websiteId);
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
}
