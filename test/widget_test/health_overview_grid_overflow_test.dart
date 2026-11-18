import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/dashboard/models/dashboard_view_models.dart';
import 'package:onepanel_client/features/dashboard/widgets/health_overview_grid.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  const health = HealthOverviewGrid(
    data: DashboardData(
      cpuPercent: 91.2,
      memoryPercent: 71.4,
      diskPercent: 19.6,
      load: 3.15,
    ),
  );

  testWidgets('metric grid fits a narrow pane at 200 percent text',
      (tester) async {
    await pumpOverflowHarness(
      tester,
      variant: kCoreOverflowVariants[1],
      child: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: health,
      ),
    );

    await expectNoFlutterExceptions(tester);
    final cpu = tester.getTopLeft(find.text('91.2%'));
    final memory = tester.getTopLeft(find.text('71.4%'));
    expect(cpu.dx, memory.dx);
    expect(cpu.dy, lessThan(memory.dy));
    expect(find.text('3.15'), findsOneWidget);
  });

  testWidgets('metric grid keeps two columns when labels have room',
      (tester) async {
    await pumpOverflowHarness(
      tester,
      variant: kCoreOverflowVariants.first,
      child: const Padding(padding: EdgeInsets.all(16), child: health),
    );

    await expectNoFlutterExceptions(tester);
    expect(tester.getTopLeft(find.text('91.2%')).dx,
        lessThan(tester.getTopLeft(find.text('71.4%')).dx));
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });
}
