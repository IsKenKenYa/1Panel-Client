import '../../../data/repositories/website_repository.dart';
import '../../../data/models/website_models.dart';

class WebsiteDetailService {
  WebsiteDetailService({WebsiteRepository? repository})
      : _repository = repository ?? WebsiteRepository();

  final WebsiteRepository _repository;

  Future<WebsiteInfo> fetchWebsiteDetail(int websiteId) async {
    return _repository.getWebsiteDetail(websiteId);
  }

  Future<void> operateWebsite({
    required int websiteId,
    required String action,
  }) async {
    await _repository.operateWebsite(websiteId: websiteId, action: action);
  }
}
