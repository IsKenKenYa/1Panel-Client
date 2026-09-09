import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/v2/backup_account_v2.dart';
import '../../api/v2/database_v2.dart';
import '../../data/models/backup_request_models.dart';
import '../network/api_client_manager.dart';
import '../services/logger/logger_service.dart';

/// 统一返回结构：成功 `{success: true}`，失败 `{success: false, error: String}`。
Map<String, dynamic> _ok() => {'success': true};
Map<String, dynamic> _err(Object e) => {'success': false, 'error': e.toString()};

/// B4 数据库深度通道 handlers（11 读 + 12 写）。
///
/// 契约单一事实源：docs/development/modules/b4_database_channel_contract.md。
/// 底层复用 `DatabaseV2Api`；备份记录走 `BackupAccountV2Api.searchBackupRecords`。
///
/// 读语义：透传解析后的服务端数据，缺参/失败返回空值并记录日志；
/// 写语义：成功 `{success: true}`，失败 `{success: false, error}`；
/// 必填参数缺失时快速失败，不发出请求。
class NativeChannelDatabaseDeepHandlers {
  NativeChannelDatabaseDeepHandlers._();

  /// 测试注入口：注入后读/写 handler 从该工厂获取底层 API，避免真实网络。
  @visibleForTesting
  static Future<DatabaseV2Api> Function()? databaseApiFactory;

  /// 测试注入口：`getDatabaseBackups` 底层 API 工厂（同上）。
  @visibleForTesting
  static Future<BackupAccountV2Api> Function()? backupApiFactory;

  static Future<DatabaseV2Api> _databaseApi() async {
    final factory = databaseApiFactory;
    if (factory != null) {
      return factory();
    }
    return DatabaseV2Api(await ApiClientManager.instance.getCurrentClient());
  }

  static Future<BackupAccountV2Api> _backupApi() async {
    final factory = backupApiFactory;
    if (factory != null) {
      return factory();
    }
    return BackupAccountV2Api(
      await ApiClientManager.instance.getCurrentClient(),
    );
  }

  static String _str(dynamic value) => value as String? ?? '';

  static int? _toInt(dynamic value) => int.tryParse('$value');

  // ── 读通道（11）────────────────────────────────────────────────────────

  /// 数据库基础信息。参数：`{type: String, name: String}`。
  /// POST /databases/common/info。
  static Future<dynamic> getDatabaseBaseInfo(dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final name = _str(arguments?['name']);
      if (type.isEmpty || name.isEmpty) {
        return <String, dynamic>{};
      }
      return (await _databaseApi())
          .loadDatabaseBaseInfo(type: type, name: name)
          .then((r) => r.data ?? <String, dynamic>{});
    } catch (e) {
      appLogger.e('Failed to get database base info for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 数据库配置文件内容。参数：`{type: String, name: String}`；
  /// conf 类型由调用方传 `type-conf`（与上游前端一致，handler 透传）。
  /// POST /databases/common/load/file，返回 `{content: String}`。
  static Future<dynamic> getDatabaseConfFile(dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final name = _str(arguments?['name']);
      if (type.isEmpty || name.isEmpty) {
        return <String, dynamic>{};
      }
      final content = await (await _databaseApi())
          .loadDatabaseConfigFile(type: type, name: name)
          .then((r) => r.data ?? '');
      return <String, dynamic>{'content': content};
    } catch (e) {
      appLogger.e('Failed to get database conf file for native: $e');
      return <String, dynamic>{};
    }
  }

  /// MySQL 运行变量。参数：`{type: String, name: String}`。
  /// POST /databases/variables。
  static Future<dynamic> getMysqlVariables(dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final name = _str(arguments?['name']);
      if (type.isEmpty || name.isEmpty) {
        return <String, dynamic>{};
      }
      return (await _databaseApi())
          .loadMysqlVariables(type: type, name: name)
          .then((r) => r.data ?? <String, dynamic>{});
    } catch (e) {
      appLogger.e('Failed to get mysql variables for native: $e');
      return <String, dynamic>{};
    }
  }

