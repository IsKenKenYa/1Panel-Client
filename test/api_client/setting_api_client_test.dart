import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/setting_models.dart';

import '../api_client_test_base.dart';
import '../core/test_config_manager.dart';

const String _pkg = 'test.api_client.setting';

String _prettyJson(Object? data) {
  try {
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data?.toString() ?? '';
  }
}

void _logSection(String title,
    {String? method, String? path, Object? request, Object? response}) {
  appLogger.dWithPackage(_pkg, '========================================');
  appLogger.dWithPackage(_pkg, title);
  if (method != null && path != null) {
    appLogger.dWithPackage(_pkg, 'Request: $method $path');
  }
  if (request != null) {
    appLogger.dWithPackage(_pkg, 'RequestBody: ${_prettyJson(request)}');
  }
  if (response != null) {
    appLogger.dWithPackage(_pkg, 'Response: ${_prettyJson(response)}');
  }
  appLogger.dWithPackage(_pkg, '========================================');
}

Future<Response<dynamic>> _rawGet(DioClient client, String path) {
  return client.get<dynamic>(ApiConstants.buildApiPath(path));
}

String _integrationSkipReason() =>
    TestEnvironment.skipIntegration() ??
    TestEnvironment.skipNoApiKey() ??
    'Integration tests unavailable';

bool _isSecureLoginHtml(dynamic payload) {
  return payload is String &&
      payload.contains('Access Temporarily Unavailable') &&
      payload.contains('1pctl user-info');
}

