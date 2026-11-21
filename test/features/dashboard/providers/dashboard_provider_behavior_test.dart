import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/data/models/dashboard_models.dart';
import 'package:onepanel_client/features/dashboard/dashboard_provider.dart';
import 'package:onepanel_client/features/dashboard/services/dashboard_service.dart';

class _FakeDashboardService extends DashboardService {
  _FakeDashboardService({
    this.dashboardData = const DashboardData(),
    this.cpuProcesses = const <ProcessInfo>[],
    this.appLaunchers = const <AppLauncherItem>[],
    this.quickOptions = const <QuickJumpOption>[],
    this.currentNode,
    this.throwOnLoad = false,
    this.throwOnQuickChange = false,
  });

  DashboardData dashboardData;
  List<ProcessInfo> cpuProcesses;
  List<ProcessInfo> memoryProcesses = const <ProcessInfo>[];
  List<AppLauncherItem> appLaunchers;
  List<QuickJumpOption> quickOptions;
  NodeInfo? currentNode;
  bool throwOnLoad;
  bool throwOnProcesses = false;
  bool throwOnQuickOptions = false;
  bool throwOnQuickChange;

  Future<DashboardData> Function()? loadDashboardDataOverride;
  Future<({List<ProcessInfo> cpu, List<ProcessInfo> memory})> Function()?
      loadTopProcessesOverride;

  @override
  Future<DashboardData> loadDashboardData() {
    final override = loadDashboardDataOverride;
    if (override != null) return override();
    if (throwOnLoad) throw Exception('mock dashboard load failure');
    return Future.value(dashboardData);
  }

  @override
  Future<({List<ProcessInfo> cpu, List<ProcessInfo> memory})>
      loadTopProcesses() {
    final override = loadTopProcessesOverride;
    if (override != null) return override();
    if (throwOnProcesses) throw Exception('mock processes failure');
    return Future.value((cpu: cpuProcesses, memory: memoryProcesses));
  }

  @override
  Future<List<AppLauncherItem>> loadAppLaunchers() =>
      Future.value(appLaunchers);

  @override
  Future<List<QuickJumpOption>> loadQuickOptions() {
    if (throwOnQuickOptions) throw Exception('mock quick options failure');
    return Future.value(quickOptions);
  }

  @override
  Future<NodeInfo?> loadCurrentNode() => Future.value(currentNode);

  @override
  Future<void> updateAppLauncherShow({
    required String key,
    required bool show,
  }) async {}

  @override
  Future<void> updateQuickChange(List<String> enabledKeys) {
    if (throwOnQuickChange) throw Exception('mock quick change failure');
    return Future.value();
  }

  @override
  Future<void> restartSystem() async {}

  @override
  Future<void> shutdownSystem() async {}

}

