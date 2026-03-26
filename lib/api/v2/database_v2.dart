import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/database_models.dart';

class DatabaseV2Api {
  DatabaseV2Api(this._client);

  final DioClient _client;

  Future<Response<PageResult<DatabaseInfo>>> searchDatabases(
    DatabaseSearch request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/databases/db/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        _unwrapData(response.data),
        (json) => DatabaseInfo.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<Map<String, dynamic>>>> searchMysqlDatabases(
    DatabaseSearch request, {
    String? operateNode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      _withNode('/databases/search', operateNode),
      data: request.toJson(),
    );
    return _mapPageResult(response);
  }

  Future<Response<PageResult<Map<String, dynamic>>>> searchPostgresqlDatabases(
    DatabaseSearch request, {
    String? operateNode,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      _withNode('/databases/pg/search', operateNode),
      data: request.toJson(),
    );
    return _mapPageResult(response);
  }

  Future<Response<List<Map<String, dynamic>>>> listDatabases(
    String type, {
    String? operateNode,
  }) async {
    final response = await _client.get<List<dynamic>>(
      _withNode('/databases/db/list/$type', operateNode),
    );
    return _mapListResponse(response);
  }

  Future<Response<List<Map<String, dynamic>>>> listDatabaseItems(
    String type,
  ) async {
    final response = await _client.get<List<dynamic>>(
      ApiConstants.buildApiPath('/databases/db/item/$type'),
    );
    return _mapListResponse(response);
  }

  Future<Response<Map<String, dynamic>>> getRemoteDatabase(String name) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/databases/db/$name'),
    );
    return _mapObjectResponse(response);
  }

  Future<Response<bool>> checkRemoteDatabase(
    Map<String, dynamic> request,
  ) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/databases/db/check'),
      data: request,
    );
    return Response(
      data: _unwrapPrimitive<bool>(response.data) ?? false,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> createRemoteDatabase(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/db'),
      data: request,
    );
  }

  Future<Response<void>> updateRemoteDatabase(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/db/update'),
      data: request,
    );
  }

  Future<Response<List<Map<String, dynamic>>>> deleteRemoteDatabaseCheck(
    int id,
  ) async {
    final response = await _client.post<List<dynamic>>(
      ApiConstants.buildApiPath('/databases/db/del/check'),
      data: {'id': id},
    );
    return _mapListResponse(response);
  }

  Future<Response<void>> deleteRemoteDatabase(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/db/del'),
      data: request,
    );
  }

  Future<Response<Map<String, dynamic>>> loadDatabaseBaseInfo({
    required String type,
    required String name,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/databases/common/info'),
      data: {'type': type, 'name': name},
    );
    return _mapObjectResponse(response);
  }

  Future<Response<String>> loadDatabaseConfigFile({
    required String type,
    required String name,
  }) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/databases/common/load/file'),
      data: {'type': type, 'name': name},
    );
    return Response(
      data: _unwrapPrimitive<String>(response.data) ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> updateDatabaseConfigFile(
      Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/common/update/conf'),
      data: request,
    );
  }

  Future<Response<void>> createMysqlDatabase(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases'),
      data: request,
    );
  }

  Future<Response<void>> bindMysqlUser(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/bind'),
      data: request,
    );
  }

  Future<Response<void>> loadMysqlDatabaseFromRemote(
    Map<String, dynamic> request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/load'),
      data: request,
    );
  }

  Future<Response<void>> updateMysqlAccess(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/change/access'),
      data: request,
    );
  }

  Future<Response<void>> updateMysqlPassword(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/change/password'),
      data: request,
    );
  }

  Future<Response<void>> updateMysqlDescription(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/description/update'),
      data: request,
    );
  }

  Future<Response<Map<String, dynamic>>> loadMysqlVariables({
    required String type,
    required String name,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/databases/variables'),
      data: {'type': type, 'name': name},
    );
    return _mapObjectResponse(response);
  }

  Future<Response<void>> updateMysqlVariables(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/variables/update'),
      data: request,
    );
  }

  Future<Response<Map<String, dynamic>>> loadMysqlStatus({
    required String type,
    required String name,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/databases/status'),
      data: {'type': type, 'name': name},
    );
    return _mapObjectResponse(response);
  }

  Future<Response<bool>> loadRemoteAccess({
    required String type,
    required String name,
  }) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/databases/remote'),
      data: {'type': type, 'name': name},
    );
    return Response(
      data: _unwrapPrimitive<bool>(response.data) ?? false,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<Map<String, dynamic>>>> loadFormatCollations(
    String database,
  ) async {
    final response = await _client.post<List<dynamic>>(
      ApiConstants.buildApiPath('/databases/format/options'),
      data: {'name': database},
    );
    return _mapListResponse(response);
  }

  Future<Response<List<dynamic>>> deleteMysqlDatabaseCheck(
    Map<String, dynamic> request,
  ) async {
    final response = await _client.post<List<dynamic>>(
      ApiConstants.buildApiPath('/databases/del/check'),
      data: request,
    );
    return Response(
      data: response.data ?? const <dynamic>[],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> deleteMysqlDatabase(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/del'),
      data: request,
    );
  }

  Future<Response<void>> createPostgresqlDatabase(
    Map<String, dynamic> request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/pg'),
      data: request,
    );
  }

  Future<Response<void>> bindPostgresqlUser(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/pg/bind'),
      data: request,
    );
  }

  Future<Response<void>> changePostgresqlPrivileges(
    Map<String, dynamic> request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/pg/privileges'),
      data: request,
    );
  }

  Future<Response<void>> loadPostgresqlDatabaseFromRemote(
    String database,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/pg/$database/load'),
    );
  }

  Future<Response<void>> updatePostgresqlDescription(
    Map<String, dynamic> request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/pg/description'),
      data: request,
    );
  }

  Future<Response<void>> updatePostgresqlPassword(
    Map<String, dynamic> request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/pg/password'),
      data: request,
    );
  }

  Future<Response<List<Map<String, dynamic>>>> deletePostgresqlDatabaseCheck(
    Map<String, dynamic> request,
  ) async {
    final response = await _client.post<List<dynamic>>(
      ApiConstants.buildApiPath('/databases/pg/del/check'),
      data: request,
    );
    return _mapListResponse(response);
  }

  Future<Response<void>> deletePostgresqlDatabase(
      Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/pg/del'),
      data: request,
    );
  }

  Future<Response<Map<String, dynamic>>> loadRedisStatus({
    required String type,
    required String name,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/databases/redis/status'),
      data: {'type': type, 'name': name},
    );
    return _mapObjectResponse(response);
  }

  Future<Response<Map<String, dynamic>>> loadRedisConf({
    required String type,
    required String name,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/databases/redis/conf'),
      data: {'type': type, 'name': name},
    );
    return _mapObjectResponse(response);
  }

  Future<Response<Map<String, dynamic>>> loadRedisPersistenceConf({
    required String type,
    required String name,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/databases/redis/persistence/conf'),
      data: {'type': type, 'name': name},
    );
    return _mapObjectResponse(response);
  }

  Future<Response<bool>> checkRedisCli() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/databases/redis/check'),
    );
    return Response(
      data: _unwrapPrimitive<bool>(response.data) ?? false,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> installRedisCli() {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/redis/install/cli'),
    );
  }

  Future<Response<void>> changeRedisPassword(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/redis/password'),
      data: request,
    );
  }

  Future<Response<void>> updateRedisPersistenceConf(
    Map<String, dynamic> request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/redis/persistence/update'),
      data: request,
    );
  }

  Future<Response<void>> updateRedisConf(Map<String, dynamic> request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/databases/redis/conf/update'),
      data: request,
    );
  }

  String _withNode(String path, String? operateNode) {
    final base = ApiConstants.buildApiPath(path);
    if (operateNode == null || operateNode.isEmpty) {
      return base;
    }
    return '$base?operateNode=$operateNode';
  }

  Response<PageResult<Map<String, dynamic>>> _mapPageResult(
    Response<Map<String, dynamic>> response,
  ) {
    return Response(
      data: PageResult.fromJson(
        _unwrapData(response.data),
        (json) => Map<String, dynamic>.from(json as Map),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Response<Map<String, dynamic>> _mapObjectResponse(
    Response<Map<String, dynamic>> response,
  ) {
    return Response(
      data: _unwrapMap(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Response<List<Map<String, dynamic>>> _mapListResponse(
    Response<List<dynamic>> response,
  ) {
    final data = response.data ?? const <dynamic>[];
    return Response(
      data: data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic>? response) {
    if (response == null) {
      return const <String, dynamic>{};
    }
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return response;
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic>? response) {
    if (response == null) {
      return const <String, dynamic>{};
    }
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return response;
  }

  T? _unwrapPrimitive<T>(dynamic response) {
    if (response is T) {
      return response;
    }
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is T) {
        return data;
      }
    }
    return null;
  }
}
