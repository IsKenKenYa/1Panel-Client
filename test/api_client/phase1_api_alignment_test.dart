import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/api/v2/command_v2.dart';
import 'package:onepanel_client/api/v2/cronjob_v2.dart';
import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/api/v2/process_v2.dart';
import 'package:onepanel_client/api/v2/runtime_v2.dart';
import 'package:onepanel_client/api/v2/script_library_v2.dart';
import 'package:onepanel_client/api/v2/ssh_v2.dart';
import 'package:onepanel_client/api/v2/system_group_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/backup_request_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/cronjob_form_request_models.dart';
import 'package:onepanel_client/data/models/cronjob_form_response_models.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart'
    as group_models;

void main() {
  group('Phase 1 API alignment', () {
    late HttpServer server;
    late DioClient client;
    late Map<String, dynamic>? requestBody;
    late String requestMethod;
    late String requestPath;
    late Map<String, dynamic> Function() responseBuilder;

    setUp(() async {
      requestBody = null;
      requestMethod = '';
      requestPath = '';
      responseBuilder = () => <String, dynamic>{'code': 200, 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;
        final payload = await utf8.decoder.bind(request).join();
        requestBody = payload.isEmpty
            ? null
            : jsonDecode(payload) as Map<String, dynamic>;

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

    test('SystemGroupV2Api posts core group search request', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 1,
                'name': 'Default',
                'type': 'command',
                'isDefault': true,
              },
            ],
          };

      final api = SystemGroupV2Api(client);
      final response = await api.searchCoreGroups(
        const group_models.GroupSearch(type: 'command'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/core/groups/search');
      expect(requestBody, <String, dynamic>{'type': 'command'});
      expect(response.data, hasLength(1));
      expect(response.data!.first.isDefault, isTrue);
    });

    test('HostV2Api aligns search route and parses page payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 7,
                  'name': 'edge-01',
                  'address': '10.0.0.7',
                  'username': 'root',
                  'status': 'healthy',
                },
              ],
              'total': 1,
            },
          };

      final api = HostV2Api(client);
      final response = await api.searchHosts(
        const HostSearch(page: 1, pageSize: 20),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/core/hosts/search');
      expect(response.data?.items.single.name, 'edge-01');
      expect(response.data?.total, 1);
    });

    test('CommandV2Api aligns tree route to POST /core/commands/tree',
        () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'label': 'Default', 'value': 'default'},
            ],
          };

      final api = CommandV2Api(client);
      final response = await api.getCommandTree();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/core/commands/tree');
      expect(requestBody, <String, dynamic>{'type': 'command'});
      expect(response.data?.single.label, 'Default');
    });

    test('SshV2Api aligns settings route to POST /hosts/ssh/search', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'autoStart': true,
              'isExist': true,
              'isActive': true,
              'message': '',
              'port': '22',
              'listenAddress': '',
              'passwordAuthentication': 'yes',
              'pubkeyAuthentication': 'yes',
              'permitRootLogin': 'yes',
              'useDNS': 'no',
              'currentUser': 'root',
            },
          };

      final api = SshV2Api(client);
      final response = await api.getSshInfo();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/hosts/ssh/search');
      expect(response.data?.port, '22');
    });

    test('ProcessV2Api aligns listening route to POST /process/listening',
        () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'PID': 88, 'Name': 'sshd'},
            ],
          };

      final api = ProcessV2Api(client);
      final response = await api.getListeningProcesses();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/process/listening');
      expect(response.data?.single.name, 'sshd');
    });

    test('CronjobV2Api aligns load info route to POST /cronjobs/load/info',
        () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'id': 3, 'name': 'daily-backup'},
          };

      final api = CronjobV2Api(client);
      final response = await api.loadCronjobInfo(3);

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/load/info');
      expect(requestBody, <String, dynamic>{'id': 3});
      expect(response.data?.name, 'daily-backup');
    });

    test('CronjobV2Api aligns status route to POST /cronjobs/status', () async {
      final api = CronjobV2Api(client);
      await api.updateCronjobStatus(
        const CronjobStatusUpdate(id: 3, status: 'Enable'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/status');
      expect(requestBody, <String, dynamic>{'id': 3, 'status': 'Enable'});
    });

    test('CronjobV2Api aligns handle route to POST /cronjobs/handle', () async {
      final api = CronjobV2Api(client);
      await api.handleCronjobOnce(const CronjobHandleRequest(id: 3));

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/handle');
      expect(requestBody, <String, dynamic>{'id': 3});
    });

    test(
        'CronjobV2Api aligns record search and parses page payload from /cronjobs/search/records',
        () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 9,
                  'taskID': 'task-1',
                  'startTime': '2026-03-27 02:00:00',
                  'status': 'Success',
                  'message': 'done',
                  'targetPath': '/backup',
                  'interval': 900,
                  'file': 'backup.log',
                },
              ],
              'total': 1,
            },
          };

      final api = CronjobV2Api(client);
      final response = await api.searchCronjobRecords(
        const CronjobRecordQuery(cronjobId: 3, status: 'Success'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/search/records');
      expect(requestBody, <String, dynamic>{
        'cronjobID': 3,
        'page': 1,
        'pageSize': 20,
        'status': 'Success',
      });
      expect(response.data?.items.single.taskId, 'task-1');
    });

    test('CronjobV2Api aligns record log route to POST /cronjobs/records/log',
        () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': 'line-1\nline-2',
          };

      final api = CronjobV2Api(client);
      final response = await api.getRecordLog(9);

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/records/log');
      expect(requestBody, <String, dynamic>{'id': 9});
      expect(response.data, contains('line-1'));
    });

    test('CronjobV2Api aligns clean route to POST /cronjobs/records/clean',
        () async {
      final api = CronjobV2Api(client);
      await api.cleanRecords(
        const CronjobRecordCleanRequest(
          cronjobId: 3,
          cleanData: true,
          cleanRemoteData: false,
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/records/clean');
      expect(requestBody, <String, dynamic>{
        'cronjobID': 3,
        'cleanData': true,
        'cleanRemoteData': false,
      });
    });

    test(
        'CronjobV2Api aligns script options route to GET /cronjobs/script/options',
        () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': 5, 'name': 'Demo'},
            ],
          };

      final api = CronjobV2Api(client);
      final response = await api.getScriptOptions();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/cronjobs/script/options');
      expect(response.data?.single.name, 'Demo');
    });

    test('CronjobV2Api aligns create/update/delete form routes', () async {
      final api = CronjobV2Api(client);
      await api.createCronjob(
        const CronjobOperateRequest(
          name: 'nightly',
          groupID: 1,
          type: 'shell',
          specCustom: true,
          spec: '0 0 * * *',
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs');
      expect(requestBody?['name'], 'nightly');
      expect(requestBody?['groupID'], 1);

      await api.updateCronjob(
        const CronjobOperateRequest(
          id: 3,
          name: 'nightly',
          groupID: 1,
          type: 'shell',
          specCustom: true,
          spec: '0 0 * * *',
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/update');
      expect(requestBody?['id'], 3);

      await api.deleteCronjob(
        const CronjobBatchDeleteRequest(
          ids: <int>[3],
          cleanData: true,
          cleanRemoteData: false,
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/del');
      expect(requestBody, <String, dynamic>{
        'ids': <int>[3],
        'cleanData': true,
        'cleanRemoteData': false,
      });
    });

    test('CronjobV2Api aligns import/export routes', () async {
      final api = CronjobV2Api(client);
      await api.importCronjobs(
        const CronjobImportRequest(
          cronjobs: <CronjobTransItem>[
            CronjobTransItem(
              name: 'imported',
              type: 'shell',
              groupID: 1,
              specCustom: true,
              spec: '0 1 * * *',
            ),
          ],
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/import');
      expect((requestBody?['cronjobs'] as List<dynamic>).length, 1);

      final export = await api.exportCronjobs(
        const CronjobExportRequest(ids: <int>[3]),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/cronjobs/export');
      expect(requestBody, <String, dynamic>{
        'ids': <int>[3]
      });
      expect(export.data, isNotNull);
    });

    test('BackupAccountV2Api aligns search/check/client info routes', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{'id': 1, 'name': 'bucket-a', 'type': 'S3'},
              ],
              'total': 1,
            },
          };

      final api = BackupAccountV2Api(client);
      final search = await api.searchBackupAccounts(
        const BackupAccountSearchRequest(
            page: 1, pageSize: 20, keyword: 'bucket'),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/backups/search');
      expect(requestBody?['info'], 'bucket');
      expect(requestBody?['name'], 'bucket');
      expect(search.data?.items.single.name, 'bucket-a');

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'isOk': true,
              'msg': 'ok',
              'token': 'aGVsbG8='
            },
          };
      final check = await api.checkBackupConnection(
        const BackupOperate(
          name: 'bucket-a',
          type: 'S3',
          vars: '{}',
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/backups/conn/check');
      expect(check.data?.isOk, isTrue);

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'client_id': 'client',
              'client_secret': 'secret',
              'redirect_uri': 'onepanel://backup/oauth',
            },
          };
      final clientInfo = await api.getBackupClientInfo('Onedrive');
      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/core/backups/client/Onedrive');
      expect(clientInfo.data?.clientId, 'client');
    });

    test('BackupAccountV2Api aligns records and action routes', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 9,
                  'fileName': 'dump.tar.gz',
                  'fileDir': '/data',
                  'status': 'Success',
                },
              ],
              'total': 1,
            },
          };

      final api = BackupAccountV2Api(client);
      await api.searchBackupRecords(const BackupRecordQuery(type: 'app'));
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/backups/record/search');

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'id': 9, 'name': 'dump.tar.gz', 'size': 100},
            ],
          };
      await api.loadBackupRecordSizes(const BackupRecordSizeQuery(type: 'app'));
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/backups/record/size');

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String>['dump.tar.gz'],
          };
      await api.listBackupFiles(const OperateByID(id: 1));
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/backups/search/files');

      responseBuilder = () => <String, dynamic>{'code': 200, 'data': null};
      await api.deleteBackupRecords(const BatchDelete(ids: <int>[9]));
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/backups/record/del');

      await api.backupSystemData(
        const BackupRunRequest(
            type: 'app', name: 'wordpress', taskID: 'task-1'),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/backups/backup');

      await api.recoverSystemData(
        const BackupRecoverRequest(
          downloadAccountID: 1,
          type: 'app',
          name: 'wordpress',
          detailName: 'WordPress',
          file: '/data/dump.tar.gz',
          taskID: 'task-1',
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/backups/recover');
    });

    test('ScriptLibraryV2Api aligns search route to POST /core/script/search',
        () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 8,
                  'name': 'Hello Script',
                  'isInteractive': false,
                  'lable': '',
                  'script': 'echo hello',
                  'groupList': <int>[1],
                  'groupBelong': <String>['Default'],
                  'isSystem': false,
                  'description': 'demo',
                  'createdAt': '2026-03-27T08:00:00Z',
                },
              ],
              'total': 1,
            },
          };

      final api = ScriptLibraryV2Api(client);
      final response = await api.searchScripts(
        const ScriptLibraryQuery(
            page: 1, pageSize: 10, groupId: 1, info: 'hello'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/core/script/search');
      expect(requestBody, <String, dynamic>{
        'page': 1,
        'pageSize': 10,
        'groupID': 1,
        'info': 'hello',
      });
      expect(response.data?.items.single.name, 'Hello Script');
    });

    test('ScriptLibraryV2Api aligns sync route to POST /core/script/sync',
        () async {
      final api = ScriptLibraryV2Api(client);
      await api.syncScripts('task-1');

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/core/script/sync');
      expect(requestBody, <String, dynamic>{'taskID': 'task-1'});
    });

    test('ScriptLibraryV2Api aligns delete route to POST /core/script/del',
        () async {
      final api = ScriptLibraryV2Api(client);
      await api.deleteScripts(const ScriptDeleteRequest(ids: <int>[8]));

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/core/script/del');
      expect(requestBody, <String, dynamic>{
        'ids': <int>[8]
      });
    });

    test('RuntimeV2Api aligns search and detail routes', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 7,
                  'name': 'node-main',
                  'type': 'node',
                  'resource': 'local',
                },
              ],
              'total': 1,
            },
          };

      final api = RuntimeV2Api(client);
      final search = await api.getRuntimes(
        const RuntimeSearch(page: 1, pageSize: 10, type: 'node'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/search');
      expect(requestBody, <String, dynamic>{
        'page': 1,
        'pageSize': 10,
        'type': 'node',
        'name': null,
        'status': null,
      });
      expect(search.data?.items.single.id, 7);

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'id': 7, 'name': 'node-main'},
          };
      final detail = await api.getRuntime(7);
      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/runtimes/7');
      expect(detail.data?.id, 7);
    });

    test('RuntimeV2Api aligns create/update/delete/operate/sync/remark routes',
        () async {
      final api = RuntimeV2Api(client);

      await api.createRuntime(
        const RuntimeCreate(
          name: 'node-main',
          resource: 'local',
          image: 'node:20-alpine',
          type: 'node',
          codeDir: '/apps/node',
          port: 3000,
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes');

      await api.updateRuntime(
        const RuntimeUpdate(
          id: 7,
          name: 'node-main',
          type: 'node',
          resource: 'local',
          image: 'node:20-alpine',
          codeDir: '/apps/node',
          port: 3000,
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/update');

      await api.deleteRuntime(const RuntimeDelete(id: 7));
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/del');

      await api.operateRuntime(const RuntimeOperate(id: 7, operate: 'restart'));
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/operate');

      await api.syncRuntimeStatus();
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/sync');

      await api.updateRuntimeRemark(
        const RuntimeRemarkUpdate(id: 7, remark: 'prod'),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/remark');
    });

    test('RuntimeV2Api aligns Week8 node modules/package routes and payloads',
        () async {
      final api = RuntimeV2Api(client);

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'eslint',
                'version': '9.0.0',
                'description': 'lint tool',
              },
            ],
          };
      final modules = await api.getNodeModules(const NodeModuleRequest(id: 7));
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/node/modules');
      expect(requestBody, <String, dynamic>{
        'ID': 7,
      });
      expect(modules.data?.single.name, 'eslint');

      await api.operateNodeModule(
        const NodeModuleRequest(
          id: 7,
          operate: 'install',
          module: 'pm2',
          packageManager: 'npm',
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/node/modules/operate');
      expect(requestBody, <String, dynamic>{
        'ID': 7,
        'Operate': 'install',
        'Module': 'pm2',
        'PkgManager': 'npm',
      });

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'start', 'script': 'node index.js'},
            ],
          };
      final scripts = await api.getNodePackageScripts(
        const NodePackageRequest(codeDir: '/opt/node-app'),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/node/package');
      expect(requestBody, <String, dynamic>{
        'codeDir': '/opt/node-app',
      });
      expect(scripts.data?.single.name, 'start');
    });

    test('RuntimeV2Api aligns Week8 supervisor process and process-file routes',
        () async {
      final api = RuntimeV2Api(client);

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'php-fpm',
                'command': 'php-fpm -F',
                'user': 'www-data',
                'dir': '/www/wwwroot/default',
                'numprocs': '1',
                'status': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'PID': '100',
                    'status': 'RUNNING',
                    'uptime': '0:00:10',
                    'name': 'php-fpm',
                  },
                ],
              },
            ],
          };

      final processes = await api.getSupervisorProcesses(9);
      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/runtimes/supervisor/process/9');
      expect(processes.data?.single.name, 'php-fpm');
      expect(processes.data?.single.status.single.status, 'RUNNING');

      await api.operateSupervisorProcess(
        const SupervisorProcessOperateRequest(
          operate: 'restart',
          name: 'queue-worker',
          id: 9,
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/supervisor/process');
      expect(requestBody, <String, dynamic>{
        'operate': 'restart',
        'name': 'queue-worker',
        'id': 9,
      });

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': '[program:queue-worker]\\ncommand=php artisan queue:work',
          };

      final processFile = await api.operateSupervisorProcessFile(
        const SupervisorProcessFileRequest(
          operate: 'get',
          name: 'queue-worker',
          file: 'config',
          id: 9,
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/supervisor/process/file');
      expect(requestBody, <String, dynamic>{
        'operate': 'get',
        'name': 'queue-worker',
        'file': 'config',
        'id': 9,
      });
      expect(processFile.data, contains('[program:queue-worker]'));
    });

    test(
        'RuntimeV2Api aligns Week8 php extension install/uninstall routes and payloads',
        () async {
      final api = RuntimeV2Api(client);

      await api.installPhpExtension(
        const PHPExtensionInstallRequest(
          id: 9,
          name: 'redis',
          taskId: 'task-install',
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/php/extensions/install');
      expect(requestBody, <String, dynamic>{
        'id': 9,
        'name': 'redis',
        'taskID': 'task-install',
      });

      await api.uninstallPhpExtension(
        const PHPExtensionInstallRequest(
          id: 9,
          name: 'redis',
          taskId: 'task-uninstall',
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/php/extensions/uninstall');
      expect(requestBody, <String, dynamic>{
        'id': 9,
        'name': 'redis',
        'taskID': 'task-uninstall',
      });
    });

    test('RuntimeV2Api aligns Week8 php deep routes and payloads', () async {
      final api = RuntimeV2Api(client);

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'path': '/etc/php/8.4/php.ini',
              'content': '; php config',
            },
          };
      final phpFile = await api.loadPhpConfigFile(
        const PHPConfigFileRequest(id: 9, type: 'php'),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/php/file');
      expect(requestBody, <String, dynamic>{'id': 9, 'type': 'php'});
      expect(phpFile.data?.path, '/etc/php/8.4/php.ini');

      await api.updatePhpConfigFile(
        const PHPConfigFileUpdate(
          id: 9,
          type: 'fpm',
          content: '; fpm config',
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/php/update');
      expect(requestBody, <String, dynamic>{
        'id': 9,
        'type': 'fpm',
        'content': '; fpm config',
      });

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'pm': 'dynamic',
              'pm.max_children': '50',
            },
          };
      final fpmConfig = await api.loadPhpFpmConfig(9);
      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/runtimes/php/fpm/config/9');
      expect(fpmConfig.data?.params['pm.max_children'], '50');

      await api.updatePhpFpmConfig(
        const PHPFpmConfig(
          id: 9,
          params: <String, String>{
            'pm': 'dynamic',
            'pm.max_children': '100',
          },
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/php/fpm/config');
      expect(requestBody, <String, dynamic>{
        'id': 9,
        'params': <String, String>{
          'pm': 'dynamic',
          'pm.max_children': '100',
        },
      });

      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'id': 9,
              'containerName': 'php-84',
              'environments': <Map<String, dynamic>>[
                <String, dynamic>{'key': 'TZ', 'value': 'Asia/Shanghai'},
              ],
            },
          };
      final container = await api.loadPhpContainerConfig(9);
      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/runtimes/php/container/9');
      expect(container.data?.containerName, 'php-84');

      await api.updatePhpContainerConfig(
        const PHPContainerConfig(
          id: 9,
          containerName: 'php-84',
          environments: <PhpContainerEnvironment>[
            PhpContainerEnvironment(key: 'TZ', value: 'Asia/Shanghai'),
          ],
        ),
      );
      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/runtimes/php/container/update');
      expect(requestBody, <String, dynamic>{
        'id': 9,
        'containerName': 'php-84',
        'environments': <Map<String, dynamic>>[
          <String, dynamic>{'key': 'TZ', 'value': 'Asia/Shanghai'},
        ],
      });
    });
  });
}
