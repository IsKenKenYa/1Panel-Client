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

  group('备份账户API测试', () {
    test('POST /backups/search - 获取备份账户列表', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final response = await dio.post('/api/v2/backups/search');
      
      debugPrint('\n========================================');
      debugPrint('POST /backups/search 响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('GET /backups/options - 获取备份账户选项', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      final response = await dio.get('/api/v2/backups/options');
      
      debugPrint('\n========================================');
      debugPrint('GET /backups/options 响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });
  });
}
