import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/dashboard/dashboard_provider.dart';
import 'package:onepanel_client/features/dashboard/models/dashboard_view_models.dart';
import 'package:onepanel_client/features/dashboard/widgets/health_overview_grid.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  Widget createTestWidget({required DashboardData data}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: HealthOverviewGrid(data: data),
        ),
      ),
    );
  }

  testWidgets('renders four health cards with values', (tester) async {
    await tester.pumpWidget(createTestWidget(
      data: const DashboardData(
        cpuPercent: 12.5,
        memoryPercent: 48.2,
        diskPercent: 82.1,
        load: 0.77,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('12.5%'), findsOneWidget);
    expect(find.text('48.2%'), findsOneWidget);
    expect(find.text('82.1%'), findsOneWidget);
    expect(find.text('0.77'), findsOneWidget);
  });

  testWidgets('renders dash placeholders when metrics are null',
      (tester) async {
    await tester.pumpWidget(createTestWidget(data: const DashboardData()));
    await tester.pumpAndSettle();

    expect(find.text('--'), findsNWidgets(4));
  });

  testWidgets('status dot uses error color at >= 90 percent', (tester) async {
    await tester.pumpWidget(createTestWidget(
      data: const DashboardData(diskPercent: 92.0),
    ));
    await tester.pumpAndSettle();

    final errorDots = tester.widgetList<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 8.0 &&
            (widget.decoration is BoxDecoration) &&
            (widget.decoration as BoxDecoration).color ==
                Theme.of(tester.element(find.byType(HealthOverviewGrid)))
                    .colorScheme
                    .error,
      ),
    );
    expect(errorDots, isNotEmpty);
  });

  testWidgets('status dot uses amber at 70-89 percent', (tester) async {
    const amber = Color(0xFFF59E0B);
    await tester.pumpWidget(createTestWidget(
      data: const DashboardData(diskPercent: 82.1),
    ));
    await tester.pumpAndSettle();

    final amberDots = tester.widgetList<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 8.0 &&
            (widget.decoration is BoxDecoration) &&
            (widget.decoration as BoxDecoration).color == amber,
      ),
    );
    expect(amberDots, isNotEmpty);
  });

  testWidgets('status dot uses neutral color when percent is null',
      (tester) async {
    await tester.pumpWidget(createTestWidget(
      data: const DashboardData(load: 0.5),
    ));
    await tester.pumpAndSettle();

    // load 卡有数据（primary 点），CPU/内存/磁盘 无数据：三颗中性点。
    final scheme = Theme.of(tester.element(find.byType(HealthOverviewGrid)))
        .colorScheme;
    final neutralDots = tester.widgetList<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 8.0 &&
            (widget.decoration is BoxDecoration) &&
            (widget.decoration as BoxDecoration).color ==
                scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
    // load 卡 percent 为 null 同样走中性色，所以是 4 颗中性点。
    expect(neutralDots.length, 4);
  });
}
