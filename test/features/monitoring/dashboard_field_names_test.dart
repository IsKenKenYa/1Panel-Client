import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/repositories/monitor_repository.dart';

void main() {
  group('Dashboard API Field Names', () {
    test('should parse Dashboard API response correctly', () {
      // 模拟Dashboard API的真实响应
      final mockResponse = {
        'code': 200,
        'message': '',
        'data': {
          'uptime': 2112292,
          'load1': 0.5,
          'load5': 0.3,
          'load15': 0.2,
          'cpuUsedPercent': 1.0239760239760254,
          'memoryTotal': 3904180224,
          'memoryUsed': 1115643904,
          'memoryUsedPercent': 28.57562509901182,
          'diskData': [
            {
              'path': '/',
              'type': 'ext4',
              'device': '/dev/vda2',
              'total': 42156257280,
              'free': 19487469568,
              'used': 20826927104,
              'usedPercent': 51.6612645190971,
            }
          ],
        }
      };

      final payload = mockResponse['data'] as Map<String, dynamic>;

      // 解析磁盘数据
      double? diskPercent;
      final diskDataList = payload['diskData'] as List?;
      if (diskDataList != null && diskDataList.isNotEmpty) {
        final firstDisk = diskDataList.first as Map<String, dynamic>?;
        diskPercent = (firstDisk?['usedPercent'] as num?)?.toDouble();
      }

      final snapshot = MonitorMetricsSnapshot(
        cpuPercent: (payload['cpuUsedPercent'] as num?)?.toDouble(),
        memoryPercent: (payload['memoryUsedPercent'] as num?)?.toDouble(),
        diskPercent: diskPercent,
        load1: (payload['load1'] as num?)?.toDouble(),
        load5: (payload['load5'] as num?)?.toDouble(),
        load15: (payload['load15'] as num?)?.toDouble(),
        memoryUsed: payload['memoryUsed'] as int?,
        memoryTotal: payload['memoryTotal'] as int?,
        uptime: payload['uptime'] as int?,
        timestamp: DateTime.now(),
      );

      // 验证所有字段都正确解析
      expect(snapshot.cpuPercent, 1.0239760239760254);
      expect(snapshot.memoryPercent, 28.57562509901182);
      expect(snapshot.diskPercent, 51.6612645190971);
      expect(snapshot.load1, 0.5);
      expect(snapshot.load5, 0.3);
      expect(snapshot.load15, 0.2);
      expect(snapshot.memoryUsed, 1115643904);
      expect(snapshot.memoryTotal, 3904180224);
      expect(snapshot.uptime, 2112292);
    });

    test('should handle missing diskData gracefully', () {
      final mockResponse = {
        'code': 200,
        'message': '',
        'data': {
          'cpuUsedPercent': 1.0,
          'memoryUsedPercent': 28.5,
          'load1': 0.5,
          // diskData 缺失
        }
      };

      final payload = mockResponse['data'] as Map<String, dynamic>;

      // 解析磁盘数据
      double? diskPercent;
      final diskDataList = payload['diskData'] as List?;
      if (diskDataList != null && diskDataList.isNotEmpty) {
        final firstDisk = diskDataList.first as Map<String, dynamic>?;
        diskPercent = (firstDisk?['usedPercent'] as num?)?.toDouble();
      }

      final snapshot = MonitorMetricsSnapshot(
        cpuPercent: (payload['cpuUsedPercent'] as num?)?.toDouble(),
        memoryPercent: (payload['memoryUsedPercent'] as num?)?.toDouble(),
        diskPercent: diskPercent,
        load1: (payload['load1'] as num?)?.toDouble(),
      );

      // 验证CPU和内存正常，磁盘为null
      expect(snapshot.cpuPercent, 1.0);
      expect(snapshot.memoryPercent, 28.5);
      expect(snapshot.diskPercent, isNull);
      expect(snapshot.load1, 0.5);
    });

    test('should handle empty diskData array', () {
      final mockResponse = {
        'code': 200,
        'message': '',
        'data': {
          'cpuUsedPercent': 1.0,
          'memoryUsedPercent': 28.5,
          'load1': 0.5,
          'diskData': [], // 空数组
        }
      };

      final payload = mockResponse['data'] as Map<String, dynamic>;

      // 解析磁盘数据
      double? diskPercent;
      final diskDataList = payload['diskData'] as List?;
      if (diskDataList != null && diskDataList.isNotEmpty) {
        final firstDisk = diskDataList.first as Map<String, dynamic>?;
        diskPercent = (firstDisk?['usedPercent'] as num?)?.toDouble();
      }

      final snapshot = MonitorMetricsSnapshot(
        cpuPercent: (payload['cpuUsedPercent'] as num?)?.toDouble(),
        memoryPercent: (payload['memoryUsedPercent'] as num?)?.toDouble(),
        diskPercent: diskPercent,
        load1: (payload['load1'] as num?)?.toDouble(),
      );

      // 验证磁盘为null
      expect(snapshot.diskPercent, isNull);
    });
  });
}
