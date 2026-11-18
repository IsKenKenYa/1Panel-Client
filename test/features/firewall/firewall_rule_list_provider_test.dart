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
    String? strategy,
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
    String? strategy,
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

  test('FirewallPortsProvider loads with type port', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallPortsProvider(service: service);
    await provider.load();
    expect(service.lastType, 'port');
  });

  test('FirewallRuleListProvider toggleStrategy fails for forward rules',
      () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRuleListProvider(
      service: service,
      useFilterApi: false,
    );

    await provider.load();
    final ok = await provider.toggleStrategy(
      const FirewallRule(
        targetIP: '10.0.0.1',
        targetPort: '8080',
        port: '80',
        protocol: 'tcp',
        strategy: 'accept',
      ),
      'drop',
    );

    expect(ok, isFalse);
    expect(provider.error, contains('Forward'));
  });

  test('FirewallRulesProvider toggleFilterChainBinding calls service', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRulesProvider(service: service);

    await provider.load();
    final ok = await provider.toggleFilterChainBinding(true);

    expect(ok, isTrue);
    expect(service.lastFilterChainOperation, isNotNull);
    expect(service.lastFilterChainOperation!.operate, 'bind');
  });

  test('FirewallRulesProvider toggleFilterChainBinding unbind', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRulesProvider(service: service);

    await provider.load();
    final ok = await provider.toggleFilterChainBinding(false);

    expect(ok, isTrue);
    expect(service.lastFilterChainOperation!.operate, 'unbind');
  });

  test('FirewallRulesProvider switchFilterChain skips when same chain',
      () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRulesProvider(service: service);

    await provider.load();
    final pageBefore = service.lastPage;
    await provider.switchFilterChain('1PANEL_INPUT');

    expect(provider.filterChain, '1PANEL_INPUT');
    expect(service.lastPage, pageBefore);
  });

  test('FirewallRulesProvider deleteRules uses filter batch API', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRulesProvider(service: service);

    await provider.load();
    await provider.deleteRules([
      const FirewallRule(id: 1, address: '1.1.1.1', strategy: 'accept'),
    ]);

    expect(service.lastFilterBatchOperation, isNotNull);
    expect(service.lastFilterBatchOperation!.rules, hasLength(1));
    expect(service.lastFilterBatchOperation!.rules.first.operation, 'remove');
  });

  test('FirewallRulesProvider updateDescription uses filter batch API',
      () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRulesProvider(service: service);

    await provider.load();
    await provider.updateDescription(
      const FirewallRule(id: 1, address: '1.1.1.1', strategy: 'accept'),
      'new description',
    );

    expect(service.lastFilterBatchOperation, isNotNull);
    expect(service.lastFilterBatchOperation!.rules, hasLength(2));
    expect(service.lastFilterBatchOperation!.rules.first.operation, 'remove');
    expect(service.lastFilterBatchOperation!.rules.last.operation, 'add');
  });

  test('FirewallIpProvider toggleStrategy uses IP update API', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallIpProvider(service: service);

    await provider.load();
    await provider.toggleStrategy(
      const FirewallRule(address: '1.1.1.1', strategy: 'accept'),
      'drop',
    );

    expect(service.lastIpUpdate, isNotNull);
    expect(service.lastIpUpdate!.newRule.strategy, 'drop');
    expect(service.lastIpUpdate!.oldRule.strategy, 'accept');
  });

  test('FirewallPortsProvider deleteRules builds batch request', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallPortsProvider(service: service);

    await provider.deleteRules([
      const FirewallRule(
        address: '',
        port: '443',
        protocol: 'tcp',
        strategy: 'accept',
      ),
    ]);

    expect(service.lastDeleteRequest, isNotNull);
    expect(service.lastDeleteRequest!.type, 'port');
  });

  test('FirewallRuleFormProvider submitPort succeeds', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRuleFormProvider(service: service);

    final ok = await provider.submitPort(
      payload: const FirewallPortRulePayload(
        operation: 'add',
        address: '',
        port: '80',
        source: 'anyWhere',
        protocol: 'tcp',
        strategy: 'accept',
      ),
    );

    expect(ok, isTrue);
    expect(provider.isSubmitting, isFalse);
    expect(provider.error, isNull);
  });

  test('FirewallRuleFormProvider submitIp succeeds', () async {
    final service = _FakeFirewallRuleService();
    final provider = FirewallRuleFormProvider(service: service);

    final ok = await provider.submitIp(
      payload: const FirewallIpRulePayload(
        operation: 'add',
        address: '10.0.0.0/8',
        strategy: 'drop',
      ),
    );

    expect(ok, isTrue);
    expect(provider.error, isNull);
  });

  test('FirewallRuleFormProvider surfaces errors', () async {
    final service = _ThrowingFormService();
    final provider = FirewallRuleFormProvider(service: service);

    final ok = await provider.submitPort(
      payload: const FirewallPortRulePayload(
        operation: 'add',
        address: '',
        port: '80',
        source: 'anyWhere',
        protocol: 'tcp',
        strategy: 'accept',
      ),
    );

    expect(ok, isFalse);
    expect(provider.error, contains('form failed'));
  });
}

class _ThrowingFormService implements FirewallServiceInterface {
  @override
  Future<FirewallBaseInfo> loadBaseInfo({String tab = 'base'}) async =>
      const FirewallBaseInfo();

  @override
  Future<PageResult<FirewallRule>> searchRules({
    required int page,
    required int pageSize,
    String? type,
    String? info,
    String? strategy,
  }) async =>
      const PageResult(items: [], total: 0);

  @override
  Future<PageResult<FirewallRule>> searchFilterRules({
    required int page,
    required int pageSize,
    required String type,
    String? info,
    String? strategy,
  }) async =>
      const PageResult(items: [], total: 0);

  @override
  Future<FirewallFilterChainStatus> loadFilterChainStatus({
    required String name,
  }) async =>
      const FirewallFilterChainStatus();

  @override
  Future<void> operateFilterChain({
    required FirewallFilterChainOperation operation,
  }) async {}

  @override
  Future<void> operateFilterRule(FirewallFilterRuleOperation request) async {}

  @override
  Future<void> batchOperateFilterRules(
    FirewallFilterBatchOperation request,
  ) async {}

  @override
  Future<void> operateForwardRules(
    FirewallForwardOperateRequest request,
  ) async {}

  @override
  Future<void> operateFirewall({required FirewallOperation operation}) async {}

  @override
  Future<void> createIpRule(FirewallIpRulePayload payload) async {}

  @override
  Future<void> createPortRule(FirewallPortRulePayload payload) async =>
      throw Exception('form failed');

  @override
  Future<void> deleteRules(FirewallBatchRuleRequest request) async {}

  @override
  Future<void> updateDescription(FirewallDescriptionUpdate request) async {}

  @override
  Future<void> updateIpRule(FirewallUpdateIpRequest request) async {}

  @override
  Future<void> updatePortRule(FirewallUpdatePortRequest request) async =>
      throw Exception('form failed');
}
