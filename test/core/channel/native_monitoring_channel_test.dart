import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:onepanel_client/core/channel/native_monitoring_payloads.dart';
import 'package:onepanel_client/data/models/monitor_models.dart';
import 'package:onepanel_client/data/models/monitoring_runtime_models.dart';

void main() {
  group('monitoringSeriesPayload', () {
    test('输出时间戳与数值点并保留聚合值', () {
      final series = MonitorTimeSeries.fromPoints(
        'cpu',
        [
          MonitorDataPoint(time: DateTime.fromMillisecondsSinceEpoch(1000), value: 10),
          MonitorDataPoint(time: DateTime.fromMillisecondsSinceEpoch(2000), value: 30),
        ],
      );

      final payload = monitoringSeriesPayload(series);
      final points = payload['points'] as List<Object?>;

      expect(payload['name'], 'cpu');
      expect(payload['count'], 2);
      expect(payload['min'], 10);
      expect(payload['max'], 30);
      expect(payload['avg'], 20);
      expect((points.first as Map<String, Object?>)['time'], 1000);
      expect((points.last as Map<String, Object?>)['value'], 30);
    });

    test('空序列返回空点集', () {
      final payload = monitoringSeriesPayload(null);

      expect(payload['points'], isEmpty);
      expect(payload['count'], 0);
    });
  });

  group('monitoringHistoryPayload', () {
    test('五个序列键齐备', () {
      final package = MonitorDataPackage(
        current: const MonitorMetricsSnapshot(),
        timeSeries: <String, MonitorTimeSeries>{
          'cpu': MonitorTimeSeries.empty('cpu'),
          'memory': MonitorTimeSeries.empty('memory'),
          'load': MonitorTimeSeries.empty('load'),
          'io': MonitorTimeSeries.empty('io'),
          'network': MonitorTimeSeries.empty('network'),
        },
      );

      final payload = monitoringHistoryPayload(package);

      expect(payload.keys, containsAll(<String>['cpu', 'memory', 'load', 'io', 'network']));
    });
  });

  group('monitoringSettingsPayload', () {
    test('设置字段与启用开关', () {
      final payload = monitoringSettingsPayload(const MonitorSetting(
        interval: 30,
        retention: 7,
        enabled: true,
        defaultNetwork: 'eth0',
        defaultIO: 'sda',
      ));

      expect(payload['enabled'], isTrue);
      expect(payload['interval'], 30);
      expect(payload['retention'], 7);
      expect(payload['defaultNetwork'], 'eth0');
      expect(payload['defaultIO'], 'sda');
    });
  });

  group('monitoringOptionsPayload', () {
    test('网卡与磁盘设备列表透传', () {
      final payload = monitoringOptionsPayload(
        networks: const <String>['eth0', 'eth1'],
        ios: const <String>['sda', 'sdb'],
      );

      expect(payload['networks'], <String>['eth0', 'eth1']);
      expect(payload['ios'], <String>['sda', 'sdb']);
    });
  });

  group('监控通道入口', () {
    test('设置缺少正数间隔时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.updateMonitoringSettings(
        <String, dynamic>{'interval': 0, 'retention': 7},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('interval'));
    });

    test('设置 dispatch 路由到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'updateMonitoringSettings',
        <String, dynamic>{'interval': -1, 'retention': 0},
      );

      expect(result['success'], isFalse);
    });
  });
}