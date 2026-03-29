import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/common_models.dart';
import '../../data/models/file/file_info.dart';
import '../../data/models/website_models.dart';
import '../../data/models/ssl_models.dart';

class WebsiteV2Api {
  final DioClient _client;

  WebsiteV2Api(this._client);

  static Map<String, dynamic> _extractMapData(
      Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) return <String, dynamic>{};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  static List<dynamic> _extractListData(
      Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) return const <dynamic>[];
    final data = body['data'];
    if (data is List) return data;
    return const <dynamic>[];
  }

  static dynamic _extractRawData(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) return null;
    return body['data'];
  }

  /// 获取网站列表
  ///
  /// 获取所有网站列表
  /// @param name 网站名称（可选）
  /// @param type 网站类型（可选）
  /// @param status 网站状态（可选）
  /// @param page 页码（可选，默认为1）
  /// @param pageSize 每页数量（可选，默认为10）
  /// @return 网站列表
  Future<PageResult<WebsiteInfo>> getWebsites({
    String? name,
    String? type,
    int page = 1,
    int pageSize = 10,
    String order = 'descending',
    String orderBy = 'createdAt',
  }) async {
    final request = WebsiteSearch(
      page: page,
      pageSize: pageSize,
      order: order,
      orderBy: orderBy,
      name: name,
      type: type,
    );
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/search'),
      data: request.toJson(),
    );
    return PageResult.fromJson(
      _extractMapData(response),
      (json) => WebsiteInfo.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<WebsiteInfo>> listWebsites() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/list'),
    );
    final list = _extractListData(response);
    return list
        .map((e) => WebsiteInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取网站详情
  ///
  /// 获取指定网站的详细信息
  /// @param id 网站ID
  /// @return 网站详情
  Future<WebsiteInfo> getWebsiteDetail(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/$id'),
    );
    return WebsiteInfo.fromJson(_extractMapData(response));
  }

  Future<void> createWebsite(WebsiteCreate request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites'),
      data: request.toJson(),
    );
  }

  Future<void> updateWebsite(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/update'),
      data: request,
    );
  }

  Future<List<Map<String, dynamic>>> getWebsiteOptions(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/options'),
      data: request,
    );
    final list = _extractListData(response);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> preCheckWebsite(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/check'),
      data: request,
    );
    final list = _extractListData(response);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> deleteWebsite(int id) async {
    final operation = BatchDelete(ids: [id]);
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/del'),
      data: operation.toJson(),
    );
  }

  Future<void> batchOperateWebsites({
    required List<int> ids,
    required String operate,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/batch/operate'),
      data: {
        'ids': ids,
        'operate': operate,
      },
    );
  }

  Future<void> batchSetWebsiteGroup({
    required List<int> ids,
    required int groupId,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/batch/group'),
      data: {
        'ids': ids,
        'groupId': groupId,
      },
    );
  }

  Future<void> batchSetWebsiteHttps({
    required List<int> ids,
    required bool https,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/batch/https'),
      data: {
        'ids': ids,
        'https': https,
      },
    );
  }

  Future<void> changeDefaultServer({
    required int id,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/default/server'),
      data: {'id': id},
    );
  }

  Future<Map<String, dynamic>> getDefaultHtml(String type) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/default/html/$type'),
    );
    return _extractMapData(response);
  }

  Future<void> updateDefaultHtml({
    required String type,
    required String content,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/default/html/update'),
      data: {
        'type': type,
        'content': content,
      },
    );
  }

  Future<void> operateWebsite({
    required int id,
    required String operate,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/operate'),
      data: {
        'id': id,
        'operate': operate,
      },
    );
  }

  Future<void> startWebsite(int id) => operateWebsite(id: id, operate: 'start');

  Future<void> stopWebsite(int id) => operateWebsite(id: id, operate: 'stop');

  Future<void> restartWebsite(int id) =>
      operateWebsite(id: id, operate: 'restart');

  Future<FileInfo> getWebsiteConfigFile({
    required int id,
    required String type,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/$id/config/$type'),
    );
    return FileInfo.fromJson(_extractMapData(response));
  }

  Future<Map<String, dynamic>> loadWebsiteNginxConfig(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/config'),
      data: request,
    );
    return _extractMapData(response);
  }

  Future<void> updateWebsiteNginxConfigByRequest(
      Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/config/update'),
      data: request,
    );
  }

  Future<void> updateWebsiteNginxConfig({
    required int id,
    required String content,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/nginx/update'),
      data: {
        'id': id,
        'content': content,
      },
    );
  }

  Future<List<WebsiteDomain>> getWebsiteDomains(int websiteId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/domains/$websiteId'),
    );

    final list = _extractListData(response);
    return list
        .map((e) => WebsiteDomain.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addWebsiteDomains({
    required int websiteId,
    required List<Map<String, dynamic>> domains,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/domains'),
      data: {
        'websiteID': websiteId,
        'domains': domains,
      },
    );
  }

  Future<void> deleteWebsiteDomain({required int id}) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/domains/del'),
      data: {
        'id': id,
      },
    );
  }

  Future<void> updateWebsiteDomainSsl({
    required int id,
    bool? ssl,
    String? domain,
    int? port,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/domains/update'),
      data: {
        'id': id,
        if (ssl != null) 'ssl': ssl,
        if (domain != null) 'domain': domain,
        if (port != null) 'port': port,
      },
    );
  }

  Future<WebsiteHttpsConfig> getWebsiteHttps(int websiteId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/$websiteId/https'),
    );
    return WebsiteHttpsConfig.fromJson(_extractMapData(response));
  }

  Future<Map<String, dynamic>> getWebsiteResource(int websiteId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/resource/$websiteId'),
    );
    return _extractMapData(response);
  }

  Future<List<Map<String, dynamic>>> getWebsiteDatabases() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/databases'),
    );
    final list = _extractListData(response);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> changeWebsiteDatabase(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/databases'),
      data: request,
    );
  }

  Future<WebsiteHttpsConfig> updateWebsiteHttps({
    required int websiteId,
    required WebsiteHttpsUpdateRequest request,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/$websiteId/https'),
      data: request.toJson(),
    );
    return WebsiteHttpsConfig.fromJson(_extractMapData(response));
  }

  Future<void> updateWebsitePhpVersion({
    required int websiteId,
    int? runtimeId,
  }) async {
    final request =
        WebsitePhpVersionRequest(websiteId: websiteId, runtimeId: runtimeId);
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/php/version'),
      data: request.toJson(),
    );
  }

  Future<Map<String, dynamic>> getWebsiteDirectory(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/dir'),
      data: request,
    );
    return _extractMapData(response);
  }

  Future<void> updateWebsiteDirectory(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/dir/update'),
      data: request,
    );
  }

  Future<void> updateWebsiteDirectoryPermission(
      Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/dir/permission'),
      data: request,
    );
  }

  Future<Map<String, dynamic>> getWebsiteRewrite({
    required int websiteId,
    required String name,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/rewrite'),
      data: {
        'websiteId': websiteId,
        'name': name,
      },
    );
    return _extractMapData(response);
  }

  Future<List<Map<String, dynamic>>> listCustomRewrite() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/rewrite/custom'),
    );
    final list = _extractListData(response);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> operateCustomRewrite(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/rewrite/custom'),
      data: request,
    );
  }

  Future<void> updateWebsiteRewrite({
    required int websiteId,
    required String name,
    required String content,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/rewrite/update'),
      data: {
        'websiteId': websiteId,
        'name': name,
        'content': content,
      },
    );
  }

  Future<Map<String, dynamic>> getWebsiteProxy({required int id}) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/proxies'),
      data: {
        'id': id,
      },
    );
    return _extractMapData(response);
  }

  Future<void> updateWebsiteProxyFile(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/proxies/file'),
      data: request,
    );
  }

  Future<void> deleteWebsiteProxy(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/proxies/delete'),
      data: request,
    );
  }

  Future<void> updateWebsiteProxyStatus(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/proxies/status'),
      data: request,
    );
  }

  Future<Map<String, dynamic>> getWebsiteAuthConfig(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/auths'),
      data: request,
    );
    return _extractMapData(response);
  }

  Future<List<Map<String, dynamic>>> getWebsitePathAuthConfig(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/auths/path'),
      data: request,
    );
    final list = _extractListData(response);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> updateWebsiteAuthConfig(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/auths/update'),
      data: request,
    );
  }

  Future<void> updateWebsitePathAuthConfig(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/auths/path/update'),
      data: request,
    );
  }

  Future<Map<String, dynamic>> getWebsiteCorsConfig(int websiteId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/cors/$websiteId'),
    );
    return _extractMapData(response);
  }

  Future<void> updateWebsiteCorsConfig(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/cors/update'),
      data: request,
    );
  }

  Future<void> operateCrossSiteAccess(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/crosssite'),
      data: request,
    );
  }

  Future<Map<String, dynamic>> getWebsiteRealIpConfig(int websiteId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/realip/config/$websiteId'),
    );
    return _extractMapData(response);
  }

  Future<void> updateWebsiteRealIpConfig(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/realip/config'),
      data: request,
    );
  }

  Future<Map<String, dynamic>> getWebsiteLeechConfig(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/leech'),
      data: request,
    );
    return _extractMapData(response);
  }

  Future<void> updateWebsiteLeechConfig(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/leech/update'),
      data: request,
    );
  }

  Future<List<Map<String, dynamic>>> getWebsiteRedirectConfig(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/redirect'),
      data: request,
    );
    final list = _extractListData(response);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> updateWebsiteRedirectConfig(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/redirect/update'),
      data: request,
    );
  }

  Future<void> updateWebsiteRedirectFile(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/redirect/file'),
      data: request,
    );
  }

  Future<List<Map<String, dynamic>>> getWebsiteLoadBalancers(
      int websiteId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/lbs'),
      queryParameters: {'id': websiteId},
    );
    final list = _extractListData(response);
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> createWebsiteLoadBalancer(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/lbs/create'),
      data: request,
    );
  }

  Future<void> updateWebsiteLoadBalancer(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/lbs/update'),
      data: request,
    );
  }

  Future<void> updateWebsiteLoadBalancerFile(
      Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/lbs/file'),
      data: request,
    );
  }

  Future<void> deleteWebsiteLoadBalancer(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/lbs/del'),
      data: request,
    );
  }

  Future<Map<String, dynamic>> getWebsiteProxyCacheConfig(int websiteId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/proxy/config/$websiteId'),
    );
    return _extractMapData(response);
  }

  Future<void> updateWebsiteProxyCacheConfig(
      Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/proxy/config'),
      data: request,
    );
  }

  Future<void> clearWebsiteProxyCache(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/proxy/clear'),
      data: request,
    );
  }

  Future<void> updateWebsiteStreamConfig(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/stream/update'),
      data: request,
    );
  }

  Future<void> execWebsiteComposer(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/exec/composer'),
      data: request,
    );
  }

  Future<Map<String, dynamic>> operateWebsiteLog(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/log'),
      data: request,
    );
    final raw = _extractRawData(response);
    if (raw is Map<String, dynamic>) return raw;
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> searchDnsAccounts(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/dns/search'),
      data: request,
    );
    final data = _extractMapData(response);
    final items = data['items'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<void> createDnsAccount(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/dns'),
      data: request,
    );
  }

  Future<void> updateDnsAccount(Map<String, dynamic> request) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/dns/update'),
      data: request,
    );
  }

  Future<void> deleteDnsAccount(int id) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/dns/del'),
      data: {'id': id},
    );
  }

  Future<List<Map<String, dynamic>>> searchAcmeAccounts(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/acme/search'),
      data: request,
    );
    final data = _extractMapData(response);
    final items = data['items'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> createAcmeAccount(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/acme'),
      data: request,
    );
    return _extractMapData(response);
  }

  Future<Map<String, dynamic>> updateAcmeAccount(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/acme/update'),
      data: request,
    );
    return _extractMapData(response);
  }

  Future<void> deleteAcmeAccount(int id) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/acme/del'),
      data: {'id': id},
    );
  }

  Future<List<Map<String, dynamic>>> searchCertificateAuthorities(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/ca/search'),
      data: request,
    );
    final data = _extractMapData(response);
    final items = data['items'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  Future<Map<String, dynamic>> createCertificateAuthority(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/ca'),
      data: request,
    );
    return _extractMapData(response);
  }

  Future<Map<String, dynamic>> getCertificateAuthority(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/ca/$id'),
    );
    return _extractMapData(response);
  }

  Future<void> deleteCertificateAuthority(int id) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/ca/del'),
      data: {'id': id},
    );
  }

  Future<Map<String, dynamic>> obtainCertificateByAuthority(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/ca/obtain'),
      data: request,
    );
    return _extractMapData(response);
  }

  Future<void> renewCertificateByAuthority(int sslId) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/ca/renew'),
      data: {'SSLID': sslId},
    );
  }

  Future<String> downloadCertificateAuthorityFile(int id) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/websites/ca/download'),
      data: {'id': id},
    );
    return response.data.toString();
  }

  Future<void> updateWebsiteProxy({
    required int websiteId,
    required String name,
    required String content,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/proxies/update'),
      data: {
        'websiteID': websiteId,
        'name': name,
        'content': content,
      },
    );
  }
}
