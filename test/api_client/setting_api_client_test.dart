import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../api_client_test_base.dart';
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
    hasApiKey = TestEnvironment.apiKey.isNotEmpty &&
        TestEnvironment.apiKey != 'your_api_key_here';

    if (hasApiKey) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = SettingV2Api(client);
    }
  });

  group('Setting API客户端测试', () {
    test('配置验证 - API密钥已配置', () {
      debugPrint('\n========================================');
      debugPrint('Setting API测试配置');
      debugPrint('========================================');
      debugPrint('服务器地址: ${TestEnvironment.baseUrl}');
      debugPrint('API密钥: ${hasApiKey ? "已配置" : "未配置"}');
      debugPrint('========================================\n');

      expect(hasApiKey, equals(TestEnvironment.canRunIntegrationTests));
    });

    group('getSystemSettings - 获取系统设置', () {
      test('应该成功获取系统设置', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getSystemSettings();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<SystemSettingInfo>());

        debugPrint('\n========================================');
        debugPrint('✅ 系统设置测试成功');
        debugPrint('========================================');
        debugPrint('系统设置已获取');
        debugPrint('面板名称: ${response.data?.panelName}');
        debugPrint('系统版本: ${response.data?.systemVersion}');
        debugPrint('========================================\n');
      });
    });

    group('getTerminalSettings - 获取终端设置', () {
      test('应该成功获取终端设置', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getTerminalSettings();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<TerminalInfo>());

        debugPrint('\n========================================');
        debugPrint('✅ 终端设置测试成功');
        debugPrint('========================================');
        debugPrint('终端设置已获取');
        debugPrint('========================================\n');
      });
    });

    group('getNetworkInterfaces - 获取网络接口列表', () {
      test('应该成功获取网络接口列表', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.getNetworkInterfaces();

        expect(response.statusCode, equals(200));
        debugPrint('\n========================================');
        debugPrint('✅ 网络接口列表测试成功');
        debugPrint('状态码: ${response.statusCode}');
        debugPrint('接口数量: ${response.data?.length ?? 0}');
        if (response.data != null && response.data!.isNotEmpty) {
          debugPrint('第一个IP: ${response.data!.first}');
        }
        debugPrint('========================================\n');
      });
    });

    group('MFA相关API', () {
      test('loadMfaInfo - 应该成功加载MFA信息', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final request = const MfaLoadRequest(
          title: '1Panel Client',
          interval: 30,
        );

        final response = await api.loadMfaInfo(request);

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<MfaOtp>());

        final otp = response.data!;
        debugPrint('\n========================================');
        debugPrint('✅ MFA信息加载成功');
        debugPrint('========================================');
        debugPrint('Secret: ${otp.secret}');
        debugPrint('QR Image: ${otp.qrImage != null ? "已生成" : "未生成"}');
        debugPrint('========================================\n');
      });
    });

    group('generateApiKey - 生成API密钥', () {
      test('应该成功生成API密钥', () async {
        if (!hasApiKey) {
          debugPrint('⚠️  跳过测试: API密钥未配置');
          return;
        }

        final response = await api.generateApiKey();

        expect(response.statusCode, equals(200));
        // API密钥生成可能返回null（如果已存在或其他原因）
        debugPrint('\n========================================');
        debugPrint('✅ API密钥生成测试成功');
        debugPrint('状态码: ${response.statusCode}');
        debugPrint('数据: ${response.data}');
        debugPrint('========================================\n');
      });
    });

    group('getSystemSettingByKey - 按键获取设置', () {
      test('应当能获取指定设置项', () async {
        if (!hasApiKey) {
          debugPrint('跳过按键获取设置测试: 未配置API密钥');
          return;
        }

        try {
          debugPrint('调用获取设置接口: key=PanelName');
          final response = await api.getSystemSettingByKey('PanelName');

          debugPrint('响应状态码: ${response.statusCode}');
          debugPrint('响应消息: ${response.statusMessage}');
          if (response.data != null) {
            debugPrint('面板名称: ${response.data!.value}');
          } else {
            debugPrint('设置数据为空');
          }

          expect(response.statusCode, equals(200));
          // 返回值可能是SettingInfo或者为空，具体取决于后端
        } catch (e) {
          debugPrint('测试失败: $e');
          rethrow;
        }
      });
    });

    group('getMonitorSetting - 获取监控设置', () {
      test('应当能成功获取监控设置', () async {
        if (!hasApiKey) {
          debugPrint('跳过获取监控设置测试: 未配置API密钥');
          return;
        }

        try {
          debugPrint('调用获取监控设置接口');
          final response = await api.getMonitorSetting();

          debugPrint('响应状态码: ${response.statusCode}');
          debugPrint('响应消息: ${response.statusMessage}');
          if (response.data != null) {
            debugPrint('监控设置数据: ${response.data}');
          } else {
            debugPrint('监控设置数据为空');
          }

          expect(response.statusCode, equals(200));
        } catch (e) {
          debugPrint('测试失败: $e');
          rethrow;
        }
      });
    });
  });

  group('Setting API性能测试', () {
    test('getSystemSettings响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('getSystemSettings');
      timer.start();
      await api.getSystemSettings();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });

    test('getTerminalSettings响应时间应该小于3秒', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final timer = TestPerformanceTimer('getTerminalSettings');
      timer.start();
      await api.getTerminalSettings();
      timer.stop();
      timer.logResult();
      expect(timer.duration.inMilliseconds, lessThan(3000));
    });
  });
}
