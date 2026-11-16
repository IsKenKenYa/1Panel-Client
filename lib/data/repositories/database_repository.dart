import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/paged_query.dart';

import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';

class DatabaseRepository {
  DatabaseRepository({ApiClientManager? clientManager})
      : _clientManager = clientManager ?? ApiClientManager.instance;

  final ApiClientManager _clientManager;
  static const String _remoteDatabaseTypes =
      'mysql,mariadb,postgresql,redis,redis-cluster';

  Future<DatabaseV2Api> _getApi() => _clientManager.getDatabaseApi();

  Future<List<DatabaseItemOption>> loadDatabaseItems(String type) async {
    final api = await _getApi();
    final response = await api.listDbItems(type);
    return response.data ?? const <DatabaseItemOption>[];
  }

  Future<DatabaseBaseInfo> loadBaseInfo(DatabaseListItem item) async {
    final api = await _getApi();
    final response = await api.loadDatabaseBaseInfo(
      type: item.engine,
      name: item.lookupName,
    );
    return DatabaseBaseInfo.fromJson(
        response.data ?? const <String, dynamic>{});
  }

  Future<List<DatabaseListItem>> loadDatabaseTargets(
      DatabaseScope scope) async {
    final api = await _getApi();
    final type = switch (scope) {
      DatabaseScope.mysql => 'mysql,mariadb',
      DatabaseScope.postgresql => 'postgresql',
      DatabaseScope.mongodb => 'mongodb',
      DatabaseScope.redis => 'redis,redis-cluster',
      DatabaseScope.remote => _remoteDatabaseTypes,
    };
    final response = await api.listDatabases(type);
    return response.data
            ?.map((item) => DatabaseListItem.fromDatabaseOption(item, scope))
            .toList(growable: false) ??
        const <DatabaseListItem>[];
  }

  Future<PageResult<DatabaseListItem>> searchByScope({
    required DatabaseScope scope,
    String? targetDatabase,
    String? query,
    int page = 1,
    int pageSize = PagedQuery.searchPageSize,
  }) async {
    final api = await _getApi();
    switch (scope) {
      case DatabaseScope.mysql:
        if (targetDatabase == null || targetDatabase.isEmpty) {
          return const PageResult<DatabaseListItem>(
            items: <DatabaseListItem>[],
            total: 0,
            page: 1,
            pageSize: 20,
          );
        }
        final response = await api.searchMysqlDatabases(
          DatabaseSearch(
            info: query,
            database: targetDatabase,
            page: page,
            pageSize: pageSize,
          ),
        );
        return PageResult<DatabaseListItem>(
          items: response.data?.items
                  .map(DatabaseListItem.fromMysqlJson)
                  .toList(growable: false) ??
              const <DatabaseListItem>[],
          total: response.data?.total ?? 0,
          page: page,
          pageSize: pageSize,
        );
      case DatabaseScope.postgresql:
        if (targetDatabase == null || targetDatabase.isEmpty) {
          return const PageResult<DatabaseListItem>(
            items: <DatabaseListItem>[],
            total: 0,
            page: 1,
            pageSize: 20,
          );
        }
        final response = await api.searchPostgresqlDatabases(
          DatabaseSearch(
            info: query,
            database: targetDatabase,
            page: page,
            pageSize: pageSize,
          ),
        );
        return PageResult<DatabaseListItem>(
          items: response.data?.items
                  .map(DatabaseListItem.fromPostgresqlJson)
                  .toList(growable: false) ??
              const <DatabaseListItem>[],
          total: response.data?.total ?? 0,
          page: page,
          pageSize: pageSize,
        );
      case DatabaseScope.redis:
        final response = await api.listDatabases('redis,redis-cluster');
        final items = response.data
                ?.map((item) => DatabaseListItem.fromDatabaseOption(
                      item,
                      DatabaseScope.redis,
                    ))
                .toList(growable: false) ??
            const <DatabaseListItem>[];
        return PageResult<DatabaseListItem>(
          items: items,
          total: items.length,
          page: 1,
          pageSize: items.length,
        );
      case DatabaseScope.mongodb:
        if (targetDatabase == null || targetDatabase.isEmpty) {
          return const PageResult<DatabaseListItem>(
            items: <DatabaseListItem>[],
            total: 0,
            page: 1,
            pageSize: 20,
          );
        }
        final response = await api.searchMongodbDatabases(
          DatabaseSearch(
            info: query,
            database: targetDatabase,
            page: page,
            pageSize: pageSize,
          ),
        );
        return PageResult<DatabaseListItem>(
          items: response.data?.items
                  .map(DatabaseListItem.fromMongodbJson)
                  .toList(growable: false) ??
              const <DatabaseListItem>[],
          total: response.data?.total ?? 0,
          page: page,
          pageSize: pageSize,
        );
      case DatabaseScope.remote:
        final response = await api.searchDatabases(
          DatabaseSearch(
            type: _remoteDatabaseTypes,
            info: query,
            database: '',
            page: page,
            pageSize: pageSize,
          ),
        );
        return PageResult<DatabaseListItem>(
          items: response.data?.items
                  .where((item) => item.host?.isNotEmpty == true)
                  .map(DatabaseListItem.fromRemoteInfo)
                  .toList(growable: false) ??
              const <DatabaseListItem>[],
          total: response.data?.total ?? 0,
          page: page,
          pageSize: pageSize,
        );
    }
  }

