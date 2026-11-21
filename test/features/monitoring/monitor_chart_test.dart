import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/monitor_models.dart';
import 'package:onepanel_client/features/monitoring/widgets/monitor_chart.dart';

void main() {
  testWidgets('窄屏图表可选择单个采样', (tester) async {
    final point = MonitorDataPoint(time: DateTime.utc(2026, 11, 21), value: 42);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
      child: SizedBox(
        width: 120,
        height: 180,
        child: MonitorChart(
            label: 'CPU', data: [point], unit: '%', minY: 42, maxY: 42),
      ),
    ))));
    await tester.tap(find.byType(MonitorChart));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('42.0%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
