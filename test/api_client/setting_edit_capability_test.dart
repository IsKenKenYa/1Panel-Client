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

  group('1Panel设置编辑能力测试', () {
    test('1. 测试终端设置更新接口 - /core/settings/terminal/update', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试终端设置更新接口');
      debugPrint('========================================');
      
      // 获取当前设置
      final searchResponse = await dio.post('/api/v2/core/settings/terminal/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      
      debugPrint('当前终端设置: ${jsonEncode(data)}');
      
      // 尝试更新
      debugPrint('\n--- 尝试更新字体大小为 16 ---');
      final updateResponse = await dio.post(
        '/api/v2/core/settings/terminal/update',
        data: {'fontSize': 16},
      );
      
      debugPrint('更新响应: ${jsonEncode(updateResponse.data)}');
      
      // 验证
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyResponse = await dio.post('/api/v2/core/settings/terminal/search');
      final verifyData = verifyResponse.data as Map<String, dynamic>;
      final verifySettings = verifyData['data'] as Map<String, dynamic>?;
      
      debugPrint('验证后的终端设置: ${jsonEncode(verifySettings)}');
      debugPrint('========================================\n');
    });

    test('2. 测试系统升级接口 - /core/settings/upgrade', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试系统升级接口');
      debugPrint('========================================');
      
      // 获取当前版本
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final currentVersion = data?['systemVersion'] as String?;
      
      debugPrint('当前版本: $currentVersion');
      
      // 获取可用版本
      debugPrint('\n--- 获取可用升级版本 ---');
      try {
        final releasesResponse = await dio.post('/api/v2/core/settings/upgrade/releases');
        debugPrint('可用版本响应: ${jsonEncode(releasesResponse.data)}');
      } catch (e) {
        debugPrint('获取版本错误: $e');
      }
      
      debugPrint('========================================\n');
    });

    test('3. 测试端口更新接口 - /core/settings/port/update', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试端口更新接口');
      debugPrint('========================================');
      
      // 获取当前端口
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final currentPort = data?['serverPort'] as String?;
      
      debugPrint('当前端口: $currentPort');
      
      // 尝试更新端口 (使用 serverPort 参数)
      debugPrint('\n--- 尝试更新端口 ---');
      final updateResponse = await dio.post(
        '/api/v2/core/settings/port/update',
        data: {'serverPort': currentPort ?? '9999'},
      );
      
      debugPrint('更新响应: ${jsonEncode(updateResponse.data)}');
      debugPrint('========================================\n');
    });

    test('4. 测试绑定地址更新接口 - /core/settings/bind/update', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试绑定地址更新接口');
      debugPrint('========================================');
      
      // 获取当前绑定地址
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final currentBind = data?['bindAddress'] as String?;
      
      debugPrint('当前绑定地址: $currentBind');
      
      // 尝试更新
      debugPrint('\n--- 尝试更新绑定地址 ---');
      final updateResponse = await dio.post(
        '/api/v2/core/settings/bind/update',
        data: {'bindAddress': currentBind ?? '::'},
      );
      
      debugPrint('更新响应: ${jsonEncode(updateResponse.data)}');
      debugPrint('========================================\n');
    });

    test('5. 测试API密钥接口 - /core/settings/api/config/update', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试API密钥配置接口');
      debugPrint('========================================');
      
      // 获取当前设置
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      
      debugPrint('当前API状态: ${data?['apiInterfaceStatus']}');
      debugPrint('当前API密钥: ${data?['apiKey']}');
      
      // 尝试更新API配置
      debugPrint('\n--- 尝试更新API配置 ---');
      final updateResponse = await dio.post(
        '/api/v2/core/settings/api/config/update',
        data: {
          'status': data?['apiInterfaceStatus'] ?? 'Enable',
          'ipWhiteList': data?['ipWhiteList'] ?? '0.0.0.0/0',
          'validityTime': data?['apiKeyValidityTime'] ?? 0,
        },
      );
      
      debugPrint('更新响应: ${jsonEncode(updateResponse.data)}');
      debugPrint('========================================\n');
    });

    test('6. 测试快照创建接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试快照创建接口');
      debugPrint('========================================');
      
      // 获取现有快照
      final searchResponse = await dio.post('/api/v2/settings/snapshot/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      
      debugPrint('现有快照: ${jsonEncode(searchData['data'])}');
      
      // 尝试创建快照
      debugPrint('\n--- 尝试创建快照 ---');
      final createResponse = await dio.post(
        '/api/v2/settings/snapshot/create',
        data: {'description': 'Test snapshot from API test'},
      );
      
      debugPrint('创建响应: ${jsonEncode(createResponse.data)}');
      debugPrint('========================================\n');
    });

    test('7. 总结：哪些接口可用', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('API接口可用性总结');
      debugPrint('========================================');
      
      final endpoints = [
        {'name': '终端设置更新', 'path': '/core/settings/terminal/update', 'method': 'POST'},
        {'name': '系统升级', 'path': '/core/settings/upgrade', 'method': 'POST'},
        {'name': '升级版本列表', 'path': '/core/settings/upgrade/releases', 'method': 'POST'},
        {'name': '端口更新', 'path': '/core/settings/port/update', 'method': 'POST'},
        {'name': '绑定地址更新', 'path': '/core/settings/bind/update', 'method': 'POST'},
        {'name': 'API配置更新', 'path': '/core/settings/api/config/update', 'method': 'POST'},
        {'name': '快照创建', 'path': '/settings/snapshot/create', 'method': 'POST'},
        {'name': '快照列表', 'path': '/settings/snapshot/search', 'method': 'POST'},
        {'name': '通用设置更新', 'path': '/core/settings/update', 'method': 'POST'},
      ];
      
      for (final endpoint in endpoints) {
        try {
          final response = await dio.post(
            '/api/v2${endpoint['path']}',
            data: {},
          );
          final data = response.data as Map<String, dynamic>;
          final code = data['code'];
          final message = data['message'] ?? '';
          
          String status;
          if (code == 200) {
            status = '✅ 成功';
          } else if (code == 400 || code == 500) {
            status = '⚠️  参数错误/服务错误: $message';
          } else {
            status = '❓ 未知: code=$code';
          }
          
          debugPrint('${endpoint['name']}: $status');
        } catch (e) {
          debugPrint('${endpoint['name']}: ❌ 错误: $e');
        }
      }
      
      debugPrint('========================================\n');
    });
  });
}
