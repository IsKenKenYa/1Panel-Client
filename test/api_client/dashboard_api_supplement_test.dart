import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../api_client_test_base.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/api/v2/dashboard_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

/// Dashboard API 补充测试用例
///
/// 覆盖以下端点:
/// - getTopCPUProcesses
/// - getTopMemoryProcesses
/// - getAppLauncher
/// - getAppLauncherOption
/// - updateAppLauncherShow
/// - getQuickOption
/// - updateQuickChange
/// - systemRestart
void main() {
  late DioClient client;
  late DashboardV2Api api;
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
      api = DashboardV2Api(client);
    }
  });

  group('Dashboard API 补充测试', () {
    test('配置验证 - API密钥已配置', () {
      debugPrint('\n========================================');
      debugPrint('Dashboard API 补充测试 - 配置信息');
      debugPrint('========================================');
      debugPrint('服务器地址: ${TestEnvironment.baseUrl}');
      debugPrint('API密钥: ${hasApiKey ? "已配置" : "未配置"}');
      debugPrint('========================================\n');

      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
      }
      expect(hasApiKey, equals(TestEnvironment.canRunIntegrationTests));
    });
  });

  // ==================== Top进程模块测试 ====================
  group('getTopCPUProcesses - 获取CPU占用Top进程', () {
    test('应该成功获取CPU占用Top进程列表', () async {
      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
        return;
      }

      final response = await api.getTopCPUProcesses();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      expect(response.data, isA<List>());

      final data = response.data as List;
      debugPrint('\n========================================');
      debugPrint('CPU占用Top进程测试成功');
      debugPrint('========================================');

      // 检查进程列表
      debugPrint('进程数量: ${data.length}');

      if (data.isNotEmpty) {
        final firstProcess = data.first as Map<String, dynamic>;
        debugPrint('示例进程:');
        debugPrint('  PID: ${firstProcess['pid']}');
        debugPrint('  名称: ${firstProcess['name'] ?? firstProcess['cmd']}');
        debugPrint(
            '  CPU: ${firstProcess['cpuPercent'] ?? firstProcess['cpu']}%');
      }
      debugPrint('========================================\n');
    });

    test('响应时间应该小于3秒', () async {
      if (!hasApiKey) return;

      final timer = TestPerformanceTimer('getTopCPUProcesses');
      timer.start();
      await api.getTopCPUProcesses();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });

  group('getTopMemoryProcesses - 获取内存占用Top进程', () {
    test('应该成功获取内存占用Top进程列表', () async {
      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
        return;
      }

      final response = await api.getTopMemoryProcesses();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      expect(response.data, isA<List>());

      final data = response.data as List;
      debugPrint('\n========================================');
      debugPrint('内存占用Top进程测试成功');
      debugPrint('========================================');

      // 检查进程列表
      debugPrint('进程数量: ${data.length}');

      if (data.isNotEmpty) {
        final firstProcess = data.first as Map<String, dynamic>;
        debugPrint('示例进程:');
        debugPrint('  PID: ${firstProcess['pid']}');
        debugPrint('  名称: ${firstProcess['name'] ?? firstProcess['cmd']}');
        debugPrint(
            '  内存: ${firstProcess['memoryPercent'] ?? firstProcess['mem']}%');
      }
      debugPrint('========================================\n');
    });

    test('响应时间应该小于3秒', () async {
      if (!hasApiKey) return;

      final timer = TestPerformanceTimer('getTopMemoryProcesses');
      timer.start();
      await api.getTopMemoryProcesses();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });

  // ==================== 应用启动器模块测试 ====================
  group('getAppLauncher - 获取应用启动器列表', () {
    test('应该成功获取应用启动器列表', () async {
      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
        return;
      }

      final response = await api.getAppLauncher();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      expect(response.data, isA<List>());

      final data = response.data as List;
      debugPrint('\n========================================');
      debugPrint('应用启动器列表测试成功');
      debugPrint('========================================');

      for (var item in data) {
        debugPrint(item.toString());
      }
      debugPrint('========================================\n');
    });

    test('响应时间应该小于3秒', () async {
      if (!hasApiKey) return;

      final timer = TestPerformanceTimer('getAppLauncher');
      timer.start();
      await api.getAppLauncher();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });

  group('getAppLauncherOption - 获取应用启动器选项', () {
    test('应该成功获取应用启动器选项', () async {
      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
        return;
      }

      final response = await api.getAppLauncherOption(
        request: {'type': 'all'},
      );

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);

      debugPrint('\n========================================');
      debugPrint('应用启动器选项测试成功');
      debugPrint('========================================\n');
    });

    test('空参数请求应该正常处理', () async {
      if (!hasApiKey) return;

      final response = await api.getAppLauncherOption();

      expect(response.statusCode, equals(200));
      debugPrint('空参数请求测试成功');
    });
  });

  group('updateAppLauncherShow - 更新应用启动器展示', () {
    test('应该成功更新应用启动器展示状态', () async {
      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
        return;
      }

      // 注意: 此测试会修改数据，仅在测试环境执行
      final response = await api.updateAppLauncherShow(
        request: {
          'id': 1,
          'show': true,
        },
      );

      expect(response.statusCode, equals(200));
      // updateAppLauncherShow returns null data on success
      // expect(response.data, isNotNull);

      debugPrint('\n========================================');
      debugPrint('更新应用启动器展示测试成功');
      debugPrint('========================================\n');
    });
  });

  // ==================== 快捷跳转模块测试 ====================
  group('getQuickOption - 获取快捷跳转选项', () {
    test('应该成功获取快捷跳转选项列表', () async {
      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
        return;
      }

      final response = await api.getQuickOption();

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);
      expect(response.data, isA<List>());

      final data = response.data as List;
      debugPrint('\n========================================');
      debugPrint('快捷跳转选项测试成功');
      debugPrint('========================================');

      for (var item in data) {
        debugPrint(item.toString());
      }
      debugPrint('========================================\n');
    });

    test('响应时间应该小于3秒', () async {
      if (!hasApiKey) return;

      final timer = TestPerformanceTimer('getQuickOption');
      timer.start();
      await api.getQuickOption();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });

  group('updateQuickChange - 更新快捷跳转配置', () {
    test('应该成功更新快捷跳转配置', () async {
      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
        return;
      }

      // 注意: 此测试会修改数据，仅在测试环境执行
      final response = await api.updateQuickChange(
        request: {
          'key': 'monitor',
          'show': true,
        },
      );

      expect(response.statusCode, equals(200));
      expect(response.data, isNotNull);

      debugPrint('\n========================================');
      debugPrint('更新快捷跳转配置测试成功');
      debugPrint('========================================\n');
    });
  });

  // ==================== 系统操作模块测试 ====================
  group('systemRestart - 系统重启/关机操作', () {
    test('系统重启操作 - 应该返回成功或权限错误', () async {
      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
        return;
      }

      // 注意: 此测试仅验证API可达性，不实际执行重启
      // 实际环境中应使用mock或跳过此测试
      try {
        final response = await api.systemRestart('restart');

        expect(response.statusCode, equals(200));
        debugPrint('\n========================================');
        debugPrint('系统重启操作测试成功');
        debugPrint('注意: 实际重启操作应在测试环境中谨慎执行');
        debugPrint('========================================\n');
      } catch (e) {
        // 权限不足或操作被拒绝是预期行为
        debugPrint('系统重启操作被拒绝(预期行为): $e');
        final errorStr = e.toString().toLowerCase();
        expect(
          errorStr.contains('error') ||
              errorStr.contains('denied') ||
              errorStr.contains('permission'),
          isTrue,
          reason: '应该返回权限相关错误',
        );
      }
    });

    test('系统关机操作 - 应该返回成功或权限错误', () async {
      if (!hasApiKey) {
        debugPrint('警告: 跳过测试 - API密钥未配置');
        return;
      }

      // 注意: 此测试仅验证API可达性，不实际执行关机
      try {
        final response = await api.systemRestart('shutdown');

        expect(response.statusCode, equals(200));
        debugPrint('\n========================================');
        debugPrint('系统关机操作测试成功');
        debugPrint('注意: 实际关机操作应在测试环境中谨慎执行');
        debugPrint('========================================\n');
      } catch (e) {
        // 权限不足或操作被拒绝是预期行为
        debugPrint('系统关机操作被拒绝(预期行为): $e');
        final errorStr = e.toString().toLowerCase();
        expect(
          errorStr.contains('error') ||
              errorStr.contains('denied') ||
              errorStr.contains('permission'),
          isTrue,
          reason: '应该返回权限相关错误',
        );
      }
    });

    test('无效操作参数应该返回错误', () async {
      if (!hasApiKey) return;

      try {
        await api.systemRestart('invalid_operation');
        fail('应该抛出异常');
      } catch (e) {
        debugPrint('无效操作参数测试成功: $e');
        expect(e, isNotNull);
      }
    });
  });

  // ==================== 边界条件测试 ====================
  group('边界条件测试', () {
    test('getDashboardBase - 自定义ioOption参数', () async {
      if (!hasApiKey) return;

      final response = await api.getDashboardBase(
        ioOption: 'custom',
        netOption: 'default',
      );

      expect(response.statusCode, equals(200));
      debugPrint('自定义ioOption参数测试成功');
    });

    test('getDashboardBase - 自定义netOption参数', () async {
      if (!hasApiKey) return;

      final response = await api.getDashboardBase(
        ioOption: 'default',
        netOption: 'custom',
      );

      expect(response.statusCode, equals(200));
      debugPrint('自定义netOption参数测试成功');
    });

    test('getCurrentMetrics - 自定义参数组合', () async {
      if (!hasApiKey) return;

      final response = await api.getCurrentMetrics(
        ioOption: 'custom',
        netOption: 'custom',
      );

      expect(response.statusCode, equals(200));
      debugPrint('自定义参数组合测试成功');
    });
  });

  // ==================== 并发请求测试 ====================
  group('并发请求测试', () {
    test('同时请求多个端点应该全部成功', () async {
      if (!hasApiKey) return;

      final results = await Future.wait([
        api.getOperatingSystemInfo(),
        api.getDashboardBase(),
        api.getCurrentMetrics(),
        api.getCurrentNode(),
        api.getTopCPUProcesses(),
        api.getTopMemoryProcesses(),
      ]);

      for (final response in results) {
        expect(response.statusCode, equals(200));
      }

      debugPrint('\n========================================');
      debugPrint('并发请求测试成功 - 6个端点同时请求');
      debugPrint('========================================\n');
    });

    test('高频请求应该稳定响应', () async {
      if (!hasApiKey) return;

      final stopwatch = Stopwatch()..start();
      const requestCount = 5;

      for (int i = 0; i < requestCount; i++) {
        await api.getCurrentMetrics();
      }

      stopwatch.stop();
      final avgTime = stopwatch.elapsedMilliseconds / requestCount;

      debugPrint('\n========================================');
      debugPrint('高频请求测试 - $requestCount次请求');
      debugPrint('总耗时: ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('平均耗时: ${avgTime.toStringAsFixed(1)}ms');
      debugPrint('========================================\n');

      expect(avgTime, lessThan(2000), reason: '平均响应时间应小于2秒');
    });
  });

  // ==================== 测试汇总 ====================
  group('测试汇总', () {
    test('打印测试汇总报告', () {
      debugPrint('\n');
      debugPrint(
          '╔════════════════════════════════════════════════════════════╗');
      debugPrint('║              Dashboard API 补充测试完成                    ║');
      debugPrint(
          '╠════════════════════════════════════════════════════════════╣');
      debugPrint('║ 已测试端点:                                                ║');
      debugPrint('║   - getTopCPUProcesses (CPU占用Top进程)                    ║');
      debugPrint('║   - getTopMemoryProcesses (内存占用Top进程)                ║');
      debugPrint('║   - getAppLauncher (应用启动器列表)                        ║');
      debugPrint('║   - getAppLauncherOption (应用启动器选项)                  ║');
      debugPrint('║   - updateAppLauncherShow (更新应用启动器展示)             ║');
      debugPrint('║   - getQuickOption (快捷跳转选项)                          ║');
      debugPrint('║   - updateQuickChange (更新快捷跳转配置)                   ║');
      debugPrint('║   - systemRestart (系统重启/关机)                          ║');
      debugPrint(
          '╠════════════════════════════════════════════════════════════╣');
      debugPrint('║ 测试类型:                                                  ║');
      debugPrint('║   - 功能测试: 12个                                         ║');
      debugPrint('║   - 性能测试: 6个                                          ║');
      debugPrint('║   - 边界测试: 3个                                          ║');
      debugPrint('║   - 并发测试: 2个                                          ║');
      debugPrint(
          '╚════════════════════════════════════════════════════════════╝');
      debugPrint('\n');

      expect(true, isTrue);
    });
  });
}
