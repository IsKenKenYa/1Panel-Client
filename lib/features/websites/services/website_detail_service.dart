import '../../../api/v2/website_v2.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/website_models.dart';

class WebsiteDetailService {
  WebsiteV2Api? _api;

  Future<void> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getWebsiteApi();
  }

  Future<WebsiteInfo> fetchWebsiteDetail(int websiteId) async {
    await _ensureApi();
    return _api!.getWebsiteDetail(websiteId);
  }

  Future<void> operateWebsite({
    required int websiteId,
    required String action,
  }) async {
    await _ensureApi();
    await _api!.operateWebsite(id: websiteId, operate: action);
  }
}
