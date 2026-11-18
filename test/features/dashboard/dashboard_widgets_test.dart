import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/dashboard_models.dart';
import 'package:onepanel_client/features/dashboard/dashboard_provider.dart';
import 'package:onepanel_client/features/dashboard/widgets/activity_card.dart';
import 'package:onepanel_client/features/dashboard/widgets/dashboard_loading_view.dart';
import 'package:onepanel_client/features/dashboard/widgets/resource_card.dart';
import 'package:onepanel_client/features/dashboard/widgets/server_info_card.dart';
import 'package:onepanel_client/features/dashboard/widgets/top_processes_card.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

Widget _buildTestableWidget(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('ServerInfoCard', () {
    testWidgets('renders connecting state when systemInfo is null',
        (tester) async {
      const data = DashboardData();

      await tester.pumpWidget(_buildTestableWidget(
        const ServerInfoCard(data: data),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('--'), findsWidgets);
    });

    testWidgets('renders server info when systemInfo is present',
        (tester) async {
      final data = DashboardData(
        systemInfo: const SystemInfo(
          hostname: 'test-server',
          os: 'Ubuntu',
          platform: 'Linux',
          platformVersion: '24.04',
          kernelVersion: '6.8.0',
          cpuCores: 8,
        ),
        uptime: '3天 5小时',
        lastUpdated: DateTime(2024, 6, 15, 10, 30, 0),
      );

      await tester.pumpWidget(_buildTestableWidget(
        ServerInfoCard(data: data),
      ));
      await tester.pumpAndSettle();

      expect(find.text('test-server'), findsOneWidget);
      expect(find.text('3天 5小时'), findsOneWidget);
    });
  });

  group('ResourceCard', () {
    testWidgets('renders dash values when data is null', (tester) async {
      const data = DashboardData();

      await tester.pumpWidget(_buildTestableWidget(
        const ResourceCard(data: data),
      ));
      await tester.pumpAndSettle();

      expect(find.text('--'), findsWidgets);
    });

    testWidgets('renders resource percentages when data present',
        (tester) async {
      final data = DashboardData(
        cpuPercent: 45.5,
        memoryPercent: 62.3,
        diskPercent: 78.1,
        memoryUsage: '8.0 GB / 16.0 GB',
        diskUsage: '156.2 GB / 200.0 GB',
      );

      await tester.pumpWidget(_buildTestableWidget(
        ResourceCard(data: data),
      ));
      await tester.pumpAndSettle();

      expect(find.text('45.5%'), findsOneWidget);
      expect(find.text('62.3%'), findsOneWidget);
      expect(find.text('78.1%'), findsOneWidget);
      expect(find.text('8.0 GB / 16.0 GB'), findsOneWidget);
    });

    testWidgets('renders progress indicators', (tester) async {
      final data = DashboardData(
        cpuPercent: 50.0,
        memoryPercent: 80.0,
        diskPercent: 95.0,
      );

      await tester.pumpWidget(_buildTestableWidget(
        ResourceCard(data: data),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });

  group('ActivityCard', () {
    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(
        const ActivityCard(activities: []),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('No recent activity'), findsOneWidget);
    });

    testWidgets('renders activity items', (tester) async {
      final activities = [
        DashboardActivity(
          title: 'System Restart',
          description: 'Server restarted successfully',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          type: ActivityType.success,
        ),
        DashboardActivity(
          title: 'Backup Warning',
          description: 'Backup storage is almost full',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          type: ActivityType.warning,
        ),
        DashboardActivity(
          title: 'Service Error',
          description: 'nginx service crashed',
          time: DateTime.now().subtract(const Duration(days: 1)),
          type: ActivityType.error,
        ),
      ];

      await tester.pumpWidget(_buildTestableWidget(
        ActivityCard(activities: activities),
      ));
      await tester.pumpAndSettle();

      expect(find.text('System Restart'), findsOneWidget);
      expect(find.text('Server restarted successfully'), findsOneWidget);
      expect(find.text('Backup Warning'), findsOneWidget);
      expect(find.text('Service Error'), findsOneWidget);
    });

    testWidgets('renders different activity type icons', (tester) async {
      final activities = [
        DashboardActivity(
          title: 'Success',
          description: 'ok',
          time: DateTime.now(),
          type: ActivityType.success,
        ),
        DashboardActivity(
          title: 'Warning',
          description: 'warn',
          time: DateTime.now(),
          type: ActivityType.warning,
        ),
        DashboardActivity(
          title: 'Error',
          description: 'err',
          time: DateTime.now(),
          type: ActivityType.error,
        ),
        DashboardActivity(
          title: 'Info',
          description: 'info',
          time: DateTime.now(),
          type: ActivityType.info,
        ),
      ];

      await tester.pumpWidget(_buildTestableWidget(
        ActivityCard(activities: activities),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });

  group('TopProcessesCard', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(
        const TopProcessesCard(
          isLoading: true,
        ),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty process list', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(
        const TopProcessesCard(
          cpuProcesses: [],
          memoryProcesses: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('No process data'), findsWidgets);
    });

    testWidgets('renders process items', (tester) async {
      final cpuProcesses = [
        const ProcessInfo(
          pid: 1234,
          name: 'nginx',
          cpuPercent: 15.5,
          memoryPercent: 2.3,
        ),
        const ProcessInfo(
          pid: 5678,
          name: 'mysql',
          cpuPercent: 12.0,
          memoryPercent: 8.5,
        ),
      ];

      final memoryProcesses = [
        const ProcessInfo(
          pid: 9012,
          name: 'java',
          cpuPercent: 5.0,
          memoryPercent: 45.2,
        ),
      ];

      await tester.pumpWidget(_buildTestableWidget(
        TopProcessesCard(
          cpuProcesses: cpuProcesses,
          memoryProcesses: memoryProcesses,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('nginx'), findsOneWidget);
      expect(find.text('mysql'), findsOneWidget);
      expect(find.text('PID: 1234'), findsOneWidget);
      expect(find.text('15.5%'), findsOneWidget);
    });

    testWidgets('renders refresh button when onRefresh provided',
        (tester) async {
      await tester.pumpWidget(_buildTestableWidget(
        TopProcessesCard(
          onRefresh: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh_outlined), findsOneWidget);
    });

    testWidgets('shows tabs for CPU and Memory', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(
        const TopProcessesCard(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Tab), findsNWidgets(2));
    });
  });

  group('DashboardLoadingView', () {
    testWidgets('renders loading indicator and text', (tester) async {
      await tester.pumpWidget(_buildTestableWidget(
        const DashboardLoadingView(),
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Loading'), findsOneWidget);
    });
  });

  group('Dashboard error state', () {
    testWidgets('renders ModuleErrorStateWidget with retry button',
        (tester) async {
      var retryTapped = false;

      await tester.pumpWidget(_buildTestableWidget(
        ModuleErrorStateWidget(
          message: 'Connection timeout',
          onRetry: () => retryTapped = true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ModuleErrorStateWidget), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(retryTapped, isTrue);
    });
  });
}
