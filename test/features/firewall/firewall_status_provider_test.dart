import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/features/firewall/firewall_service.dart';
import 'package:onepanel_client/features/firewall/providers/firewall_status_provider.dart';

class _FakeFirewallService implements FirewallServiceInterface {
  _FakeFirewallService([this.status = const FirewallBaseInfo()]);

  final FirewallBaseInfo status;

  @override
  Future<FirewallBaseInfo> loadBaseInfo({String tab = 'base'}) async => status;

  @override
  Future<PageResult<FirewallRule>> searchRules({
    required int page,
    required int pageSize,
    String? type,
    String? info,
    String? strategy,
  }) async {
    return const PageResult(items: [], total: 0);
  }

  @override
  Future<PageResult<FirewallRule>> searchFilterRules({
    required int page,
    required int pageSize,
    required String type,
    String? info,
  }) async {
    return const PageResult(items: [], total: 0);
  }

  @override
  Future<FirewallFilterChainStatus> loadFilterChainStatus({
    required String name,
  }) async {
    return const FirewallFilterChainStatus();
  }

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
  Future<void> operateForwardRules(FirewallForwardOperateRequest request) async {}

  @override
  Future<void> operateFirewall({required FirewallOperation operation}) async {}

  @override
  Future<void> createIpRule(FirewallIpRulePayload payload) async {}

  @override
  Future<void> createPortRule(FirewallPortRulePayload payload) async {}

  @override
  Future<void> deleteRules(FirewallBatchRuleRequest request) async {}

  @override
  Future<void> updateDescription(FirewallDescriptionUpdate request) async {}

  @override
  Future<void> updateIpRule(FirewallUpdateIpRequest request) async {}

  @override
  Future<void> updatePortRule(FirewallUpdatePortRequest request) async {}
}

class _ThrowingFirewallService extends _FakeFirewallService {
  @override
  Future<FirewallBaseInfo> loadBaseInfo({String tab = 'base'}) async {
    throw Exception('failed');
  }
}

void main() {
  test('FirewallStatusProvider loads data', () async {
    final provider = FirewallStatusProvider(
      service: _FakeFirewallService(const FirewallBaseInfo(name: 'firewall')),
    );
    await provider.load();
    expect(provider.status?.name, 'firewall');
    expect(provider.error, isNull);
    expect(provider.loading, isFalse);
  });

  test('FirewallStatusProvider reports error', () async {
    final provider = FirewallStatusProvider(
      service: _ThrowingFirewallService(),
    );
    await provider.load();
    expect(provider.error, isNotNull);
    expect(provider.status, isNull);
  });
}
