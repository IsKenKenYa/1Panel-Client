import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/network_exceptions.dart';
import '../../data/models/common_models.dart';
import '../../data/models/host_asset_models.dart';
import '../../data/models/host_models.dart';
import '../../data/models/host_tree_models.dart';
import 'api_response_parser.dart';

/// 1Panel host management API client.
///
/// Supports CRUD, connection testing, and tree queries with automatic legacy endpoint fallback.
class HostV2Api {
  HostV2Api(this._client);

  final DioClient _client;

  // 1Panel 2.x moved host endpoints from /hosts/* to /core/hosts/*.
  // Older servers return 404/405 for the new paths, or 200 + SPA HTML
  // fallback page (surfaced as EndpointNotFoundException by DioClient),
  // so we fall back.
  bool _shouldFallbackToLegacy(Object error) {
    if (error is EndpointNotFoundException) {
      return true;
    }
    int? statusCode;
    if (error is DioException) {
      statusCode = error.response?.statusCode;
    } else if (error is NetworkException) {
      // DioClient 统一将 DioException 转换为 NetworkException 子类抛出，
      // 404/405 场景实际以 HttpException 形态到达这里。
      statusCode = error.statusCode;
    }
    return statusCode == 404 || statusCode == 405;
  }

  /// Tries [primaryPath] first; on 404/405 (or SPA HTML fallback) retries
  /// with [legacyPath].
  Future<Response<T>> _postWithLegacyFallback<T>({
    required String primaryPath,
    required String legacyPath,
    Object? data,
  }) async {
    try {
      return await _client.post<T>(
        ApiConstants.buildApiPath(primaryPath),
        data: data,
      );
    } catch (error) {
      if (!_shouldFallbackToLegacy(error)) {
        rethrow;
      }
      return _client.post<T>(
        ApiConstants.buildApiPath(legacyPath),
        data: data,
      );
    }
  }

