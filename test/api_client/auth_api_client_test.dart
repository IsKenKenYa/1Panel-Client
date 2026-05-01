import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/auth_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

import '../core/test_config_manager.dart';

void main() {
  late DioClient client;
  late AuthV2Api api;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty &&
        TestEnvironment.apiKey != 'your_api_key_here';

    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = AuthV2Api(client);
    }
  });

  group('Auth API客户端测试', () {
    bool isSecureLoginHtml(dynamic payload) {
      return payload is String &&
          payload.contains('Access Temporarily Unavailable') &&
          payload.contains('1pctl user-info');
    }

    test('GET /core/auth/captcha 应该返回可解析验证码结构', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final rawResponse = await client.dio.get('/api/v2/core/auth/captcha');
      final response = await api.getCaptcha();

      expect(response.statusCode, equals(200));
      if (isSecureLoginHtml(rawResponse.data)) {
        expect(response.data, isNull);
      } else {
        expect(response.data, isNotNull);
        expect(
          response.data?.base64 != null ||
              response.data?.imagePath != null ||
              response.data?.captchaId != null,
          isTrue,
        );
      }
    });

    test('GET /core/auth/demo 应该返回演示模式结构', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final rawResponse = await client.dio.get('/api/v2/core/auth/demo');
      final response = await api.checkDemoMode();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      if (isSecureLoginHtml(rawResponse.data)) {
        expect(response.data, isEmpty);
      } else {
        expect(
          response.data!.containsKey('demo') ||
              response.data!.containsKey('isDemo') ||
              response.data!.containsKey('message'),
          isTrue,
        );
      }
    });

    test('GET /core/auth/issafety 应该返回安全状态结构', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final rawResponse = await client.dio.get('/api/v2/core/auth/issafety');
      final response = await api.getSafetyStatus();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      if (isSecureLoginHtml(rawResponse.data)) {
        expect(response.data, isEmpty);
      } else {
        expect(
          response.data!.containsKey('issafety') ||
              response.data!.containsKey('isSafety') ||
              response.data!.containsKey('message'),
          isTrue,
        );
      }
    });

    test('GET /core/auth/language 应该返回非空语言值', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final rawResponse = await client.dio.get('/api/v2/core/auth/language');
      final response = await api.getSystemLanguage();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      if (isSecureLoginHtml(rawResponse.data)) {
        expect(response.data, isEmpty);
      } else {
        expect(response.data, isNotEmpty);
      }
    });

    test('GET /core/auth/setting 应该返回登录设置结构', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final response = await api.getLoginSettings();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      expect(
        response.data!.containsKey('captcha') ||
            response.data!.containsKey('needCaptcha') ||
            response.data!.containsKey('mfa') ||
            response.data!.containsKey('panelName') ||
            response.data!.containsKey('title') ||
            response.data!.containsKey('logo'),
        isTrue,
      );
    });
  });
}
