import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart' as common;
import '../../data/models/system_group_models.dart' as group_models;

class SystemGroupV2Api {
  SystemGroupV2Api(this._client);

  final DioClient _client;

  Future<Response<void>> createCoreGroup(group_models.GroupCreate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/groups'),
      data: request.toJson(),
    );
  }

  Future<Response<List<group_models.GroupInfo>>> searchCoreGroups(
    group_models.GroupSearch request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/groups/search'),
      data: request.toJson(),
    );
    return _toGroupListResponse(response);
  }

  Future<Response<void>> updateCoreGroup(group_models.GroupUpdate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/groups/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteCoreGroup(common.OperateByID request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/groups/del'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> createAgentGroup(group_models.GroupCreate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/groups'),
      data: request.toJson(),
    );
  }

  Future<Response<List<group_models.GroupInfo>>> searchAgentGroups(
    group_models.GroupSearch request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/groups/search'),
      data: request.toJson(),
    );
    return _toGroupListResponse(response);
  }

  Future<Response<void>> updateAgentGroup(group_models.GroupUpdate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/groups/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteAgentGroup(common.OperateByID request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/groups/del'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> createGroup(group_models.GroupCreate request) {
    return createCoreGroup(request);
  }

  Future<Response<List<group_models.GroupInfo>>> searchGroups(
    group_models.GroupSearch request,
  ) {
    return searchCoreGroups(request);
  }

  Future<Response<void>> updateGroup(group_models.GroupUpdate request) {
    return updateCoreGroup(request);
  }

  Future<Response<void>> deleteGroup(common.OperateByID request) {
    return deleteCoreGroup(request);
  }

  Response<List<group_models.GroupInfo>> _toGroupListResponse(
    Response<Map<String, dynamic>> response,
  ) {
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    final groups = rawItems
        .whereType<Map<String, dynamic>>()
        .map(group_models.GroupInfo.fromJson)
        .toList(growable: false);
    return Response<List<group_models.GroupInfo>>(
      data: groups,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}
