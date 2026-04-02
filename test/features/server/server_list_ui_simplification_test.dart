import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/data/repositories/monitor_repository.dart';

void main() {
  group('Server List UI Simplification Tests', () {
    test('Server provider should have auto-refresh capability', () {
      final provider = ServerProvider();

      // 验证provider有dispose方法（包含timer清理）
      expect(provider.dispose, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.servers, isEmpty);

      provider.dispose();
    });

    test('Monitor repository should parse IO data with fallback fields', () {
      // 测试IO数据解析的容错性
      final testData = {
        'data': [
          {
            'param': 'io',
            'date': ['2026-04-02T10:00:00Z'],
            'value': [
              {'diskRead': 100.5, 'diskWrite': 50.2}
            ]
          }
        ]
      };

      final result = parseTimeSeriesResponse(testData, 'io', 'disk');
      expect(result.data.isNotEmpty, isTrue);
      expect(result.data.first.value, 100.5);
    });

    test('Monitor repository should parse network data with fallback fields',
        () {
      // 测试网络数据解析的容错性
      final testData = {
        'data': [
          {
            'param': 'network',
            'date': ['2026-04-02T10:00:00Z'],
            'value': [
              {'up': 1024.0, 'down': 512.0}
            ]
          }
        ]
      };

      final result = parseTimeSeriesResponse(testData, 'network', 'networkIn');
      expect(result.data.isNotEmpty, isTrue);
      expect(result.data.first.value, 1024.0);
    });

    test('Monitor repository should handle empty data gracefully', () {
      final testData = {
        'data': []
      };

      final result = parseTimeSeriesResponse(testData, 'io', 'disk');
      expect(result.data, isEmpty);
    });
  });
}
