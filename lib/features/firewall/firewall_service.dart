import '../../core/services/base_component.dart';
import '../../core/config/api_config.dart';
import '../../api/v2/firewall_v2.dart';
import '../../api/v2/task_log_v2.dart';
import '../../data/models/common_models.dart';
import '../../data/models/firewall_models.dart';
import '../../data/models/firewall_v2_models.dart';
import '../../data/repositories/firewall_repository.dart';

abstract class FirewallServiceInterface {
  Future<FirewallBaseInfo> loadBaseInfo({String tab});

  Future<PageResult<FirewallRule>> searchRules({
    required int page,
    required int pageSize,
    String? type,
    String? info,
    String? strategy,
  });

  Future<PageResult<FirewallRule>> searchFilterRules({
    required int page,
    required int pageSize,
    required String type,
    String? info,
    String? strategy,
  });

  Future<FirewallFilterChainStatus> loadFilterChainStatus({
    required String name,
  });

  Future<void> operateFilterChain({
    required FirewallFilterChainOperation operation,
  });

  Future<void> operateFilterRule(FirewallFilterRuleOperation request);

  Future<void> batchOperateFilterRules(FirewallFilterBatchOperation request);

  Future<void> operateForwardRules(FirewallForwardOperateRequest request);

  Future<void> operateFirewall({required FirewallOperation operation});

  Future<void> createPortRule(FirewallPortRulePayload payload);

  Future<void> updatePortRule(FirewallUpdatePortRequest request);

  Future<void> createIpRule(FirewallIpRulePayload payload);

  Future<void> updateIpRule(FirewallUpdateIpRequest request);

  Future<void> updateDescription(FirewallDescriptionUpdate request);

  Future<void> deleteRules(FirewallBatchRuleRequest request);
}

