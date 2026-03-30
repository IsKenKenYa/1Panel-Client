import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/features/firewall/firewall_service.dart';
import 'package:onepanel_client/features/firewall/providers/firewall_rule_list_provider.dart';

class _FakeFirewallRuleService implements FirewallServiceInterface {
  _FakeFirewallRuleService();

  int lastPage = 0;
  int lastPageSize = 0;
  String? lastType;
  String? lastInfo;
  String? lastStrategy;
  FirewallBatchRuleRequest? lastDeleteRequest;
  FirewallDescriptionUpdate? lastDescriptionUpdate;
  FirewallUpdateIpRequest? lastIpUpdate;
  FirewallUpdatePortRequest? lastPortUpdate;
  FirewallFilterBatchOperation? lastFilterBatchOperation;
  FirewallFilterChainOperation? lastFilterChainOperation;
  FirewallForwardOperateRequest? lastForwardRequest;

  final FirewallRule _rule = const FirewallRule(
    id: 1,
    address: '1.1.1.1',
    strategy: 'accept',
  );

  @override
  Future<FirewallBaseInfo> loadBaseInfo({String tab = 'base'}) async {
    return const FirewallBaseInfo(name: 'firewall');
  }

  @override
  Future<PageResult<FirewallRule>> searchRules({
    required int page,
    required int pageSize,
    String? type,
    String? info,
    String? strategy,
  }) async {
    lastPage = page;
    lastPageSize = pageSize;
    lastType = type;
    lastInfo = info;
    lastStrategy = strategy;
    return PageResult(items: [_rule], total: 1);
  }

  @override
  Future<PageResult<FirewallRule>> searchFilterRules({
    required int page,
    required int pageSize,
    required String type,
    String? info,
  }) async {
    lastPage = page;
    lastPageSize = pageSize;
    lastType = type;
    lastInfo = info;
    return PageResult(items: [_rule], total: 1);
  }

  @override
  Future<FirewallFilterChainStatus> loadFilterChainStatus({
    required String name,
  }) async {
    return const FirewallFilterChainStatus(
      isBind: true,
      defaultStrategy: 'accept',
    );
  }

  @override
  Future<void> operateFilterChain({
    required FirewallFilterChainOperation operation,
  }) async {
    lastFilterChainOperation = operation;
  }

  @override
  Future<void> operateFilterRule(FirewallFilterRuleOperation request) async {}

  @override
  Future<void> batchOperateFilterRules(
    FirewallFilterBatchOperation request,
  ) async {
    lastFilterBatchOperation = request;
  }

  @override
  Future<void> operateForwardRules(FirewallForwardOperateRequest request) async {
    lastForwardRequest = request;
  }

  @override
  Future<void> operateFirewall({required FirewallOperation operation}) async {}

  @override
  Future<void> createIpRule(FirewallIpRulePayload payload) async {}

  @override
  Future<void> createPortRule(FirewallPortRulePayload payload) async {}

  @override
  Future<void> deleteRules(FirewallBatchRuleRequest request) async {
    lastDeleteRequest = request;
  }

  @override
  Future<void> updateDescription(FirewallDescriptionUpdate request) async {
    lastDescriptionUpdate = request;
  }

  @override
  Future<void> updateIpRule(FirewallUpdateIpRequest request) async {
    lastIpUpdate = request;
  }

  @override
  Future<void> updatePortRule(FirewallUpdatePortRequest request) async {
    lastPortUpdate = request;
  }
}

class _ThrowingRuleService extends _FakeFirewallRuleService {
  @override
  Future<PageResult<FirewallRule>> searchFilterRules({
    required int page,
    required int pageSize,
    required String type,
    String? info,
  }) async {
    throw Exception('search fail');
  }
}

void main() {
  test('FirewallRulesProvider loads list', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRulesProvider(service: service);
    await provider.load(page: 2, pageSize: 5, search: 'hello');

    expect(provider.items, hasLength(1));
    expect(provider.total, 1);
    expect(service.lastPage, 2);
    expect(service.lastPageSize, 5);
    expect(service.lastInfo, 'hello');
    expect(service.lastType, '1PANEL_INPUT');
  });

  test('FirewallRulesProvider keeps search term on refresh',
      () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRulesProvider(service: service);
    await provider.load(search: 'ssh', strategy: 'drop');

    expect(service.lastInfo, 'ssh');
    expect(service.lastType, '1PANEL_INPUT');

    await provider.refresh();
    expect(service.lastInfo, 'ssh');
    expect(service.lastType, '1PANEL_INPUT');
  });

  test('FirewallRulesProvider can switch filter chain', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRulesProvider(service: service);

    await provider.switchFilterChain('1PANEL_OUTPUT');

    expect(provider.filterChain, '1PANEL_OUTPUT');
    expect(service.lastType, '1PANEL_OUTPUT');
  });

  test('FirewallIpProvider attaches type filter', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallIpProvider(service: service);
    await provider.load();
    expect(service.lastType, 'address');
  });

  test('FirewallRuleListProvider surfaces errors', () async {
    final service = _ThrowingRuleService();
    final provider = FirewallRulesProvider(service: service);

    await provider.load();

    expect(provider.error, isNotNull);
    expect(provider.items, isEmpty);
  });

  test('FirewallIpProvider deleteRules builds batch request', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallIpProvider(service: service);

    await provider.deleteRules([
      const FirewallRule(address: '1.1.1.1', strategy: 'accept'),
    ]);

    expect(service.lastDeleteRequest, isNotNull);
    expect(service.lastDeleteRequest!.type, 'address');
  });

  test('FirewallPortsProvider toggleStrategy updates port payload', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallPortsProvider(service: service);

    await provider.toggleStrategy(
      const FirewallRule(
        address: '',
        port: '80',
        protocol: 'tcp',
        strategy: 'accept',
      ),
      'drop',
    );

    expect(service.lastPortUpdate, isNotNull);
    expect(service.lastPortUpdate!.newRule.strategy, 'drop');
  });
}
