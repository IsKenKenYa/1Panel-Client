import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/dashboard_models.dart';
import 'package:onepanel_client/features/dashboard/models/dashboard_view_models.dart';
import 'package:onepanel_client/features/dashboard/services/dashboard_service.dart';

class _FakeDashboardService extends DashboardService {
  _FakeDashboardService({
    this.dashboardData = const DashboardData(),
    this.cpuProcesses = const <ProcessInfo>[],
    this.memoryProcesses = const <ProcessInfo>[],
    this.appLaunchers = const <AppLauncherItem>[],
    this.appLauncherOptions = const <AppLauncherOption>[],
    this.currentNode,
    this.quickOptions = const <QuickJumpOption>[],
  });

  final DashboardData dashboardData;
  final List<ProcessInfo> cpuProcesses;
  final List<ProcessInfo> memoryProcesses;
  final List<AppLauncherItem> appLaunchers;
  final List<AppLauncherOption> appLauncherOptions;
  final NodeInfo? currentNode;
  final List<QuickJumpOption> quickOptions;

  @override
  Future<DashboardData> loadDashboardData() async => dashboardData;

  @override
  Future<({List<ProcessInfo> cpu, List<ProcessInfo> memory})>
      loadTopProcesses() async {
    return (cpu: cpuProcesses, memory: memoryProcesses);
  }

  @override
  Future<List<AppLauncherItem>> loadAppLaunchers() async => appLaunchers;

  @override
  Future<List<AppLauncherOption>> loadAppLauncherOptions() async =>
      appLauncherOptions;

  @override
  Future<NodeInfo?> loadCurrentNode() async => currentNode;

  @override
  Future<List<QuickJumpOption>> loadQuickOptions() async => quickOptions;

  @override
  Future<void> restartSystem() async {}

  @override
  Future<void> shutdownSystem() async {}

}

