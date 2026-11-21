import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/monitor_models.dart';

void main() {
  test('图表采样保留首尾时间并使用完整时间段计算统计值', () {
    final start = DateTime.utc(2026, 11, 21);
    final points = [0.0, 50.0, 1.0, 1.0, 3.0].indexed.map((entry) {
      return MonitorDataPoint(
        time: start.add(Duration(minutes: entry.$1)),
        value: entry.$2,
      );
    }).toList();
    final series = MonitorTimeSeries.fromPoints('cpu', points, limit: 3);
    expect(series.data, [points.first, points[2], points.last]);
    expect((series.min, series.max, series.avg), (0.0, 50.0, 11.0));
    points.clear();
    expect(series.data.length, 3);
  });

  test('扩大时间范围后补齐缓存之前和中间的采样', () {
    final start = DateTime.utc(2026, 1, 1);
    final samples = List.generate(
        5,
        (index) => MonitorDataPoint(
              time: start.add(Duration(minutes: index)),
              value: index.toDouble(),
            ));
    final points = [samples[1], samples[3]];
    expect(mergeMonitorPoints(points, samples.reversed.toList()), isTrue);
    expect(points, samples);
    expect(mergeMonitorPoints(points, samples), isFalse);
  });

  test('追加增量采样时按本地存储的毫秒精度去重', () {
    final first = DateTime.utc(2026, 1, 1);
    final saved = MonitorDataPoint(time: first, value: 1);
    final duplicate = MonitorDataPoint(
      time: first.add(const Duration(microseconds: 500)),
      value: 1,
    );
    final next = MonitorDataPoint(
      time: first.add(const Duration(seconds: 1)),
      value: 2,
    );
    final points = [saved];
    expect(mergeMonitorPoints(points, [duplicate, next]), isTrue);
    expect(points, [saved, next]);
  });
}
