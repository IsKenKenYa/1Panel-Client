import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/websites/providers/website_detail_provider.dart';
import 'package:onepanel_client/features/websites/providers/website_lifecycle_provider.dart';
import 'package:onepanel_client/features/websites/providers/websites_provider.dart';
import 'package:onepanel_client/features/websites/services/website_service.dart';

class FakeWebsiteService extends WebsiteService {
  PageResult<WebsiteInfo> searchResult;
  List<WebsiteGroup> groupResult;
  List<RuntimeInfo> runtimeResult;
  List<WebsiteInfo> parentResult;
  WebsiteInfo? detailResult;

  FakeWebsiteService({
    this.searchResult = const PageResult<WebsiteInfo>(items: [], total: 0),
    this.groupResult = const [],
    this.runtimeResult = const [],
    this.parentResult = const [],
    this.detailResult,
  });

  String? lastSearchName;
  String? lastSearchType;
  int? lastBatchGroupId;
  List<int>? lastBatchIds;
  String? lastBatchAction;
  WebsiteCreate? createdRequest;
  WebsiteUpdate? updatedRequest;
  int? lastDefaultId;

  @override
  Future<PageResult<WebsiteInfo>> searchWebsites({
    String? name,
    String? type,
    int page = 1,
    int pageSize = 100,
  }) async {
    lastSearchName = name;
    lastSearchType = type;
    return searchResult;
  }

  @override
  Future<List<WebsiteGroup>> listWebsiteGroups() async => groupResult;

  @override
  Future<void> batchOperate({
    required List<int> ids,
    required String operate,
  }) async {
    lastBatchIds = ids;
    lastBatchAction = operate;
  }

  @override
  Future<void> batchSetGroup({
    required List<int> ids,
    required int groupId,
  }) async {
    lastBatchIds = ids;
    lastBatchGroupId = groupId;
  }

  @override
  Future<List<RuntimeInfo>> listPhpRuntimes() async => runtimeResult;

  @override
  Future<List<WebsiteInfo>> listParentWebsites() async => parentResult;

  @override
  Future<WebsiteInfo> getWebsiteDetail(int id) async {
    return detailResult ??
        const WebsiteInfo(
          id: 1,
          primaryDomain: 'example.com',
          alias: 'example',
          type: 'runtime',
          webSiteGroupId: 1,
          runtimeId: 10,
        );
  }

  @override
  Future<List<Map<String, dynamic>>> preCheck(Map<String, dynamic> request) async {
    return const [];
  }

  @override
  Future<void> createWebsite(WebsiteCreate request) async {
    createdRequest = request;
  }

  @override
  Future<void> updateWebsiteByModel(WebsiteUpdate request) async {
    updatedRequest = request;
  }

  @override
  Future<void> changeDefaultServer(int id) async {
    lastDefaultId = id;
  }

  @override
  Future<void> operateWebsite({
    required int websiteId,
    required String action,
  }) async {
    lastBatchIds = [websiteId];
    lastBatchAction = action;
  }
}

void main() {
  test('WebsitesProvider applies search/type/group filters', () async {
    final service = FakeWebsiteService(
      searchResult: const PageResult(
        items: [
          WebsiteInfo(id: 1, primaryDomain: 'a.com', webSiteGroupId: 1),
          WebsiteInfo(id: 2, primaryDomain: 'b.com', webSiteGroupId: 2),
        ],
        total: 2,
      ),
      groupResult: const [
        WebsiteGroup(id: 1, name: 'prod'),
        WebsiteGroup(id: 2, name: 'test'),
      ],
    );
    final provider = WebsitesProvider(service: service);

    await provider.loadWebsites(
      query: 'demo',
      type: 'runtime',
      websiteGroupId: 1,
    );

    expect(service.lastSearchName, 'demo');
    expect(service.lastSearchType, 'runtime');
    expect(provider.data.websites, hasLength(1));
    expect(provider.data.groupFilterId, 1);
    expect(provider.data.groups, hasLength(2));
  });

  test('WebsitesProvider batchSetGroup delegates to service', () async {
    final service = FakeWebsiteService();
    final provider = WebsitesProvider(service: service);

    final ok = await provider.batchSetGroup(ids: const [1, 2], groupId: 3);

    expect(ok, isTrue);
    expect(service.lastBatchIds, [1, 2]);
    expect(service.lastBatchGroupId, 3);
  });

  test('WebsiteLifecycleProvider create submits WebsiteCreate', () async {
    final service = FakeWebsiteService(
      groupResult: const [WebsiteGroup(id: 1, name: 'prod')],
      runtimeResult: const [RuntimeInfo(id: 10, name: 'php-8.2')],
    );
    final provider = WebsiteLifecycleProvider(
      mode: WebsiteLifecycleMode.create,
      service: service,
    );

    await provider.load();
    provider.setAlias('main-site');
    provider.setPrimaryDomain('example.com');
    provider.setGroupId(1);
    provider.setRuntimeId(10);
    provider.setSiteDir('/opt/www/example');

    final ok = await provider.submit();

    expect(ok, isTrue);
    expect(service.createdRequest, isNotNull);
    expect(service.createdRequest!.alias, 'main-site');
    expect(service.createdRequest!.domains!.first.domain, 'example.com');
  });

  test('WebsiteLifecycleProvider edit submits WebsiteUpdate', () async {
    final service = FakeWebsiteService(
      groupResult: const [WebsiteGroup(id: 2, name: 'ops')],
      detailResult: const WebsiteInfo(
        id: 9,
        primaryDomain: 'old.com',
        alias: 'old',
        type: 'runtime',
        webSiteGroupId: 2,
        ipv6: true,
        favorite: true,
      ),
    );
    final provider = WebsiteLifecycleProvider(
      mode: WebsiteLifecycleMode.edit,
      websiteId: 9,
      service: service,
    );

    await provider.load();
    provider.setPrimaryDomain('new.com');
    provider.setRemark('updated');
    provider.setGroupId(2);

    final ok = await provider.submit();

    expect(ok, isTrue);
    expect(service.updatedRequest, isNotNull);
    expect(service.updatedRequest!.primaryDomain, 'new.com');
    expect(service.updatedRequest!.id, 9);
  });

  test('WebsiteDetailProvider setDefaultServer delegates to service', () async {
    final service = FakeWebsiteService();
    final provider = WebsiteDetailProvider(
      websiteId: 5,
      service: service,
    );

    await provider.setDefaultServer();

    expect(service.lastDefaultId, 5);
  });
}