void main() {
  group('DashboardService', () {
    test('loadDashboardData returns DashboardData', () async {
      final service = _FakeDashboardService(
        dashboardData: DashboardData(
          cpuPercent: 55.0,
          memoryPercent: 70.0,
          uptime: '2天 3小时',
          systemInfo: const SystemInfo(
            hostname: 'prod-server',
            os: 'Ubuntu',
          ),
        ),
      );

      final data = await service.loadDashboardData();

      expect(data.cpuPercent, 55.0);
      expect(data.memoryPercent, 70.0);
      expect(data.uptime, '2天 3小时');
      expect(data.systemInfo?.hostname, 'prod-server');
    });

    test('loadTopProcesses returns cpu and memory process lists', () async {
      final service = _FakeDashboardService(
        cpuProcesses: const [
          ProcessInfo(pid: 1, name: 'nginx', cpuPercent: 10, memoryPercent: 1),
          ProcessInfo(pid: 2, name: 'redis', cpuPercent: 5, memoryPercent: 3),
        ],
        memoryProcesses: const [
          ProcessInfo(
              pid: 3, name: 'java', cpuPercent: 2, memoryPercent: 40),
        ],
      );

      final result = await service.loadTopProcesses();

      expect(result.cpu, hasLength(2));
      expect(result.cpu.first.name, 'nginx');
      expect(result.memory, hasLength(1));
      expect(result.memory.first.name, 'java');
    });

    test('loadAppLaunchers returns launcher items', () async {
      final service = _FakeDashboardService(
        appLaunchers: const [
          AppLauncherItem(key: 'nginx', name: 'Nginx', icon: 'icon-nginx'),
          AppLauncherItem(key: 'mysql', name: 'MySQL', url: 'http://mysql'),
        ],
      );

      final items = await service.loadAppLaunchers();

      expect(items, hasLength(2));
      expect(items.first.key, 'nginx');
      expect(items.last.url, 'http://mysql');
    });

    test('loadAppLauncherOptions returns options', () async {
      final service = _FakeDashboardService(
        appLauncherOptions: const [
          AppLauncherOption(key: 'web', name: 'Web Server'),
          AppLauncherOption(key: 'db', name: 'Database', icon: 'icon-db'),
        ],
      );

      final options = await service.loadAppLauncherOptions();

      expect(options, hasLength(2));
      expect(options.first.key, 'web');
      expect(options.last.icon, 'icon-db');
    });

    test('loadCurrentNode returns node info', () async {
      final service = _FakeDashboardService(
        currentNode: const NodeInfo(
          name: 'node-1',
          status: 'online',
          version: '2.0.0',
          ip: '192.168.1.1',
        ),
      );

      final node = await service.loadCurrentNode();

      expect(node, isNotNull);
      expect(node!.name, 'node-1');
      expect(node.status, 'online');
      expect(node.ip, '192.168.1.1');
    });

    test('loadCurrentNode returns null when empty', () async {
      final service = _FakeDashboardService(currentNode: null);

      final node = await service.loadCurrentNode();

      expect(node, isNull);
    });

    test('loadQuickOptions returns quick jump options', () async {
      final service = _FakeDashboardService(
        quickOptions: const [
          QuickJumpOption(key: 'terminal', name: 'Terminal'),
          QuickJumpOption(key: 'files', name: 'Files', enabled: false),
        ],
      );

      final options = await service.loadQuickOptions();

      expect(options, hasLength(2));
      expect(options.first.key, 'terminal');
      expect(options.last.enabled, isFalse);
    });

    test('restartSystem completes without error', () async {
      final service = _FakeDashboardService();

      expect(() => service.restartSystem(), returnsNormally);
    });

    test('shutdownSystem completes without error', () async {
      final service = _FakeDashboardService();

      expect(() => service.shutdownSystem(), returnsNormally);
    });
  });

  group('NodeInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'name': 'node-1',
        'status': 'online',
        'version': '2.0.0',
        'ip': '10.0.0.1',
      };

      final node = NodeInfo.fromJson(json);

      expect(node.name, 'node-1');
      expect(node.status, 'online');
      expect(node.version, '2.0.0');
      expect(node.ip, '10.0.0.1');
    });

    test('fromJson handles missing fields', () {
      final node = NodeInfo.fromJson(<String, dynamic>{});

      expect(node.name, isNull);
      expect(node.status, isNull);
      expect(node.version, isNull);
      expect(node.ip, isNull);
    });

    test('constructor creates with all fields', () {
      const node = NodeInfo(
        name: 'n1',
        status: 'offline',
        version: '1.0',
        ip: '127.0.0.1',
      );

      expect(node.name, 'n1');
      expect(node.status, 'offline');
    });
  });

  group('AppLauncherOption', () {
    test('fromJson parses all fields', () {
      final json = {
        'key': 'web',
        'name': 'Web Server',
        'icon': 'icon-web',
      };

      final option = AppLauncherOption.fromJson(json);

      expect(option.key, 'web');
      expect(option.name, 'Web Server');
      expect(option.icon, 'icon-web');
    });

    test('fromJson handles missing fields with defaults', () {
      final option = AppLauncherOption.fromJson(<String, dynamic>{});

      expect(option.key, isEmpty);
      expect(option.name, isEmpty);
      expect(option.icon, isNull);
    });
  });

  group('AppLauncherItem', () {
    test('fromJson parses all fields', () {
      final json = {
        'key': 'nginx',
        'name': 'Nginx',
        'icon': 'icon-nginx',
        'url': 'http://nginx:80',
      };

      final item = AppLauncherItem.fromJson(json);

      expect(item.key, 'nginx');
      expect(item.name, 'Nginx');
      expect(item.icon, 'icon-nginx');
      expect(item.url, 'http://nginx:80');
    });

    test('fromJson handles missing optional fields', () {
      final item = AppLauncherItem.fromJson({'key': 'x', 'name': 'X'});

      expect(item.icon, isNull);
      expect(item.url, isNull);
    });
  });

  group('QuickJumpOption', () {
    test('fromJson parses all fields', () {
      final json = {
        'key': 'terminal',
        'name': 'Terminal',
        'icon': 'icon-term',
        'enabled': false,
      };

      final option = QuickJumpOption.fromJson(json);

      expect(option.key, 'terminal');
      expect(option.name, 'Terminal');
      expect(option.icon, 'icon-term');
      expect(option.enabled, isFalse);
    });

    test('fromJson defaults enabled to true', () {
      final option =
          QuickJumpOption.fromJson({'key': 'k', 'name': 'N'});

      expect(option.enabled, isTrue);
    });

    test('fromJson handles empty map', () {
      final option = QuickJumpOption.fromJson(<String, dynamic>{});

      expect(option.key, isEmpty);
      expect(option.name, isEmpty);
      expect(option.icon, isNull);
      expect(option.enabled, isTrue);
    });
  });

  group('DashboardData - extended tests', () {
    test('copyWith preserves appLaunchers and quickOptions', () {
      final data = DashboardData(
        cpuPercent: 50,
        appLaunchers: const [
          AppLauncherItem(key: 'a', name: 'A'),
        ],
        quickOptions: const [
          QuickJumpOption(key: 'q', name: 'Q'),
        ],
      );

      final copied = data.copyWith(cpuPercent: 75);

      expect(copied.cpuPercent, 75);
      expect(copied.appLaunchers, hasLength(1));
      expect(copied.quickOptions, hasLength(1));
    });

    test('copyWith can replace appLaunchers', () {
      final data = DashboardData(
        appLaunchers: const [
          AppLauncherItem(key: 'a', name: 'A'),
        ],
      );

      final copied = data.copyWith(
        appLaunchers: const [
          AppLauncherItem(key: 'b', name: 'B'),
          AppLauncherItem(key: 'c', name: 'C'),
        ],
      );

      expect(copied.appLaunchers, hasLength(2));
      expect(copied.appLaunchers.first.key, 'b');
    });

    test('copyWith can replace nodeInfo', () {
      const data = DashboardData();

      final copied = data.copyWith(
        nodeInfo: const NodeInfo(name: 'node-1', status: 'online'),
      );

      expect(copied.nodeInfo, isNotNull);
      expect(copied.nodeInfo!.name, 'node-1');
    });

    test('default appLauncherOptions is empty', () {
      const data = DashboardData();

      expect(data.appLauncherOptions, isEmpty);
      expect(data.appLaunchers, isEmpty);
      expect(data.quickOptions, isEmpty);
      expect(data.nodeInfo, isNull);
    });
  });
}
