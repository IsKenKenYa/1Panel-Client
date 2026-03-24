import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/setting_models.dart';

void main() {
  late DioClient client;
  late SettingV2Api api;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty && TestEnvironment.apiKey != 'your_api_key_here';
    
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = SettingV2Api(client);
    }
  });

  group('Setting API响应数据测试', () {
    test('getSystemSettings - 打印完整响应数据', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      // 首先打印原始响应
      final dio = client.dio;
      final rawResponse = await dio.post('/api/v2/core/settings/search');
      
      debugPrint('\n========================================');
      debugPrint('getSystemSettings 原始响应');
      debugPrint('========================================');
      debugPrint('状态码: ${rawResponse.statusCode}');
      debugPrint('数据类型: ${rawResponse.data.runtimeType}');
      
      if (rawResponse.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(rawResponse.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
      
      // 测试解析后的数据
      final response = await api.getSystemSettings();
      
      debugPrint('\n========================================');
      debugPrint('getSystemSettings 解析后的数据');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据是否为null: ${response.data == null}');
      
      if (response.data != null) {
        final data = response.data!;
        debugPrint('userName: ${data.userName}');
        debugPrint('systemVersion: ${data.systemVersion}');
        debugPrint('panelName: ${data.panelName}');
        debugPrint('theme: ${data.theme}');
        debugPrint('language: ${data.language}');
        debugPrint('port: ${data.port}');
        debugPrint('ssl: ${data.ssl}');
        debugPrint('mfaStatus: ${data.mfaStatus}');
        debugPrint('apiKey: ${data.apiKey}');
        debugPrint('apiInterfaceStatus: ${data.apiInterfaceStatus}');
        
        final jsonStr = const JsonEncoder.withIndent('  ').convert(data.toJson());
        debugPrint('\n完整数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('getTerminalSettings - 打印完整响应数据', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final response = await api.getTerminalSettings();

      debugPrint('\n========================================');
      debugPrint('getTerminalSettings 响应数据');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('数据内容:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('getNetworkInterfaces - 打印完整响应数据', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final response = await api.getNetworkInterfaces();

      debugPrint('\n========================================');
      debugPrint('getNetworkInterfaces 响应数据');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('数据内容:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('loadMfaInfo - 打印完整响应数据', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final request = MfaCredential(
        code: '',
        interval: '30',
        secret: '',
      );
      
      final response = await api.loadMfaInfo(request);

      debugPrint('\n========================================');
      debugPrint('loadMfaInfo 响应数据');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('数据内容:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('generateApiKey - 打印完整响应数据', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final response = await api.generateApiKey();

      debugPrint('\n========================================');
      debugPrint('generateApiKey 响应数据');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据类型: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(response.data);
        debugPrint('数据内容:\n$jsonStr');
      }
      debugPrint('========================================\n');
    });

    test('getInterfaceSettings - 打印完整响应数据', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      // 首先打印原始响应
      final dio = client.dio;
      final rawResponse = await dio.get('/api/v2/core/settings/interface');
      
      debugPrint('\n========================================');
      debugPrint('getInterfaceSettings 原始响应');
      debugPrint('========================================');
      debugPrint('状态码: ${rawResponse.statusCode}');
      debugPrint('数据类型: ${rawResponse.data.runtimeType}');
      
      if (rawResponse.data != null) {
        final jsonStr = const JsonEncoder.withIndent('  ').convert(rawResponse.data);
        debugPrint('原始数据:\n$jsonStr');
      }
      debugPrint('========================================\n');
      
      // 测试解析后的数据
      final response = await api.getNetworkInterfaces();
      
      debugPrint('\n========================================');
      debugPrint('getNetworkInterfaces 解析后的数据');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据是否为null: ${response.data == null}');
      
      if (response.data != null) {
        debugPrint('接口数量: ${response.data!.length}');
        if (response.data!.isNotEmpty) {
          debugPrint('第一个IP: ${response.data!.first}');
        }
      }
      debugPrint('========================================\n');
    });
  });
}
