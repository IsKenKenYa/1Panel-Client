import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/data/models/monitoring_runtime_models.dart';
import 'package:onepanel_client/data/models/monitor_models.dart';
import 'package:onepanel_client/data/repositories/monitor_repository.dart';
import 'package:onepanel_client/features/monitoring/data/datasources/monitor_local_datasource.dart';
import 'package:onepanel_client/features/monitoring/monitoring_page.dart';
import 'package:onepanel_client/features/monitoring/monitoring_provider.dart';
import 'package:onepanel_client/features/monitoring/monitoring_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeCurrentServerController extends CurrentServerController {
  @override
  String? get currentServerId => 'server-1';

  @override
  bool get hasServer => true;
}

class _FakeMonitorLocalDataSource extends MonitorLocalDataSource {
  @override
  Future<void> init() async {}

  @override
  Future<List<MonitorDataPoint>> getPoints(
    String metric,
    DateTime start,
    DateTime end,
  ) async {
    return const [];
  }

  @override
  Future<void> savePoints(String metric, List<MonitorDataPoint> points) async {}
}

class _FakeMonitoringService extends MonitoringService {
  int updateSettingsCallCount = 0;

  @override
  Future<MonitorDataPackage> getMonitorData({
    CancelToken? cancelToken,
    Duration duration = const Duration(hours: 1),
    String? io,
    String? network,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    return MonitorDataPackage(
      current: const MonitorMetricsSnapshot(
        cpuPercent: 0.2,
        memoryPercent: 0.3,
      ),
      timeSeries: {
        'cpu': MonitorTimeSeries.empty('cpu'),
        'memory': MonitorTimeSeries.empty('memory'),
        'load': MonitorTimeSeries.empty('load'),
        'io': MonitorTimeSeries.empty('io'),
        'network': MonitorTimeSeries.empty('network'),
      },
    );
  }

  @override
  Future<List<MonitorGpuInfo>> getGPUInfo() async {
    return const [MonitorGpuInfo(name: 'NVIDIA')];
  }

  @override
  Future<MonitorSetting?> getSetting() async {
    return const MonitorSetting(
      enabled: true,
      retention: 30,
      defaultIO: 'sda',
      defaultNetwork: 'eth0',
    );
  }

  @override
  Future<List<String>> getIOOptions() async {
    return const ['all', 'sda'];
  }

  @override
  Future<List<String>> getNetworkOptions() async {
    return const ['all', 'eth0'];
  }

  @override
  Future<bool> updateSetting({
    int? interval,
    int? retention,
    bool? enabled,
    String? defaultIO,
    String? defaultNetwork,
  }) async {
    updateSettingsCallCount += 1;
    return true;
  }

  @override
  Future<bool> cleanData() async {
    return true;
  }
}

Future<void> _tapGpuRefreshSwitch(WidgetTester tester) async {
  final gpuSwitch = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(SwitchListTile),
  );
  await tester.scrollUntilVisible(
    gpuSwitch,
    160,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(gpuSwitch);
  await tester.pumpAndSettle();
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

  testWidgets('MonitoringPage allows toggling GPU refresh strategy in settings',
      (tester) async {
    final provider = MonitoringProvider(
      service: _FakeMonitoringService(),
      dataSource: _FakeMonitorLocalDataSource(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<MonitoringProvider>.value(
            value: provider,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MonitoringPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(SwitchListTile)),
        findsOneWidget);
    expect(find.byType(DropdownButtonFormField<Duration>), findsNWidgets(3));

    await _tapGpuRefreshSwitch(tester);

    expect(find.byType(DropdownButtonFormField<Duration>), findsNWidgets(2));

    await _tapGpuRefreshSwitch(tester);

    expect(find.byType(DropdownButtonFormField<Duration>), findsNWidgets(3));

    provider.toggleAutoRefresh(false);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    provider.dispose();
  });

  testWidgets('MonitoringPage saves GPU refresh strategy through provider',
      (tester) async {
    final service = _FakeMonitoringService();
    final provider = MonitoringProvider(
      service: service,
      dataSource: _FakeMonitorLocalDataSource(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<MonitoringProvider>.value(
            value: provider,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MonitoringPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    await _tapGpuRefreshSwitch(tester);

    final dialog = find.byType(AlertDialog);
    final saveButton = find.descendant(
      of: dialog,
      matching: find.byType(FilledButton),
    );
    await tester.tap(saveButton.last);
    await tester.pumpAndSettle();

    expect(provider.gpuAutoRefreshEnabled, isFalse);
    expect(service.updateSettingsCallCount, 0);

    provider.toggleAutoRefresh(false);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();
    provider.dispose();
  });
}
