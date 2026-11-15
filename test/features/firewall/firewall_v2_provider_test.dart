import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/firewall/firewall_v2_service.dart';
import 'package:onepanel_client/features/firewall/providers/firewall_v2_provider.dart';

class _FakeFirewallV2Service extends FirewallV2Service {
  _FakeFirewallV2Service() : super(api: null);

  bool fail = false;
  int settingsLoads = 0;
  int ruleLoads = 0;
  int forwardLoads = 0;
  int dockerLoads = 0;
  int backupLoads = 0;
  String? lastBackupSubsystem;

  void _maybeThrow() {
    if (fail) throw Exception('firewall v2 unavailable');
  }

  @override
  Future<Map<String, dynamic>> loadSettings() async {
    _maybeThrow();
    settingsLoads++;
    return <String, dynamic>{'ipv6Enabled': true, 'panelPort': '26314'};
  }

  @override
  Future<Map<String, dynamic>> searchRuleInventory({
    int page = 1,
    int pageSize = 20,
    String? info,
  }) async {
    _maybeThrow();
    ruleLoads++;
    return <String, dynamic>{'total': 2, 'items': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> loadRuleBackups(String subsystem) async {
    _maybeThrow();
    backupLoads++;
    lastBackupSubsystem = subsystem;
    return <String, dynamic>{'directory': '/backup'};
  }

  @override
  Future<Map<String, dynamic>> loadForwardBase() async {
    _maybeThrow();
    forwardLoads++;
    return <String, dynamic>{'isActive': true};
  }

  @override
  Future<Map<String, dynamic>> searchForwardRules({
    int page = 1,
    int pageSize = 20,
  }) async {
    _maybeThrow();
    return <String, dynamic>{'total': 1, 'items': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> loadDockerPorts() async {
    _maybeThrow();
    dockerLoads++;
    return <String, dynamic>{'base': <String, dynamic>{'isActive': true}};
  }

  @override
  Future<List<dynamic>> loadDockerEndpoints() async {
    _maybeThrow();
    return <dynamic>[
      <String, dynamic>{'name': 'nginx', 'endpoints': <dynamic>[]},
    ];
  }
}

void main() {
  group('FirewallV2Provider', () {
    late _FakeFirewallV2Service service;
    late FirewallV2Provider provider;

    setUp(() {
      service = _FakeFirewallV2Service();
      provider = FirewallV2Provider(service: service);
    });

    test('loadSettings_populatesSettings', () async {
      await provider.loadSettings();

      expect(service.settingsLoads, 1);
      expect(provider.settings['ipv6Enabled'], isTrue);
      expect(provider.settings['panelPort'], '26314');
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('loadRuleInventory_populatesInventory', () async {
      await provider.loadRuleInventory(info: '22');

      expect(service.ruleLoads, 1);
      expect(provider.ruleInventory['total'], 2);
    });

    test('loadRuleBackups_passesSubsystem', () async {
      await provider.loadRuleBackups('system');

      expect(service.backupLoads, 1);
      expect(service.lastBackupSubsystem, 'system');
      expect(provider.ruleBackups['directory'], '/backup');
    });

    test('loadForward_populatesBaseAndRules', () async {
      await provider.loadForward();

      expect(service.forwardLoads, 1);
      expect(provider.forwardBase['isActive'], isTrue);
      expect(provider.forwardRules['total'], 1);
    });

    test('loadDocker_populatesPortsAndEndpoints', () async {
      await provider.loadDocker();

      expect(service.dockerLoads, 1);
      expect(provider.dockerPorts['base'], isNotNull);
      expect(provider.dockerEndpoints.length, 1);
    });

    test('loadSettings_onFailure_setsErrorAndStopsLoading', () async {
      service.fail = true;

      await provider.loadSettings();

      expect(provider.error, isNotNull);
      expect(provider.isLoading, isFalse);
      expect(provider.settings, isEmpty);
    });
  });
}
