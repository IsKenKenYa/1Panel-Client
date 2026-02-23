import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/common_models.dart';
import '../../data/models/file/file_info.dart';
import '../../data/models/website_models.dart';

class WebsiteV2Api {
  final DioClient _client;

  WebsiteV2Api(this._client);

  static Map<String, dynamic> _extractMapData(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) return <String, dynamic>{};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  static List<dynamic> _extractListData(Response<Map<String, dynamic>> response) {
    final body = response.data;
    if (body == null) return const <dynamic>[];
    final data = body['data'];
    if (data is List) return data;
    return const <dynamic>[];
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
    String? status,
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
      status: status,
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

  Future<void> deleteWebsite(int id) async {
    final operation = BatchDelete(ids: [id]);
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/del'),
      data: operation.toJson(),
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

  Future<void> restartWebsite(int id) => operateWebsite(id: id, operate: 'restart');

  Future<FileInfo> getWebsiteConfigFile({
    required int id,
    required String type,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/$id/config/$type'),
    );
    return FileInfo.fromJson(_extractMapData(response));
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
    return list.map((e) => WebsiteDomain.fromJson(e as Map<String, dynamic>)).toList();
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
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/domains/update'),
      data: {
        'id': id,
        if (ssl != null) 'ssl': ssl,
      },
    );
  }

  Future<Map<String, dynamic>> getWebsiteHttps(int websiteId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/$websiteId/https'),
    );
    return _extractMapData(response);
  }

  Future<Map<String, dynamic>> updateWebsiteHttps({
    required int websiteId,
    required Map<String, dynamic> request,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/$websiteId/https'),
      data: request,
    );
    return _extractMapData(response);
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
