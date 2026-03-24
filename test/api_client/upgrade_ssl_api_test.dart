import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

void main() {
  late DioClient client;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty && TestEnvironment.apiKey != 'your_api_key_here';
    
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
    }
  });

  group('Upgrade API响应测试', () {
    test('GET /core/settings/upgrade - 获取升级信息', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final response = await dio.get('/api/v2/core/settings/upgrade');
      
      debugPrint('\n========================================');
      debugPrint('GET /core/settings/upgrade 响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('GET /core/settings/upgrade/releases - 获取版本列表', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final response = await dio.get('/api/v2/core/settings/upgrade/releases');
      
      debugPrint('\n========================================');
      debugPrint('GET /core/settings/upgrade/releases 响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });
  });

  group('SSL API响应测试', () {
    test('GET /core/settings/ssl/info - 获取SSL信息', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final response = await dio.get('/api/v2/core/settings/ssl/info');
      
      debugPrint('\n========================================');
      debugPrint('GET /core/settings/ssl/info 响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });
  });
}
