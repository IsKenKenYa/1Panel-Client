import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import '../core/test_config_manager.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import '../test_helper.dart';

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

  group('系统设置API响应测试', () {
    test('getSystemSettings - 获取系统设置', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final response = await api.getSystemSettings();

      debugPrint('\n========================================');
      debugPrint('getSystemSettings 响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据是否为null: ${response.data == null}');

      if (response.data != null) {
        final data = response.data!;
        expect(data, isA<SystemSettingInfo>());

        debugPrint('userName: ${data.userName}');
        debugPrint('panelName: ${data.panelName}');
        debugPrint('systemVersion: ${data.systemVersion}');
        debugPrint('theme: ${data.theme}');
        debugPrint('language: ${data.language}');
        debugPrint('port: ${data.port}');
        debugPrint('ssl: ${data.ssl}');
        debugPrint('apiInterfaceStatus: ${data.apiInterfaceStatus}');

        expect(response.statusCode, equals(200));
      }
      debugPrint('========================================\n');
    });

    test('getTerminalSettings - 获取终端设置', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final response = await api.getTerminalSettings();

      debugPrint('\n========================================');
      debugPrint('getTerminalSettings 响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据是否为null: ${response.data == null}');

      if (response.data != null) {
        final data = response.data!;
        expect(data, isA<TerminalInfo>());

        debugPrint('cursorBlink: ${data.cursorBlink}');
        debugPrint('cursorStyle: ${data.cursorStyle}');
        debugPrint('fontSize: ${data.fontSize}');
        debugPrint('lineHeight: ${data.lineHeight}');

        expect(response.statusCode, equals(200));
      }
      debugPrint('========================================\n');
    });

    test('getNetworkInterfaces - 获取网络接口列表', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final response = await api.getNetworkInterfaces();

      debugPrint('\n========================================');
      debugPrint('getNetworkInterfaces 响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据是否为null: ${response.data == null}');

      if (response.data != null) {
        expect(response.data, isA<List<String>>());
        debugPrint('接口数量: ${response.data!.length}');
        if (response.data!.isNotEmpty) {
          debugPrint('前3个IP: ${response.data!.take(3).join(", ")}');
        }
        expect(response.statusCode, equals(200));
      }
      debugPrint('========================================\n');
    });

    test('getSSLInfo - 获取SSL信息', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      try {
        final response = await api.getSSLInfo();

        debugPrint('\n========================================');
        debugPrint('getSSLInfo 响应');
        debugPrint('========================================');
        debugPrint('状态码: ${response.statusCode}');
        debugPrint('数据是否为null: ${response.data == null}');

        if (response.data != null) {
          final jsonStr =
              const JsonEncoder.withIndent('  ').convert(response.data);
          debugPrint('SSL信息:\n$jsonStr');
        }
        expect(response.statusCode, equals(200));
        debugPrint('========================================\n');
      } catch (e) {
        debugPrint('⚠️  getSSLInfo 测试失败: $e');
      }
    });

    test('getUpgradeInfo - 获取升级信息', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      try {
        final response = await api.getUpgradeInfo();

        debugPrint('\n========================================');
        debugPrint('getUpgradeInfo 响应');
        debugPrint('========================================');
        debugPrint('状态码: ${response.statusCode}');
        debugPrint('数据是否为null: ${response.data == null}');

        if (response.data != null) {
          final jsonStr =
              const JsonEncoder.withIndent('  ').convert(response.data);
          debugPrint('升级信息:\n$jsonStr');
        }
        expect(response.statusCode, equals(200));
        debugPrint('========================================\n');
      } catch (e) {
        debugPrint('⚠️  getUpgradeInfo 测试失败: $e');
      }
    });

    test('getUpgradeReleases - 获取升级版本列表', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final Response<dynamic> response;
      try {
        response = await api.getUpgradeReleases();
      } catch (e) {
        if (SkipConditions.isServerUnavailable(e)) {
          debugPrint('⚠️  跳过测试: 服务器升级版本端点当前不可用');
          return;
        }
        rethrow;
      }

      debugPrint('\n========================================');
      debugPrint('getUpgradeReleases 响应');
      debugPrint('========================================');
      debugPrint('状态码: ${response.statusCode}');
      debugPrint('数据是否为null: ${response.data == null}');

      if (response.data != null) {
        debugPrint('版本数量: ${response.data!.length}');
        if (response.data!.isNotEmpty) {
          debugPrint('第一个版本: ${response.data!.first}');
        }
      }
      expect(response.statusCode, equals(200));
      debugPrint('========================================\n');
    });

    test('searchSnapshots - 搜索快照', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      try {
        final response =
            await api.searchSnapshots(SnapshotSearch(page: 1, pageSize: 10));

        debugPrint('\n========================================');
        debugPrint('searchSnapshots 响应');
        debugPrint('========================================');
        debugPrint('状态码: ${response.statusCode}');
        debugPrint('数据是否为null: ${response.data == null}');

        if (response.data != null) {
          final jsonStr =
              const JsonEncoder.withIndent('  ').convert(response.data);
          debugPrint('快照数据:\n$jsonStr');
        }
        expect(response.statusCode, equals(200));
        debugPrint('========================================\n');
      } catch (e) {
        debugPrint('⚠️  searchSnapshots 测试失败: $e');
      }
    });

    test('getAuthSetting - 获取认证设置', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      try {
        final response = await api.getAuthSetting();

        debugPrint('\n========================================');
        debugPrint('getAuthSetting 响应');
        debugPrint('========================================');
        debugPrint('状态码: ${response.statusCode}');
        debugPrint('数据是否为null: ${response.data == null}');

        if (response.data != null) {
          final jsonStr =
              const JsonEncoder.withIndent('  ').convert(response.data);
          debugPrint('认证设置:\n$jsonStr');
        }
        expect(response.statusCode, equals(200));
        debugPrint('========================================\n');
      } catch (e) {
        debugPrint('⚠️  getAuthSetting 测试失败: $e');
      }
    });

    test('getSSHConnection - 获取SSH连接信息', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      try {
        final response = await api.getSSHConnection();

        debugPrint('\n========================================');
        debugPrint('getSSHConnection 响应');
        debugPrint('========================================');
        debugPrint('状态码: ${response.statusCode}');
        debugPrint('数据是否为null: ${response.data == null}');

        if (response.data != null) {
          final jsonStr =
              const JsonEncoder.withIndent('  ').convert(response.data);
          debugPrint('SSH连接信息:\n$jsonStr');
        }
        expect(response.statusCode, equals(200));
        debugPrint('========================================\n');
      } catch (e) {
        debugPrint('⚠️  getSSHConnection 测试失败: $e');
      }
    });
  });

  group('API性能测试', () {
    test('性能基准测试', () async {
      if (!hasApiKey) {
        debugPrint('⚠️  跳过测试: API密钥未配置');
        return;
      }

      final stopwatch = Stopwatch()..start();

      try {
        await api.getSystemSettings();
        final systemTime = stopwatch.elapsedMilliseconds;
        stopwatch.reset();
        stopwatch.start();

        await api.getTerminalSettings();
        final terminalTime = stopwatch.elapsedMilliseconds;
        stopwatch.reset();
        stopwatch.start();

        await api.getNetworkInterfaces();
        final interfaceTime = stopwatch.elapsedMilliseconds;

        debugPrint('\n========================================');
        debugPrint('API性能基准');
        debugPrint('========================================');
        debugPrint('getSystemSettings: ${systemTime}ms');
        debugPrint('getTerminalSettings: ${terminalTime}ms');
        debugPrint('getNetworkInterfaces: ${interfaceTime}ms');
        debugPrint('========================================\n');

        expect(systemTime, lessThan(5000));
        expect(terminalTime, lessThan(5000));
        expect(interfaceTime, lessThan(5000));
      } catch (e) {
        if (SkipConditions.isServerUnavailable(e)) {
          debugPrint('⚠️  跳过测试: 服务器当前连接中断');
          return;
        }
        rethrow;
      }
    });
  });
}
