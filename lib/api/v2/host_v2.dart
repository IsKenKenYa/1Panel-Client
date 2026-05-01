import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/host_asset_models.dart';
import '../../data/models/host_models.dart';
import '../../data/models/host_tree_models.dart';
import 'api_response_parser.dart';

class HostV2Api {
  HostV2Api(this._client);

  final DioClient _client;

  bool _shouldFallbackToLegacy(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 404 || statusCode == 405;
  }

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
    } on DioException catch (error) {
      if (!_shouldFallbackToLegacy(error)) {
        rethrow;
      }
      return _client.post<T>(
        ApiConstants.buildApiPath(legacyPath),
        data: data,
      );
    }
  }

  Future<Response<Map<String, dynamic>>> _postHostByIdWithFallback(
    int id,
  ) async {
    try {
      return await _client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/core/hosts/test/byid/$id'),
      );
    } on DioException catch (error) {
      if (!_shouldFallbackToLegacy(error)) {
        rethrow;
      }
      return _client.post<Map<String, dynamic>>(
        ApiConstants.buildApiPath('/hosts/test/byid'),
        data: <String, dynamic>{'id': id},
      );
    }
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
