import 'package:onepanel_client/api/v2/runtime_v2.dart' as runtime_api;
import 'package:onepanel_client/api/v2/website_group_v2.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';

class WebsiteRepository {
  WebsiteRepository({
    WebsiteV2Api? websiteApi,
    WebsiteGroupV2Api? groupApi,
    runtime_api.RuntimeV2Api? runtimeApi,
  })  : _websiteApi = websiteApi,
        _groupApi = groupApi,
        _runtimeApi = runtimeApi;

  WebsiteV2Api? _websiteApi;
  WebsiteGroupV2Api? _groupApi;
  runtime_api.RuntimeV2Api? _runtimeApi;

  Future<WebsiteV2Api> _ensureWebsiteApi() async {
    _websiteApi ??= await ApiClientManager.instance.getWebsiteApi();
    return _websiteApi!;
  }

  Future<WebsiteGroupV2Api> _ensureGroupApi() async {
    _groupApi ??=
        WebsiteGroupV2Api(await ApiClientManager.instance.getCurrentClient());
    return _groupApi!;
  }

  Future<runtime_api.RuntimeV2Api> _ensureRuntimeApi() async {
    _runtimeApi ??= await ApiClientManager.instance.getRuntimeApi();
    return _runtimeApi!;
  }

  Future<PageResult<WebsiteInfo>> searchWebsites({
    String? name,
    String? type,
    int page = 1,
    int pageSize = 100,
  }) async {
    final api = await _ensureWebsiteApi();
    return api.getWebsites(
      name: name,
      type: type,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<WebsiteInfo>> listWebsites() async {
    final api = await _ensureWebsiteApi();
    return api.listWebsites();
  }

  Future<WebsiteInfo> getWebsiteDetail(int id) async {
    final api = await _ensureWebsiteApi();
    return api.getWebsiteDetail(id);
  }

  Future<void> createWebsite(WebsiteCreate request) async {
    final api = await _ensureWebsiteApi();
    await api.createWebsite(request);
  }

  Future<void> updateWebsite(Map<String, dynamic> request) async {
    final api = await _ensureWebsiteApi();
    await api.updateWebsite(request);
  }

  Future<void> startWebsite(int id) async {
    final api = await _ensureWebsiteApi();
    await api.startWebsite(id);
  }

  Future<void> stopWebsite(int id) async {
    final api = await _ensureWebsiteApi();
    await api.stopWebsite(id);
  }

  Future<void> restartWebsite(int id) async {
    final api = await _ensureWebsiteApi();
    await api.restartWebsite(id);
  }

  Future<void> operateWebsite({
    required int websiteId,
    required String action,
  }) async {
    final api = await _ensureWebsiteApi();
    await api.operateWebsite(id: websiteId, operate: action);
  }

  Future<void> deleteWebsite(int id) async {
    final api = await _ensureWebsiteApi();
    await api.deleteWebsite(id);
  }

  Future<void> batchOperate({
    required List<int> ids,
    required String operate,
  }) async {
    final api = await _ensureWebsiteApi();
    await api.batchOperateWebsites(ids: ids, operate: operate);
  }

  Future<void> batchSetGroup({
    required List<int> ids,
    required int groupId,
  }) async {
    final api = await _ensureWebsiteApi();
    await api.batchSetWebsiteGroup(ids: ids, groupId: groupId);
  }

  Future<void> batchSetHttps({
    required List<int> ids,
    required bool https,
  }) async {
    final api = await _ensureWebsiteApi();
    await api.batchSetWebsiteHttps(ids: ids, https: https);
  }

  Future<void> changeDefaultServer({required int id}) async {
    final api = await _ensureWebsiteApi();
    await api.changeDefaultServer(id: id);
  }

  Future<Map<String, dynamic>> getDefaultHtml(String type) async {
    final api = await _ensureWebsiteApi();
    return api.getDefaultHtml(type);
  }

  Future<void> updateDefaultHtml({
    required String type,
    required String content,
  }) async {
    final api = await _ensureWebsiteApi();
    await api.updateDefaultHtml(type: type, content: content);
  }

  Future<List<Map<String, dynamic>>> preCheckWebsite(
    Map<String, dynamic> request,
  ) async {
    final api = await _ensureWebsiteApi();
    return api.preCheckWebsite(request);
  }

  Future<List<Map<String, dynamic>>> getWebsiteOptions({
    String type = 'all',
  }) async {
    final api = await _ensureWebsiteApi();
    return api.getWebsiteOptions({'type': type});
  }

  Future<List<RuntimeInfo>> listPhpRuntimes() async {
    final api = await _ensureRuntimeApi();
    final response = await api.getRuntimes(
      const RuntimeSearch(
        page: 1,
        pageSize: 100,
        type: 'php',
        status: 'Running',
      ),
    );
    return response.data?.items
            .map(
              (runtime) => RuntimeInfo(
                id: runtime.id,
                name: runtime.name,
                type: runtime.type,
                version: runtime.version,
                status: runtime.status,
              ),
            )
            .toList(growable: false) ??
        const <RuntimeInfo>[];
  }

  Future<List<WebsiteGroup>> listWebsiteGroups() async {
    final groupApi = await _ensureGroupApi();
    final response = await groupApi.searchGroups(
      const WebsiteGroupSearch(page: 1, pageSize: 100).toJson(),
    );
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
    return items
        .whereType<Map<String, dynamic>>()
        .map(WebsiteGroup.fromJson)
        .toList();
  }
}
