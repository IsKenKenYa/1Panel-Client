import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/auth_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  group('AuthV2Api alignment', () {
    late HttpServer server;
    late DioClient client;
    late AuthV2Api api;
    late Map<String, dynamic> Function() responseBuilder;
    late String requestMethod;
    late String requestPath;

    setUp(() async {
      requestMethod = '';
      requestPath = '';
      responseBuilder = () => <String, dynamic>{'code': 200, 'data': null};

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        requestMethod = request.method;
        requestPath = request.uri.path;
        await utf8.decoder.bind(request).join();

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(responseBuilder()));
        await request.response.close();
      });

      client = DioClient(
        baseUrl: 'http://${server.address.host}:${server.port}',
        apiKey: 'test-key',
      );
      api = AuthV2Api(client);
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('getCaptcha unwraps structured captcha payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'captchaId': 'captcha-1',
              'image': 'YmFzZTY0',
              'path': '/captcha.png',
            },
          };

      final response = await api.getCaptcha();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/core/auth/captcha');
      expect(response.data?.captchaId, 'captcha-1');
      expect(response.data?.base64, 'YmFzZTY0');
      expect(response.data?.imagePath, '/captcha.png');
    });

    test('checkDemoMode unwraps data envelope', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'demo': true},
          };

      final response = await api.checkDemoMode();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/core/auth/demo');
      expect(response.data?['demo'], isTrue);
    });

    test('getSafetyStatus unwraps data envelope', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{'issafety': true},
          };

      final response = await api.getSafetyStatus();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/core/auth/issafety');
      expect(response.data?['issafety'], isTrue);
    });

    test('getSystemLanguage unwraps string data', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': 'zh',
          };

      final response = await api.getSystemLanguage();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/core/auth/language');
      expect(response.data, 'zh');
    });

    test('getLoginSettings unwraps settings map', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': <String, dynamic>{
              'captcha': true,
              'mfa': false,
              'title': '1Panel',
            },
          };

      final response = await api.getLoginSettings();

      expect(requestMethod, 'GET');
      expect(requestPath, '/api/v2/core/auth/setting');
      expect(response.data?['captcha'], isTrue);
      expect(response.data?['title'], '1Panel');
    });

    test('logout tolerates empty data payload', () async {
      responseBuilder = () => <String, dynamic>{
            'code': 200,
            'data': null,
          };

      final response = await api.logout();

      expect(requestMethod, 'POST');
      expect(requestPath, '/api/v2/core/auth/logout');
      expect(response.data, isEmpty);
    });
  });
}
