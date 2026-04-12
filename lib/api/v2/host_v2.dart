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

  Future<Response<void>> createHost(HostCreate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/hosts'),
      data: _mapHostPayload(request),
    );
  }

  Future<Response<void>> createHostAsset(HostOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/hosts'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteHost(OperateByIDs request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/hosts/del'),
      data: request.toJson(),
    );
  }

  Future<Response<HostInfo>> updateHost(HostUpdate request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/update'),
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
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/update'),
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
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/search'),
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
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/search'),
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
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/info'),
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
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/tree'),
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
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/tree'),
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
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/test/byinfo'),
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
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/test/byinfo'),
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
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/hosts/test/byid/$id'),
    );
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
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/hosts/update/group'),
      data: <String, dynamic>{
        'id': id,
        'groupID': groupId,
      },
    );
  }

  Future<Response<void>> updateHostAssetGroup(HostGroupChange request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/hosts/update/group'),
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
