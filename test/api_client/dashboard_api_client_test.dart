import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../api_client_test_base.dart';
import '../core/test_config_manager.dart';
import 'package:onepanelapp_app/api/v2/dashboard_v2.dart';
import 'package:onepanelapp_app/core/network/dio_client.dart';
import 'package:onepanelapp_app/data/models/common_models.dart';
import 'package:onepanelapp_app/data/models/monitoring_models.dart';

void main() {
  late DioClient client;
  late DashboardV2Api api;
  bool hasApiKey = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    hasApiKey = TestEnvironment.apiKey.isNotEmpty && TestEnvironment.apiKey != 'your_api_key_here';
    
    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = DashboardV2Api(client);
    }
  });

  group('Dashboard API客户端测试', () {
    test('配置验证 - API密钥已配置', () {
      debugPrint('\n========================================');
      debugPrint('测试配置信息');
      debugPrint('========================================');
      debugPrint('服务器地址: ${TestEnvironment.baseUrl}');
      debugPrint('API密钥: ${hasApiKey ? "已配置" : "未配置"}');
      debugPrint('========================================\n');
      
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
      }
      expect(hasApiKey, equals(TestEnvironment.canRunIntegrationTests));
    });

    group('getOperatingSystemInfo - 获取操作系统信息', () {
      test('应该成功获取操作系统信息', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getOperatingSystemInfo();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<SystemInfo>());

        final info = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 操作系统信息测试成功');
        debugPrint('========================================');
        debugPrint('操作系统: ${info.os}');
        debugPrint('平台: ${info.platform}');
        debugPrint('内核版本: ${info.kernelVersion}');
        debugPrint('架构: ${info.architecture}');
        debugPrint('主机名: ${info.hostname}');
        debugPrint('========================================\n');

        TestDataValidator.expectNonEmptyString(info.os, fieldName: 'os');
        TestDataValidator.expectNonEmptyString(info.platform, fieldName: 'platform');
      });
    });

    group('getDashboardBase - 获取仪表板基础指标', () {
      test('应该成功获取基础指标（默认参数）', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getDashboardBase();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<Map<String, dynamic>>());

        final data = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 仪表板基础指标测试成功');
        debugPrint('========================================');

        if (data.containsKey('hostname')) {
          debugPrint('主机名: ${data['hostname']}');
        }
        if (data.containsKey('cpuCores')) {
          debugPrint('CPU核心数: ${data['cpuCores']}');
        }
        if (data.containsKey('ipV4Addr')) {
          debugPrint('IPv4地址: ${data['ipV4Addr']}');
        }
        if (data.containsKey('websiteNumber')) {
          debugPrint('网站数量: ${data['websiteNumber']}');
        }
        if (data.containsKey('databaseNumber')) {
          debugPrint('数据库数量: ${data['databaseNumber']}');
        }
        if (data.containsKey('appInstalledNumber')) {
          debugPrint('已安装应用: ${data['appInstalledNumber']}');
        }
        debugPrint('========================================\n');
      });

      test('应该成功获取基础指标（自定义参数）', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getDashboardBase(
          ioOption: 'default',
          netOption: 'default',
        );

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        debugPrint('✅ 自定义参数测试成功');
      });
    });

    group('getCurrentMetrics - 获取当前指标', () {
      test('应该成功获取当前系统指标', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getCurrentMetrics();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<SystemMetrics>());

        final metrics = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 当前系统指标测试成功');
        debugPrint('========================================');
        debugPrint('指标类型: ${metrics.type?.value}');
        debugPrint('单位: ${metrics.unit}');
        debugPrint('当前值: ${metrics.current}');
        debugPrint('最小值: ${metrics.min}');
        debugPrint('最大值: ${metrics.max}');
        debugPrint('平均值: ${metrics.avg}');
        debugPrint('========================================\n');
      });
    });

    group('getCurrentNode - 获取当前节点信息', () {
      test('应该成功获取节点信息', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getCurrentNode();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);

        final data = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ 节点信息测试成功');
        debugPrint('========================================');
        data.forEach((key, value) {
          if (value != null && value.toString().length < 100) {
            debugPrint('$key: $value');
          }
        });
        debugPrint('========================================\n');
      });
    });
  });

  group('Dashboard API性能测试', () {
    test('getOperatingSystemInfo响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('getOperatingSystemInfo');
      timer.start();
      await api.getOperatingSystemInfo();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });

    test('getDashboardBase响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('getDashboardBase');
      timer.start();
      await api.getDashboardBase();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });

    test('getCurrentMetrics响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('getCurrentMetrics');
      timer.start();
      await api.getCurrentMetrics();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });
}