void main() {
  group('DashboardProvider behavior', () {
    test('silent load failure keeps loaded status and resets refreshing flag',
        () async {
      final service = _FakeDashboardService(
        dashboardData: const DashboardData(cpuPercent: 11.0),
      );
      final provider = DashboardProvider(service: service);

      await provider.loadData();
      expect(provider.status, DashboardStatus.loaded);

      service.throwOnLoad = true;
      await provider.loadData(silent: true);

      expect(provider.status, DashboardStatus.loaded);
      expect(provider.errorMessage, isNotEmpty);
      expect(provider.isRefreshing, isFalse);
      expect(provider.data.cpuPercent, 11.0);
    });

    test('silent load toggles refreshing flag during fetch and keeps status',
        () async {
      final service = _FakeDashboardService();
      final provider = DashboardProvider(service: service);

      final completer = Completer<DashboardData>();
      service.loadDashboardDataOverride = () => completer.future;

      final pending = provider.loadData(silent: true);
      expect(provider.isRefreshing, isTrue);
      expect(provider.status, DashboardStatus.initial);

      completer.complete(const DashboardData(cpuPercent: 7.5));
      await pending;

      expect(provider.isRefreshing, isFalse);
      expect(provider.status, DashboardStatus.loaded);
      expect(provider.data.cpuPercent, 7.5);
    });

    test('overlapping refreshes share work and publish metrics before processes',
        () async {
      final service = _FakeDashboardService();
      final provider = DashboardProvider(service: service);

      final dataCompleter = Completer<DashboardData>();
      final processesCompleter =
          Completer<({List<ProcessInfo> cpu, List<ProcessInfo> memory})>();
      service.loadDashboardDataOverride = () => dataCompleter.future;
      service.loadTopProcessesOverride = () => processesCompleter.future;

      final pending = provider.loadData();
      expect(provider.refresh(), same(pending));
      dataCompleter.complete(const DashboardData(cpuPercent: 1.0));
      await Future<void>.delayed(Duration.zero);

      expect(provider.status, DashboardStatus.loaded);
      expect(provider.isLoadingTopProcesses, isTrue);
      expect(provider.loadTopProcesses(), same(provider.loadTopProcesses()));

      processesCompleter.complete((
        cpu: const [
          ProcessInfo(pid: 1, name: 'nginx', cpuPercent: 9, memoryPercent: 1),
        ],
        memory: const <ProcessInfo>[],
      ));
      await pending;

      expect(provider.isLoadingTopProcesses, isFalse);
      expect(provider.data.topCpuProcesses.first.name, 'nginx');
      final nextDashboard = Completer<DashboardData>();
      service.loadDashboardDataOverride = () => nextDashboard.future;
      var processReads = 0;
      service.loadTopProcessesOverride = () {
        processReads++;
        return processesCompleter.future;
      };
      final refreshing = provider.refresh();
      await provider.loadTopProcesses();
      nextDashboard.complete(const DashboardData(cpuPercent: 2));
      await refreshing;
      expect(processReads, 1);
      expect(provider.data.topCpuProcesses.first.name, 'nginx');
      expect(provider.data.cpuPercent, 2);
    });

    test('non silent failure then success recovers to loaded state',
        () async {
      final service = _FakeDashboardService(throwOnLoad: true);
      final provider = DashboardProvider(service: service);

      await provider.loadData();
      expect(provider.status, DashboardStatus.error);
      expect(provider.errorMessage, isNotEmpty);

      service.throwOnLoad = false;
      service.dashboardData = const DashboardData(cpuPercent: 3.0);
      await provider.loadData();

      expect(provider.status, DashboardStatus.loaded);
      expect(provider.errorMessage, isEmpty);
      expect(provider.data.cpuPercent, 3.0);
    });

    test('network exception surfaces its own message as error', () async {
      final service = _FakeDashboardService();
      final provider = DashboardProvider(service: service);
      service.loadDashboardDataOverride = () => Future<DashboardData>.error(
            const NetworkConnectionException('connection refused'),
          );

      await provider.loadData();

      expect(provider.status, DashboardStatus.error);
      expect(provider.errorMessage, 'connection refused');
    });

    test('top processes failure keeps previous lists and resets loading flag',
        () async {
      final service = _FakeDashboardService(
        cpuProcesses: const [
          ProcessInfo(pid: 1, name: 'nginx', cpuPercent: 5, memoryPercent: 1),
        ],
      );
      final provider = DashboardProvider(service: service);

      await provider.loadTopProcesses();
      expect(provider.data.topCpuProcesses, hasLength(1));

      service.throwOnProcesses = true;
      await provider.loadTopProcesses();

      expect(provider.data.topCpuProcesses, hasLength(1));
      expect(provider.data.topCpuProcesses.first.name, 'nginx');
      expect(provider.isLoadingTopProcesses, isFalse);
    });

    test('loadQuickOptions populates options and survives failure', () async {
      final service = _FakeDashboardService(
        quickOptions: const [
          QuickJumpOption(key: 'terminal', name: 'Terminal'),
        ],
      );
      final provider = DashboardProvider(service: service);

      await provider.loadQuickOptions();
      expect(provider.data.quickOptions, hasLength(1));
      expect(provider.data.quickOptions.first.key, 'terminal');
      expect(provider.isLoadingQuickOptions, isFalse);

      service.throwOnQuickOptions = true;
      await provider.loadQuickOptions();

      expect(provider.data.quickOptions, hasLength(1));
      expect(provider.isLoadingQuickOptions, isFalse);
    });

    test('loadCurrentNode populates node info', () async {
      final service = _FakeDashboardService(
        currentNode: const NodeInfo(
          name: 'node-1',
          status: 'online',
          version: '2.0.0',
          ip: '10.0.0.5',
        ),
      );
      final provider = DashboardProvider(service: service);

      await provider.loadCurrentNode();

      expect(provider.data.nodeInfo?.name, 'node-1');
      expect(provider.data.nodeInfo?.status, 'online');
    });

    test('updateAppLauncherShow records activity and reloads launchers',
        () async {
      final service = _FakeDashboardService(
        appLaunchers: const [
          AppLauncherItem(key: 'nginx', name: 'Nginx'),
        ],
      );
      final provider = DashboardProvider(service: service);

      await provider.updateAppLauncherShow('nginx', false);

      expect(provider.data.appLaunchers, hasLength(1));
      expect(provider.activities.first.title, 'App Launcher Updated');
      expect(provider.activities.first.type, ActivityType.success);
    });

    test('updateQuickChange rethrows failure to caller', () async {
      final service = _FakeDashboardService(throwOnQuickChange: true);
      final provider = DashboardProvider(service: service);

      await expectLater(
        provider.updateQuickChange(['terminal']),
        throwsA(isA<Exception>()),
      );
    });

    test('system restart and shutdown record activities', () async {
      final provider = DashboardProvider(service: _FakeDashboardService());

      await provider.restartSystem();
      expect(provider.activities.first.title, 'System Restart');
      expect(provider.activities.first.type, ActivityType.success);

      await provider.shutdownSystem();
      expect(provider.activities.first.title, 'System Shutdown');
      expect(provider.activities.first.type, ActivityType.warning);

      expect(provider.activities, hasLength(2));
    });

    test('activities are capped at ten with newest first', () async {
      final provider = DashboardProvider(service: _FakeDashboardService());

      for (var i = 0; i < 12; i++) {
        await provider.shutdownSystem();
      }

      expect(provider.activities, hasLength(10));
      expect(provider.activities.first.title, 'System Shutdown');
      expect(provider.activities.last.title, 'System Shutdown');
    });
  });
}
