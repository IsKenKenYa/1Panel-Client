import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/panels/one_panel_adapter.dart';
import 'package:onepanel_client/features/server/server_connection_service.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/core/config/api_config.dart';

void main() {
  group('ServerConnectionService', () {
    test('resolveConnectionFailure 透出白名单拒绝的服务端原因并附修复提示', () {
      // 回归：1Panel IP 白名单拒绝返回 HTTP 200 + {code:401, message:...}，
      // 客户端曾笼统报 "Invalid response from server"，掩盖真实原因。
      final result = resolveConnectionFailure(const {
        'code': 401,
        'message': '调用 API 接口 IP 不在白名单',
        'data': null,
      }, const Duration(milliseconds: 120));

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('调用 API 接口 IP 不在白名单'));
      expect(result.errorMessage, contains('添加当前出口 IP'));
      expect(result.responseTime, isNotNull);
    });

    test('resolveConnectionFailure 透出其他服务端 message', () {
      final result = resolveConnectionFailure(const {
        'code': 403,
        'message': '时间戳校验失败',
      }, const Duration(milliseconds: 30));

      expect(result.success, isFalse);
      expect(result.errorMessage, '时间戳校验失败');
    });

    test('resolveConnectionFailure 无 message 时回退笼统错误', () {
      final result = resolveConnectionFailure(
        const {'code': 500, 'message': null},
        const Duration(milliseconds: 10),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Invalid response from server');
    });

    test('resolveConnectionFailure 处理空 data', () {
      final result = resolveConnectionFailure(
        null,
        const Duration(milliseconds: 10),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, 'Invalid response from server');
    });

    test('ServerConnectionResult should be created correctly', () {
      const result = ServerConnectionResult(
        success: true,
        operatingSystem: 'Linux',
        responseTime: Duration(milliseconds: 100),
      );

      expect(result.success, isTrue);
      expect(result.operatingSystem, equals('Linux'));
      expect(result.responseTime, equals(const Duration(milliseconds: 100)));
    });

    test('ServerConnectionResult with error should have errorMessage', () {
      const result = ServerConnectionResult(
        success: false,
        errorMessage: 'Connection timeout',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Connection timeout'));
      expect(result.operatingSystem, isNull);
    });
  });

  group('ServerModels', () {
    test('ServerMetricsSnapshot should have correct defaults', () {
      const metrics = ServerMetricsSnapshot();

      expect(metrics.cpuPercent, isNull);
      expect(metrics.memoryPercent, isNull);
      expect(metrics.diskPercent, isNull);
      expect(metrics.load, isNull);
    });

    test('ServerMetricsSnapshot should store values correctly', () {
      const metrics = ServerMetricsSnapshot(
        cpuPercent: 45.5,
        memoryPercent: 60.2,
        diskPercent: 30.0,
        load: 1.5,
      );

      expect(metrics.cpuPercent, equals(45.5));
      expect(metrics.memoryPercent, equals(60.2));
      expect(metrics.diskPercent, equals(30.0));
      expect(metrics.load, equals(1.5));
    });

    test('ServerCardViewModel should be created correctly', () {
      final config = ApiConfig(
        id: 'test-id',
        name: 'Test Server',
        url: 'http://localhost:9999',
        apiKey: 'test-api-key',
      );

      final viewModel = ServerCardViewModel(
        config: config,
        isCurrent: true,
        metrics: const ServerMetricsSnapshot(cpuPercent: 50.0),
      );

      expect(viewModel.config.id, equals('test-id'));
      expect(viewModel.config.name, equals('Test Server'));
      expect(viewModel.isCurrent, isTrue);
      expect(viewModel.metrics.cpuPercent, equals(50.0));
    });
  });

  group('ApiConfig', () {
    test('ApiConfig should serialize to JSON correctly', () {
      final config = ApiConfig(
        id: 'test-id',
        name: 'Test Server',
        url: 'http://localhost:9999',
        apiKey: 'test-api-key',
        isDefault: true,
      );

      final json = config.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['name'], equals('Test Server'));
      expect(json['url'], equals('http://localhost:9999'));
      expect(json['panelType'], ApiConfig.onePanelType);
      expect(json.containsKey('apiKey'), isFalse);
      expect(json['isDefault'], isTrue);
    });

    test('ApiConfig should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Server',
        'url': 'http://localhost:9999',
        'panelType': ApiConfig.onePanelType,
        'revision': '96777808-5c89-47d2-90da-f96f55a05b1f',
        'credentialId': 'ce3f7514-5911-49bd-8744-f30ad8ec76fa',
        'tokenValidity': 0,
        'allowInsecureTls': false,
        'isDefault': true,
        'lastUsed': '2026-01-01T00:00:00.000',
      };

      final config = ApiConfig.fromJson(json, apiKey: 'test-api-key');

      expect(config.id, equals('test-id'));
      expect(config.name, equals('Test Server'));
      expect(config.url, equals('http://localhost:9999'));
      expect(config.apiKey, equals('test-api-key'));
      expect(config.isDefault, isTrue);
    });
  });
}
