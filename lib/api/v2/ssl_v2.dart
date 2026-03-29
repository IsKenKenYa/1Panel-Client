import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/ssl_models.dart';
import '../../data/models/common_models.dart';

class SSLV2Api {
  final DioClient _client;

  SSLV2Api(this._client);

  /// 创建网站SSL证书
  ///
  /// 为网站创建SSL证书
  /// @param ssl 网站SSL配置
  /// @return 创建结果
  Future<Response> createWebsiteSSL(WebsiteSSLCreate ssl) async {
    return await _client.post(
      ApiConstants.buildApiPath('/websites/ssl'),
      data: ssl.toJson(),
    );
  }

  /// 根据ID搜索网站SSL证书
  ///
  /// 获取指定ID的网站SSL证书详情
  /// @param id SSL证书ID
  /// @return SSL证书详情
  Future<Response<WebsiteSSL>> getWebsiteSSLById(int id) async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/websites/ssl/$id'),
    );
    return Response(
      data: WebsiteSSL.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 删除网站SSL证书
  ///
  /// 删除指定的网站SSL证书
  /// @param ids SSL证书ID列表
  /// @return 删除结果
  Future<Response> deleteWebsiteSSL(List<int> ids) async {
    final operation = BatchDelete(ids: ids);
    return await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/del'),
      data: operation.toJson(),
    );
  }

  /// 下载SSL文件
  ///
  /// 下载网站SSL证书文件
  /// @param id SSL证书ID
  /// @return 下载链接
  Future<Response<String>> downloadSSLFile(int id) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/download'),
      data: {'id': id},
    );
    return Response(
      data: response.data.toString(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 申请SSL证书
  ///
  /// 为网站申请SSL证书
  /// @param sslApply SSL申请配置
  /// @return 申请结果
  Future<Response> applySSL(WebsiteSSLApply sslApply) async {
    return await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/obtain'),
      data: sslApply.toJson(),
    );
  }

  /// 解析网站SSL
  ///
  /// 解析网站SSL证书状态和配置
  /// @param sslResolve SSL解析配置
  /// @return 解析结果
  Future<Response<WebsiteSSL>> resolveWebsiteSSL(
      WebsiteSSLResolve sslResolve) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/resolve'),
      data: sslResolve.toJson(),
    );
    return Response(
      data: WebsiteSSL.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 分页搜索网站SSL证书
  ///
  /// 分页搜索网站SSL证书列表
  /// @param search 搜索请求
  /// @return SSL证书分页列表
  Future<Response<PageResult<WebsiteSSL>>> searchWebsiteSSL(
      WebsiteSSLSearch search) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/search'),
      data: search.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => WebsiteSSL.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<WebsiteSSL>>> listWebsiteSSL(
      WebsiteSSLSearch request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/websites/ssl/list'),
      data: request.toJson(),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<WebsiteSSL>>(
      data: rawItems
          .whereType<Map<String, dynamic>>()
          .map(WebsiteSSL.fromJson)
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新SSL证书
  ///
  /// 更新网站SSL证书配置
  /// @param ssl SSL更新配置
  /// @return 更新结果
  Future<Response> updateWebsiteSSL(WebsiteSSLUpdate ssl) async {
    return await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/update'),
      data: ssl.toJson(),
    );
  }

  /// 上传SSL证书
  ///
  /// 上传SSL证书文件
  /// @param sslUpload SSL上传配置
  /// @return 上传结果
  Future<Response> uploadSSL(WebsiteSSLUpload sslUpload) async {
    return await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/upload'),
      data: sslUpload.toJson(),
    );
  }

  Future<Response> uploadSSLFile(FormData formData) async {
    return await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/upload/file'),
      data: formData,
    );
  }

  /// 根据网站ID搜索SSL证书
  ///
  /// 获取指定网站的SSL证书信息
  /// @param websiteId 网站ID
  /// @return SSL证书信息
  Future<Response<WebsiteSSL>> getWebsiteSSLByWebsiteId(int websiteId) async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/websites/ssl/website/$websiteId'),
    );
    return Response(
      data: WebsiteSSL.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取SSL选项
  ///
  /// 获取SSL证书操作的可用选项
  /// @return SSL选项列表
  Future<Response<List<Map<String, dynamic>>>> getSSLOptions() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/websites/ssl/options'),
    );
    return Response(
      data: (response.data as List?)
              ?.map((item) => item as Map<String, dynamic>)
              .toList() ??
          [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 验证SSL证书配置
  ///
  /// 验证SSL证书配置的正确性
  /// @param sslConfig SSL配置信息
  /// @return 验证结果
  Future<Response<Map<String, dynamic>>> validateSSLConfig(
      Map<String, dynamic> sslConfig) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/validate'),
      data: sslConfig,
    );
    return Response(
      data: response.data as Map<String, dynamic>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 自动续期SSL证书
  ///
  /// 自动续期即将过期的SSL证书
  /// @param ids SSL证书ID列表
  /// @return 续期结果
  Future<Response> autoRenewSSL(List<int> ids) async {
    final operation = BatchDelete(ids: ids);
    return await _client.post(
      ApiConstants.buildApiPath('/websites/ssl/auto-renew'),
      data: operation.toJson(),
    );
  }

  /// 获取SSL证书申请状态
  ///
  /// 获取SSL证书申请的当前状态
  /// @param id 申请ID
  /// @return 申请状态
  Future<Response<Map<String, dynamic>>> getSSLApplicationStatus(int id) async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/websites/ssl/application/$id/status'),
    );
    return Response(
      data: response.data as Map<String, dynamic>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // 系统 SSL 证书管理相关方法
  /// 下载系统证书
  ///
  /// 下载系统 SSL 证书文件
  /// @return 证书下载链接
  Future<Response<String>> downloadSystemCert() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/settings/ssl/download'),
    );
    return Response(
      data: response.data.toString(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取系统证书信息
  ///
  /// 获取系统 SSL 证书的详细信息
  /// @return 系统证书信息
  Future<Response<Map<String, dynamic>>> loadSystemCertInfo() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/settings/ssl/info'),
    );
    return Response(
      data: response.data as Map<String, dynamic>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新系统SSL证书
  ///
  /// 更新系统 SSL 证书
  /// @param certData 证书数据
  /// @return 更新结果
  Future<Response> updateSystemSSL(Map<String, dynamic> certData) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/ssl/update'),
      data: certData,
    );
  }
}
