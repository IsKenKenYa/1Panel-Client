import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/firewall_models.dart';

class FirewallV2Api {
  FirewallV2Api(this._client);

  final DioClient _client;

  Future<Response<FirewallBaseInfo>> loadFirewallBaseInfo({
    String tab = 'base',
  }) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/hosts/firewall/base'),
      data: {'name': tab},
    );
    return Response(
      data: FirewallBaseInfo.fromJson(response.data as Map<String, dynamic>),
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
    return Response(
      data: PageResult.fromJson(
        response.data as Map<String, dynamic>,
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
}