  // Legacy path puts the ID in the request body, not the URL path.
  Future<Response<Map<String, dynamic>>> _postHostByIdWithFallback(
    int id,
  ) async {
    try {
      return await _client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/core/hosts/test/byid/$id'),
      );
    } catch (error) {
      if (!_shouldFallbackToLegacy(error)) {
        rethrow;
      }
      return _client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/hosts/test/byid'),
        data: <String, dynamic>{'id': id},
      );
    }
  }

  /// GET 版本的主路径与旧路径回退，响应体交给调用方转换。
  Future<Response<T>> _getWithLegacyFallback<T>({
    required String primaryPath,
    required String legacyPath,
    required T Function(dynamic data) parse,
  }) async {
    Response<Map<String, dynamic>> raw;
    try {
      raw = await _client.get<Map<String, dynamic>>(
        ApiConstants.buildApiPath(primaryPath),
      );
    } catch (error) {
      if (!_shouldFallbackToLegacy(error)) {
        rethrow;
      }
      raw = await _client.get<Map<String, dynamic>>(
        ApiConstants.buildApiPath(legacyPath),
      );
    }
    return Response<T>(
      data: parse(raw.data),
      statusCode: raw.statusCode,
      statusMessage: raw.statusMessage,
      requestOptions: raw.requestOptions,
    );
  }

  Future<Response<void>> createHost(HostCreate request) {
    return _postWithLegacyFallback<void>(
      primaryPath: '/core/hosts',
      legacyPath: '/hosts',
      data: _mapHostPayload(request),
    );
  }

  Future<Response<void>> createHostAsset(HostOperate request) {
    return _postWithLegacyFallback<void>(
      primaryPath: '/core/hosts',
      legacyPath: '/hosts',
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteHost(OperateByIDs request) {
    return _postWithLegacyFallback<void>(
      primaryPath: '/core/hosts/del',
      legacyPath: '/hosts/del',
      data: request.toJson(),
    );
  }

  Future<Response<HostInfo>> updateHost(HostUpdate request) async {
    final response = await _postWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/update',
      legacyPath: '/hosts/update',
      data: _mapHostPayload(request, id: request.id),
    );
    return Response<HostInfo>(
      data: HostInfo.fromJson(ApiResponseParser.asMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<HostInfo>> updateHostAsset(HostOperate request) async {
    final response = await _postWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/update',
      legacyPath: '/hosts/update',
      data: request.toJson(),
    );
    return Response<HostInfo>(
      data: HostInfo.fromJson(ApiResponseParser.asMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<HostInfo>>> searchHosts(HostSearch request) async {
    final response = await _postWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/search',
      legacyPath: '/hosts/search',
      data: request.toJson(),
    );
    return Response<PageResult<HostInfo>>(
      data: PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) => HostInfo.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<HostInfo>>> searchHostAssets(
    HostSearchRequest request,
  ) async {
    final response = await _postWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/search',
      legacyPath: '/hosts/search',
      data: request.toJson(),
    );
    return Response<PageResult<HostInfo>>(
      data: PageResult.fromJson(
        ApiResponseParser.asMap(response.data),
        (dynamic item) => HostInfo.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<HostInfo>> getHostById(int id) async {
    final response = await _postWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/info',
      legacyPath: '/hosts/info',
      data: OperateByID(id: id).toJson(),
    );
    return Response<HostInfo>(
      data: HostInfo.fromJson(ApiResponseParser.asMap(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<Map<String, dynamic>>>> getHostTree(
    SearchWithPage request,
  ) async {
    final response = await _postWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/tree',
      legacyPath: '/hosts/tree',
      data: request.toJson(),
    );
    final rawItems = ApiResponseParser.asList(response.data);
    return Response<List<Map<String, dynamic>>>(
      data: rawItems.whereType<Map<String, dynamic>>().toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<HostTreeNode>>> getHostAssetTree({
    String? info,
  }) async {
    final response = await _postWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/tree',
      legacyPath: '/hosts/tree',
      data: <String, dynamic>{'info': info ?? ''},
    );
    final rawItems = ApiResponseParser.asList(response.data);
    return Response<List<HostTreeNode>>(
      data: rawItems
          .whereType<Map<String, dynamic>>()
          .map(HostTreeNode.fromJson)
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<bool>> testHostByInfo(HostCreate request) async {
    final response = await _postWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/test/byinfo',
      legacyPath: '/hosts/test/byinfo',
      data: _mapHostPayload(request),
    );
    return Response<bool>(
      data: ApiResponseParser.asPrimitive<bool>(response.data) ?? false,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<bool>> testHostAssetByInfo(HostConnTest request) async {
    final response = await _postWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/test/byinfo',
      legacyPath: '/hosts/test/byinfo',
      data: request.toJson(),
    );
    return Response<bool>(
      data: ApiResponseParser.asPrimitive<bool>(response.data) ?? false,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<bool>> testHostById(int id) async {
    final response = await _postHostByIdWithFallback(id);
    return Response<bool>(
      data: ApiResponseParser.asPrimitive<bool>(response.data) ?? false,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> updateHostGroup({
    required int id,
    required int groupId,
  }) {
    return _postWithLegacyFallback<void>(
      primaryPath: '/core/hosts/update/group',
      legacyPath: '/hosts/update/group',
      data: <String, dynamic>{
        'id': id,
        'groupID': groupId,
      },
    );
  }

  Future<Response<void>> updateHostAssetGroup(HostGroupChange request) {
    return _postWithLegacyFallback<void>(
      primaryPath: '/core/hosts/update/group',
      legacyPath: '/hosts/update/group',
      data: request.toJson(),
    );
  }

  Future<Response<Map<String, dynamic>>> getHostComponent(String name) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/components/$name'),
    );
    return Response<Map<String, dynamic>>(
      data: ApiResponseParser.asMap(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ── 诊断与 SSH 日志清理（V2 新增）──

  /// 获取诊断摘要（goroutine/内存等概览）。
  ///
  /// 2.x 主路径为 `/core/hosts/diagnostics/*`，旧服务端只暴露 `/hosts/*`。
  Future<Response<Map<String, dynamic>>> getDiagnosticsSummary() {
    return _getWithLegacyFallback<Map<String, dynamic>>(
      primaryPath: '/core/hosts/diagnostics/summary',
      legacyPath: '/hosts/diagnostics/summary',
      parse: ApiResponseParser.asMap,
    );
  }

  /// 获取 goroutine 转储。
  Future<Response<String>> getDiagnosticsGoroutines() {
    return _getWithLegacyFallback<String>(
      primaryPath: '/core/hosts/diagnostics/goroutines',
      legacyPath: '/hosts/diagnostics/goroutines',
      // goroutine 转储以纯文本返回，同时兼容 `{data: text}` 信封。
      parse: (dynamic payload) =>
          ApiResponseParser.asStringOrNull(payload) ?? payload?.toString() ?? '',
    );
  }

  /// 创建运行时性能剖析（type: heap|cpu|mutex|block|goroutine|trace）。
  Future<Response<void>> createRuntimeProfile({
    required String type,
    int? duration,
  }) {
    return _postWithLegacyFallback<void>(
      primaryPath: '/core/hosts/diagnostics/profiles',
      legacyPath: '/hosts/diagnostics/profiles',
      data: <String, dynamic>{
        'type': type,
        if (duration != null) 'duration': duration,
      },
    );
  }

  /// 清理 SSH 登录日志。
  Future<Response<void>> cleanSshLog() {
    return _client.post(
      ApiConstants.buildApiPath('/hosts/ssh/log/clean'),
    );
  }

  Map<String, dynamic> _mapHostPayload(HostCreate request, {int? id}) {
    final hasKeyAuth = (request.privateKey?.isNotEmpty ?? false);
    return <String, dynamic>{
      if (id != null) 'id': id,
      'name': request.name,
      'addr': request.address,
      'port': request.port,
      'user': request.username,
      'password': request.password ?? '',
      'privateKey': request.privateKey ?? '',
      'passPhrase': '',
      'authMode': hasKeyAuth ? 'key' : 'password',
      'rememberPassword':
          !hasKeyAuth && (request.password?.isNotEmpty ?? false),
      'description': request.description ?? '',
      if (request.groupID != null) 'groupID': int.tryParse(request.groupID!),
    }..removeWhere((String _, dynamic value) => value == null);
  }
}
