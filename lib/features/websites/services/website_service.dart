import '../../../data/models/common_models.dart';
import '../../../data/models/runtime_models.dart';
import '../../../data/models/website_group_models.dart';
import '../../../data/models/website_models.dart';
import '../../../data/repositories/website_repository.dart';

class WebsiteService {
  WebsiteService({WebsiteRepository? repository})
      : _repository = repository ?? WebsiteRepository();

  final WebsiteRepository _repository;

  Future<PageResult<WebsiteInfo>> searchWebsites({
    String? name,
    String? type,
    int page = 1,
    int pageSize = 100,
  }) async {
    return _repository.searchWebsites(
      name: name,
      type: type,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<WebsiteInfo>> listWebsites() async {
    return _repository.listWebsites();
  }

  Future<WebsiteInfo> getWebsiteDetail(int id) async {
    return _repository.getWebsiteDetail(id);
  }

  Future<void> createWebsite(WebsiteCreate request) async {
    await _repository.createWebsite(request);
  }

  Future<void> updateWebsite(Map<String, dynamic> request) async {
    await _repository.updateWebsite(request);
  }

  Future<void> updateWebsiteByModel(WebsiteUpdate request) {
    return updateWebsite(request.toJson());
  }

  Future<void> startWebsite(int id) async {
    await _repository.startWebsite(id);
  }

  Future<void> stopWebsite(int id) async {
    await _repository.stopWebsite(id);
  }

  Future<void> restartWebsite(int id) async {
    await _repository.restartWebsite(id);
  }

  Future<void> operateWebsite({
    required int websiteId,
    required String action,
  }) {
    switch (action) {
      case 'start':
        return startWebsite(websiteId);
      case 'stop':
        return stopWebsite(websiteId);
      case 'restart':
        return restartWebsite(websiteId);
      case 'delete':
        return deleteWebsite(websiteId);
      default:
        throw ArgumentError('Unsupported website action: $action');
    }
  }

  Future<void> deleteWebsite(int id) async {
    await _repository.deleteWebsite(id);
  }

  Future<void> batchDelete({
    required List<int> ids,
  }) async {
    for (final id in ids) {
      await deleteWebsite(id);
    }
  }

  Future<void> batchOperate({
    required List<int> ids,
    required String operate,
  }) async {
    await _repository.batchOperate(ids: ids, operate: operate);
  }

  Future<void> batchSetGroup({
    required List<int> ids,
    required int groupId,
  }) async {
    await _repository.batchSetGroup(ids: ids, groupId: groupId);
  }

  Future<void> batchSetHttps({
    required List<int> ids,
    required bool https,
  }) async {
    await _repository.batchSetHttps(ids: ids, https: https);
  }

  Future<void> changeDefaultServer(int id) async {
    await _repository.changeDefaultServer(id: id);
  }

  Future<Map<String, dynamic>> getDefaultHtml(String type) async {
    return _repository.getDefaultHtml(type);
  }

  Future<void> updateDefaultHtml({
    required String type,
    required String content,
  }) async {
    await _repository.updateDefaultHtml(type: type, content: content);
  }

  Future<List<Map<String, dynamic>>> preCheck(
      Map<String, dynamic> request) async {
    return _repository.preCheckWebsite(request);
  }

  Future<List<Map<String, dynamic>>> getWebsiteOptions(
      {String type = 'all'}) async {
    return _repository.getWebsiteOptions(type: type);
  }

  Future<List<RuntimeInfo>> listPhpRuntimes() async {
    return _repository.listPhpRuntimes();
  }

  Future<List<WebsiteInfo>> listParentWebsites() async {
    final result = await listWebsites();
    return result.where((item) => item.id != null).toList(growable: false);
  }

  Future<List<WebsiteGroup>> listWebsiteGroups() async {
    return _repository.listWebsiteGroups();
  }
}
