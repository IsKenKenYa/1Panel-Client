import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';

/// Firewall repository wrapping raw HTTP requests.
class FirewallRepository {
  const FirewallRepository();

  Future<FirewallBaseInfo> loadBaseInfo(
    DioClient client, {
    String tab = 'base',
  }) async {
    final response = await client.post(
      ApiConstants.buildApiPath('/hosts/firewall/base'),
      data: {'name': tab},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return FirewallBaseInfo.fromJson(data);
    }
    throw StateError('Unexpected firewall base response');
  }

  Future<PageResult<FirewallRule>> searchRules(
    DioClient client,
    FirewallRuleSearch request,
  ) async {
    final response = await client.post(
      ApiConstants.buildApiPath('/hosts/firewall/search'),
      data: request.toJson(),
    );
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return PageResult.fromJson(
        body,
        (json) => FirewallRule.fromJson(json as Map<String, dynamic>),
      );
    }
    throw StateError('Unexpected firewall rules response');
  }

  Future<void> operateFirewall(
    DioClient client,
    FirewallOperation operation,
  ) async {
    await client.post(
      ApiConstants.buildApiPath('/hosts/firewall/operate'),
      data: operation.toJson(),
    );
  }

  Future<void> operatePortRule(
    DioClient client,
    FirewallPortRulePayload payload,
  ) async {
    await client.post(
      ApiConstants.buildApiPath('/hosts/firewall/port'),
      data: payload.toJson(),
    );
  }

  Future<void> operateIpRule(
    DioClient client,
    FirewallIpRulePayload payload,
  ) async {
    await client.post(
      ApiConstants.buildApiPath('/hosts/firewall/ip'),
      data: payload.toJson(),
    );
  }

  Future<void> updatePortRule(
    DioClient client,
    FirewallUpdatePortRequest request,
  ) async {
    await client.post(
      ApiConstants.buildApiPath('/hosts/firewall/update/port'),
      data: request.toJson(),
    );
  }

  Future<void> updateIpRule(
    DioClient client,
    FirewallUpdateIpRequest request,
  ) async {
    await client.post(
      ApiConstants.buildApiPath('/hosts/firewall/update/addr'),
      data: request.toJson(),
    );
  }

  Future<void> updateDescription(
    DioClient client,
    FirewallDescriptionUpdate request,
  ) async {
    await client.post(
      ApiConstants.buildApiPath('/hosts/firewall/update/description'),
      data: request.toJson(),
    );
  }

  Future<void> batchOperate(
    DioClient client,
    FirewallBatchRuleRequest request,
  ) async {
    await client.post(
      ApiConstants.buildApiPath('/hosts/firewall/batch'),
      data: request.toJson(),
    );
  }
}
