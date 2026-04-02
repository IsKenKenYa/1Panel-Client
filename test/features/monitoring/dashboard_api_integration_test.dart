import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/repositories/monitor_repository.dart';

void main() {
  group('Dashboard API Integration Tests', () {
    test('MonitorMetricsSnapshot should handle dashboard API response', () {
      // 模拟Dashboard API响应
      final dashboardResponse = {
        'cpuPercent': 45.5,
        'memoryPercent': 62.3,
        'diskPercent': 78.9,
        'load1': 1.23,
        'load5': 1.45,
        'load15': 1.67,
        'memoryUsed': 8589934592, // 8GB
        'memoryTotal': 17179869184, // 16GB
        'uptime': 86400, // 1 day
      };

      final snapshot = MonitorMetricsSnapshot(
        cpuPercent: (dashboardResponse['cpuPercent'] as num?)?.toDouble(),
        memoryPercent: (dashboardResponse['memoryPercent'] as num?)?.toDouble(),
        diskPercent: (dashboardResponse['diskPercent'] as num?)?.toDouble(),
        load1: (dashboardResponse['load1'] as num?)?.toDouble(),
        load5: (dashboardResponse['load5'] as num?)?.toDouble(),
        load15: (dashboardResponse['load15'] as num?)?.toDouble(),
        memoryUsed: dashboardResponse['memoryUsed'] as int?,
        memoryTotal: dashboardResponse['memoryTotal'] as int?,
        uptime: dashboardResponse['uptime'] as int?,
        timestamp: DateTime.now(),
      );

      expect(snapshot.cpuPercent, 45.5);
      expect(snapshot.memoryPercent, 62.3);
      expect(snapshot.diskPercent, 78.9);
      expect(snapshot.load1, 1.23);
      expect(snapshot.hasData, isTrue);
    });

    test('MonitorMetricsSnapshot should handle null values gracefully', () {
      final snapshot = const MonitorMetricsSnapshot(
        cpuPercent: null,
        memoryPercent: null,
        diskPercent: null,
        load1: null,
      );

      expect(snapshot.hasData, isFalse);
      expect(snapshot.cpuPercent, isNull);
      expect(snapshot.memoryPercent, isNull);
    });

    test('parseTimeSeriesResponse should handle IO data with various field names',
        () {
      // 测试diskRead字段
      final testData1 = {
        'data': [
          {
            'param': 'io',
            'value': [
              {'diskRead': 100.5}
            ]
          }
        ]
      };
      final result1 = parseTimeSeriesResponse(testData1, 'io', 'disk');
      expect(result1.data.isNotEmpty, isTrue);
      expect(result1.data.first.value, 100.5);

      // 测试ioRead字段
      final testData2 = {
        'data': [
          {
            'param': 'io',
            'value': [
              {'ioRead': 200.5}
            ]
          }
        ]
      };
      final result2 = parseTimeSeriesResponse(testData2, 'io', 'disk');
      expect(result2.data.isNotEmpty, isTrue);
      expect(result2.data.first.value, 200.5);
    });

    test(
        'parseTimeSeriesResponse should handle network data with various field names',
        () {
      // 测试up字段
      final testData1 = {
        'data': [
          {
            'param': 'network',
            'value': [
              {'up': 1024.0}
            ]
          }
        ]
      };
      final result1 = parseTimeSeriesResponse(testData1, 'network', 'networkIn');
      expect(result1.data.isNotEmpty, isTrue);
      expect(result1.data.first.value, 1024.0);

      // 测试down字段
      final testData2 = {
        'data': [
          {
            'param': 'network',
            'value': [
              {'down': 512.0}
            ]
          }
        ]
      };
      final result2 = parseTimeSeriesResponse(testData2, 'network', 'networkIn');
      expect(result2.data.isNotEmpty, isTrue);
      expect(result2.data.first.value, 512.0);
    });
  });
}
