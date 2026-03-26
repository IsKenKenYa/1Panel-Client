import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';

class DatabaseRepository {
  DatabaseRepository({ApiClientManager? clientManager})
      : _clientManager = clientManager ?? ApiClientManager.instance;

  final ApiClientManager _clientManager;

  Future<DatabaseV2Api> _getApi() => _clientManager.getDatabaseApi();

  Future<PageResult<DatabaseListItem>> searchByScope({
    required DatabaseScope scope,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final api = await _getApi();
    switch (scope) {
      case DatabaseScope.mysql:
        final response = await api.searchMysqlDatabases(
          DatabaseSearch(
            info: query,
            database: 'mysql',
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
        final response = await api.searchPostgresqlDatabases(
          DatabaseSearch(
            info: query,
            database: 'postgresql',
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
      case DatabaseScope.remote:
        final response = await api.searchDatabases(
          DatabaseSearch(
            type: 'remote',
            info: query,
            page: page,
            pageSize: pageSize,
          ),
        );
        return PageResult<DatabaseListItem>(
          items: response.data?.items
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
    final type = item.engine;
    final baseInfoResponse = await api.loadDatabaseBaseInfo(
      type: type,
      name: lookupName,
    );
    final rawConfigResponse = await api.loadDatabaseConfigFile(
      type: type,
      name: lookupName,
    );

    Map<String, dynamic>? status;
    Map<String, dynamic>? variables;
    Map<String, dynamic>? redisConf;
    Map<String, dynamic>? redisPersistence;
    bool? remoteAccess;
    List<Map<String, dynamic>> formatOptions = const <Map<String, dynamic>>[];

    if (item.scope == DatabaseScope.mysql) {
      status = (await api.loadMysqlStatus(type: type, name: lookupName)).data;
      variables =
          (await api.loadMysqlVariables(type: type, name: lookupName)).data;
      remoteAccess =
          (await api.loadRemoteAccess(type: type, name: lookupName)).data;
      formatOptions =
          (await api.loadFormatCollations(lookupName)).data ?? const [];
    } else if (item.scope == DatabaseScope.redis) {
      status = (await api.loadRedisStatus(type: type, name: lookupName)).data;
      redisConf = (await api.loadRedisConf(type: type, name: lookupName)).data;
      redisPersistence =
          (await api.loadRedisPersistenceConf(type: type, name: lookupName))
              .data;
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
      rawConfigFile: rawConfigResponse.data,
      formatOptions: formatOptions,
    );
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
        'password': input.password,
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
      'database': input.engine,
      'format': input.format,
      'username': input.username,
      'password': input.password,
      'description': input.description,
    };
    switch (input.scope) {
      case DatabaseScope.mysql:
        await api.createMysqlDatabase(payload);
        return;
      case DatabaseScope.postgresql:
        await api.createPostgresqlDatabase({
          ...payload,
          'superUser': false,
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
        'database': item.engine,
        'username': username,
        'password': password,
        'superUser': false,
      });
      return;
    }
    await api.bindMysqlUser({
      'database': item.engine,
      'db': item.name,
      'username': username,
      'password': password,
      'permission': '%',
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
}
