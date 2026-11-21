import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/auth_v2.dart';
import 'package:onepanel_client/api/v2/command_v2.dart';
import 'package:onepanel_client/api/v2/container_v2.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/api/v2/script_library_v2.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/api/v2/toolbox_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';

void main() {
  group('Whitelist endpoint alignment', () {
    late HttpServer server;
    late DioClient client;
    late String requestMethod;
    late String requestPath;
    late Map<String, dynamic>? requestBody;
    late dynamic Function() responseBuilder;

    setUp(() async {
      requestMethod = '';
      requestPath = '';
      requestBody = null;
      responseBuilder = () => <String, dynamic>{'code': 200, 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;

        final raw = await utf8.decoder.bind(request).join();
        if (raw.isNotEmpty) {
          requestBody = jsonDecode(raw) as Map<String, dynamic>;
        } else {
          requestBody = null;
        }

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder()));
        await request.response.close();
      });

      client = DioClient(
        baseUrl: 'http://${server.address.host}:${server.port}',
        apiKey: 'test-key',
      );
    });

    tearDown(() async {
      await server.close(force: true);
    });

    group('Database - whitelist endpoints', () {
      test('updateDatabase aligns POST /databases/update', () async {
        final api = DatabaseV2Api(client);
        await api.updateDatabase(const DatabaseUpdate(
          id: 42,
          name: 'mydb',
          type: 'mysql',
          description: 'updated',
        ));

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/databases/update');
        expect(requestBody, isNotNull);
        expect(requestBody!['id'], 42);
        expect(requestBody!['name'], 'mydb');
        expect(requestBody!['type'], 'mysql');
      });

      test('searchDatabaseBackups aligns POST /databases/{id}/backups',
          () async {
        responseBuilder = () => <String, dynamic>{
              'code': 200,
              'data': <String, dynamic>{
                'total': 0,
                'items': <dynamic>[],
              },
            };

        final api = DatabaseV2Api(client);
        await api.searchDatabaseBackups(
          7,
          const RecordSearch(page: 1, pageSize: 10),
        );

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/databases/7/backups');
        expect(requestBody, isNotNull);
        expect(requestBody!['page'], 1);
        expect(requestBody!['pageSize'], 10);
      });

      test('getDatabasePrivileges aligns GET /databases/{id}/privileges',
          () async {
        responseBuilder = () => <String, dynamic>{
              'code': 200,
              'data': <dynamic>[
                <String, dynamic>{'user': 'admin', 'privilege': 'all'},
              ],
            };

        final api = DatabaseV2Api(client);
        final response = await api.getDatabasePrivileges(5);

        expect(requestMethod, 'GET');
        expect(requestPath, '/api/v2/databases/5/privileges');
        expect(response.data, isNotNull);
      });

      test('updateDatabasePrivileges aligns POST /databases/{id}/privileges',
          () async {
        final api = DatabaseV2Api(client);
        await api.updateDatabasePrivileges(5, <String, dynamic>{
          'privileges': <String>['SELECT', 'INSERT'],
        });

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/databases/5/privileges');
        expect(requestBody, isNotNull);
        expect(requestBody!['privileges'], <String>['SELECT', 'INSERT']);
      });


      test('testDatabaseConnection aligns GET /databases/{id}/connection/test',
          () async {
        final api = DatabaseV2Api(client);
        await api.testDatabaseConnection(9);

        expect(requestMethod, 'GET');
        expect(requestPath, '/api/v2/databases/9/connection/test');
      });
    });

    group('Container - createContainerByCommand', () {
      test('aligns POST /containers/command', () async {
        final api = ContainerV2Api(client);
        await api.createContainerByCommand(
          const ContainerCreateByCommand(
            command: 'docker run -d nginx',
            name: 'my-nginx',
          ),
        );

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/containers/command');
        expect(requestBody, <String, dynamic>{
          'command': 'docker run -d nginx',
          'name': 'my-nginx',
        });
      });
    });

    group('Toolbox - clean endpoints', () {
      test('getCleanData aligns GET /toolbox/clean/data', () async {
        responseBuilder = () => <dynamic>[
              <String, dynamic>{
                'name': 'cache',
                'size': '100MB',
                'type': 'system',
              },
            ];

        final api = ToolboxV2Api(client);
        final response = await api.getCleanData();

        expect(requestMethod, 'GET');
        expect(requestPath, '/api/v2/toolbox/clean/data');
        expect(response.data, isNotNull);
        expect(response.data, isNotEmpty);
      });

      test('getCleanTree aligns GET /toolbox/clean/tree', () async {
        responseBuilder = () => <dynamic>[
              <String, dynamic>{
                'name': 'root',
                'children': <dynamic>[],
              },
            ];

        final api = ToolboxV2Api(client);
        final response = await api.getCleanTree();

        expect(requestMethod, 'GET');
        expect(requestPath, '/api/v2/toolbox/clean/tree');
        expect(response.data, isNotNull);
      });

      test('getCleanLogs aligns POST /toolbox/clean/log', () async {
        responseBuilder = () => <String, dynamic>{
              'code': 200,
              'data': <String, dynamic>{
                'total': 0,
                'items': <dynamic>[],
              },
            };

        final api = ToolboxV2Api(client);
        await api.getCleanLogs(const PageRequest(page: 1, pageSize: 10));

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/toolbox/clean/log');
        expect(requestBody, isNotNull);
        expect(requestBody!['page'], 1);
        expect(requestBody!['pageSize'], 10);
      });
    });

    group('Setting - backup/MFA/reset/SSH endpoints', () {
      test('deleteBackupAccount aligns POST /backups/del', () async {
        final api = SettingV2Api(client);
        await api.deleteBackupAccount(const BackupAccountDelete(id: 42));

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/backups/del');
        expect(requestBody, <String, dynamic>{'id': 42});
      });

      test('closeMfa sends no request body', () async {
        await AuthV2Api(client).closeMfa();

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/auth/mfa/close');
        expect(requestBody, isNull);
      });

      test('resetSystemSetting aligns POST /core/settings/reset', () async {
        final api = SettingV2Api(client);
        await api.resetSystemSetting();

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/settings/reset');
      });

      test('saveSSHConnection aligns POST /settings/ssh', () async {
        final api = SettingV2Api(client);
        await api.saveSSHConnection(const SSHConnectionSave(
          addr: '192.168.1.1',
          port: 22,
          user: 'root',
          authMode: 'password',
        ));

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/settings/ssh');
        expect(requestBody, isNotNull);
        expect(requestBody!['addr'], '192.168.1.1');
        expect(requestBody!['port'], 22);
      });
    });

    group('Host - testHostById with legacy fallback', () {
      test('testHostById uses POST /core/hosts/test/byid/{id} primarily',
          () async {
        responseBuilder = () => <String, dynamic>{
              'code': 200,
              'data': true,
            };

        final api = HostV2Api(client);
        await api.testHostById(7);

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/hosts/test/byid/7');
      });
    });

    group('Command - tree and script endpoints', () {
      test('getCommandTree aligns POST /core/commands/tree', () async {
        responseBuilder = () => <String, dynamic>{
              'code': 200,
              'data': <dynamic>[],
            };

        final api = CommandV2Api(client);
        await api.getCommandTree();

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/commands/tree');
        expect(requestBody, isNotNull);
      });

      test('searchScript aligns POST /core/script/search (legacy)',
          () async {
        responseBuilder = () => <String, dynamic>{
              'code': 200,
              'data': <String, dynamic>{
                'total': 0,
                'items': <dynamic>[],
              },
            };

        final api = CommandV2Api(client);
        await api.searchScript(const PageRequest(page: 1, pageSize: 10));

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/script/search');
        expect(requestBody, isNotNull);
        expect(requestBody!['page'], 1);
      });

      test('createScript aligns POST /core/script (legacy)', () async {
        final api = CommandV2Api(client);
        await api.createScript(const ScriptOperate(
          name: 'test-script',
          script: 'echo hello',
        ));

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/script');
        expect(requestBody, isNotNull);
        expect(requestBody!['name'], 'test-script');
      });

      test('updateScript aligns POST /core/script/update (legacy)', () async {
        final api = CommandV2Api(client);
        await api.updateScript(const ScriptOperate(
          id: 1,
          name: 'updated-script',
          script: 'echo updated',
        ));

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/script/update');
        expect(requestBody, isNotNull);
        expect(requestBody!['id'], 1);
        expect(requestBody!['name'], 'updated-script');
      });
    });

    group('ScriptLibrary - core/script endpoints', () {
      test('searchScripts aligns POST /core/script/search', () async {
        responseBuilder = () => <String, dynamic>{
              'code': 200,
              'data': <String, dynamic>{
                'total': 0,
                'items': <dynamic>[],
              },
            };

        final api = ScriptLibraryV2Api(client);
        await api.searchScripts(
          const ScriptLibraryQuery(page: 1, pageSize: 10),
        );

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/script/search');
        expect(requestBody, isNotNull);
        expect(requestBody!['page'], 1);
      });

      test('syncScripts aligns POST /core/script/sync', () async {
        final api = ScriptLibraryV2Api(client);
        await api.syncScripts('task-123');

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/script/sync');
        expect(requestBody, <String, dynamic>{'taskID': 'task-123'});
      });

      test('deleteScripts aligns POST /core/script/del', () async {
        final api = ScriptLibraryV2Api(client);
        await api.deleteScripts(const ScriptDeleteRequest(ids: [1, 2, 3]));

        expect(requestMethod, 'POST');
        expect(requestPath, '/api/v2/core/script/del');
        expect(requestBody, <String, dynamic>{'ids': [1, 2, 3]});
      });
    });
  });
}
