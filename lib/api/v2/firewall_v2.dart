import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/firewall_models.dart';
import '../../data/models/firewall_v2_models.dart';

/// 1Panel host firewall API client.
///
/// Manages firewall base info, port/IP rules, filter chains, and forward rules.
class FirewallV2Api {
  FirewallV2Api(this._client);

  final DioClient _client;

  // Server may return either `{data: {…}}` or `{…}` directly; normalize both.
  Map<String, dynamic> _extractMapPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final nested = raw['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return raw;
    }
    return const <String, dynamic>{};
  }

  Future<Response<FirewallBaseInfo>> loadFirewallBaseInfo({
    String tab = 'base',
  }) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/base'),
      data: {'name': tab},
    );
    return Response(
      data: FirewallBaseInfo.fromJson(_extractMapPayload(response.data)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<FirewallRule>>> searchFirewallRules(
    FirewallRuleSearch request,
  ) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/search'),
      data: request.toJson(),
    );
    final payload = _extractMapPayload(response.data);
    return Response(
      data: PageResult.fromJson(
        payload,
        (json) => FirewallRule.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> operateFirewall(FirewallOperation operation) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/operate'),
      data: operation.toJson(),
    );
  }

  Future<Response> startFirewall() async {
    return await operateFirewall(
      const FirewallOperation(operation: 'start'),
    );
  }

  Future<Response> stopFirewall() async {
    return await operateFirewall(
      const FirewallOperation(operation: 'stop'),
    );
  }

  Future<Response> restartFirewall() async {
    return await operateFirewall(
      const FirewallOperation(operation: 'restart'),
    );
  }

  Future<Response<void>> operatePort(Map<String, dynamic> payload) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/port'),
      data: payload,
    );
  }

  Future<Response<void>> operateIp(Map<String, dynamic> payload) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/ip'),
      data: payload,
    );
  }

  Future<Response<void>> batchOperate(Map<String, dynamic> payload) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/batch'),
      data: payload,
    );
  }

  Future<Response<void>> updateAddr(Map<String, dynamic> payload) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/update/addr'),
      data: payload,
    );
  }

  Future<Response<void>> updateDescription(Map<String, dynamic> payload) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/update/description'),
      data: payload,
    );
  }

  Future<Response<void>> updatePort(Map<String, dynamic> payload) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/update/port'),
      data: payload,
    );
  }

  Future<Response<FirewallFilterChainStatus>> loadFilterChainStatus(
    String name,
  ) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/filter/chain/status'),
      data: <String, dynamic>{'name': name},
    );
    return Response(
      data: FirewallFilterChainStatus.fromJson(
        _extractMapPayload(response.data),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<FirewallRule>>> searchFilterRules(
    FirewallRuleSearch request,
  ) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/filter/rule/search'),
      data: request.toJson(),
    );
    final payload = _extractMapPayload(response.data);
    return Response(
      data: PageResult.fromJson(
        payload,
        (json) => FirewallRule.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> operateFilterChain(
    FirewallFilterChainOperation request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/filter/operate'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> operateFilterRule(FirewallFilterRuleOperation request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/filter/rule/operate'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> batchOperateFilterRules(
    FirewallFilterBatchOperation request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/filter/rule/batch'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> operateForwardRules(
    FirewallForwardOperateRequest request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/forward'),
      data: request.toJson(),
    );
  }

  // ==================== Unified firewall v2 (1Panel v2.5.1) ====================

  Map<String, dynamic> _unwrapMap(dynamic raw) {
    final payload = _extractMapPayload(raw);
    return payload;
  }

  Future<Response<Map<String, dynamic>>> loadFirewallV2Settings() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/hosts/firewall/settings'),
    );
    return Response<Map<String, dynamic>>(
      data: _unwrapMap(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> updateFirewallIPv6(
      FirewallIPv6Operation request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/settings/ipv6'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> operateFirewallBackend(
      FirewallBackendOperation request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/settings/operate'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> createFirewallPortWhitelist(
      FirewallPortWhitelistOperation request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/settings/whitelist'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateFirewallPortWhitelist(
      FirewallPortWhitelistUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/settings/whitelist/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteFirewallPortWhitelist(
      FirewallPortWhitelistOperation request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/settings/whitelist/delete'),
      data: request.toJson(),
    );
  }

  Future<Response<Map<String, dynamic>>> loadFirewallRuleBackups(
      String subsystem) async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/hosts/firewall/rules/backups'),
      queryParameters: <String, dynamic>{'subsystem': subsystem},
    );
    return Response<Map<String, dynamic>>(
      data: _unwrapMap(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<Map<String, dynamic>>> searchFirewallRuleInventory(
      FirewallRuleInventoryRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/rules/search'),
      data: request.toJson(),
    );
    return Response<Map<String, dynamic>>(
      data: _unwrapMap(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> createFirewallV2Rules(
      FirewallRuleCreateRequest request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/rules'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteFirewallV2Rules(
      FirewallRuleDeleteRequest request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/rules/delete'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateFirewallV2Rule(
      FirewallRuleUpdateRequest request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/rules/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> reorderFirewallV2Rule(
      FirewallRuleReorderRequest request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/rules/reorder'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> resetFirewallV2Rules(
      FirewallRuleResetRequest request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/rules/reset'),
      data: request.toJson(),
    );
  }

  Future<Response<String>> loadFirewallNativeDetail(
      FirewallNativeDetailRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/rules/native/detail'),
      data: request.toJson(),
    );
    final raw = response.data is Map ? response.data['data'] : response.data;
    return Response<String>(
      data: raw?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<Map<String, dynamic>>> loadFirewallForwardBase() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/forward/base'),
    );
    return Response<Map<String, dynamic>>(
      data: _unwrapMap(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> enableFirewallForwarding(
      FirewallForwardEnableRequest request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/forward/enable'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> operateFirewallForwardRules(
      FirewallForwardOperateV2Request request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/forward/operate'),
      data: request.toJson(),
    );
  }

  Future<Response<Map<String, dynamic>>> searchFirewallForwardRules(
      FirewallForwardSearchRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/forward/search'),
      data: request.toJson(),
    );
    return Response<Map<String, dynamic>>(
      data: _unwrapMap(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<Map<String, dynamic>>> loadFirewallDockerPorts() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/hosts/firewall/docker/ports'),
    );
    return Response<Map<String, dynamic>>(
      data: _unwrapMap(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<dynamic>>> loadFirewallDockerEndpoints() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/hosts/firewall/docker/endpoints'),
    );
    final raw = response.data is Map ? response.data['data'] : response.data;
    return Response<List<dynamic>>(
      data: raw is List ? List<dynamic>.from(raw) : const <dynamic>[],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> operateFirewallDockerGuard(
      FirewallDockerOperation request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/docker/operate'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> batchUpsertFirewallDockerPolicies(
      FirewallDockerPolicyBatch request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/docker/policies/batch'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> batchDeleteFirewallDockerPolicies(
      FirewallDockerPolicyBatchDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath(
          '/hosts/firewall/docker/policies/delete/batch'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> operateFirewallFamily(
      FirewallFamilyOperation request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/firewall/family/operate'),
      data: request.toJson(),
    );
  }
}
