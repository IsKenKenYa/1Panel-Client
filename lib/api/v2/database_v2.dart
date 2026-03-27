import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/database_models.dart';
import '../../data/models/database_option_models.dart';
import '../../data/models/common_models.dart';

class DatabaseV2Api {
  final DioClient _client;

  DatabaseV2Api(this._client);

  /// 创建数据库
  ///
  /// 创建一个新的数据库
  /// @param request 数据库创建请求
  /// @return 创建结果
  Future<Response> createDatabase(DatabaseCreate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/databases'),
      data: request.toJson(),
    );
  }

  /// 删除数据库
  ///
  /// 删除指定的数据库
  /// @param request 删除请求
  /// @return 删除结果
  Future<Response> deleteDatabase(OperateByID request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/databases/del'),
      data: request.toJson(),
    );
  }

  /// 更新数据库
  ///
  /// 更新指定的数据库
  /// @param request 更新请求
  /// @return 更新结果
  Future<Response> updateDatabase(DatabaseUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/databases/update'),
      data: request.toJson(),
    );
  }

  /// 搜索数据库
  ///
  /// 获取数据库列表，支持分页和搜索
  /// @param request 搜索请求
  /// @return 数据库列表
  Future<Response<PageResult<DatabaseInfo>>> searchDatabases(
      DatabaseSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/databases/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DatabaseInfo.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取数据库详情
  ///
  /// 获取指定数据库的详细信息
  /// @param id 数据库ID
  /// @return 数据库详情
  Future<Response<DatabaseInfo>> getDatabaseDetail(int id) async {
    final response = await _client.get(
      '${ApiConstants.buildApiPath('/databases')}/$id',
    );
    return Response(
      data: DatabaseInfo.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 备份数据库
  ///
  /// 备份指定的数据库
  /// @param id 数据库ID
  /// @param request 备份请求
  /// @return 备份结果
  Future<Response> backupDatabase(int id, DatabaseBackup request) async {
    return await _client.post(
      '${ApiConstants.buildApiPath('/databases')}/$id/backup',
      data: request.toJson(),
    );
  }

  /// 恢复数据库
  ///
  /// 从备份恢复数据库
  /// @param id 数据库ID
  /// @param request 恢复请求
  /// @return 恢复结果
  Future<Response> restoreDatabase(int id, DatabaseRestore request) async {
    return await _client.post(
      '${ApiConstants.buildApiPath('/databases')}/$id/restore',
      data: request.toJson(),
    );
  }

  /// 获取数据库备份列表
  ///
  /// 获取指定数据库的备份列表
  /// @param id 数据库ID
  /// @param request 搜索请求
  /// @return 备份列表
  Future<Response<PageResult>> searchDatabaseBackups(
      int id, RecordSearch request) async {
    final response = await _client.post(
      '${ApiConstants.buildApiPath('/databases')}/$id/backups',
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 删除数据库备份
  ///
  /// 删除指定的数据库备份
  /// @param id 数据库ID
  /// @param request 删除请求
  /// @return 删除结果
  Future<Response> deleteDatabaseBackups(int id, OperateByID request) async {
    return await _client.post(
      '${ApiConstants.buildApiPath('/databases')}/$id/backups/del',
      data: request.toJson(),
    );
  }

  /// 获取数据库连接信息
  ///
  /// 获取指定数据库的连接信息
  /// @param id 数据库ID
  /// @return 连接信息
  Future<Response<DatabaseConn>> getDatabaseConnection(int id) async {
    final response = await _client.get(
      '${ApiConstants.buildApiPath('/databases')}/$id/connection',
    );
    return Response(
      data: DatabaseConn.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 重置数据库密码
  ///
  /// 重置指定数据库的密码
  /// @param request 重置密码请求
  /// @return 重置结果
  Future<Response<DatabaseConn>> resetDatabasePassword(
      DatabaseResetPassword request) async {
    final response = await _client.post(
      '${ApiConstants.buildApiPath('/databases')}/${request.id}/password/reset',
      data: request.toJson(),
    );
    return Response(
      data: DatabaseConn.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取数据库权限列表
  ///
  /// 获取指定数据库的权限列表
  /// @param id 数据库ID
  /// @return 权限列表
  Future<Response<List<Map<String, dynamic>>>> getDatabasePrivileges(
      int id) async {
    final response = await _client.get(
      '${ApiConstants.buildApiPath('/databases')}/$id/privileges',
    );
    return Response(
      data: (response.data as List<dynamic>).cast<Map<String, dynamic>>(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新数据库权限
  ///
  /// 更新指定数据库的权限
  /// @param id 数据库ID
  /// @param privileges 权限信息
  /// @return 更新结果
  Future<Response> updateDatabasePrivileges(
      int id, Map<String, dynamic> privileges) async {
    return await _client.post(
      '${ApiConstants.buildApiPath('/databases')}/$id/privileges',
      data: privileges,
    );
  }

  /// 测试数据库连接
  ///
  /// 测试指定数据库的连接
  /// @param id 数据库ID
  /// @return 测试结果
  Future<Response<bool>> testDatabaseConnection(int id) async {
    final response = await _client.get(
      '${ApiConstants.buildApiPath('/databases')}/$id/connection/test',
    );
    return Response(
      data: response.statusCode == 200,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 检查数据库是否存在
  ///
  /// 检查指定名称的数据库是否已存在
  /// @param name 数据库名称
  /// @param type 数据库类型
  /// @return 检查结果
  Future<Response<bool>> checkDatabaseExists(String name, String type) async {
    final request = DatabaseSearch(
      name: name,
      type: type,
      page: 1,
      pageSize: 1,
    );
    final response = await searchDatabases(request);

    final databases = response.data?.items ?? [];
    final exists = databases.any((db) => db.name == name && db.type == type);

    return Response(
      data: exists,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取数据库类型选项
  ///
  /// 获取所有支持的数据库类型选项
  /// @return 数据库类型列表
  Future<List<DatabaseType>> getDatabaseTypes() async {
    return DatabaseType.values;
  }

  Future<Response<List<DatabaseItemOption>>> listDbItems(String type) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/databases/db/item/$type'),
    );
    final data = response.data?['data'];
    final items = <DatabaseItemOption>[];
    if (data is List) {
      items.addAll(
        data.whereType<Map<String, dynamic>>().map(DatabaseItemOption.fromJson),
      );
    }
    return Response<List<DatabaseItemOption>>(
      data: items,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取数据库状态选项
  ///
  /// 获取所有数据库状态选项
  /// @return 数据库状态列表
  Future<List<DatabaseStatus>> getDatabaseStatuses() async {
    return DatabaseStatus.values;
  }
}
