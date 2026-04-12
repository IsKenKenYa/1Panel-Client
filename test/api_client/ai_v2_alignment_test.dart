import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/ai_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';

void main() {
  group('AIV2Api alignment', () {
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

    test('aligns /ai/agents/browser/get route and parses payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'enabled': true,
              'executablePath': '/usr/bin/chromium-browser',
              'defaultProfile': 'default',
              'headless': true,
              'noSandbox': false,
            },
          };

      final api = AIV2Api(client);
      final response = await api.getAgentBrowserConfig(
        const AgentBrowserConfigReq(agentId: 11),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/ai/agents/browser/get');
      expect(requestBody, <String, dynamic>{'agentId': 11});
      expect(response.data?.enabled, isTrue);
      expect(response.data?.defaultProfile, 'default');
      expect(response.data?.executablePath, '/usr/bin/chromium-browser');
    });

    test('aligns /ai/agents/browser/update route and payload', () async {
      final api = AIV2Api(client);
      await api.updateAgentBrowserConfig(
        const AgentBrowserConfigUpdateReq(
          agentId: 11,
          defaultProfile: 'work',
          enabled: true,
          headless: false,
          noSandbox: true,
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/ai/agents/browser/update');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'defaultProfile': 'work',
        'enabled': true,
        'headless': false,
        'noSandbox': true,
      });
    });

    test('aligns /ai/agents/channel/feishu/approve route and payload',
        () async {
      final api = AIV2Api(client);
      await api.approveAgentFeishuPairing(
        const AgentFeishuPairingApproveReq(
          agentId: 11,
          pairingCode: 'PAIR-1234',
        ),
      );

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/ai/agents/channel/feishu/approve');
      expect(requestBody, <String, dynamic>{
        'agentId': 11,
        'pairingCode': 'PAIR-1234',
      });
    });
  });
}