void main() {
  late DioClient client;
  late SettingV2Api api;
  bool canRun = false;

  setUpAll(() async {
    await TestEnvironment.initialize();
    canRun = TestEnvironment.canRunIntegrationTests;

    if (canRun) {
      client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      api = SettingV2Api(client);
    }
  });

  group('Setting API客户端测试', () {
    test('配置验证 - API密钥与集成测试开关', () {
      appLogger.iWithPackage(_pkg, '========================================');
      appLogger.iWithPackage(_pkg, 'Setting API测试配置');
      appLogger.iWithPackage(_pkg, '========================================');
      appLogger.iWithPackage(_pkg, '服务器地址: ${TestEnvironment.baseUrl}');
      appLogger.iWithPackage(
          _pkg, '集成测试: ${TestEnvironment.runIntegrationTests}');
      appLogger.iWithPackage(
          _pkg, '真实API测试: ${TestEnvironment.runLiveApiTests}');
      appLogger.iWithPackage(_pkg,
          'API密钥: ${TestEnvironment.skipNoApiKey() == null ? "已配置" : "未配置"}');
      appLogger.iWithPackage(_pkg, '========================================');

      expect(canRun, equals(TestEnvironment.canRunIntegrationTests));
    });

    group('真实返回体结构校验', () {
      test('getDashboardMemo 应匹配真实字符串返回体', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        final raw = await _rawGet(client, '/core/settings/memo');
        _logSection('Raw /core/settings/memo',
            method: 'GET', path: '/core/settings/memo', response: raw.data);

        expect(raw.statusCode, equals(200));
        final response = await api.getDashboardMemo();
        expect(response.statusCode, equals(200));
        if (_isSecureLoginHtml(raw.data)) {
          expect(response.data, isNull);
        } else {
          expect(raw.data, isA<Map<String, dynamic>>());
          expect(raw.data, containsPair('code', 200));
          expect(raw.data, contains('data'));

          final rawMemo = (raw.data as Map<String, dynamic>)['data'];
          expect(rawMemo, anyOf(isNull, isA<String>()));
          expect(response.data, equals(rawMemo?.toString()));
        }
      });

      test('listPasskeys 应匹配真实数组返回体', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        final raw = await _rawGet(client, '/core/settings/passkey/list');
        _logSection('Raw /core/settings/passkey/list',
            method: 'GET',
            path: '/core/settings/passkey/list',
            response: raw.data);

        expect(raw.statusCode, equals(200));
        final response = await api.listPasskeys();
        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        if (_isSecureLoginHtml(raw.data)) {
          expect(response.data, isEmpty);
        } else {
          expect(raw.data, isA<Map<String, dynamic>>());
          expect(raw.data, containsPair('code', 200));
          expect(raw.data, contains('data'));

          final rawItems = (raw.data as Map<String, dynamic>)['data'];
          expect(rawItems, isA<List<dynamic>>());
          expect(response.data, hasLength((rawItems as List<dynamic>).length));

          for (var i = 0; i < rawItems.length; i++) {
            final item = Map<String, dynamic>.from(rawItems[i] as Map);
            final parsed = response.data![i];

            expect(item, containsPair('id', item['id']));
            expect(item, containsPair('name', item['name']));
            expect(parsed.id, equals(item['id']));
            expect(parsed.name, equals(item['name']));
            expect(parsed.createdAt, equals(item['createdAt']));
            expect(parsed.lastUsedAt, equals(item['lastUsedAt']));
          }
        }
      });

      test('getAppStoreConfig 应匹配真实对象返回体', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        final raw = await _rawGet(client, '/core/settings/apps/store/config');
        _logSection('Raw /core/settings/apps/store/config',
            method: 'GET',
            path: '/core/settings/apps/store/config',
            response: raw.data);

        expect(raw.statusCode, equals(200));
        final response = await api.getAppStoreConfig();
        expect(response.statusCode, equals(200));
        if (_isSecureLoginHtml(raw.data)) {
          expect(response.data, isNull);
        } else {
          expect(raw.data, isA<Map<String, dynamic>>());
          expect(raw.data, containsPair('code', 200));
          expect(raw.data, contains('data'));

          final rawConfig = Map<String, dynamic>.from(
              (raw.data as Map<String, dynamic>)['data'] as Map);
          expect(
              rawConfig.keys,
              containsAll(<String>[
                'upgradeBackup',
                'uninstallDeleteBackup',
                'uninstallDeleteImage',
              ]));
          for (final key in <String>[
            'upgradeBackup',
            'uninstallDeleteBackup',
            'uninstallDeleteImage',
          ]) {
            expect(rawConfig[key], isA<String>());
            expect((rawConfig[key] as String).isNotEmpty, isTrue);
          }

          expect(response.data, isA<Map>());
          final parsed = Map<String, dynamic>.from(response.data as Map);
          expect(parsed, equals(rawConfig));
        }
      });

      test('getBaseDir 应匹配真实路径字符串返回体', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        final raw = await _rawGet(client, '/settings/basedir');
        _logSection('Raw /settings/basedir',
            method: 'GET', path: '/settings/basedir', response: raw.data);

        expect(raw.statusCode, equals(200));
        final response = await api.getBaseDir();
        expect(response.statusCode, equals(200));
        if (_isSecureLoginHtml(raw.data)) {
          expect(response.data, isNull);
        } else {
          expect(raw.data, isA<Map<String, dynamic>>());
          expect(raw.data, containsPair('code', 200));
          expect(raw.data, contains('data'));

          final rawBaseDir = (raw.data as Map<String, dynamic>)['data'];
          expect(rawBaseDir, isA<String>());
          expect((rawBaseDir as String).isNotEmpty, isTrue);
          expect(RegExp(r'^(/|[A-Za-z]:[\\/])').hasMatch(rawBaseDir), isTrue);
          expect(response.data, equals(rawBaseDir));
        }
      });

      test('getMonitorSetting 应匹配真实对象返回体', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        final raw = await _rawGet(client, '/hosts/monitor/setting');
        _logSection('Raw /hosts/monitor/setting',
            method: 'GET', path: '/hosts/monitor/setting', response: raw.data);

        expect(raw.statusCode, equals(200));
        final response = await api.getMonitorSetting();
        expect(response.statusCode, equals(200));
        if (_isSecureLoginHtml(raw.data)) {
          expect(response.data, isNull);
        } else {
          expect(raw.data, isA<Map<String, dynamic>>());
          expect(raw.data, containsPair('code', 200));
          expect(raw.data, contains('data'));

          final rawSetting = Map<String, dynamic>.from(
              (raw.data as Map<String, dynamic>)['data'] as Map);
          expect(
              rawSetting.keys,
              containsAll(<String>[
                'monitorStatus',
                'monitorStoreDays',
                'monitorInterval',
                'defaultNetwork',
                'defaultIO',
              ]));
          expect(rawSetting['monitorStatus'], isA<String>());
          expect((rawSetting['monitorStatus'] as String).isNotEmpty, isTrue);
          expect(int.tryParse(rawSetting['monitorStoreDays']?.toString() ?? ''),
              greaterThan(0));
          expect(int.tryParse(rawSetting['monitorInterval']?.toString() ?? ''),
              greaterThan(0));
          expect(rawSetting['defaultNetwork'], isA<String>());
          expect(rawSetting['defaultIO'], isA<String>());

          expect(response.data, isNotNull);
          expect(response.data, equals(rawSetting));
        }
      });
    });

    group('getSystemSettings - 获取系统设置', () {
      test('应该成功获取系统设置', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        final response = await api.getSystemSettings();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<SystemSettingInfo>());
      });
    });

    group('getTerminalSettings - 获取终端设置', () {
      test('应该成功获取终端设置', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        final response = await api.getTerminalSettings();

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<TerminalInfo>());
      });
    });

    group('getNetworkInterfaces - 获取网络接口列表', () {
      test('应该成功获取网络接口列表', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        final response = await api.getNetworkInterfaces();

        expect(response.statusCode, equals(200));
      });
    });

    group('MFA相关API', () {
      test('loadMfaInfo - 应该成功加载MFA信息', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        const request = MfaLoadRequest(
          title: '1Panel Client',
          interval: 30,
        );

        final response = await api.loadMfaInfo(request);

        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);
        expect(response.data, isA<MfaOtp>());
      });
    });

    group('generateApiKey - 生成API密钥', () {
      test('应该成功生成API密钥', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        try {
          final response = await api.generateApiKey();
          expect(response.statusCode, equals(200));
        } catch (error) {
          expect(error.toString(), contains('此接口禁止使用 API 接口调用'));
        }
      });
    });

    group('getSystemSettingByKey - 按键获取设置', () {
      test('应当能获取指定设置项', () async {
        if (!canRun) {
          appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
          return;
        }

        try {
          final response = await api.getSystemSettingByKey('PanelName');
          expect(response.statusCode, equals(200));
        } catch (error) {
          expect(
            error.toString(),
            contains("Field validation for 'Key' failed on the 'oneof' tag"),
          );
        }
      });
    });

    group('updateMonitorSetting - 监控设置更新', () {
      test('同值回放幂等验证仅在 destructive 模式下执行', () async {
        final skipReason = TestEnvironment.skipIntegration() ??
            TestEnvironment.skipDestructive();
        if (skipReason != null) {
          appLogger.wWithPackage(_pkg, '跳过测试: $skipReason');
          return;
        }

        final beforeResponse = await api.getMonitorSetting();
        expect(beforeResponse.statusCode, equals(200));
        expect(beforeResponse.data, isNotNull);

        const candidates = <Map<String, String>>[
          <String, String>{
            'readKey': 'defaultNetwork',
            'writeKey': 'DefaultNetwork',
          },
          <String, String>{
            'readKey': 'defaultIO',
            'writeKey': 'DefaultIO',
          },
        ];

        String? readKey;
        String? writeKey;
        String? currentValue;
        for (final candidate in candidates) {
          final value = beforeResponse.data![candidate['readKey']!]?.toString();
          if (value != null && value.isNotEmpty) {
            readKey = candidate['readKey'];
            writeKey = candidate['writeKey'];
            currentValue = value;
            break;
          }
        }

        if (readKey == null || writeKey == null || currentValue == null) {
          appLogger.wWithPackage(_pkg, '当前环境没有可安全回放的 monitor setting 值');
          return;
        }

        _logSection('Replay monitor setting with same value',
            method: 'POST',
            path: '/hosts/monitor/setting/update',
            request: <String, String>{'key': writeKey, 'value': currentValue});

        final updateResponse =
            await api.updateMonitorSetting(writeKey, currentValue);
        expect(updateResponse.statusCode, anyOf(equals(200), equals(204)));

        final afterResponse = await api.getMonitorSetting();
        expect(afterResponse.statusCode, equals(200));
        expect(afterResponse.data, isNotNull);
        expect(afterResponse.data![readKey], equals(currentValue));
      });
    });
  });

  group('Setting API性能测试', () {
    test('getSystemSettings响应时间应该小于3秒', () async {
      if (!canRun) {
        appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
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
      if (!canRun) {
        appLogger.wWithPackage(_pkg, '跳过测试: ${_integrationSkipReason()}');
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
