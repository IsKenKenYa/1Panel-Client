import '../../core/services/base_component.dart';
import '../../api/v2/firewall_v2.dart';
import '../../data/models/common_models.dart';
import '../../data/models/firewall_models.dart';
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
  }) async {
    return runGuarded(() async {
      final api = await _loadApi();
      final request = FirewallRuleSearch(
        page: page,
        pageSize: pageSize,
        type: type,
        strategy: strategy,
        info: info,
      );
      return _repository.searchRules(api, request);
    });
  }

  @override
  Future<PageResult<FirewallRule>> searchFilterRules({
    required int page,
    required int pageSize,
    required String type,
    String? info,
  }) async {
    return runGuarded(() async {
      final api = await _loadApi();
      final request = FirewallRuleSearch(
        page: page,
        pageSize: pageSize,
        type: type,
        info: info,
      );
      return _repository.searchFilterRules(api, request);
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
  Future<void> operateForwardRules(FirewallForwardOperateRequest request) async {
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
      final api = await _loadApi();
      await _repository.operatePortRule(api, payload);
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
      final api = await _loadApi();
      await _repository.operateIpRule(api, payload);
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
  Future<void> deleteRules(FirewallBatchRuleRequest request) async {
    return runGuarded(() async {
      final api = await _loadApi();
      await _repository.batchOperate(api, request);
    });
  }
}
