import 'dart:convert';

import '../../api/v2/database_v2.dart';
import '../../data/models/backup_account_models.dart' as backup;
import '../../data/models/database_models.dart';
import '../../data/models/file_models.dart';
import '../../data/repositories/database_repository.dart';
import '../../data/repositories/logs_repository.dart';
import '../../features/databases/databases_service.dart';
import '../../features/databases/services/database_backup_service.dart';
import '../../features/databases/services/database_user_service.dart';
import '../config/api_config.dart';
import '../network/api_client_manager.dart';

class HarmonyDatabaseHandlers {
  static DatabaseScope _scope(Map arguments) =>
      DatabaseScope.values.byName(arguments['scope'] as String);

  static DatabaseListItem _item(Map arguments) {
    final data = Map<String, dynamic>.from(arguments['item'] as Map);
    return DatabaseListItem(
      scope: DatabaseScope.values.byName(data['scope'] as String),
      id: data['id'] as int?,
      name: data['name'] as String,
      engine: data['engine'] as String,
      source: data['source'] as String,
      targetDatabase: data['targetDatabase'] as String?,
      instanceLabel: data['instanceLabel'] as String?,
      database: data['database'] as String?,
      version: data['version'] as String?,
      username: data['username'] as String?,
      description: data['description'] as String?,
      status: data['status'] as String?,
      address: data['address'] as String?,
      port: data['port'] as int?,
      raw: Map<String, dynamic>.from(data['raw'] as Map),
    );
  }

  static Map<String, dynamic> _serialize(DatabaseListItem item) => {
        'scope': item.scope.name,
        'id': item.id,
        'name': item.name,
        'engine': item.engine,
        'source': item.source,
        'targetDatabase': item.targetDatabase,
        'instanceLabel': item.instanceLabel,
        'database': item.database,
        'lookupName': item.lookupName,
        'version': item.version,
        'username': item.username,
        'description': item.description,
        'status': item.status,
        'address': item.address,
        'port': item.port,
        'raw': item.raw,
      };

  static DatabaseFormInput _input(Map arguments) => DatabaseFormInput(
        scope: _scope(arguments),
        id: arguments['id'] as int?,
        name: arguments['name'] as String,
        engine: arguments['engine'] as String,
        source: arguments['source'] as String,
        targetDatabase: arguments['targetDatabase'] as String?,
        address: arguments['address'] as String?,
        port: arguments['port'] as int?,
        username: arguments['username'] as String?,
        password: arguments['password'] as String?,
        description: arguments['description'] as String?,
        format: arguments['format'] as String?,
        permission: arguments['permission'] as String?,
        permissionIps: arguments['permissionIps'] as String?,
        superUser: arguments['superUser'] as bool?,
        timeout: arguments['timeout'] as int?,
      );

  static Future<Map<String, dynamic>> getPage(dynamic value) async {
    final arguments = value as Map;
    final page = await DatabasesService().loadPage(
      scope: _scope(arguments),
      targetDatabase: arguments['targetDatabase'] as String?,
      query: arguments['query'] as String?,
      page: arguments['page'] as int,
      pageSize: arguments['pageSize'] as int,
    );
    final serverId = (await ApiConfigManager.getCurrentConfig())?.id;
    return {
      'items': page.items.map((item) => {..._serialize(item), 'serverId': serverId}).toList(),
      'total': page.total,
      'page': page.page,
      'totalPages': page.total == 0 ? 0 : (page.total / page.pageSize).ceil(),
    };
  }

  static Future<List<Map<String, dynamic>>> getTargets(dynamic value) async =>
      (await DatabasesService().loadDatabaseTargets(_scope(value as Map)))
          .map(_serialize)
          .toList();

  static Future<Map<String, dynamic>> getDetail(dynamic value) async {
    final item = _item(value as Map);
    if (item.scope == DatabaseScope.remote) {
      return {
        'baseInfo': {
          'address': item.address,
          'port': item.port,
          'version': item.version,
          'username': item.username,
          'description': item.description,
        },
      };
    }
    final detail = await DatabasesService().loadDetail(item);
    return {
      'baseInfo': detail.baseInfo?.raw,
      'status': detail.status,
      'variables': detail.variables,
      'redisConfig': detail.redisConfig,
      'redisPersistence': detail.redisPersistence,
      'remoteAccess': detail.remoteAccess,
      'rawConfigFile': detail.rawConfigFile,
      'formatOptions': detail.formatOptions,
    };
  }

  static Map<String, dynamic> _remoteInput(Map arguments) {
    final request = Map<String, dynamic>.from(arguments['remoteConfig'] as Map);
    if (request['ssl'] == true) {
      for (final key in ['clientKey', 'clientCert', 'rootCert']) {
        final content = request[key] as String?;
        if (content != null) request[key] = base64.encode(utf8.encode(content));
      }
    }
    return request;
  }

  static Future<Map<String, dynamic>> getRemoteConfig(dynamic value) async {
    final arguments = value as Map;
    final api = await ApiClientManager.instance.getDatabaseApi();
    final response = await api.getRemoteDatabase(arguments['name'] as String);
    return response.data!;
  }

  static Future<void> submitForm(dynamic value) async {
    final arguments = value as Map;
    if (_scope(arguments) != DatabaseScope.remote) {
      await DatabasesService().submitForm(_input(arguments));
      return;
    }
    final DatabaseV2Api api = await ApiClientManager.instance.getDatabaseApi();
    final request = _remoteInput(arguments);
    if (request['id'] == null) {
      request.remove('id');
      await api.createRemoteDatabase(request);
    } else {
      await api.updateRemoteDatabase(request);
    }
  }

