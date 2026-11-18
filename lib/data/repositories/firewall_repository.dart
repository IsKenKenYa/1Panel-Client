import 'dart:async';

import 'package:onepanel_client/api/v2/firewall_v2.dart';
import 'package:onepanel_client/api/v2/task_log_v2.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/data/models/firewall_v2_models.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';

/// Firewall repository wrapping the typed V2 API client.
class FirewallRepository {
  const FirewallRepository();

  Future<Map<String, dynamic>?> loadV2SettingsIfSupported(
    FirewallV2Api api,
  ) async {
    try {
      final response = await api.loadFirewallV2Settings();
      final settings = response.data;
      if (settings == null || settings['system'] is! Map) {
        throw const FormatException('Invalid firewall settings response.');
      }
      return settings;
    } on EndpointNotFoundException {
      return null;
    } on HttpException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> createRules(
    FirewallV2Api api,
    TaskLogV2Api taskLogs,
    FirewallRuleCreateRequest request,
  ) async {
    final taskId = await api.createFirewallV2Rules(request);
    await _waitForTask(taskLogs, taskId);
  }

  Future<void> deleteInventoryRules(
    FirewallV2Api api,
    TaskLogV2Api taskLogs,
    List<String> ids, {
    List<FirewallInventoryDeletionTarget>? expectedTargets,
  }) async {
    final settings = await loadV2SettingsIfSupported(api);
    if (settings == null) {
      throw StateError('Firewall inventory is unavailable.');
    }
    final inventory = await _loadRuleInventory(
      api,
      const FirewallRuleSearch(),
      settings,
      all: true,
    );
    final targets = <FirewallInventoryDeletionTarget>[];
    for (final (index, id) in ids.indexed) {
      final matches = inventory.items.where((rule) => rule.inventoryId == id);
      final target = matches.length == 1 ? matches.single.modernTarget : null;
      if (target == null ||
          (expectedTargets != null && expectedTargets[index] != target)) {
        throw StateError(
            'The firewall rule changed. Refresh the list and try again.');
      }
      targets.add(target);
    }
    final managed = targets.where((target) => target.uuid != null).toList();
    if (managed.isNotEmpty && managed.length != targets.length) {
      throw const FormatException('Inconsistent firewall rule inventory.');
    }
    final request = managed.isEmpty
        ? FirewallRuleDeleteRequest(
            targets: [for (final target in targets) target.toJson()])
        : FirewallRuleDeleteRequest.managed(
            [for (final target in managed) target.uuid!]);
    final result = await api.deleteFirewallV2Rules(request);
    final taskId = result['taskID'];
    if (result['queued'] == true && taskId is String && taskId.isNotEmpty) {
      await _waitForTask(taskLogs, taskId);
    } else if (managed.isNotEmpty &&
        result['queued'] != true &&
        result['succeeded'] == targets.length &&
        result['failed'] == 0) {
      return;
    } else {
      final errors = result['errors'];
      if (errors is List && errors.isNotEmpty) {
        throw StateError('Firewall rule deletion failed. $errors');
      }
      throw const FormatException(
        'The firewall deletion could not be confirmed. Refresh the list and check task logs before trying again.',
      );
    }
  }

  Future<void> _waitForTask(TaskLogV2Api taskLogs, String taskId) async {
    final query = TaskLogSearch(taskId: taskId, pageSize: 1);
    const timeout = Duration(minutes: 1);
    const interval = Duration(seconds: 1);
    final elapsed = Stopwatch()..start();
    while (elapsed.elapsed < timeout) {
      final PageResult<TaskLog>? page;
      try {
        final response = await taskLogs
            .searchTaskLogs(query)
            .timeout(timeout - elapsed.elapsed);
        page = response.data;
      } on TimeoutException {
        break;
      } on NetworkException catch (error) {
        throw StateError(
          'Could not read firewall task $taskId. Check task logs before submitting again. ${error.message}',
        );
      }
      final task = page?.items.where((item) => item.id == taskId).firstOrNull;
      switch (task?.status) {
        case 'Success':
          return;
        case 'Failed':
        case 'Canceled':
          final detail = task?.errorMsg?.trim();
          throw StateError(detail != null && detail.isNotEmpty
              ? detail
              : 'Firewall task $taskId ${task?.status}.');
      }
      await Future<void>.delayed(interval);
    }
    throw TimeoutException(
      'Firewall task $taskId is still unconfirmed. Check task logs before submitting again.',
      timeout,
    );
  }

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
    FirewallRuleSearch request, {
    String? serverId,
  }) async {
    final inventory =
        await _searchRuleInventoryIfSupported(api, request, serverId);
    if (inventory != null) return inventory;

    final response = await api.searchFirewallRules(request);
    final body = response.data;
    if (body != null) {
      return body;
    }
    throw StateError('Unexpected firewall rules response');
  }

  Future<FirewallInventoryPageResult?> _searchRuleInventoryIfSupported(
    FirewallV2Api api,
    FirewallRuleSearch request, [
    String? serverId,
  ]) async {
    final settings = await loadV2SettingsIfSupported(api);
    if (settings == null) return null;
    return (await _loadRuleInventory(api, request, settings,
            serverId: serverId))
        .pageFor(request);
  }

  Future<FirewallRuleInventoryResponse> _loadRuleInventory(
    FirewallV2Api api,
    FirewallRuleSearch request,
    Map<String, dynamic> settings, {
    String? serverId,
    bool all = false,
  }) async {
    final provider = (settings['system'] as Map)['selected'];
    if (provider is! String || provider.isEmpty) {
      throw const FormatException('Invalid firewall system provider.');
    }
    final response = await api.searchFirewallRuleInventory(
      FirewallRuleInventoryRequest.forSearch(request,
          provider: provider, all: all),
    );
    final inventory = response.data;
    if (inventory == null) {
      throw const FormatException('Invalid firewall inventory response.');
    }
    return FirewallRuleInventoryResponse.fromJson(inventory,
        serverId: serverId);
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
    FirewallRuleSearch request, {
    String? serverId,
  }) async {
    final inventory =
        await _searchRuleInventoryIfSupported(api, request, serverId);
    if (inventory != null) return inventory;

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