  /// MySQL 运行状态。参数：`{type: String, name: String}`。
  /// POST /databases/status。
  static Future<dynamic> getMysqlStatus(dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final name = _str(arguments?['name']);
      if (type.isEmpty || name.isEmpty) {
        return <String, dynamic>{};
      }
      return (await _databaseApi())
          .loadMysqlStatus(type: type, name: name)
          .then((r) => r.data ?? <String, dynamic>{});
    } catch (e) {
      appLogger.e('Failed to get mysql status for native: $e');
      return <String, dynamic>{};
    }
  }

  /// Redis 配置。参数：`{type: String, name: String}`。
  /// POST /databases/redis/conf。
  static Future<dynamic> getRedisConf(dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final name = _str(arguments?['name']);
      if (type.isEmpty || name.isEmpty) {
        return <String, dynamic>{};
      }
      return (await _databaseApi())
          .loadRedisConf(type: type, name: name)
          .then((r) => r.data ?? <String, dynamic>{});
    } catch (e) {
      appLogger.e('Failed to get redis conf for native: $e');
      return <String, dynamic>{};
    }
  }

  /// Redis 状态。参数：`{type: String, name: String}`。
  /// POST /databases/redis/status。
  static Future<dynamic> getRedisStatus(dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final name = _str(arguments?['name']);
      if (type.isEmpty || name.isEmpty) {
        return <String, dynamic>{};
      }
      return (await _databaseApi())
          .loadRedisStatus(type: type, name: name)
          .then((r) => r.data ?? <String, dynamic>{});
    } catch (e) {
      appLogger.e('Failed to get redis status for native: $e');
      return <String, dynamic>{};
    }
  }

  /// Redis 持久化配置。参数：`{type: String, name: String}`。
  /// POST /databases/redis/persistence/conf。
  static Future<dynamic> getRedisPersistence(dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final name = _str(arguments?['name']);
      if (type.isEmpty || name.isEmpty) {
        return <String, dynamic>{};
      }
      return (await _databaseApi())
          .loadRedisPersistenceConf(type: type, name: name)
          .then((r) => r.data ?? <String, dynamic>{});
    } catch (e) {
      appLogger.e('Failed to get redis persistence conf for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 远程访问开关状态。参数：`{type: String, name: String}`。
  /// POST /databases/remote，返回 `{remoteAccess: bool}`。
  static Future<dynamic> getDatabaseRemoteAccess(dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final name = _str(arguments?['name']);
      if (type.isEmpty || name.isEmpty) {
        return <String, dynamic>{};
      }
      final remoteAccess = await (await _databaseApi())
          .loadRemoteAccess(type: type, name: name)
          .then((r) => r.data ?? false);
      return <String, dynamic>{'remoteAccess': remoteAccess};
    } catch (e) {
      appLogger.e('Failed to get database remote access for native: $e');
      return <String, dynamic>{};
    }
  }

  /// 数据库用户列表。参数：`{database: String}`。
  /// POST /databases/users/search。
  static Future<dynamic> getDatabaseUsers(dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      if (database.isEmpty) {
        return <dynamic>[];
      }
      return (await _databaseApi())
          .searchDatabaseUsers(database)
          .then((r) => r.data ?? const <Map<String, dynamic>>[]);
    } catch (e) {
      appLogger.e('Failed to get database users for native: $e');
      return <dynamic>[];
    }
  }

  /// 数据库授权列表。参数：`{database: String}`。
  /// POST /databases/grants/search。
  static Future<dynamic> getDatabaseGrants(dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      if (database.isEmpty) {
        return <dynamic>[];
      }
      return (await _databaseApi())
          .searchDatabaseGrants(database)
          .then((r) => r.data ?? const <Map<String, dynamic>>[]);
    } catch (e) {
      appLogger.e('Failed to get database grants for native: $e');
      return <dynamic>[];
    }
  }

  /// 数据库备份记录分页。参数：
  /// `{type: String, name: String, detailName: String, page?: int, pageSize?: int}`。
  /// POST /backups/record/search（BackupAccountV2Api.searchBackupRecords，
  /// 业务类型 type + 服务名 name + 库名 detailName 筛选）。
  static Future<dynamic> getDatabaseBackups(dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final name = _str(arguments?['name']);
      if (type.isEmpty || name.isEmpty) {
        return <String, dynamic>{};
      }
      final page = await (await _backupApi()).searchBackupRecords(
        BackupRecordQuery(
          type: type,
          name: name,
          detailName: _str(arguments?['detailName']),
          page: _toInt(arguments?['page']) ?? 1,
          pageSize: _toInt(arguments?['pageSize']) ?? 20,
        ),
      );
      final items = page.data;
      return <String, dynamic>{
        'items': items?.items.map((r) => r.toJson()).toList() ?? const [],
        'total': items?.total ?? 0,
        'page': items?.page ?? 1,
        'pageSize': items?.pageSize ?? 20,
        'totalPages': items?.totalPages ?? 0,
      };
    } catch (e) {
      appLogger.e('Failed to get database backups for native: $e');
      return <String, dynamic>{};
    }
  }

  // ── 写通道（12）────────────────────────────────────────────────────────

  /// 保存数据库配置文件。参数：
  /// `{type: String, database: String, file: String}`。
  /// POST /databases/common/update/conf。
  static Future<Map<String, dynamic>> updateDatabaseConfFile(
      dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final database = _str(arguments?['database']);
      final file = _str(arguments?['file']);
      if (type.isEmpty || database.isEmpty || file.isEmpty) {
        return {'success': false, 'error': 'type, database and file are required'};
      }
      await (await _databaseApi()).updateDatabaseConfigFile(
        <String, dynamic>{'type': type, 'database': database, 'file': file},
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateDatabaseConfFile failed: $e');
      return _err(e);
    }
  }

  /// 更新 MySQL 运行变量。参数：
  /// `{type: String, database: String, variables: [{param, value}]}`。
  /// POST /databases/variables/update。
  static Future<Map<String, dynamic>> updateMysqlVariables(
      dynamic arguments) async {
    try {
      final type = _str(arguments?['type']);
      final database = _str(arguments?['database']);
      final variables = arguments?['variables'];
      if (type.isEmpty || database.isEmpty) {
        return {'success': false, 'error': 'type and database are required'};
      }
      if (variables is! List || variables.isEmpty) {
        return {'success': false, 'error': 'variables must be a non-empty list'};
      }
      await (await _databaseApi()).updateMysqlVariables(
        <String, dynamic>{
          'type': type,
          'database': database,
          'variables': variables,
        },
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateMysqlVariables failed: $e');
      return _err(e);
    }
  }

  /// 更新 Redis 配置。参数：
  /// `{dbType: String, database: String, timeout: String,
  ///   maxclients: String, maxmemory: String}`。
  /// POST /databases/redis/conf/update。
  static Future<Map<String, dynamic>> updateRedisConf(
      dynamic arguments) async {
    try {
      final dbType = _str(arguments?['dbType']);
      final database = _str(arguments?['database']);
      final timeout = _str(arguments?['timeout']);
      final maxclients = _str(arguments?['maxclients']);
      final maxmemory = _str(arguments?['maxmemory']);
      if (dbType.isEmpty ||
          database.isEmpty ||
          timeout.isEmpty ||
          maxclients.isEmpty ||
          maxmemory.isEmpty) {
        return {
          'success': false,
          'error':
              'dbType, database, timeout, maxclients and maxmemory are required',
        };
      }
      await (await _databaseApi()).updateRedisConf(<String, dynamic>{
        'dbType': dbType,
        'database': database,
        'timeout': timeout,
        'maxclients': maxclients,
        'maxmemory': maxmemory,
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateRedisConf failed: $e');
      return _err(e);
    }
  }

  /// 更新 Redis 持久化配置。参数：
  /// `{database: String, type: 'aof'|'rbd', appendonly?: String,
  ///   appendfsync?: String, save?: String, dbType: String}`。
  /// POST /databases/redis/persistence/update。
  static Future<Map<String, dynamic>> updateRedisPersistence(
      dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      final type = _str(arguments?['type']);
      final dbType = _str(arguments?['dbType']);
      if (database.isEmpty || type.isEmpty || dbType.isEmpty) {
        return {
          'success': false,
          'error': 'database, type and dbType are required',
        };
      }
      await (await _databaseApi()).updateRedisPersistenceConf(<String, dynamic>{
        'database': database,
        'type': type,
        'dbType': dbType,
        if (arguments?['appendonly'] != null)
          'appendonly': _str(arguments?['appendonly']),
        if (arguments?['appendfsync'] != null)
          'appendfsync': _str(arguments?['appendfsync']),
        if (arguments?['save'] != null) 'save': _str(arguments?['save']),
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateRedisPersistence failed: $e');
      return _err(e);
    }
  }

  /// 修改 Redis 密码。参数：`{database: String, password: String}`。
  /// POST /databases/redis/password。上游前端将 password base64 编码后
  /// 以 `value` 键提交（api/modules/database.ts changeRedisPassword），
  /// Dart 底层方法透传 Map，故在此编码并映射。
  static Future<Map<String, dynamic>> changeRedisPassword(
      dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      final password = _str(arguments?['password']);
      if (database.isEmpty) {
        return {'success': false, 'error': 'database is required'};
      }
      if (password.isEmpty) {
        return {'success': false, 'error': 'password is required'};
      }
      await (await _databaseApi()).changeRedisPassword(<String, dynamic>{
        'database': database,
        'value': base64.encode(utf8.encode(password)),
      });
      return _ok();
    } catch (e) {
      appLogger.e('changeRedisPassword failed: $e');
      return _err(e);
    }
  }

  /// 修改远程访问范围。参数：
  /// `{id: int, from: String, type: String, database: String,
  ///   value: '%'|'localhost'}`。
  /// POST /databases/change/access。
  static Future<Map<String, dynamic>> updateDatabaseAccess(
      dynamic arguments) async {
    try {
      final id = _toInt(arguments?['id']);
      final from = _str(arguments?['from']);
      final type = _str(arguments?['type']);
      final database = _str(arguments?['database']);
      final value = _str(arguments?['value']);
      if (id == null) {
        return {'success': false, 'error': 'id is required'};
      }
      if (from.isEmpty || type.isEmpty || database.isEmpty || value.isEmpty) {
        return {
          'success': false,
          'error': 'from, type, database and value are required',
        };
      }
      await (await _databaseApi()).updateMysqlAccess(<String, dynamic>{
        'id': id,
        'from': from,
        'type': type,
        'database': database,
        'value': value,
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateDatabaseAccess failed: $e');
      return _err(e);
    }
  }

  /// 修改数据库用户密码。参数：
  /// `{database: String, username: String, host: String, password: String}`。
  /// POST /databases/users/password。Dart 底层透传 Map，password 在此
  /// base64 编码（上游前端 encodeBase64Fields(['password'])，仓库层
  /// DatabaseUserRepository 同此惯例）。
  static Future<Map<String, dynamic>> updateDatabaseUserPassword(
      dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      final username = _str(arguments?['username']);
      final host = _str(arguments?['host']);
      final password = _str(arguments?['password']);
      if (database.isEmpty ||
          username.isEmpty ||
          host.isEmpty ||
          password.isEmpty) {
        return {
          'success': false,
          'error': 'database, username, host and password are required',
        };
      }
      await (await _databaseApi()).updateDatabaseUserPassword(
        <String, dynamic>{
          'database': database,
          'username': username,
          'host': host,
          'password': base64.encode(utf8.encode(password)),
        },
      );
      return _ok();
    } catch (e) {
      appLogger.e('updateDatabaseUserPassword failed: $e');
      return _err(e);
    }
  }

  /// 创建数据库用户。参数：
  /// `{database: String, username: String, host: String, password: String,
  ///   description?: String}`。POST /databases/users（password base64，
  /// 同上；服务端 required 仅 database/host/password/username，dbs 可选未传）。
  static Future<Map<String, dynamic>> createDatabaseUser(
      dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      final username = _str(arguments?['username']);
      final host = _str(arguments?['host']);
      final password = _str(arguments?['password']);
      if (database.isEmpty ||
          username.isEmpty ||
          host.isEmpty ||
          password.isEmpty) {
        return {
          'success': false,
          'error': 'database, username, host and password are required',
        };
      }
      await (await _databaseApi()).createDatabaseUser(<String, dynamic>{
        'database': database,
        'username': username,
        'host': host,
        'password': base64.encode(utf8.encode(password)),
        'description': _str(arguments?['description']),
      });
      return _ok();
    } catch (e) {
      appLogger.e('createDatabaseUser failed: $e');
      return _err(e);
    }
  }

  /// 删除数据库用户。参数：
  /// `{database: String, username: String, host: String}`。
  /// POST /databases/users/del。
  static Future<Map<String, dynamic>> deleteDatabaseUser(
      dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      final username = _str(arguments?['username']);
      final host = _str(arguments?['host']);
      if (database.isEmpty || username.isEmpty || host.isEmpty) {
        return {
          'success': false,
          'error': 'database, username and host are required',
        };
      }
      await (await _databaseApi()).deleteDatabaseUser(<String, dynamic>{
        'database': database,
        'username': username,
        'host': host,
      });
      return _ok();
    } catch (e) {
      appLogger.e('deleteDatabaseUser failed: $e');
      return _err(e);
    }
  }

  /// 更新数据库用户（主机迁移/描述）。参数：
  /// `{database: String, username: String, host: String, newHost: String,
  ///   description: String}`。POST /databases/users/update。
  static Future<Map<String, dynamic>> updateDatabaseUser(
      dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      final username = _str(arguments?['username']);
      final host = _str(arguments?['host']);
      final newHost = _str(arguments?['newHost']);
      final description = _str(arguments?['description']);
      if (database.isEmpty ||
          username.isEmpty ||
          host.isEmpty ||
          newHost.isEmpty ||
          description.isEmpty) {
        return {
          'success': false,
          'error':
              'database, username, host, newHost and description are required',
        };
      }
      await (await _databaseApi()).updateDatabaseUser(<String, dynamic>{
        'database': database,
        'username': username,
        'host': host,
        'newHost': newHost,
        'description': description,
      });
      return _ok();
    } catch (e) {
      appLogger.e('updateDatabaseUser failed: $e');
      return _err(e);
    }
  }

  /// 授权用户访问数据库。参数：
  /// `{database: String, db: String, username: String, host: String}`。
  /// POST /databases/grants。
  static Future<Map<String, dynamic>> grantDatabaseUser(
      dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      final db = _str(arguments?['db']);
      final username = _str(arguments?['username']);
      final host = _str(arguments?['host']);
      if (database.isEmpty || db.isEmpty || username.isEmpty || host.isEmpty) {
        return {
          'success': false,
          'error': 'database, db, username and host are required',
        };
      }
      await (await _databaseApi()).createDatabaseGrant(<String, dynamic>{
        'database': database,
        'db': db,
        'username': username,
        'host': host,
      });
      return _ok();
    } catch (e) {
      appLogger.e('grantDatabaseUser failed: $e');
      return _err(e);
    }
  }

  /// 回收用户数据库授权。参数：
  /// `{database: String, db: String, username: String, host: String}`。
  /// POST /databases/grants/del。
  static Future<Map<String, dynamic>> revokeDatabaseGrant(
      dynamic arguments) async {
    try {
      final database = _str(arguments?['database']);
      final db = _str(arguments?['db']);
      final username = _str(arguments?['username']);
      final host = _str(arguments?['host']);
      if (database.isEmpty || db.isEmpty || username.isEmpty || host.isEmpty) {
        return {
          'success': false,
          'error': 'database, db, username and host are required',
        };
      }
      await (await _databaseApi()).deleteDatabaseGrant(<String, dynamic>{
        'database': database,
        'db': db,
        'username': username,
        'host': host,
      });
      return _ok();
    } catch (e) {
      appLogger.e('revokeDatabaseGrant failed: $e');
      return _err(e);
    }
  }
}
