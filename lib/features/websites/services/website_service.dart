import '../../../api/v2/website_group_v2.dart';
import '../../../api/v2/website_v2.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/common_models.dart';
import '../../../data/models/website_group_models.dart';
import '../../../data/models/website_models.dart';

class WebsiteService {
  WebsiteService({
    WebsiteV2Api? api,
    WebsiteGroupV2Api? groupApi,
  })  : _api = api,
        _groupApi = groupApi;

  WebsiteV2Api? _api;
  WebsiteGroupV2Api? _groupApi;

  Future<WebsiteV2Api> _ensureApi() async {
    _api ??= await ApiClientManager.instance.getWebsiteApi();
    return _api!;
  }

  Future<WebsiteGroupV2Api> _ensureGroupApi() async {
    _groupApi ??= WebsiteGroupV2Api(await ApiClientManager.instance.getCurrentClient());
    return _groupApi!;
  }

  Future<PageResult<WebsiteInfo>> searchWebsites({
    String? name,
    String? type,
    int page = 1,
    int pageSize = 100,
  }) async {
    final api = await _ensureApi();
    return api.getWebsites(
      name: name,
      type: type,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<WebsiteInfo>> listWebsites() async {
    final api = await _ensureApi();
    return api.listWebsites();
  }

  Future<WebsiteInfo> getWebsiteDetail(int id) async {
    final api = await _ensureApi();
    return api.getWebsiteDetail(id);
  }

  Future<void> createWebsite(WebsiteCreate request) async {
    final api = await _ensureApi();
    await api.createWebsite(request);
  }

  Future<void> updateWebsite(Map<String, dynamic> request) async {
    final api = await _ensureApi();
    await api.updateWebsite(request);
  }

  Future<void> startWebsite(int id) async {
    final api = await _ensureApi();
    await api.startWebsite(id);
  }

  Future<void> stopWebsite(int id) async {
    final api = await _ensureApi();
    await api.stopWebsite(id);
  }

  Future<void> restartWebsite(int id) async {
    final api = await _ensureApi();
    await api.restartWebsite(id);
  }

  Future<void> deleteWebsite(int id) async {
    final api = await _ensureApi();
    await api.deleteWebsite(id);
  }

  Future<void> batchOperate({
    required List<int> ids,
    required String operate,
  }) async {
    final api = await _ensureApi();
    await api.batchOperateWebsites(ids: ids, operate: operate);
  }

  Future<void> batchSetGroup({
    required List<int> ids,
    required int groupId,
  }) async {
    final api = await _ensureApi();
    await api.batchSetWebsiteGroup(ids: ids, groupId: groupId);
  }

  Future<void> batchSetHttps({
    required List<int> ids,
    required bool https,
  }) async {
    final api = await _ensureApi();
    await api.batchSetWebsiteHttps(ids: ids, https: https);
  }

  Future<void> changeDefaultServer(int id) async {
    final api = await _ensureApi();
    await api.changeDefaultServer(id: id);
  }

  Future<Map<String, dynamic>> getDefaultHtml(String type) async {
    final api = await _ensureApi();
    return api.getDefaultHtml(type);
  }

  Future<void> updateDefaultHtml({
    required String type,
    required String content,
  }) async {
    final api = await _ensureApi();
    await api.updateDefaultHtml(type: type, content: content);
  }

  Future<List<Map<String, dynamic>>> preCheck(Map<String, dynamic> request) async {
    final api = await _ensureApi();
    return api.preCheckWebsite(request);
  }

  Future<List<Map<String, dynamic>>> getWebsiteOptions({String type = 'all'}) async {
    final api = await _ensureApi();
    return api.getWebsiteOptions({'type': type});
  }

  Future<List<WebsiteGroup>> listWebsiteGroups() async {
    final groupApi = await _ensureGroupApi();
    final response = await groupApi.searchGroups(const WebsiteGroupSearch(page: 1, pageSize: 100).toJson());
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return const <WebsiteGroup>[];
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return const <WebsiteGroup>[];
    }
    final items = data['items'];
    if (items is! List) {
      return const <WebsiteGroup>[];
    }
    return items.whereType<Map<String, dynamic>>().map(WebsiteGroup.fromJson).toList();
  }
}
