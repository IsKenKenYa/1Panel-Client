import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/command_v2.dart';
import 'package:onepanel_client/api/v2/cronjob_v2.dart';
import 'package:onepanel_client/api/v2/host_v2.dart';
import 'package:onepanel_client/api/v2/process_v2.dart';
import 'package:onepanel_client/api/v2/system_group_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/host_models.dart';
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
      expect(response.data?.single['Name'], 'sshd');
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
      expect(response.data?['name'], 'daily-backup');
    });
  });
}
