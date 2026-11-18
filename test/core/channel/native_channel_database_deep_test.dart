import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/core/channel/native_channel_database_deep_handlers.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 数据库深度通道契约（B4）。
///
/// 契约单一事实源：docs/development/modules/b4_database_channel_contract.md。
/// 覆盖：23 个 method 全量注册查表、读通道透传 golden、写通道成功/失败
/// 返回形态、必填参数缺失快速失败（不发网络请求）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const readMethods = <String>[
    'getDatabaseBaseInfo',
    'getDatabaseConfFile',
    'getMysqlVariables',
    'getMysqlStatus',
    'getRedisConf',
    'getRedisStatus',
    'getRedisPersistence',
    'getDatabaseRemoteAccess',
    'getDatabaseUsers',
    'getDatabaseGrants',
    'getDatabaseBackups',
  ];
  const writeMethods = <String>[
    'updateDatabaseConfFile',
    'updateMysqlVariables',
    'updateRedisConf',
    'updateRedisPersistence',
    'changeRedisPassword',
    'updateDatabaseAccess',
    'updateDatabaseUserPassword',
    'createDatabaseUser',
    'deleteDatabaseUser',
    'updateDatabaseUser',
    'grantDatabaseUser',
    'revokeDatabaseGrant',
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    NativeChannelDatabaseDeepHandlers.databaseApiFactory = null;
    NativeChannelDatabaseDeepHandlers.backupApiFactory = null;
  });

  group('注册查表：23 个 method 全部在 dispatch 注册', () {
    test('11 个读 method 路由命中（缺参返回空值而非 MissingPluginException）',
        () async {
      for (final method in readMethods) {
        final result = await NativeChannelManager.instance.handleMethodCall(
          method,
          <String, dynamic>{},
        );
        expect(
          result,
          anyOf(isEmpty, isNull),
          reason: '$method 未注册或缺参惯例被破坏',
        );
      }
    });

    test('12 个写 method 路由命中（缺参返回失败结构而非 MissingPluginException）',
        () async {
      for (final method in writeMethods) {
        final result = await NativeChannelManager.instance.handleMethodCall(
          method,
          <String, dynamic>{},
        );
        expect(result, isA<Map<String, dynamic>>(), reason: '$method 未注册');
        expect(result['success'], isFalse, reason: '$method 缺参未快速失败');
        expect(result['error'], isNotNull, reason: '$method 缺少 error 字段');
      }
    });

    test('读 11 + 写 12 = 23', () {
      expect(readMethods.length + writeMethods.length, 23);
    });
  });

  group('读通道透传 golden（fake adapter，不触网）', () {
    test('getMysqlVariables 原样返回底层 data map', () async {
      final underlying = <String, dynamic>{
        'binlog_format': 'ROW',
        'innodb_buffer_pool_size': '134217728',
        'max_connections': '151',
      };
      final capturedPaths = <String>[];
      NativeChannelDatabaseDeepHandlers.databaseApiFactory = () async =>
          _fakeDatabaseApi((options) async {
            capturedPaths.add(options.uri.path);
            return _jsonBody(<String, dynamic>{
              'code': 200,
              'message': 'success',
              'data': underlying,
            });
          });

      final result =
          await NativeChannelDatabaseDeepHandlers.getMysqlVariables(
        <String, dynamic>{'type': 'mysql', 'name': 'mysql1'},
      );

      expect(result, equals(underlying));
      expect(capturedPaths.single, endsWith('/databases/variables'));
    });

    test('getDatabaseConfFile 返回 {content: 底层字符串}', () async {
      NativeChannelDatabaseDeepHandlers.databaseApiFactory = () async =>
          _fakeDatabaseApi((options) async => _jsonBody(<String, dynamic>{
                'code': 200,
                'message': 'success',
                'data': '[mysqld]\nport=3306',
              }));

      final result = await NativeChannelDatabaseDeepHandlers.getDatabaseConfFile(
        <String, dynamic>{'type': 'mysql-conf', 'name': 'mysql1'},
      );

      expect(result['content'], '[mysqld]\nport=3306');
    });

    test('getDatabaseBackups 拼装 searchBackupRecords 分页结构', () async {
      final capturedBodies = <dynamic>[];
      NativeChannelDatabaseDeepHandlers.backupApiFactory = () async =>
          _fakeBackupApi((options) async {
            capturedBodies.add(options.data);
            return _jsonBody(<String, dynamic>{
              'code': 200,
              'message': 'success',
              'data': <String, dynamic>{
                'items': <dynamic>[
                  <String, dynamic>{
                    'id': 7,
                    'name': 'mysql1',
                    'type': 'mysql',
                    'fileName': 'db-mysql1-2026.sql',
                    'size': 1024,
                    'status': 'Success',
                  },
                ],
                'total': 1,
                'page': 1,
                'pageSize': 20,
                'totalPages': 1,
              },
            });
          });

      final result = await NativeChannelDatabaseDeepHandlers.getDatabaseBackups(
        <String, dynamic>{'type': 'mysql', 'name': 'mysql1', 'detailName': 'db1'},
      );

      expect(result['total'], 1);
      final items = result['items'] as List<dynamic>;
      expect(items.single['fileName'], 'db-mysql1-2026.sql');
      expect(items.single['id'], 7);
      // POST /backups/record/search 按业务类型 + 服务名 + 库名筛选。
      expect(
        (capturedBodies.single as Map<dynamic, dynamic>)['type'],
        'mysql',
      );
      expect(
        (capturedBodies.single as Map<dynamic, dynamic>)['detailName'],
        'db1',
      );
    });
  });

  group('写通道返回形态（fake adapter，不触网）', () {
    test('changeRedisPassword 成功返回 {success: true}，密码 base64 后走 value 键',
        () async {
      RequestOptions? captured;
      NativeChannelDatabaseDeepHandlers.databaseApiFactory = () async =>
          _fakeDatabaseApi((options) async {
            captured = options;
            return _jsonBody(<String, dynamic>{
              'code': 200,
              'message': 'success',
            });
          });

      final result =
          await NativeChannelDatabaseDeepHandlers.changeRedisPassword(
        <String, dynamic>{'database': 'redis-main', 'password': 's3cret'},
      );

      expect(result['success'], isTrue);
      expect(captured!.uri.path, endsWith('/databases/redis/password'));
      final body = captured!.data as Map<dynamic, dynamic>;
      expect(body['database'], 'redis-main');
      // 上游前端 changeRedisPassword：encodeBase64(password) 后以 value 提交。
      expect(body['value'], base64.encode(utf8.encode('s3cret')));
      expect(body.containsKey('password'), isFalse);
    });

    test('changeRedisPassword 失败返回 {success: false, error}', () async {
      NativeChannelDatabaseDeepHandlers.databaseApiFactory = () async =>
          _fakeDatabaseApi((options) async =>
              _jsonBody(<String, dynamic>{'code': 400, 'message': 'redis error'},
                  status: 400));

      final result =
          await NativeChannelDatabaseDeepHandlers.changeRedisPassword(
        <String, dynamic>{'database': 'redis-main', 'password': 's3cret'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('updateDatabaseUserPassword 成功返回 {success: true}，密码 base64', () async {
      RequestOptions? captured;
      NativeChannelDatabaseDeepHandlers.databaseApiFactory = () async =>
          _fakeDatabaseApi((options) async {
            captured = options;
            return _jsonBody(<String, dynamic>{
              'code': 200,
              'message': 'success',
            });
          });

      final result =
          await NativeChannelDatabaseDeepHandlers.updateDatabaseUserPassword(
        <String, dynamic>{
          'database': 'mysql-main',
          'username': 'app',
          'host': '%',
          'password': 'pw',
        },
      );

      expect(result['success'], isTrue);
      expect(captured!.uri.path, endsWith('/databases/users/password'));
      expect(
        (captured!.data as Map<dynamic, dynamic>)['password'],
        base64.encode(utf8.encode('pw')),
      );
    });
  });

  group('必填参数缺失快速失败（不触网）', () {
    test('updateRedisConf 缺 dbType 快速失败', () async {
      final result = await NativeChannelDatabaseDeepHandlers.updateRedisConf(
        <String, dynamic>{
          'database': 'redis-main',
          'timeout': '0',
          'maxclients': '10000',
          'maxmemory': '0',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('dbType'));
    });

    test('createDatabaseUser 缺 password 快速失败', () async {
      final result = await NativeChannelDatabaseDeepHandlers.createDatabaseUser(
        <String, dynamic>{
          'database': 'mysql-main',
          'username': 'app',
          'host': '%',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('password'));
    });

    test('updateDatabaseAccess 缺 id 快速失败', () async {
      final result = await NativeChannelDatabaseDeepHandlers.updateDatabaseAccess(
        <String, dynamic>{
          'from': 'local',
          'type': 'mysql',
          'database': 'db1',
          'value': '%',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id is required'));
    });

    test('grantDatabaseUser 缺 db 快速失败', () async {
      final result = await NativeChannelDatabaseDeepHandlers.grantDatabaseUser(
        <String, dynamic>{
          'database': 'mysql-main',
          'username': 'app',
          'host': '%',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('db'));
    });

    test('updateMysqlVariables variables 非列表快速失败', () async {
      final result = await NativeChannelDatabaseDeepHandlers.updateMysqlVariables(
        <String, dynamic>{
          'type': 'mysql',
          'database': 'mysql-main',
          'variables': 'not-a-list',
        },
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('variables'));
    });

    test('读通道缺参空值惯例：getRedisStatus 缺 type 返回空映射', () async {
      final result = await NativeChannelDatabaseDeepHandlers.getRedisStatus(
        <String, dynamic>{'name': 'redis-main'},
      );

      expect(result, isEmpty);
    });
  });
}

/// 构造带 fake adapter 的 DatabaseV2Api（ DioClient 拦截器链照常工作，
/// 请求不触网，由 [responder] 直接应答/抛错）。
DatabaseV2Api _fakeDatabaseApi(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final client = DioClient(baseUrl: 'http://localhost:9', apiKey: 'test-key');
  client.dio.httpClientAdapter = _FakeAdapter(responder);
  return DatabaseV2Api(client);
}

/// 构造带 fake adapter 的 BackupAccountV2Api。
BackupAccountV2Api _fakeBackupApi(
  Future<ResponseBody> Function(RequestOptions options) responder,
) {
  final client = DioClient(baseUrl: 'http://localhost:9', apiKey: 'test-key');
  client.dio.httpClientAdapter = _FakeAdapter(responder);
  return BackupAccountV2Api(client);
}

/// 1Panel `{code, message, data?}` JSON 信封响应体。
ResponseBody _jsonBody(dynamic payload, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._responder);

  final Future<ResponseBody> Function(RequestOptions options) _responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _responder(options);
  }

  @override
  void close({bool force = false}) {}
}
