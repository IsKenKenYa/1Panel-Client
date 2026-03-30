import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/firewall_models.dart';

class FirewallV2Api {
  FirewallV2Api(this._client);

  final DioClient _client;

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

  Future<Response> operateFirewall(FirewallOperation operation) async {
    return await _client.post(
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

  Future<Response> operatePort(Map<String, dynamic> payload) async {
    return await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/port'),
      data: payload,
    );
  }

  Future<Response> operateIp(Map<String, dynamic> payload) async {
    return await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/ip'),
      data: payload,
    );
  }

  Future<Response> batchOperate(Map<String, dynamic> payload) async {
    return await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/batch'),
      data: payload,
    );
  }

  Future<Response> updateAddr(Map<String, dynamic> payload) async {
    return await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/update/addr'),
      data: payload,
    );
  }

  Future<Response> updateDescription(Map<String, dynamic> payload) async {
    return await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/update/description'),
      data: payload,
    );
  }

  Future<Response> updatePort(Map<String, dynamic> payload) async {
    return await _client.post(
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
      ApiConstants.buildApiPath('/hosts/firewall/filter/search'),
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
}
