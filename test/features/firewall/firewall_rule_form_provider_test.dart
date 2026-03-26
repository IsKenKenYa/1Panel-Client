import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/features/firewall/firewall_service.dart';
import 'package:onepanel_client/features/firewall/providers/firewall_rule_list_provider.dart';

class _FakeFirewallFormService implements FirewallServiceInterface {
  FirewallPortRulePayload? createdPort;
  FirewallIpRulePayload? createdIp;
  FirewallUpdatePortRequest? updatedPort;
  FirewallUpdateIpRequest? updatedIp;

  @override
  Future<void> createIpRule(FirewallIpRulePayload payload) async {
    createdIp = payload;
  }

  @override
  Future<void> createPortRule(FirewallPortRulePayload payload) async {
    createdPort = payload;
  }

  @override
  Future<void> deleteRules(FirewallBatchRuleRequest request) async {}

  @override
  Future<FirewallBaseInfo> loadBaseInfo({String tab = 'base'}) async {
    return const FirewallBaseInfo();
  }

  @override
  Future<void> operateFirewall({required FirewallOperation operation}) async {}

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
  Future<void> updateDescription(FirewallDescriptionUpdate request) async {}

  @override
  Future<void> updateIpRule(FirewallUpdateIpRequest request) async {
    updatedIp = request;
  }

  @override
  Future<void> updatePortRule(FirewallUpdatePortRequest request) async {
    updatedPort = request;
  }
}

void main() {
  test('FirewallRuleFormProvider submits port create', () async {
    final service = _FakeFirewallFormService();
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
    expect(service.createdPort, isNotNull);
  });

  test('FirewallRuleFormProvider submits ip update', () async {
    final service = _FakeFirewallFormService();
    final provider = FirewallRuleFormProvider(service: service);

    final ok = await provider.submitIp(
      payload: const FirewallIpRulePayload(
        operation: 'add',
        address: '1.1.1.1',
        strategy: 'drop',
      ),
      oldRule: const FirewallIpRulePayload(
        operation: 'remove',
        address: '1.1.1.1',
        strategy: 'accept',
      ),
    );

    expect(ok, isTrue);
    expect(service.updatedIp, isNotNull);
    expect(service.updatedIp!.newRule.strategy, 'drop');
  });
}
