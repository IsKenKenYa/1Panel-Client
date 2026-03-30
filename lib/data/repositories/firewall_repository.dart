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

  Future<FirewallFilterChainStatus> loadFilterChainStatus(
    FirewallV2Api api,
    String name,
  ) async {
    final response = await api.loadFilterChainStatus(name);
    final data = response.data;
    if (data != null) {
      return data;
    }
    throw StateError('Unexpected firewall filter chain status response');
  }

  Future<PageResult<FirewallRule>> searchFilterRules(
    FirewallV2Api api,
    FirewallRuleSearch request,
  ) async {
    final response = await api.searchFilterRules(request);
    final body = response.data;
    if (body != null) {
      return body;
    }
    throw StateError('Unexpected firewall filter rules response');
  }

  Future<void> operateFilterChain(
    FirewallV2Api api,
    FirewallFilterChainOperation request,
  ) async {
    await api.operateFilterChain(request);
  }

  Future<void> operateFilterRule(
    FirewallV2Api api,
    FirewallFilterRuleOperation request,
  ) async {
    await api.operateFilterRule(request);
  }

  Future<void> batchOperateFilterRules(
    FirewallV2Api api,
    FirewallFilterBatchOperation request,
  ) async {
    await api.batchOperateFilterRules(request);
  }

  Future<void> operateForwardRules(
    FirewallV2Api api,
    FirewallForwardOperateRequest request,
  ) async {
    await api.operateForwardRules(request);
  }
}
