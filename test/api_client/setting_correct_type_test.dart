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
    hasApiKey = TestEnvironment.apiKey.isNotEmpty &&
        TestEnvironment.apiKey != 'your_api_key_here';

    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
    }
  });

  group('1Panel设置编辑 - 正确参数类型测试', () {
    test('1. 终端设置更新 - fontSize使用字符串', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试终端设置更新（字符串类型）');
      debugPrint('========================================');

      // 尝试更新 - 使用字符串类型
      final updateResponse = await dio.post(
        '/api/v2/core/settings/terminal/update',
        data: {
          'fontSize': '16', // 字符串类型
          'cursorStyle': 'block',
          'cursorBlink': 'true',
          'scrollSensitivity': '1',
          'scrollback': '1000',
          'lineHeight': '1.2',
          'letterSpacing': '0',
        },
      );

      final updateData = updateResponse.data as Map<String, dynamic>;
      debugPrint(
          '更新响应: code=${updateData['code']}, message=${updateData['message']}');

      // 验证
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyResponse =
          await dio.post('/api/v2/core/settings/terminal/search');
      final verifyData = verifyResponse.data as Map<String, dynamic>;

      debugPrint('验证后的设置: ${jsonEncode(verifyData['data'])}');
      debugPrint('更新成功: ${updateData['code'] == 200}');
      debugPrint('========================================\n');
    });

    test('2. 端口更新 - serverPort使用数字', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试端口更新（数字类型）');
      debugPrint('========================================');

      // 获取当前端口
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final currentPort =
          int.tryParse(data?['serverPort']?.toString() ?? '9999') ?? 9999;

      debugPrint('当前端口: $currentPort');

      // 尝试更新端口 - 使用数字类型
      final updateResponse = await dio.post(
        '/api/v2/core/settings/port/update',
        data: {'serverPort': currentPort}, // 数字类型
      );

      final updateData = updateResponse.data as Map<String, dynamic>;
      debugPrint(
          '更新响应: code=${updateData['code']}, message=${updateData['message']}');
      debugPrint('更新成功: ${updateData['code'] == 200}');
      debugPrint('========================================\n');
    });

    test('3. 绑定地址更新 - 包含Ipv6参数', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试绑定地址更新（包含Ipv6）');
      debugPrint('========================================');

      // 获取当前设置
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final currentBind = data?['bindAddress'] as String? ?? '::';
      final ipv6Enabled = data?['ipv6'] == 'Enable';

      debugPrint('当前绑定地址: $currentBind, IPv6: $ipv6Enabled');

      // 尝试更新 - 包含Ipv6参数
      final updateResponse = await dio.post(
        '/api/v2/core/settings/bind/update',
        data: {
          'bindAddress': currentBind,
          'ipv6': ipv6Enabled ? 'Enable' : 'Disable',
        },
      );

      final updateData = updateResponse.data as Map<String, dynamic>;
      debugPrint(
          '更新响应: code=${updateData['code']}, message=${updateData['message']}');
      debugPrint('更新成功: ${updateData['code'] == 200}');
      debugPrint('========================================\n');
    });

    test('4. 快照列表 - 正确分页参数', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试快照列表（正确参数）');
      debugPrint('========================================');

      // 尝试不同的参数组合
      final testCases = [
        {'page': 1, 'pageSize': 10},
        {
          'pageInfo': {'page': 1, 'pageSize': 10}
        },
        {'page': '1', 'pageSize': '10'},
      ];

      for (final params in testCases) {
        debugPrint('\n--- 尝试参数: ${jsonEncode(params)} ---');
        try {
          final response = await dio.post(
            '/api/v2/settings/snapshot/search',
            data: params,
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

    test('5. 系统升级版本列表', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试系统升级版本列表');
      debugPrint('========================================');

      try {
        final response =
            await dio.post('/api/v2/core/settings/upgrade/releases');
        debugPrint('响应类型: ${response.data.runtimeType}');
        debugPrint('响应数据: ${jsonEncode(response.data)}');
      } catch (e) {
        debugPrint('错误: $e');
      }

      debugPrint('========================================\n');
    });

    test('6. 总结', () async {
      debugPrint('\n========================================');
      debugPrint('API接口可用性总结');
      debugPrint('========================================');

      debugPrint('''
根据测试结果，以下是API接口的可用性：

✅ 可读取的接口:
  - /core/settings/search - 获取系统设置
  - /core/settings/terminal/search - 获取终端设置

⚠️ 需要特定参数类型的更新接口:
  - /core/settings/terminal/update - fontSize等需要字符串类型
  - /core/settings/port/update - serverPort需要数字类型(uint)
  - /core/settings/bind/update - 需要ipv6参数

❌ 不可用的接口:
  - /core/settings/update - 返回 "record not found" 错误
  - /settings/snapshot/search - 参数格式需要进一步确认

❓ 需要进一步测试:
  - /core/settings/upgrade/releases - 系统升级版本列表
  - /settings/snapshot/create - 快照创建

结论：
1. 大部分设置只能读取，不能通过API修改
2. 终端设置、端口、绑定地址可以修改，但需要正确的参数类型
3. 面板名称等通用设置无法通过 /core/settings/update 修改
''');

      debugPrint('========================================\n');
    });
  });
}
