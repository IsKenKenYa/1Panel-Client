import 'dart:convert';

import 'package:dio/dio.dart' show Options, ResponseType;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';

import '../core/test_config_manager.dart';

void main() {
  late DioClient client;
  late SettingV2Api api;
  bool canRun = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    canRun = TestEnvironment.apiKey.isNotEmpty &&
        TestEnvironment.apiKey != 'your_api_key_here';

    if (canRun) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = SettingV2Api(client);
    }
  });

  group('MFA API contract verification', () {
    test('capture real mfa status and load responses', () async {
      if (!canRun) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('MFA contract verification');
      debugPrint('========================================');
      debugPrint('baseUrl: ${TestEnvironment.baseUrl}');

      final statusRaw = await dio.get(
        '/api/v2/core/settings/mfa/status',
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      debugPrint('\n--- GET /api/v2/core/settings/mfa/status ---');
      debugPrint('statusCode: ${statusRaw.statusCode}');
      debugPrint('runtimeType: ${statusRaw.data.runtimeType}');
      debugPrint('contentType: ${statusRaw.headers.value('content-type')}');
      debugPrint('location: ${statusRaw.headers.value('location')}');
      debugPrint('server: ${statusRaw.headers.value('server')}');
      debugPrint('isRedirect: ${statusRaw.isRedirect}');
      debugPrint('redirectCount: ${statusRaw.redirects.length}');
      for (final redirect in statusRaw.redirects) {
        debugPrint(
          'redirect: status=${redirect.statusCode}, method=${redirect.method}, location=${redirect.location}',
        );
      }
      debugPrint('headers: ${jsonEncode(statusRaw.headers.map)}');
      debugPrint('body: ${_pretty(statusRaw.data)}');

      final loadRequest = const MfaLoadRequest(title: '1Panel Client', interval: 30);
      debugPrint('\n--- POST /api/v2/core/settings/mfa ---');
      debugPrint('request: ${jsonEncode(loadRequest.toJson())}');
      final loadRaw = await dio.post(
        '/api/v2/core/settings/mfa',
        data: loadRequest.toJson(),
      );
      debugPrint('statusCode: ${loadRaw.statusCode}');
      debugPrint('runtimeType: ${loadRaw.data.runtimeType}');
      debugPrint('body: ${_pretty(loadRaw.data)}');

      final parsedLoad = await api.loadMfaInfo(loadRequest);
      debugPrint('\n--- parsed loadMfaInfo ---');
      debugPrint('statusCode: ${parsedLoad.statusCode}');
      debugPrint('parsed: ${parsedLoad.data == null ? 'null' : jsonEncode(parsedLoad.data!.toJson())}');

      expect(loadRaw.statusCode, equals(200));
      expect(parsedLoad.statusCode, equals(200));
      debugPrint('========================================\n');
    });
  });
}

String _pretty(dynamic data) {
  if (data == null) {
    return 'null';
  }
  if (data is String) {
    return data;
  }
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data.toString();
  }
}