  Future<DatabaseDetailData> loadDetail(DatabaseListItem item) async {
    final api = await _getApi();
    final lookupName = item.lookupName;
    // 数据库条目本身不带实例类型（mysql 与 mariadb 共用实例列表），
    // 详情接口与配置文件接口按实例类型寻址，需要先回查实例列表。
    final type = await _resolveInstanceType(item);
    final baseInfoResponse = await api.loadDatabaseBaseInfo(
      type: type,
      name: lookupName,
    );

    Map<String, dynamic>? status;
    Map<String, dynamic>? variables;
    Map<String, dynamic>? redisConf;
    Map<String, dynamic>? redisPersistence;
    bool? remoteAccess;
    String? rawConfigFile;
    List<Map<String, dynamic>> formatOptions = const <Map<String, dynamic>>[];

    if (item.scope == DatabaseScope.mysql) {
      rawConfigFile = (await api.loadDatabaseConfigFile(
        type: confFileType(type),
        name: lookupName,
      ))
          .data;
      status = (await api.loadMysqlStatus(type: type, name: lookupName)).data;
      variables =
          (await api.loadMysqlVariables(type: type, name: lookupName)).data;
      remoteAccess =
          (await api.loadRemoteAccess(type: type, name: lookupName)).data;
      formatOptions =
          (await api.loadFormatCollations(lookupName)).data ?? const [];
    } else if (item.scope == DatabaseScope.postgresql) {
      rawConfigFile = (await api.loadDatabaseConfigFile(
        type: confFileType(type),
        name: lookupName,
      ))
          .data;
    } else if (item.scope == DatabaseScope.redis) {
      status = (await api.loadRedisStatus(type: type, name: lookupName)).data;
      redisConf = (await api.loadRedisConf(type: type, name: lookupName)).data;
      redisPersistence =
          (await api.loadRedisPersistenceConf(type: type, name: lookupName))
              .data;
    } else if (item.scope == DatabaseScope.mongodb) {
      status = await api.loadMongodbStatus(type: type, name: lookupName);
    } else if (item.scope == DatabaseScope.remote) {
      final remoteInfo = await api.getRemoteDatabase(lookupName);
      status = remoteInfo.data;
    }

    return DatabaseDetailData(
      item: item,
      baseInfo: DatabaseBaseInfo.fromJson(baseInfoResponse.data ?? const {}),
      status: status,
      variables: variables,
      redisConfig: redisConf,
      redisPersistence: redisPersistence,
      remoteAccess: remoteAccess,
      rawConfigFile: rawConfigFile,
      formatOptions: formatOptions,
    );
  }

