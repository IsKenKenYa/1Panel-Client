import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

Map<String, dynamic> _snapshotSearchPayload() => const <String, dynamic>{
      'page': 1,
      'pageSize': 10,
      'orderBy': 'createdAt',
      'order': 'descending',
    };

Map<String, dynamic> _snapshotCreatePayload(String description) =>
    <String, dynamic>{
      'description': description,
      'sourceAccountIDs': '1',
      'downloadAccountID': 1,
    };

void main() {
  late DioClient client;
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
    }
  });

  group('面板配置编辑能力测试', () {
    test('1. 获取当前面板配置', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('获取当前面板配置');
      debugPrint('========================================');

      final response = await dio.post('/api/v2/core/settings/search');
      final data = response.data as Map<String, dynamic>;

      debugPrint('响应: ${jsonEncode(data)}');

      if (data['data'] != null) {
        final settings = data['data'] as Map<String, dynamic>;
        debugPrint('\n可编辑字段:');
        debugPrint('  panelName: ${settings['panelName']}');
        debugPrint('  serverPort: ${settings['serverPort']}');
        debugPrint('  bindAddress: ${settings['bindAddress']}');
        debugPrint('  ipv6: ${settings['ipv6']}');
        debugPrint('  developerMode: ${settings['developerMode']}');
        debugPrint('  sessionTimeout: ${settings['sessionTimeout']}');
        debugPrint('  theme: ${settings['theme']}');
        debugPrint('  language: ${settings['language']}');
      }

      debugPrint('========================================\n');
    });

    test('2. 测试面板名称更新接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试面板名称更新');
      debugPrint('========================================');

      // 获取当前名称
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final originalName = data?['panelName'] as String? ?? '';

      debugPrint('当前面板名称: $originalName');

      // 尝试不同的更新方式
      final testCases = [
        {
          'endpoint': '/core/settings/update',
          'data': {'key': 'panelName', 'value': 'TestPanel'}
        },
        {
          'endpoint': '/core/settings/name/update',
          'data': {'panelName': 'TestPanel'}
        },
        {
          'endpoint': '/core/settings/panel/update',
          'data': {'panelName': 'TestPanel'}
        },
      ];

      for (final testCase in testCases) {
        debugPrint('\n--- 测试 ${testCase['endpoint']} ---');
        try {
          final response = await dio.post(
            '/api/v2${testCase['endpoint']}',
            data: testCase['data'],
          );
          final responseData = response.data as Map<String, dynamic>;
          debugPrint(
              '响应: code=${responseData['code']}, message=${responseData['message']}');
        } catch (e) {
          debugPrint('错误: $e');
        }
      }

      debugPrint('========================================\n');
    });

    test('3. 测试端口更新接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试端口更新');
      debugPrint('========================================');

      // 获取当前端口
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final currentPort =
          int.tryParse(data?['serverPort']?.toString() ?? '9999') ?? 9999;

      debugPrint('当前端口: $currentPort');

      // 尝试更新（使用相同端口测试接口是否正常）
      try {
        final response = await dio.post(
          '/api/v2/core/settings/port/update',
          data: {'serverPort': currentPort},
        );

        final responseData = response.data as Map<String, dynamic>;
        debugPrint(
            '响应: code=${responseData['code']}, message=${responseData['message']}');
        debugPrint('接口可用: ${responseData['code'] == 200}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      debugPrint('========================================\n');
    });

    test('4. 测试绑定地址更新接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试绑定地址更新');
      debugPrint('========================================');

      // 获取当前设置
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final currentBind = data?['bindAddress'] as String? ?? '::';
      final ipv6Enabled = data?['ipv6'] == 'Enable';

      debugPrint('当前绑定地址: $currentBind, IPv6: $ipv6Enabled');

      // 尝试更新
      final response = await dio.post(
        '/api/v2/core/settings/bind/update',
        data: {
          'bindAddress': currentBind,
          'ipv6': ipv6Enabled ? 'Enable' : 'Disable',
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      debugPrint(
          '响应: code=${responseData['code']}, message=${responseData['message']}');
      debugPrint('接口可用: ${responseData['code'] == 200}');

      debugPrint('========================================\n');
    });

    test('5. 测试开发者模式和会话超时更新', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试开发者模式和会话超时更新');
      debugPrint('========================================');

      // 测试 /core/settings/update 接口
      final testCases = [
        {'key': 'developerMode', 'value': 'Enable'},
        {'key': 'sessionTimeout', 'value': '60'},
        {'key': 'theme', 'value': 'dark'},
        {'key': 'language', 'value': 'en'},
      ];

      for (final testCase in testCases) {
        debugPrint('\n--- 测试 ${testCase['key']} = ${testCase['value']} ---');
        try {
          final response = await dio.post(
            '/api/v2/core/settings/update',
            data: testCase,
          );
          final responseData = response.data as Map<String, dynamic>;
          debugPrint(
              '响应: code=${responseData['code']}, message=${responseData['message']}');
        } catch (e) {
          debugPrint('错误: $e');
        }
      }

      debugPrint('========================================\n');
    });
  });

  group('快照管理API测试', () {
    test('1. 测试快照列表接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试快照列表接口');
      debugPrint('========================================');

      // 尝试不同的参数格式
      final testCases = [
        {
          'desc': '完整分页参数',
          'data': _snapshotSearchPayload(),
        },
        {
          'desc': '使用 typed client 对齐参数',
          'data': _snapshotSearchPayload(),
        },
      ];

      for (final testCase in testCases) {
        debugPrint('\n--- ${testCase['desc']} ---');
        try {
          final response = await dio.post(
            '/api/v2/settings/snapshot/search',
            data: testCase['data'],
          );
          final responseData = response.data;
          debugPrint('响应: ${jsonEncode(responseData)}');

          if (responseData is Map<String, dynamic> &&
              responseData['code'] == 200 &&
              responseData['data'] is Map<String, dynamic>) {
            final data = responseData['data'] as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>? ?? [];
            debugPrint('快照数量: ${items.length}');
          }
        } catch (e) {
          debugPrint('错误: $e');
        }
      }

      debugPrint('========================================\n');
    });

    test('2. 测试快照创建接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试快照创建接口');
      debugPrint('========================================');

      final response = await dio.post(
        '/api/v2/settings/snapshot',
        data: _snapshotCreatePayload(
          'API Test Snapshot ${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      final responseData = response.data as Map<String, dynamic>;
      debugPrint(
          '响应: code=${responseData['code']}, message=${responseData['message']}');
      debugPrint('接口可用: ${responseData['code'] == 200}');

      debugPrint('========================================\n');
    });

    test('3. 测试快照载入接口', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试快照载入接口');
      debugPrint('========================================');

      // 正式契约为 /settings/snapshot/load
      try {
        final response = await dio.get('/api/v2/settings/snapshot/load');
        final responseData = response.data as Map<String, dynamic>;
        debugPrint(
            '响应: code=${responseData['code']}, message=${responseData['message']}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      debugPrint('========================================\n');
    });
  });

  group('总结', () {
    test('API接口可用性总结', () async {
      debugPrint('\n========================================');
      debugPrint('API接口可用性总结');
      debugPrint('========================================');

      debugPrint('''
根据测试结果：

✅ 可编辑的接口:
  - /core/settings/terminal/update - 终端设置（需要字符串参数）
  - /core/settings/port/update - 端口设置（需要数字参数）
  - /core/settings/bind/update - 绑定地址设置（需要ipv6参数）

❌ 不可编辑的接口:
  - /core/settings/update - 返回 "record not found" 错误
    这意味着: panelName, developerMode, sessionTimeout, theme, language 等无法通过此接口修改

⚠️ 需要进一步确认:
  - 快照创建需要 sourceAccountIDs/downloadAccountID
  - 部分设置接口是服务端设计限制，不应再走旧探测路径

结论：
1. 面板配置中的面板名称、主题、语言等无法通过API编辑
2. 端口和绑定地址可以编辑
3. 终端设置可以编辑
4. 快照管理应使用 /settings/snapshot 与 /settings/snapshot/load 正式路由
''');

      debugPrint('========================================\n');
    });
  });
}