/// Firewall service used by providers.
class FirewallService extends BaseComponent
    implements FirewallServiceInterface {
  FirewallService({
    super.clientManager,
    super.permissionResolver,
    FirewallRepository? repository,
  }) : _repository = repository ?? const FirewallRepository();

  final FirewallRepository _repository;

  Future<FirewallV2Api> _loadApi() async {
    final client = await clientManager.getCurrentClient();
    return FirewallV2Api(client);
  }

  Future<ApiConfig> _requireSelectedConfig([String? expectedServerId]) async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) throw StateError('No API config available');
    if (expectedServerId != null && config.id != expectedServerId) {
      throw StateError(
          'The selected server changed. Reload the firewall rules.');
    }
    return config;
  }

  @override
  Future<FirewallBaseInfo> loadBaseInfo({String tab = 'base'}) async {
    return runGuarded(() async {
      final api = await _loadApi();
      return _repository.loadBaseInfo(api, tab: tab);
    });
  }

  @override
  Future<PageResult<FirewallRule>> searchRules({
    required int page,
    required int pageSize,
    String? type,
    String? info,
    String? strategy,
    String? expectedServerId,
  }) async {
    return runGuarded(() async {
      final config = await _requireSelectedConfig(expectedServerId);
      final api = FirewallV2Api(clientManager.getClientForConfig(config));
      final request = FirewallRuleSearch(
        page: page,
        pageSize: pageSize,
        type: type,
        strategy: strategy,
        info: info,
      );
      return _repository.searchRules(api, request, serverId: config.id);
    });
  }

  @override
  Future<PageResult<FirewallRule>> searchFilterRules({
    required int page,
    required int pageSize,
    required String type,
    String? info,
    String? strategy,
  }) async {
    return runGuarded(() async {
      final config = await _requireSelectedConfig();
      final api = FirewallV2Api(clientManager.getClientForConfig(config));
      final request = FirewallRuleSearch(
        page: page,
        pageSize: pageSize,
        type: type,
        info: info,
        strategy: strategy,
      );
      return _repository.searchFilterRules(api, request, serverId: config.id);
    });
  }

  @override
  Future<FirewallFilterChainStatus> loadFilterChainStatus({
    required String name,
  }) async {
    return runGuarded(() async {
      final api = await _loadApi();
      return _repository.loadFilterChainStatus(api, name);
    });
  }

  @override
  Future<void> operateFilterChain({
    required FirewallFilterChainOperation operation,
  }) async {
    return runGuarded(() async {
      final api = await _loadApi();
      await _repository.operateFilterChain(api, operation);
    });
  }

  @override
  Future<void> operateFilterRule(FirewallFilterRuleOperation request) async {
    return runGuarded(() async {
      final api = await _loadApi();
      await _repository.operateFilterRule(api, request);
    });
  }

  @override
  Future<void> batchOperateFilterRules(
    FirewallFilterBatchOperation request,
  ) async {
    return runGuarded(() async {
      final api = await _loadApi();
      await _repository.batchOperateFilterRules(api, request);
    });
  }

  @override
  Future<void> operateForwardRules(
      FirewallForwardOperateRequest request) async {
    return runGuarded(() async {
      final api = await _loadApi();
      await _repository.operateForwardRules(api, request);
    });
  }

  @override
  Future<void> operateFirewall({required FirewallOperation operation}) async {
    return runGuarded(() async {
      final api = await _loadApi();
      await _repository.operateFirewall(api, operation);
    });
  }

  @override
  Future<void> createPortRule(FirewallPortRulePayload payload) async {
    return runGuarded(() async {
      final request = FirewallRuleCreateRequest.forInboundRule(
        sourceAddress: payload.address,
        destinationPort: payload.port,
        protocol: payload.protocol,
        action: payload.strategy,
        description: payload.description,
      );
      final client = await clientManager.getCurrentClient();
      final api = FirewallV2Api(client);
      if (await _repository.loadV2SettingsIfSupported(api) == null) {
        await _repository.operatePortRule(api, payload);
      } else {
        await _repository.createRules(api, TaskLogV2Api(client), request);
      }
    });
  }

  @override
  Future<void> updatePortRule(FirewallUpdatePortRequest request) async {
    return runGuarded(() async {
      final api = await _loadApi();
      await _repository.updatePortRule(api, request);
    });
  }

  @override
  Future<void> createIpRule(FirewallIpRulePayload payload) async {
    return runGuarded(() async {
      final request = FirewallRuleCreateRequest.forInboundRule(
        sourceAddress: payload.address,
        action: payload.strategy,
        description: payload.description,
      );
      final client = await clientManager.getCurrentClient();
      final api = FirewallV2Api(client);
      if (await _repository.loadV2SettingsIfSupported(api) == null) {
        await _repository.operateIpRule(api, payload);
      } else {
        await _repository.createRules(api, TaskLogV2Api(client), request);
      }
    });
  }

  @override
  Future<void> updateIpRule(FirewallUpdateIpRequest request) async {
    return runGuarded(() async {
      final api = await _loadApi();
      await _repository.updateIpRule(api, request);
    });
  }

  @override
  Future<void> updateDescription(FirewallDescriptionUpdate request) async {
    return runGuarded(() async {
      final api = await _loadApi();
      await _repository.updateDescription(api, request);
    });
  }

  @override
  Future<void> deleteRules(
    FirewallBatchRuleRequest request, {
    String? expectedServerId,
  }) async {
    return runGuarded(() async {
      final config = await _requireSelectedConfig(expectedServerId);
      final api = FirewallV2Api(clientManager.getClientForConfig(config));
      if (await _repository.loadV2SettingsIfSupported(api) != null) {
        throw StateError('Reload the firewall rules before deleting them.');
      }
      await _repository.batchOperate(api, request);
    });
  }

  Future<void> deleteInventoryRules(List<FirewallRule> rules) async {
    if (rules.isEmpty) throw ArgumentError('No firewall rules selected.');
    final serverId = rules.first.serverId;
    final ids = <String>[];
    final targets = <FirewallInventoryDeletionTarget>[];
    for (final rule in rules) {
      final id = rule.inventoryId;
      final target = rule.modernTarget;
      if (serverId == null ||
          rule.serverId != serverId ||
          id == null ||
          target == null) {
        throw StateError('Invalid firewall rule selection.');
      }
      ids.add(id);
      targets.add(target);
    }
    await deleteInventoryRulesById(
      ids,
      serverId: serverId!,
      expectedTargets: targets,
    );
  }

  Future<void> deleteInventoryRulesById(
    List<String> ids, {
    required String serverId,
    List<FirewallInventoryDeletionTarget>? expectedTargets,
  }) async {
    if (serverId.isEmpty ||
        ids.isEmpty ||
        ids.any((id) => id.isEmpty) ||
        ids.toSet().length != ids.length ||
        (expectedTargets != null && expectedTargets.length != ids.length)) {
      throw ArgumentError('Invalid firewall inventory identity.');
    }
    await runGuarded(() async {
      final config = await _requireSelectedConfig(serverId);
      final client = clientManager.getClientForConfig(config);
      await _repository.deleteInventoryRules(
        FirewallV2Api(client),
        TaskLogV2Api(client),
        ids,
        expectedTargets: expectedTargets,
      );
    });
  }
}