  /// 配置文件接口的 type 是文件类型（mysql-conf / mariadb-conf /
  /// postgresql-conf），由实例类型加后缀得到；直接传实例类型会返回 500。
  @visibleForTesting
  static String confFileType(String instanceType) => '$instanceType-conf';

  /// 数据库条目不带实例类型：mysql 与 mariadb 共用一个实例列表，
  /// 详情接口按实例 app key 寻址，需要回查实例列表取真实类型。
  Future<String> _resolveInstanceType(DatabaseListItem item) async {
    if (item.scope != DatabaseScope.mysql) {
      return item.engine;
    }
    final targets = await loadDatabaseTargets(DatabaseScope.mysql);
    for (final target in targets) {
      if ((target.targetDatabase ?? target.database) == item.lookupName) {
        return target.engine;
      }
    }
    return item.engine;
  }

  Future<void> submitForm(DatabaseFormInput input) async {
    final api = await _getApi();
    if (input.isRemote) {
      final payload = <String, dynamic>{
        if (input.id != null) 'id': input.id,
        'name': input.name,
        'version': input.engine,
        'from': 'remote',
        'address': input.address,
        'port': input.port,
        'username': input.username,
        // API requires base64-encoded password for remote databases
        'password': input.password == null
            ? null
            : base64Encode(utf8.encode(input.password!)),
        'description': input.description,
        'timeout': input.timeout ?? 30,
      };
      if (input.id == null) {
        await api.createRemoteDatabase(payload);
      } else {
        await api.updateRemoteDatabase(payload);
      }
      return;
    }

    final payload = <String, dynamic>{
      'name': input.name,
      'from': input.source,
      'database': input.targetDatabase,
      'format': input.format,
      'username': input.username,
      // API requires base64-encoded password for local database creation
      'password': input.password == null
          ? null
          : base64Encode(utf8.encode(input.password!)),
      'description': input.description,
    };
    switch (input.scope) {
      case DatabaseScope.mysql:
        await api.createMysqlDatabase({
          ...payload,
          'permission':
              input.permission == 'ip' ? input.permissionIps : input.permission,
        });
        return;
      case DatabaseScope.postgresql:
        await api.createPostgresqlDatabase({
          ...payload,
          'superUser': input.superUser ?? true,
        });
        return;
      case DatabaseScope.mongodb:
        await api.createMongodbDatabase({
          ...payload,
          'superUser': input.superUser ?? true,
        });
        return;
      case DatabaseScope.redis:
      case DatabaseScope.remote:
        return;
    }
  }

  Future<void> updateDescription(
      DatabaseListItem item, String description) async {
    final api = await _getApi();
    if (item.scope == DatabaseScope.postgresql) {
      await api.updatePostgresqlDescription({
        'name': item.name,
        'description': description,
      });
      return;
    }
    if (item.scope == DatabaseScope.mongodb) {
      await api.updateMongodbDescription({
        'database': item.lookupName,
        'description': description,
      });
      return;
    }
    await api.updateMysqlDescription({
      'name': item.name,
      'description': description,
    });
  }

  Future<void> changePassword(DatabaseListItem item, String password) async {
    final api = await _getApi();
    final payload = <String, dynamic>{
      'id': item.id ?? 0,
      'from': item.source,
      'type': item.engine,
      'database': item.lookupName,
      'value': password,
    };
    if (item.scope == DatabaseScope.postgresql) {
      await api.updatePostgresqlPassword(payload);
      return;
    }
    if (item.scope == DatabaseScope.mongodb) {
      await api.changeMongodbPassword({
        'type': item.engine,
        'database': item.lookupName,
        'value': password,
      });
      return;
    }
    if (item.scope == DatabaseScope.redis) {
      await api.changeRedisPassword({
        'database': item.lookupName,
        'value': password,
      });
      return;
    }
    await api.updateMysqlPassword(payload);
  }

