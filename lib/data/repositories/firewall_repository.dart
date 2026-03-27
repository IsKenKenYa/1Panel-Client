import 'package:onepanel_client/api/v2/firewall_v2.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';

/// Firewall repository wrapping the typed V2 API client.
class FirewallRepository {
  const FirewallRepository();

  Future<FirewallBaseInfo> loadBaseInfo(
    FirewallV2Api api, {
    String tab = 'base',
  }) async {
    final response = await api.loadFirewallBaseInfo(tab: tab);
    final data = response.data;
    if (data != null) {
      return data;
    }
    throw StateError('Unexpected firewall base response');
  }

  Future<PageResult<FirewallRule>> searchRules(
    FirewallV2Api api,
    FirewallRuleSearch request,
  ) async {
    final response = await api.searchFirewallRules(request);
    final body = response.data;
    if (body != null) {
      return body;
    }
    throw StateError('Unexpected firewall rules response');
  }

  Future<void> operateFirewall(
    FirewallV2Api api,
    FirewallOperation operation,
  ) async {
    await api.operateFirewall(operation);
  }

  Future<void> operatePortRule(
    FirewallV2Api api,
    FirewallPortRulePayload payload,
  ) async {
    await api.operatePort(payload.toJson());
  }

  Future<void> operateIpRule(
    FirewallV2Api api,
    FirewallIpRulePayload payload,
  ) async {
    await api.operateIp(payload.toJson());
  }

  Future<void> updatePortRule(
    FirewallV2Api api,
    FirewallUpdatePortRequest request,
  ) async {
    await api.updatePort(request.toJson());
  }

  Future<void> updateIpRule(
    FirewallV2Api api,
    FirewallUpdateIpRequest request,
  ) async {
    await api.updateAddr(request.toJson());
  }

  Future<void> updateDescription(
    FirewallV2Api api,
    FirewallDescriptionUpdate request,
  ) async {
    await api.updateDescription(request.toJson());
  }

  Future<void> batchOperate(
    FirewallV2Api api,
    FirewallBatchRuleRequest request,
  ) async {
    await api.batchOperate(request.toJson());
  }
}
