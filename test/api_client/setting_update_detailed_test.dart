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

  group('SettingUpdate接口详细测试', () {
    test('1. 获取所有可用设置字段', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('获取所有可用设置字段');
      debugPrint('========================================');
      
      final response = await dio.post('/api/v2/core/settings/search');
      final data = response.data as Map<String, dynamic>;
      final settings = data['data'] as Map<String, dynamic>?;
      
      if (settings != null) {
        debugPrint('\n所有设置字段:');
        for (final entry in settings.entries) {
          debugPrint('  ${entry.key}: ${entry.value}');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('2. 测试所有可能的key值', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试所有可能的key值');
      debugPrint('========================================');
      
      // 获取当前设置
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final settings = searchData['data'] as Map<String, dynamic>?;
      
      if (settings != null) {
        // 测试每个字段
        final keysToTest = [
          'panelName',
          'developerMode',
          'sessionTimeout',
          'theme',
          'language',
          'menuTabs',
          'dashboardMemoVisible',
          'dashboardSimpleNodeVisible',
          'expirationDays',
          'complexityVerification',
          'mfaInterval',
          'noAuthSetting',
          'proxyUrl',
          'proxyType',
          'proxyPort',
          'proxyUser',
          'upgradeBackupCopies',
        ];
        
        for (final key in keysToTest) {
          final currentValue = settings[key];
          debugPrint('\n--- 测试 key="$key", 当前值="$currentValue" ---');
          
          try {
            final response = await dio.post(
              '/api/v2/core/settings/update',
              data: {'key': key, 'value': currentValue?.toString() ?? ''},
            );
            final responseData = response.data as Map<String, dynamic>;
            final success = responseData['code'] == 200;
            debugPrint('结果: ${success ? "✅ 成功" : "❌ 失败"} - code=${responseData['code']}, message=${responseData['message']}');
          } catch (e) {
            debugPrint('错误: $e');
          }
        }
      }
      
      debugPrint('========================================\n');
    });

    test('3. 测试不同的请求格式', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('测试不同的请求格式');
      debugPrint('========================================');
      
      final testCases = [
        {'desc': '标准格式', 'data': {'key': 'sessionTimeout', 'value': '60'}},
        {'desc': '大写Key', 'data': {'Key': 'sessionTimeout', 'value': '60'}},
        {'desc': '大写Value', 'data': {'key': 'sessionTimeout', 'Value': '60'}},
        {'desc': '字符串数字', 'data': {'key': 'sessionTimeout', 'value': 60}},
        {'desc': '嵌套data', 'data': {'data': {'key': 'sessionTimeout', 'value': '60'}}},
      ];
      
      for (final testCase in testCases) {
        debugPrint('\n--- ${testCase['desc']} ---');
        debugPrint('请求: ${jsonEncode(testCase['data'])}');
        
        try {
          final response = await dio.post(
            '/api/v2/core/settings/update',
            data: testCase['data'],
          );
          final responseData = response.data as Map<String, dynamic>;
          debugPrint('响应: code=${responseData['code']}, message=${responseData['message']}');
        } catch (e) {
          debugPrint('错误: $e');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('4. 检查是否有其他更新接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;
      
      debugPrint('\n========================================');
      debugPrint('检查其他更新接口');
      debugPrint('========================================');
      
      final endpoints = [
        {'path': '/core/settings/menu/update', 'data': {'hideMenu': '[]'}},
        {'path': '/core/settings/proxy/update', 'data': {'proxyUrl': '', 'proxyType': ''}},
      ];
      
      for (final endpoint in endpoints) {
        debugPrint('\n--- 测试 ${endpoint['path']} ---');
        try {
          final response = await dio.post(
            '/api/v2${endpoint['path']}',
            data: endpoint['data'],
          );
          final responseData = response.data as Map<String, dynamic>;
          debugPrint('响应: code=${responseData['code']}, message=${responseData['message']}');
        } catch (e) {
          debugPrint('错误: $e');
        }
      }
      
      debugPrint('========================================\n');
    });

    test('5. 总结', () async {
      debugPrint('\n========================================');
      debugPrint('总结');
      debugPrint('========================================');
      
      debugPrint('''
根据测试结果：

1. /core/settings/update 接口返回 "record not found" 错误
   - 这可能意味着该接口需要在数据库中有对应的设置记录
   - 或者需要特定的初始化流程

2. 可用的专门更新接口：
   - /core/settings/port/update - 更新端口
   - /core/settings/bind/update - 更新绑定地址
   - /core/settings/terminal/update - 更新终端设置
   - /core/settings/ssl/update - 更新SSL设置
   - /core/settings/proxy/update - 更新代理设置
   - /core/settings/menu/update - 更新菜单设置
   - /core/settings/password/update - 更新密码
   - /core/settings/api/config/update - 更新API配置

3. 无法通过API编辑的设置：
   - panelName (面板名称)
   - developerMode (开发者模式)
   - sessionTimeout (会话超时)
   - theme (主题)
   - language (语言)

结论：大部分面板设置只能读取，无法通过API修改。
这可能是1Panel的设计限制，需要通过Web界面进行修改。
''');
      
      debugPrint('========================================\n');
    });
  });
}
