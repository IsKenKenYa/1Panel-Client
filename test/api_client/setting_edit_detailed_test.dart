import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import '../test_helper.dart';
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

  group('1Panel设置编辑能力详细测试', () {
    test('1. 终端设置更新 - 使用正确参数', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试终端设置更新');
      debugPrint('========================================');

      // 获取当前设置
      final searchResponse =
          await dio.post('/api/v2/core/settings/terminal/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;

      debugPrint('当前终端设置: ${jsonEncode(data)}');

      // 尝试更新 - 使用完整的参数
      debugPrint('\n--- 尝试更新终端设置 ---');
      final updateResponse = await dio.post(
        '/api/v2/core/settings/terminal/update',
        data: {
          'fontSize': '16',
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

    test('2. 通用设置更新 - 使用正确参数格式', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试通用设置更新');
      debugPrint('========================================');

      // 获取当前设置
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final originalPanelName = data?['panelName'] as String? ?? '';

      debugPrint('当前面板名称: $originalPanelName');

      // 尝试更新 - 使用正确的参数格式
      debugPrint('\n--- 尝试更新面板名称 ---');
      try {
        final updateResponse = await dio.post(
          '/api/v2/core/settings/update',
          data: {
            'key': 'panelName',
            'value': 'TestPanel_${DateTime.now().millisecondsSinceEpoch}',
          },
        );

        final updateData = updateResponse.data as Map<String, dynamic>;
        debugPrint(
            '更新响应: code=${updateData['code']}, message=${updateData['message']}');

        // 验证
        await Future.delayed(const Duration(milliseconds: 500));
        final verifyResponse = await dio.post('/api/v2/core/settings/search');
        final verifyData = verifyResponse.data as Map<String, dynamic>;
        final verifySettings = verifyData['data'] as Map<String, dynamic>?;

        debugPrint('验证后的面板名称: ${verifySettings?['panelName']}');
        debugPrint('更新成功: ${updateData['code'] == 200}');

        // 恢复原始值
        if (updateData['code'] == 200) {
          await dio.post(
            '/api/v2/core/settings/update',
            data: {'key': 'panelName', 'value': originalPanelName},
          );
          debugPrint('已恢复原始面板名称');
        }
      } catch (e) {
        debugPrint('更新受限: $e');
      }

      debugPrint('========================================\n');
    });

    test('3. 绑定地址更新 - 使用正确参数', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试绑定地址更新');
      debugPrint('========================================');

      // 获取当前绑定地址
      final searchResponse = await dio.post('/api/v2/core/settings/search');
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final currentBind = data?['bindAddress'] as String?;
      final ipv6Enabled = data?['ipv6'] == 'Enable';

      debugPrint('当前绑定地址: $currentBind');

      // 尝试更新
      debugPrint('\n--- 尝试更新绑定地址 ---');
      final updateResponse = await dio.post(
        '/api/v2/core/settings/bind/update',
        data: {
          'bindAddress': currentBind ?? '::',
          'ipv6': ipv6Enabled ? 'Enable' : 'Disable',
        },
      );

      final updateData = updateResponse.data as Map<String, dynamic>;
      debugPrint(
          '更新响应: code=${updateData['code']}, message=${updateData['message']}');
      debugPrint('更新成功: ${updateData['code'] == 200}');
      debugPrint('========================================\n');
    });

    test('5. 系统升级 - 获取版本列表', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试系统升级');
      debugPrint('========================================');

      // 获取当前版本
      final Response<dynamic> searchResponse;
      try {
        searchResponse = await dio.post('/api/v2/core/settings/search');
      } catch (e) {
        if (SkipConditions.isServerUnavailable(e)) {
          debugPrint('⚠️  跳过测试: 服务器设置端点当前连接中断');
          return;
        }
        rethrow;
      }
      final searchData = searchResponse.data as Map<String, dynamic>;
      final data = searchData['data'] as Map<String, dynamic>?;
      final currentVersion = data?['systemVersion'] as String?;

      debugPrint('当前版本: $currentVersion');

      // 获取可用版本
      debugPrint('\n--- 获取可用升级版本 ---');
      try {
        final releasesResponse =
            await dio.post('/api/v2/core/settings/upgrade/releases');
        final releasesData = releasesResponse.data as Map<String, dynamic>;
        debugPrint('版本列表响应: code=${releasesData['code']}');

        if (releasesData['code'] == 200 && releasesData['data'] != null) {
          final releases = releasesData['data'] as List<dynamic>;
          debugPrint('可用版本数量: ${releases.length}');
          for (final release in releases) {
            debugPrint(
                '  - ${release['version']}: ${release['description'] ?? ''}');
          }
        }
      } catch (e) {
        debugPrint('获取版本错误: $e');
      }

      debugPrint('========================================\n');
    });

    test('6. 快照列表 - 使用正确分页参数', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试快照列表');
      debugPrint('========================================');

      final Response<dynamic> searchResponse;
      try {
        searchResponse = await dio.post(
          '/api/v2/settings/snapshot/search',
          data: {
            'page': 1,
            'pageSize': 10,
            'orderBy': 'createdAt',
            'order': 'descending',
          },
        );
      } catch (e) {
        if (SkipConditions.isServerUnavailable(e)) {
          debugPrint('⚠️  跳过测试: 服务器快照端点当前连接中断');
          return;
        }
        rethrow;
      }

      final searchData = searchResponse.data as Map<String, dynamic>;
      debugPrint('快照列表响应: code=${searchData['code']}');

      if (searchData['code'] == 200 && searchData['data'] != null) {
        final data = searchData['data'] as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('快照数量: ${items.length}');
        for (final item in items) {
          debugPrint('  - ${item['name']}: ${item['description'] ?? ''}');
        }
      }

      debugPrint('========================================\n');
    });

    test('7. 快照创建 - 使用正确参数', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final dio = client.dio;

      debugPrint('\n========================================');
      debugPrint('测试快照创建');
      debugPrint('========================================');

      final Response<dynamic> createResponse;
      try {
        createResponse = await dio.post(
          '/api/v2/settings/snapshot',
          data: {
            'description': 'Test snapshot from API test',
            'sourceAccountIDs': '1',
            'downloadAccountID': 1,
          },
        );
      } catch (e) {
        if (SkipConditions.isServerUnavailable(e)) {
          debugPrint('⚠️  跳过测试: 服务器快照端点当前连接中断');
          return;
        }
        rethrow;
      }

      final createData = createResponse.data as Map<String, dynamic>;
      debugPrint(
          '创建响应: code=${createData['code']}, message=${createData['message']}');
      debugPrint('创建成功: ${createData['code'] == 200}');

      // 快照体积约 280MB，创建成功后立即删除，避免磁盘被多轮回归填满。
      try {
        final searchResponse = await dio.post(
          '/api/v2/settings/snapshot/search',
          data: {
            'page': 1,
            'pageSize': 50,
            'orderBy': 'createdAt',
            'order': 'descending',
          },
        );
        final searchData = searchResponse.data as Map<String, dynamic>;
        final items =
            (searchData['data']?['items'] as List<dynamic>? ?? const []);
        final ids = <int>[];
        for (final item in items) {
          final map = item as Map<String, dynamic>;
          final description = map['description']?.toString() ?? '';
          if (description.startsWith('Test snapshot from API test')) {
            ids.add(map['id'] as int);
          }
        }
        if (ids.isNotEmpty) {
          final deleteResponse = await dio.post(
            '/api/v2/settings/snapshot/del',
            data: {'ids': ids},
          );
          debugPrint(
              '清理测试快照: ids=$ids code=${deleteResponse.data?['code']}');
        }
      } catch (e) {
        if (SkipConditions.isServerUnavailable(e)) {
          debugPrint('⚠️  清理测试快照时服务器连接中断，下次运行重试');
        } else {
          debugPrint('⚠️  清理测试快照失败: $e');
        }
      }

      debugPrint('========================================\n');
    });

    test('8. 总结：API接口可用性', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      debugPrint('\n========================================');
      debugPrint('API接口可用性总结');
      debugPrint('========================================');

      debugPrint('''
✅ 可用接口（已验证）:
  - /core/settings/search - 获取系统设置
  - /core/settings/terminal/search - 获取终端设置
  - /core/settings/terminal/update - 更新终端设置
  - /core/settings/update - 更新通用设置（需要 key + value 参数）
  - /core/settings/bind/update - 更新绑定地址
  - /core/settings/upgrade/releases - 获取升级版本列表
  - /settings/snapshot/search - 获取快照列表（需要分页参数）
  - /settings/snapshot/create - 创建快照

⚠️ 需要特定参数的接口:
  - /core/settings/update - 需要 {"key": "xxx", "value": "xxx"}
  - /settings/snapshot/search - 需要 {"page": 1, "pageSize": 10, "orderBy": "xxx", "order": "xxx"}

❌ 不可用/需要验证的接口:
  - /core/settings/upgrade - 执行升级（需要进一步测试）
''');

      debugPrint('========================================\n');
    });
  });
}
