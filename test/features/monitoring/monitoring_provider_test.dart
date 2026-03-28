import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/repositories/monitor_repository.dart';
import 'package:onepanel_client/features/monitoring/monitoring_provider.dart';
import 'package:onepanel_client/features/monitoring/monitoring_service.dart';
import 'package:onepanel_client/features/monitoring/data/datasources/monitor_local_datasource.dart';

class MockMonitorLocalDataSource extends MonitorLocalDataSource {
  @override
  Future<void> init() async {
    // Do nothing
  }

  @override
  Future<void> savePoints(String metric, List<MonitorDataPoint> points) async {
    // Do nothing
  }

  @override
  Future<List<MonitorDataPoint>> getPoints(
      String metric, DateTime start, DateTime end) async {
    return [];
  }
}

class FakeMonitoringService extends MonitoringService {
  @override
  Future<MonitorDataPackage> getMonitorData({
    Duration duration = const Duration(hours: 1),
    DateTime? startTime,
  }) async {
    final now = DateTime.now();
    return MonitorDataPackage(
      current: const MonitorMetricsSnapshot(
        cpuPercent: 0.6,
        memoryPercent: 0.5,
      ),
      timeSeries: {
        'cpu': MonitorTimeSeries(
          name: 'cpu',
          data: [
            MonitorDataPoint(
                time: now.subtract(const Duration(minutes: 2)), value: 0.2),
            MonitorDataPoint(
                time: now.subtract(const Duration(minutes: 1)), value: 0.6),
            MonitorDataPoint(time: now, value: 0.9),
          ],
        ),
        'network': MonitorTimeSeries(
          name: 'network',
          data: [
            MonitorDataPoint(time: now, value: 1024),
          ],
        ),
        'memory': MonitorTimeSeries.empty('memory'),
        'load': MonitorTimeSeries.empty('load'),
        'io': MonitorTimeSeries.empty('io'),
      },
    );
  }
}

class ErrorMonitoringService extends MonitoringService {
  @override
  Future<MonitorDataPackage> getMonitorData({
    Duration duration = const Duration(hours: 1),
    DateTime? startTime,
  }) async {
    throw Exception('加载失败');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('dev.fluttercommunity.plus/connectivity');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'check') {
          return ['wifi'];
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      null,
    );
  });

  test('MonitoringProvider成功加载数据', () async {
    final provider = MonitoringProvider(
      service: FakeMonitoringService(),
      dataSource: MockMonitorLocalDataSource(),
    );
    var notified = 0;
    provider.addListener(() => notified++);

    await provider.load();

    expect(notified, greaterThan(0));
    expect(provider.data.error, isNull);
    expect(provider.data.currentMetrics?.cpuPercent, 0.6);
    expect(provider.data.networkTimeSeries?.data.length, 1);
  });

  test('MonitoringProvider处理错误状态', () async {
    final provider = MonitoringProvider(
      service: ErrorMonitoringService(),
      dataSource: MockMonitorLocalDataSource(),
    );
    await provider.load();
    expect(provider.data.error, isNotNull);
  });
}
