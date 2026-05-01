import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/ai_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

import '../core/test_config_manager.dart';

void main() {
  late DioClient client;
  late AIV2Api api;
  bool hasApiKey = false;

  bool isSecureLoginHtml(dynamic payload) {
    return payload is String &&
        payload.contains('Access Temporarily Unavailable') &&
        payload.contains('1pctl user-info');
  }

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty &&
        TestEnvironment.apiKey != 'your_api_key_here';

    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = AIV2Api(client);
    }
  });

  group('AI API客户端测试', () {
    test('GET /ai/agents/providers 应该兼容真实返回体', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final rawResponse = await client.dio.get('/api/v2/ai/agents/providers');
      final response = await api.getAgentProviders();

      expect(response.statusCode, equals(200));
      if (isSecureLoginHtml(rawResponse.data)) {
        expect(response.data, isEmpty);
      } else {
        final rawData = (rawResponse.data as Map<String, dynamic>)['data'];
        if (rawData is List<dynamic>) {
          expect(response.data?.length, rawData.length);
        } else if (rawData is Map<String, dynamic>) {
          expect(response.data?.length, inInclusiveRange(0, 1));
        } else {
          expect(response.data, isEmpty);
        }
      }
    });

    test('GET /ai/gpu/load 应该兼容真实返回体', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final rawResponse = await client.dio.get('/api/v2/ai/gpu/load');
      final response = await api.loadGpuInfo();

      expect(response.statusCode, equals(200));
      if (isSecureLoginHtml(rawResponse.data)) {
        expect(response.data, isEmpty);
      } else {
        final rawData = (rawResponse.data as Map<String, dynamic>)['data'];
        if (rawData is List<dynamic>) {
          expect(response.data?.length, rawData.length);
        } else if (rawData is Map<String, dynamic>) {
          expect(response.data?.length, inInclusiveRange(0, 1));
        } else {
          expect(response.data, isEmpty);
        }
      }
    });

    test('GET /ai/mcp/domain/get 应该兼容真实返回体', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final rawResponse = await client.dio.get('/api/v2/ai/mcp/domain/get');
      final response = await api.getMcpBindDomain();

      expect(response.statusCode, equals(200));
      if (isSecureLoginHtml(rawResponse.data)) {
        expect(response.data?.domain, isNull);
        expect(response.data?.connUrl, isNull);
      } else {
        final rawData = (rawResponse.data as Map<String, dynamic>)['data']
                as Map<String, dynamic>? ??
            const <String, dynamic>{};
        expect(response.data?.domain, rawData['domain']);
        expect(response.data?.connUrl, rawData['connUrl']);
      }
    });
  });
}
