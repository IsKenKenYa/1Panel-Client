import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/vm_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';

void main() {
  group('VMV2Api alignment', () {
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

    test('aligns GET /vms/environment route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'arch': 'x86_64',
              'archSupported': true,
              'ready': true,
              'kvmExist': true,
              'libvirtActive': true,
            },
          };

      final api = VMV2Api(client);
      final response = await api.getVMEnvironment();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/vms/environment');
      expect(response.data?.ready, isTrue);
      expect(response.data?.arch, 'x86_64');
    });

    test('aligns /vms/search route and payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 1,
                  'name': 'test-vm',
                  'cpu': 2,
                  'memory': 2048,
                  'status': 'Running',
                  'isoPaths': <String>['/opt/iso/test.iso'],
                },
              ],
              'total': 1,
              'limit': 5,
            },
          };

      final api = VMV2Api(client);
      final response = await api.searchVMs(
        const SearchWithPage(page: 1, pageSize: 20, info: 'test'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/vms/search');
      expect(requestBody?['page'], 1);
      expect(requestBody?['info'], 'test');
      expect(response.data?.items.single.name, 'test-vm');
      expect(response.data?.limit, 5);
    });

    test('aligns /vms/info route with checkDisks payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'id': 1,
              'name': 'test-vm',
              'disks': <Map<String, dynamic>>[
                <String, dynamic>{
                  'capacity': 21474836480,
                  'target': 'vda',
                  'bus': 'virtio',
                },
              ],
              'graphics': <String, dynamic>{
                'type': 'vnc',
                'port': '5900',
                'listen': '0.0.0.0',
              },
            },
          };

      final api = VMV2Api(client);
      final response = await api.getVMInfo(
        const VMInfoReq(name: 'test-vm', checkDisks: true),
      );

      expect(requestPath, '/api/v2/vms/info');
      expect(requestBody?['name'], 'test-vm');
      expect(requestBody?['checkDisks'], isTrue);
      expect(response.data?.disks.single.target, 'vda');
      expect(response.data?.graphics?.port, '5900');
    });

    test('aligns /vms create route and taskID parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'taskID': 'task-123'},
          };

      final api = VMV2Api(client);
      final response = await api.createVM(
        const VMCreate(
          name: 'new-vm',
          cpu: 2,
          memory: 4096,
          diskSize: 20,
          network: 'nat',
          startAfterCreate: true,
          autoStart: false,
        ),
      );

      expect(requestPath, '/api/v2/vms');
      expect(requestBody?['name'], 'new-vm');
      expect(requestBody?['memory'], 4096);
      expect(requestBody?['startAfterCreate'], isTrue);
      expect(response.data?.taskID, 'task-123');
    });

    test('aligns /vms/operate route and payload', () async {
      final api = VMV2Api(client);
      await api.operateVM(
        const VMOperate(name: 'test-vm', operate: 'start'),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/vms/operate');
      expect(requestBody?['name'], 'test-vm');
      expect(requestBody?['operate'], 'start');
    });

    test('aligns /vms/health/check route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'pass': 2,
              'warn': 1,
              'fail': 0,
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'level': 'WARN',
                  'check': 'storage',
                  'reason': 'pool low',
                },
              ],
            },
          };

      final api = VMV2Api(client);
      final response = await api.healthCheckVM(
        const OperationWithName(name: 'test-vm'),
      );

      expect(requestPath, '/api/v2/vms/health/check');
      expect(response.data?.warn, 1);
      expect(response.data?.items.single.level, 'WARN');
    });

    test('aligns /vms/templates/list route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 3,
                'name': 'ubuntu-template',
                'sourceVM': 'base-vm',
              },
            ],
          };

      final api = VMV2Api(client);
      final response = await api.listVMTemplates();

      expect(requestPath, '/api/v2/vms/templates/list');
      expect(response.data?.single.name, 'ubuntu-template');
    });

    test('aligns /vms/snapshots route and payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'taskID': 'snap-task'},
          };

      final api = VMV2Api(client);
      final response = await api.createVMSnapshot(
        const VMSnapshotReq(name: 'test-vm', snapshotName: 'snap-1'),
      );

      expect(requestPath, '/api/v2/vms/snapshots');
      expect(requestBody?['snapshotName'], 'snap-1');
      expect(response.data?.taskID, 'snap-task');
    });

    test('aligns /vms/iso/search route and page parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 7,
                  'name': 'ubuntu.iso',
                  'path': '/opt/iso/ubuntu.iso',
                },
              ],
              'total': 1,
            },
          };

      final api = VMV2Api(client);
      final response = await api.searchVMIso(
        const SearchWithPage(page: 1, pageSize: 20),
      );

      expect(requestPath, '/api/v2/vms/iso/search');
      expect(response.data?.items.single.name, 'ubuntu.iso');
    });

    test('aligns /vms/networks/bridges route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'virbr0',
                'recommended': true,
              },
            ],
          };

      final api = VMV2Api(client);
      final response = await api.listVMNetworkBridges();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/vms/networks/bridges');
      expect(response.data?.single.recommended, isTrue);
    });

    test('aligns /vms/storages route and payload', () async {
      final api = VMV2Api(client);
      await api.createVMStorage(
        const VMStorageCreate(
          name: 'default',
          type: 'dir',
          path: '/opt/vm-storage',
          autoStart: true,
        ),
      );

      expect(requestPath, '/api/v2/vms/storages');
      expect(requestBody?['type'], 'dir');
      expect(requestBody?['path'], '/opt/vm-storage');
    });

    test('aligns /vms/orphans/scan route and parse', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <Map<String, dynamic>>[
              <String, dynamic>{
                'type': 'orphan_snapshot',
                'path': '/opt/vm/old.snap',
                'size': 1024,
              },
            ],
          };

      final api = VMV2Api(client);
      final response = await api.scanVMOrphans();

      expect(requestPath, '/api/v2/vms/orphans/scan');
      expect(response.data?.single.type, 'orphan_snapshot');
    });

    test('aligns /vms/rename route and payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'taskID': 'rename-task'},
          };

      final api = VMV2Api(client);
      final response = await api.renameVM(
        const VMRename(name: 'old-name', newName: 'new-name'),
      );

      expect(requestPath, '/api/v2/vms/rename');
      expect(requestBody?['newName'], 'new-name');
      expect(response.data?.taskID, 'rename-task');
    });

    test('aligns /vms/disks/resize route and payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'taskID': 'resize-task'},
          };

      final api = VMV2Api(client);
      final response = await api.resizeVMDisk(
        const VMDiskResize(name: 'test-vm', target: 'vda', sizeGiB: 40),
      );

      expect(requestPath, '/api/v2/vms/disks/resize');
      expect(requestBody?['sizeGiB'], 40);
      expect(response.data?.taskID, 'resize-task');
    });
  });
}
