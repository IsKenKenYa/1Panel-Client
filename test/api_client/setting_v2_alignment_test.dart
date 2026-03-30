import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart' as api;
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  group('SettingV2Api alignment', () {
    late HttpServer server;
    late DioClient client;
    late List<String> requestPaths;
    late List<String> requestMethods;
    late List<Map<String, dynamic>?> requestBodies;
    late int Function(HttpRequest request) statusCodeResolver;
    late Map<String, dynamic> Function(HttpRequest request) responseBuilder;

    setUp(() async {
      requestPaths = <String>[];
      requestMethods = <String>[];
      requestBodies = <Map<String, dynamic>?>[];
      statusCodeResolver = (_) => 200;
      responseBuilder =
          (_) => <String, dynamic>{'code': 200, 'message': 'success', 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestPaths.add(request.uri.path);
        requestMethods.add(request.method);

        final payload = await utf8.decoder.bind(request).join();
        requestBodies.add(
          payload.isEmpty
              ? null
              : jsonDecode(payload) as Map<String, dynamic>,
        );

        final statusCode = statusCodeResolver(request);
        request.response.statusCode = statusCode;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder(request)));
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

    test('aligns /core/settings/update route and payload', () async {
      final apiClient = api.SettingV2Api(client);

      await apiClient.updateSystemSetting(
        const api.SettingUpdate(key: 'panelName', value: '1Panel Mobile'),
      );

      expect(requestMethods, <String>['POST']);
      expect(requestPaths, <String>['/api/v2/core/settings/update']);
      expect(requestBodies, <Map<String, dynamic>?>[
        <String, dynamic>{'key': 'panelName', 'value': '1Panel Mobile'},
      ]);
    });

    test('falls back to legacy /settings/update when core route is not found',
        () async {
      statusCodeResolver = (HttpRequest request) {
        if (request.uri.path == '/api/v2/core/settings/update') {
          return 404;
        }
        return 200;
      };
      responseBuilder = (HttpRequest request) {
        if (request.uri.path == '/api/v2/core/settings/update') {
          return <String, dynamic>{
            'code': 404,
            'message': 'not found',
            'data': null,
          };
        }
        return <String, dynamic>{'code': 200, 'message': 'success', 'data': null};
      };

      final apiClient = api.SettingV2Api(client);
      await apiClient.updateSystemSetting(
        const api.SettingUpdate(key: 'panelName', value: 'fallback-value'),
      );

      expect(requestMethods, <String>['POST', 'POST']);
      expect(requestPaths, <String>[
        '/api/v2/core/settings/update',
        '/api/v2/settings/update',
      ]);
      expect(requestBodies.last, <String, dynamic>{
        'key': 'panelName',
        'value': 'fallback-value',
      });
    });

    test('aligns /core/settings/search/available route', () async {
      responseBuilder =
          (_) => <String, dynamic>{'code': 200, 'message': 'success', 'data': true};

      final apiClient = api.SettingV2Api(client);
      final response = await apiClient.checkSettingsAvailable();

      expect(response.data, isTrue);
      expect(requestMethods, <String>['GET']);
      expect(requestPaths, <String>['/api/v2/core/settings/search/available']);
    });

    test(
        'falls back to legacy /settings/search/available when core route is not found',
        () async {
      statusCodeResolver = (HttpRequest request) {
        if (request.uri.path == '/api/v2/core/settings/search/available') {
          return 404;
        }
        return 200;
      };
      responseBuilder = (HttpRequest request) {
        if (request.uri.path == '/api/v2/core/settings/search/available') {
          return <String, dynamic>{
            'code': 404,
            'message': 'not found',
            'data': null,
          };
        }
        return <String, dynamic>{'code': 200, 'message': 'success', 'data': false};
      };

      final apiClient = api.SettingV2Api(client);
      final response = await apiClient.checkSettingsAvailable();

      expect(response.data, isFalse);
      expect(requestMethods, <String>['GET', 'GET']);
      expect(requestPaths, <String>[
        '/api/v2/core/settings/search/available',
        '/api/v2/settings/search/available',
      ]);
    });
  });
}