  static Future<bool> testConnection(dynamic value) async {
    final arguments = value as Map;
    final api = await ApiClientManager.instance.getDatabaseApi();
    final response = await api.checkRemoteDatabase(_remoteInput(arguments));
    return response.data!;
  }

  static Future<void> updateDescription(dynamic value) {
    final arguments = value as Map;
    return DatabasesService().updateDescription(
      _item(arguments),
      arguments['description'] as String,
    );
  }

  static Future<void> changePassword(dynamic value) {
    final arguments = value as Map;
    return DatabasesService().changePassword(
      _item(arguments),
      arguments['password'] as String,
    );
  }

  static Future<void> loadFromRemote(dynamic value) =>
      DatabasesService().loadFromRemote(_item(value as Map));

  static Future<List<String>> getSlowLog(dynamic value) async {
    final item = _item(value as Map);
    final response = await LogsRepository().readLogLines(
      FileReadByLineRequest(
        type: '${item.engine}-slow-logs',
        name: item.lookupName,
        latest: true,
      ),
    );
    return response.lines;
  }

  static Future<List<String>> deleteDatabase(dynamic value) async {
    final arguments = value as Map;
    final item = _item(arguments);
    if (item.scope == DatabaseScope.remote) {
      final serverId = (arguments['item'] as Map)['serverId'] as String;
      final config = await ApiConfigManager.getCurrentConfig();
      if (config == null || config.id != serverId) {
        throw StateError('Refresh the database list for the active server.');
      }
      return DatabasesService(repository: DatabaseRepository(config: config))
          .unbindRemoteDatabase(item.id!);
    }
    final api = await ApiClientManager.instance.getDatabaseApi();
    final request = {
      'id': item.id!,
      'type': item.engine,
      'database': item.lookupName,
    };
    final dependencies = switch (item.scope) {
      DatabaseScope.mysql => (await api.deleteMysqlDatabaseCheck(request)).data,
      DatabaseScope.postgresql =>
        (await api.deletePostgresqlDatabaseCheck(request)).data,
      DatabaseScope.mongodb =>
        (await api.deleteMongodbDatabaseCheck(request)).data,
      _ => throw ArgumentError.value(item.scope, 'scope'),
    };
    if (dependencies != null && dependencies.isNotEmpty) {
      return dependencies.map((entry) => (entry as Map)['name'] as String).toList();
    }
    switch (item.scope) {
      case DatabaseScope.mysql:
        await api.deleteMysqlDatabase(request);
      case DatabaseScope.postgresql:
        await api.deletePostgresqlDatabase(request);
      case DatabaseScope.mongodb:
        await api.deleteMongodbDatabase(request);
      default:
        throw ArgumentError.value(item.scope, 'scope');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getUsers(dynamic value) =>
      DatabaseUserService().listMysqlUsers(_item(value as Map));

  static Future<void> bindUser(dynamic value) {
    final arguments = value as Map;
    final item = _item(arguments);
    if (item.scope == DatabaseScope.mongodb) {
      return DatabasesService().bindUser(
        item,
        username: arguments['username'] as String,
        password: arguments['password'] as String,
      );
    }
    return DatabaseUserService().bindUser(
      item,
      username: arguments['username'] as String,
      password: arguments['password'] as String,
      permission: arguments['permission'] as String,
      superUser: arguments['superUser'] as bool,
    );
  }

  static Future<void> updatePrivileges(dynamic value) {
    final arguments = value as Map;
    return DatabaseUserService().updatePrivileges(
      _item(arguments),
      username: arguments['username'] as String,
      superUser: arguments['superUser'] as bool,
    );
  }

  static Future<Map<String, dynamic>> getBackups(dynamic value) async {
    final arguments = value as Map;
    final page = await DatabaseBackupService().loadRecords(
      _item(arguments),
      page: arguments['page'] as int,
      pageSize: arguments['pageSize'] as int,
    );
    return {
      'items': page.items.map((record) => record.toJson()).toList(),
      'page': page.page,
      'total': page.total,
      'totalPages': page.total == 0 ? 0 : (page.total / page.pageSize).ceil(),
    };
  }

  static Future<void> createBackup(dynamic value) {
    final arguments = value as Map;
    return DatabaseBackupService().createBackup(
      _item(arguments),
      secret: arguments['secret'] as String?,
    );
  }

  static Future<void> restoreBackup(dynamic value) {
    final arguments = value as Map;
    return DatabaseBackupService().restoreBackup(
      _item(arguments),
      backup.BackupRecord.fromJson(
        Map<String, dynamic>.from(arguments['record'] as Map),
      ),
      secret: arguments['secret'] as String?,
    );
  }

  static Future<void> deleteBackup(dynamic value) {
    final arguments = value as Map;
    final record = arguments['record'] as Map;
    return DatabaseBackupService().deleteBackupRecord(record['id'] as int);
  }

  static Future<List<Map<String, dynamic>>> getMongodbPrivileges(dynamic value) =>
      DatabaseRepository().loadMongodbPrivileges(_item(value as Map));

  static Future<void> changeMongodbPrivileges(dynamic value) {
    final arguments = value as Map;
    return DatabaseRepository().changeMongodbPrivileges(
      _item(arguments),
      arguments['permission'] as String,
    );
  }

  static Future<List<Map<String, dynamic>>> getPostgresqlPrivileges(dynamic value) async {
    final item = _item(value as Map);
    final page = await DatabasesService().loadPage(
      scope: DatabaseScope.postgresql,
      targetDatabase: item.lookupName,
    );
    return page.items.map((entry) => entry.raw).toList();
  }

  static Future<void> changeMongodbRootPassword(dynamic value) {
    final arguments = value as Map;
    return DatabaseRepository().changeMongodbRootPassword(
      _item(arguments),
      arguments['password'] as String,
    );
  }
}
