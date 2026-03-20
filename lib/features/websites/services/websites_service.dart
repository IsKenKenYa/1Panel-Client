import '../../../api/v2/website_v2.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/website_models.dart';

class WebsitesService {
  WebsiteV2Api? _api;

  Future<void> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getWebsiteApi();
  }

  Future<List<WebsiteInfo>> fetchWebsites({
    int page = 1,
    int pageSize = 100,
  }) async {
    await _ensureApi();
    final result = await _api!.getWebsites(page: page, pageSize: pageSize);
    return result.items;
  }

  Future<void> operateWebsite({
    required int websiteId,
    required String action,
  }) async {
    await _ensureApi();
    await _api!.operateWebsite(id: websiteId, operate: action);
  }

  Future<void> startWebsite(int websiteId) {
    return operateWebsite(websiteId: websiteId, action: 'start');
  }

  Future<void> stopWebsite(int websiteId) {
    return operateWebsite(websiteId: websiteId, action: 'stop');
  }

  Future<void> restartWebsite(int websiteId) {
    return operateWebsite(websiteId: websiteId, action: 'restart');
  }

  Future<void> deleteWebsite(int websiteId) async {
    await _ensureApi();
    await _api!.deleteWebsite(websiteId);
  }
}
