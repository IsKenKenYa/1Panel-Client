import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/server/server_connection_service.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/core/config/api_config.dart';

void main() {
  group('ServerConnectionService', () {
    test('ServerConnectionResult should be created correctly', () {
      const result = ServerConnectionResult(
        success: true,
        osInfo: {'os': 'Linux'},
        responseTime: Duration(milliseconds: 100),
      );

      expect(result.success, isTrue);
      expect(result.osInfo, isNotNull);
      expect(result.osInfo!['os'], equals('Linux'));
      expect(result.responseTime, equals(const Duration(milliseconds: 100)));
    });

    test('ServerConnectionResult with error should have errorMessage', () {
      const result = ServerConnectionResult(
        success: false,
        errorMessage: 'Connection timeout',
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Connection timeout'));
      expect(result.osInfo, isNull);
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
      expect(json['apiKey'], equals('test-api-key'));
      expect(json['isDefault'], isTrue);
    });

    test('ApiConfig should deserialize from JSON correctly', () {
      final json = {
        'id': 'test-id',
        'name': 'Test Server',
        'url': 'http://localhost:9999',
        'apiKey': 'test-api-key',
        'isDefault': true,
        'lastUsed': '2026-01-01T00:00:00.000',
      };

      final config = ApiConfig.fromJson(json);

      expect(config.id, equals('test-id'));
      expect(config.name, equals('Test Server'));
      expect(config.url, equals('http://localhost:9999'));
      expect(config.apiKey, equals('test-api-key'));
      expect(config.isDefault, isTrue);
    });
  });
}