  Future<void> bindUser(
    DatabaseListItem item, {
    required String username,
    required String password,
  }) async {
    final api = await _getApi();
    if (item.scope == DatabaseScope.postgresql) {
      await api.bindPostgresqlUser({
        'name': item.name,
        'database': item.lookupName,
        'username': username,
        'password': password,
        'superUser': false,
      });
      return;
    }
    if (item.scope == DatabaseScope.mongodb) {
      await api.bindMongodbUser({
        'database': item.lookupName,
        'username': username,
        'password': password,
      });
      return;
    }
    // V2 契约迁移：/databases/bind 已删除，MySQL 用户创建走 /databases/users。
    await api.createDatabaseUser(<String, dynamic>{
      'database': item.lookupName,
      'dbs': <String>[item.name],
      'username': username,
      'password': base64.encode(utf8.encode(password)),
      'host': '%',
      'description': '',
    });
  }

  Future<bool> testRemoteConnection(DatabaseFormInput input) async {
    final api = await _getApi();
    final response = await api.checkRemoteDatabase({
      'name': input.name,
      'version': input.engine,
      'from': 'remote',
      'address': input.address,
      'port': input.port,
      'username': input.username,
      'password': input.password,
      'description': input.description,
      'timeout': input.timeout ?? 30,
    });
    return response.data ?? false;
  }

  Future<void> updateRedisConfig({
    required String database,
    required Map<String, dynamic> payload,
  }) async {
    final api = await _getApi();
    await api.updateRedisConf({
      'database': database,
      ...payload,
    });
  }

  Future<void> updateRedisPersistence({
    required String database,
    required Map<String, dynamic> payload,
  }) async {
    final api = await _getApi();
    await api.updateRedisPersistenceConf({
      'database': database,
      ...payload,
    });
  }

  Future<void> loadFromRemote(DatabaseListItem item) async {
    final api = await _getApi();
    switch (item.scope) {
      case DatabaseScope.mysql:
        await api.loadMysqlDatabaseFromRemote({
          'from': item.source,
          'type': item.engine,
          'database': item.lookupName,
        });
        return;
      case DatabaseScope.postgresql:
        await api.loadPostgresqlDatabaseFromRemote(
          item.lookupName,
          from: item.source,
          type: item.engine,
        );
        return;
      case DatabaseScope.mongodb:
        await api.loadMongodbDatabaseFromRemote({
          'from': item.source,
          'type': item.engine,
          'database': item.lookupName,
        });
        return;
      case DatabaseScope.redis:
      case DatabaseScope.remote:
        throw UnsupportedError('Remote load is not supported for this scope.');
    }
  }

  Future<void> deleteMongodb(DatabaseListItem item) async {
    final api = await _getApi();
    await api.deleteMongodbDatabase({
      'type': item.engine,
      'database': item.lookupName,
    });
  }

  Future<List<Map<String, dynamic>>> checkDeleteMongodb(
      DatabaseListItem item) async {
    final api = await _getApi();
    final response = await api.deleteMongodbDatabaseCheck({
      'type': item.engine,
      'database': item.lookupName,
    });
    return response.data ?? const <Map<String, dynamic>>[];
  }

  Future<void> changeMongodbRootPassword(
    DatabaseListItem item,
    String password,
  ) async {
    final api = await _getApi();
    await api.changeMongodbRootPassword({
      'type': item.engine,
      'database': item.lookupName,
      'value': password,
    });
  }

  Future<List<Map<String, dynamic>>> loadMongodbPrivileges(
      DatabaseListItem item) async {
    final api = await _getApi();
    final response = await api.loadMongodbPrivileges({
      'type': item.engine,
      'database': item.lookupName,
    });
    return response.data ?? const <Map<String, dynamic>>[];
  }
}
