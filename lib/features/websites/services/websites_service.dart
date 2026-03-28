import '../../../data/repositories/website_repository.dart';
import '../../../data/models/website_models.dart';

class WebsitesService {
  WebsitesService({WebsiteRepository? repository})
      : _repository = repository ?? WebsiteRepository();

  final WebsiteRepository _repository;

  Future<List<WebsiteInfo>> fetchWebsites({
    int page = 1,
    int pageSize = 100,
  }) async {
    final result = await _repository.searchWebsites(
      page: page,
      pageSize: pageSize,
    );
    return result.items;
  }

  Future<void> operateWebsite({
    required int websiteId,
    required String action,
  }) async {
    await _repository.operateWebsite(websiteId: websiteId, action: action);
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
    await _repository.deleteWebsite(websiteId);
  }
}
