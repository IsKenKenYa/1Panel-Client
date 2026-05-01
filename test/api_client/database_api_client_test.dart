import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';

import '../api_client_test_base.dart';
import '../core/test_config_manager.dart';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _logSection(
  String title, {
  String? method,
  String? path,
  Object? request,
  Object? response,
}) {
  const pkg = 'test.api_client.database';
  appLogger.dWithPackage(pkg, '========================================');
  appLogger.dWithPackage(pkg, title);
  if (method != null && path != null) {
    appLogger.dWithPackage(pkg, 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(pkg, 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(pkg, 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage(pkg, '========================================');
}

Future<Response<dynamic>> _rawGet(DioClient client, String path) {
  return client.get<dynamic>(ApiConstants.buildApiPath(path));
}

Future<Response<dynamic>> _rawPost(
  DioClient client,
  String path, {
  dynamic data,
}) {
  return client.post<dynamic>(
    ApiConstants.buildApiPath(path),
    data: data,
  );
}

dynamic _expectSuccessEnvelope(dynamic raw, {required String path}) {
  expect(raw, isA<Map>(), reason: '$path should return a wrapped object');
  final envelope = Map<String, dynamic>.from(raw as Map);
  expect(envelope['code'], equals(200), reason: '$path should return code=200');
  expect(envelope.containsKey('data'), isTrue,
      reason: '$path should contain data');
  return envelope['data'];
}

Map<String, dynamic> _expectPagePayload(dynamic payload,
    {required String path}) {
  expect(payload, isA<Map>(), reason: '$path data should be a page object');
  final page = Map<String, dynamic>.from(payload as Map);
  expect(page['total'], isA<int>(), reason: '$path total should be int');
  expect(page.containsKey('items'), isTrue,
      reason: '$path page data should contain items');
  final items = page['items'];
  expect(items == null || items is List, isTrue,
      reason: '$path items should be null or list');
  return page;
}

List<dynamic> _expectListPayload(dynamic payload, {required String path}) {
  if (payload == null) {
    return const <dynamic>[];
  }
  expect(payload, isA<List>(), reason: '$path data should be a list');
  return List<dynamic>.from(payload as List);
}

void _expectDatabaseInfo(DatabaseInfo database) {
  TestDataValidator.expectPositiveInt(database.id, fieldName: 'database.id');
  TestDataValidator.expectNonEmptyString(
    database.name,
    fieldName: 'database.name',
  );
  TestDataValidator.expectNonEmptyString(
    database.type,
    fieldName: 'database.type',
  );
  TestDataValidator.expectNonEmptyString(
    database.version,
    fieldName: 'database.version',
  );
  TestDataValidator.expectNonEmptyString(
    database.status,
    fieldName: 'database.status',
  );
}

void _expectDatabaseOption(Map<String, dynamic> item, {required String path}) {
  expect(item, isNotEmpty, reason: '$path item should not be empty');
  expect(
    item.containsKey('name') ||
        item.containsKey('database') ||
        item.containsKey('type'),
    isTrue,
    reason: '$path item should expose database identity fields',
  );
}

void _expectItemOption(DatabaseItemOption item) {
  expect(item.id, greaterThanOrEqualTo(0));
  expect(item.name, isA<String>());
  expect(item.database, isA<String>());
  expect(item.from, isA<String>());
}

void _expectStatusShape(
  Map<String, dynamic> rawData,
  Map<String, dynamic>? parsedData, {
  required List<String> requiredKeys,
}) {
  expect(parsedData, isNotNull);
  for (final key in requiredKeys) {
    expect(rawData.containsKey(key), isTrue,
        reason: 'raw status should contain $key');
    expect(parsedData!.containsKey(key), isTrue,
        reason: 'parsed status should contain $key');
    expect(parsedData[key]?.runtimeType, equals(rawData[key]?.runtimeType));
  }
}

String? _skipReason() {
  return TestEnvironment.skipIntegration() ?? TestEnvironment.skipNoApiKey();
}

Future<DatabaseListItem?> _firstMysqlTarget(DatabaseV2Api api) async {
  final items = await api.listDbItems('mysql,mariadb');
  if (items.data == null || items.data!.isEmpty) {
    return null;
  }
  return DatabaseListItem.fromDatabaseOption(
    items.data!.first.toJson(),
    DatabaseScope.mysql,
  );
}

Future<DatabaseListItem?> _firstRedisTarget(DatabaseV2Api api) async {
  final items = await api.listDatabases('redis,redis-cluster');
  if (items.data == null || items.data!.isEmpty) {
    return null;
  }
  return DatabaseListItem.fromDatabaseOption(
    items.data!.first,
    DatabaseScope.redis,
  );
}

void main() {
  late DioClient client;
  late DatabaseV2Api api;
  bool canRun = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    final apiKey = TestEnvironment.config.getString('PANEL_API_KEY');
    canRun = TestEnvironment.runIntegrationTests &&
        apiKey.isNotEmpty &&
        apiKey != 'your_api_key_here';

    if (canRun) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: apiKey,
      );
      api = DatabaseV2Api(client);
    }
  });

  group('Database API客户端测试', () {
    test('配置验证 - API密钥已配置', () {
      _logSection(
        'Database API测试配置',
        response: <String, dynamic>{
          'baseUrl': TestEnvironment.baseUrl,
          'apiKeyConfigured': canRun,
          'runIntegrationTests': TestEnvironment.runIntegrationTests,
        },
      );
      expect(canRun, equals(TestEnvironment.canRunIntegrationTests));
    });

    test('POST /databases/db/search 返回分页结构并解析为 DatabaseInfo', () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      const request = DatabaseSearch(
        page: 1,
        pageSize: 10,
        orderBy: 'createdAt',
        order: 'descending',
      );
      final raw = await _rawPost(
        client,
        '/databases/db/search',
        data: request.toJson(),
      );
      _logSection(
        '✅ Raw /databases/db/search',
        method: 'POST',
        path: '/databases/db/search',
        request: request.toJson(),
        response: raw.data,
      );

      final rawPage = _expectPagePayload(
          _expectSuccessEnvelope(raw.data, path: '/databases/db/search'),
          path: '/databases/db/search');
      final parsed = await api.searchDatabases(request);
      _logSection(
        '✅ Parsed /databases/db/search',
        response: <String, dynamic>{
          'total': parsed.data?.total,
          'pageSize': parsed.data?.pageSize,
          'items':
              parsed.data?.items.take(3).map((item) => item.toJson()).toList(),
        },
      );

      expect(parsed.statusCode, equals(200));
      expect(parsed.data, isA<PageResult<DatabaseInfo>>());
      expect(parsed.data!.total, equals(rawPage['total']));

      final rawItems = rawPage['items'] as List?;
      expect(parsed.data!.items.length, equals(rawItems?.length ?? 0));
      for (final database in parsed.data!.items) {
        _expectDatabaseInfo(database);
      }
    });

    test('POST /databases/search 返回 MySQL/MariaDB 分页结构', () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      final targets = await api.listDatabases('mysql,mariadb');
      if (targets.data == null || targets.data!.isEmpty) {
        appLogger.wWithPackage(
          'test.api_client.database',
          '跳过 /databases/search: 当前环境没有可安全查询的 MySQL/MariaDB 实例',
        );
        return;
      }

      final target = DatabaseListItem.fromDatabaseOption(
        targets.data!.first,
        DatabaseScope.mysql,
      );
      final request = DatabaseSearch(
        database: target.lookupName,
        page: 1,
        pageSize: 10,
        orderBy: 'createdAt',
        order: 'descending',
      );
      final raw = await _rawPost(
        client,
        '/databases/search',
        data: request.toJson(),
      );
      _logSection(
        '✅ Raw /databases/search',
        method: 'POST',
        path: '/databases/search',
        request: request.toJson(),
        response: raw.data,
      );

      final rawPage = _expectPagePayload(
        _expectSuccessEnvelope(raw.data, path: '/databases/search'),
        path: '/databases/search',
      );
      final parsed = await api.searchMysqlDatabases(request);
      _logSection(
        '✅ Parsed /databases/search',
        response: <String, dynamic>{
          'total': parsed.data?.total,
          'items': parsed.data?.items.take(3).toList(),
        },
      );

      expect(parsed.statusCode, equals(200));
      expect(parsed.data, isA<PageResult<Map<String, dynamic>>>());
      expect(parsed.data!.total, equals(rawPage['total']));

      final rawItems = rawPage['items'] as List?;
      expect(parsed.data!.items.length, equals(rawItems?.length ?? 0));
      for (final item in parsed.data!.items) {
        _expectDatabaseOption(item, path: '/databases/search');
      }
    });

    test('POST /databases/pg/search 返回 PostgreSQL 分页结构', () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      final targets = await api.listDatabases('postgresql');
      if (targets.data == null || targets.data!.isEmpty) {
        appLogger.wWithPackage(
          'test.api_client.database',
          '跳过 /databases/pg/search: 当前环境没有可安全查询的 PostgreSQL 实例',
        );
        return;
      }

      final target = DatabaseListItem.fromDatabaseOption(
        targets.data!.first,
        DatabaseScope.postgresql,
      );
      final request = DatabaseSearch(
        database: target.lookupName,
        page: 1,
        pageSize: 10,
        orderBy: 'createdAt',
        order: 'descending',
      );
      final raw = await _rawPost(
        client,
        '/databases/pg/search',
        data: request.toJson(),
      );
      _logSection(
        '✅ Raw /databases/pg/search',
        method: 'POST',
        path: '/databases/pg/search',
        request: request.toJson(),
        response: raw.data,
      );

      final rawPage = _expectPagePayload(
        _expectSuccessEnvelope(raw.data, path: '/databases/pg/search'),
        path: '/databases/pg/search',
      );
      final parsed = await api.searchPostgresqlDatabases(request);
      _logSection(
        '✅ Parsed /databases/pg/search',
        response: <String, dynamic>{
          'total': parsed.data?.total,
          'items': parsed.data?.items.take(3).toList(),
        },
      );

      expect(parsed.statusCode, equals(200));
      expect(parsed.data, isA<PageResult<Map<String, dynamic>>>());
      expect(parsed.data!.total, equals(rawPage['total']));

      final rawItems = rawPage['items'] as List?;
      expect(parsed.data!.items.length, equals(rawItems?.length ?? 0));
      for (final item in parsed.data!.items) {
        _expectDatabaseOption(item, path: '/databases/pg/search');
      }
    });

    test('GET /databases/db/list/redis,redis-cluster 返回列表结构', () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      final raw =
          await _rawGet(client, '/databases/db/list/redis,redis-cluster');
      _logSection(
        '✅ Raw /databases/db/list/redis,redis-cluster',
        method: 'GET',
        path: '/databases/db/list/redis,redis-cluster',
        response: raw.data,
      );

      final rawList = _expectListPayload(
        _expectSuccessEnvelope(raw.data,
            path: '/databases/db/list/redis,redis-cluster'),
        path: '/databases/db/list/redis,redis-cluster',
      );
      final parsed = await api.listDatabases('redis,redis-cluster');
      _logSection(
        '✅ Parsed /databases/db/list/redis,redis-cluster',
        response: parsed.data?.take(3).toList(),
      );

      expect(parsed.statusCode, equals(200));
      expect(parsed.data, isA<List<Map<String, dynamic>>>());
      expect(parsed.data!.length, equals(rawList.length));
      for (final item in parsed.data!) {
        _expectDatabaseOption(
          item,
          path: '/databases/db/list/redis,redis-cluster',
        );
      }
    });

    test('GET /databases/db/item/mysql,mariadb 返回数据库目标选项结构', () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      final raw = await _rawGet(client, '/databases/db/item/mysql,mariadb');
      _logSection(
        '✅ Raw /databases/db/item/mysql,mariadb',
        method: 'GET',
        path: '/databases/db/item/mysql,mariadb',
        response: raw.data,
      );

      final rawList = _expectListPayload(
        _expectSuccessEnvelope(raw.data,
            path: '/databases/db/item/mysql,mariadb'),
        path: '/databases/db/item/mysql,mariadb',
      );
      final parsed = await api.listDbItems('mysql,mariadb');
      _logSection(
        '✅ Parsed /databases/db/item/mysql,mariadb',
        response: parsed.data?.take(3).map((item) => item.toJson()).toList(),
      );

      expect(parsed.statusCode, equals(200));
      expect(parsed.data, isA<List<DatabaseItemOption>>());
      expect(parsed.data!.length, equals(rawList.length));
      for (final item in parsed.data!) {
        _expectItemOption(item);
      }
    });

    test('GET /databases/redis/check 返回布尔结构', () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      final raw = await _rawGet(client, '/databases/redis/check');
      _logSection(
        '✅ Raw /databases/redis/check',
        method: 'GET',
        path: '/databases/redis/check',
        response: raw.data,
      );

      final rawValue =
          _expectSuccessEnvelope(raw.data, path: '/databases/redis/check');
      expect(rawValue, isA<bool>());

      final parsed = await api.checkRedisCli();
      _logSection(
        '✅ Parsed /databases/redis/check',
        response: <String, dynamic>{'value': parsed.data},
      );

      expect(parsed.statusCode, equals(200));
      expect(parsed.data, isA<bool>());
      expect(parsed.data, equals(rawValue));
    });

    test('POST /databases/common/info 返回数据库基础信息结构', () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      final target = await _firstMysqlTarget(api);
      if (target == null) {
        appLogger.wWithPackage(
          'test.api_client.database',
          '跳过 /databases/common/info: 当前环境没有可安全读取的 MySQL/MariaDB 实例',
        );
        return;
      }

      final request = <String, dynamic>{
        'type': target.engine,
        'name': target.lookupName,
      };
      final raw =
          await _rawPost(client, '/databases/common/info', data: request);
      _logSection(
        '✅ Raw /databases/common/info',
        method: 'POST',
        path: '/databases/common/info',
        request: request,
        response: raw.data,
      );

      final rawData = Map<String, dynamic>.from(
        _expectSuccessEnvelope(raw.data, path: '/databases/common/info') as Map,
      );
      final parsed = await api.loadDatabaseBaseInfo(
        type: target.engine,
        name: target.lookupName,
      );

      expect(parsed.statusCode, equals(200));
      expect(parsed.data, isA<Map<String, dynamic>>());
      expect(parsed.data, equals(rawData));
    });

    test('POST /databases/status 与 /databases/variables 返回 MySQL 详情结构',
        () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      final target = await _firstMysqlTarget(api);
      if (target == null) {
        appLogger.wWithPackage(
          'test.api_client.database',
          '跳过 MySQL 详情读接口: 当前环境没有可安全读取的 MySQL/MariaDB 实例',
        );
        return;
      }

      final request = <String, dynamic>{
        'type': target.engine,
        'name': target.lookupName,
      };

      final rawStatus =
          await _rawPost(client, '/databases/status', data: request);
      final rawStatusData = Map<String, dynamic>.from(
        _expectSuccessEnvelope(rawStatus.data, path: '/databases/status')
            as Map,
      );
      final parsedStatus = await api.loadMysqlStatus(
        type: target.engine,
        name: target.lookupName,
      );
      expect(parsedStatus.statusCode, equals(200));
      _expectStatusShape(
        rawStatusData,
        parsedStatus.data,
        requiredKeys: const <String>[
          'Connections',
          'Questions',
          'Uptime',
        ],
      );

      final rawVariables =
          await _rawPost(client, '/databases/variables', data: request);
      final rawVariablesData = Map<String, dynamic>.from(
        _expectSuccessEnvelope(rawVariables.data, path: '/databases/variables')
            as Map,
      );
      final parsedVariables = await api.loadMysqlVariables(
        type: target.engine,
        name: target.lookupName,
      );
      expect(parsedVariables.statusCode, equals(200));
      expect(parsedVariables.data, equals(rawVariablesData));
    });

    test('POST /databases/redis/status/conf/persistence/conf 返回 Redis 详情结构',
        () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      final target = await _firstRedisTarget(api);
      if (target == null) {
        appLogger.wWithPackage(
          'test.api_client.database',
          '跳过 Redis 详情读接口: 当前环境没有可安全读取的 Redis 实例',
        );
        return;
      }

      final request = <String, dynamic>{
        'type': target.engine,
        'name': target.lookupName,
      };

      final rawStatus =
          await _rawPost(client, '/databases/redis/status', data: request);
      final rawStatusData = Map<String, dynamic>.from(
        _expectSuccessEnvelope(rawStatus.data, path: '/databases/redis/status')
            as Map,
      );
      final parsedStatus = await api.loadRedisStatus(
        type: target.engine,
        name: target.lookupName,
      );
      expect(parsedStatus.statusCode, equals(200));
      _expectStatusShape(
        rawStatusData,
        parsedStatus.data,
        requiredKeys: const <String>[
          'tcp_port',
          'used_memory',
          'latest_fork_usec',
        ],
      );

      final rawConf =
          await _rawPost(client, '/databases/redis/conf', data: request);
      final rawConfData = Map<String, dynamic>.from(
        _expectSuccessEnvelope(rawConf.data, path: '/databases/redis/conf')
            as Map,
      );
      final parsedConf = await api.loadRedisConf(
        type: target.engine,
        name: target.lookupName,
      );
      expect(parsedConf.statusCode, equals(200));
      expect(parsedConf.data, equals(rawConfData));

      final rawPersistence = await _rawPost(
          client, '/databases/redis/persistence/conf',
          data: request);
      final rawPersistenceData = Map<String, dynamic>.from(
        _expectSuccessEnvelope(
          rawPersistence.data,
          path: '/databases/redis/persistence/conf',
        ) as Map,
      );
      final parsedPersistence = await api.loadRedisPersistenceConf(
        type: target.engine,
        name: target.lookupName,
      );
      expect(parsedPersistence.statusCode, equals(200));
      expect(parsedPersistence.data, equals(rawPersistenceData));
    });
  });

  group('Database API性能测试', () {
    test('searchDatabases响应时间应该小于3秒', () async {
      final skipReason = _skipReason();
      if (skipReason != null) {
        appLogger.wWithPackage('test.api_client.database', '跳过测试: $skipReason');
        return;
      }

      final timer = TestPerformanceTimer('searchDatabases');
      timer.start();
      await api.searchDatabases(
        const DatabaseSearch(
          page: 1,
          pageSize: 10,
          orderBy: 'createdAt',
          order: 'descending',
        ),
      );
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });

  group('Database enums helper', () {
    test('DatabaseType.fromString recognizes value and falls back to mysql',
        () {
      expect(DatabaseType.fromString('mysql'), DatabaseType.mysql);
      expect(DatabaseType.fromString('~unknown~'), DatabaseType.mysql);
    });

    test('DatabaseStatus.fromString falls back to stopped', () {
      expect(DatabaseStatus.fromString('running'), DatabaseStatus.running);
      expect(DatabaseStatus.fromString('invalid'), DatabaseStatus.stopped);
    });
  });
}
