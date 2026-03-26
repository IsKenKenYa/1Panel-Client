import '../../core/services/base_component.dart';
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

  @override
  Future<FirewallBaseInfo> loadBaseInfo({String tab = 'base'}) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      return _repository.loadBaseInfo(client, tab: tab);
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
      final client = await clientManager.getCurrentClient();
      final request = FirewallRuleSearch(
        page: page,
        pageSize: pageSize,
        type: type,
        strategy: strategy,
        info: info,
      );
      return _repository.searchRules(client, request);
    });
  }

  @override
  Future<void> operateFirewall({required FirewallOperation operation}) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      await _repository.operateFirewall(client, operation);
    });
  }

  @override
  Future<void> createPortRule(FirewallPortRulePayload payload) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      await _repository.operatePortRule(client, payload);
    });
  }

  @override
  Future<void> updatePortRule(FirewallUpdatePortRequest request) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      await _repository.updatePortRule(client, request);
    });
  }

  @override
  Future<void> createIpRule(FirewallIpRulePayload payload) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      await _repository.operateIpRule(client, payload);
    });
  }

  @override
  Future<void> updateIpRule(FirewallUpdateIpRequest request) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      await _repository.updateIpRule(client, request);
    });
  }

  @override
  Future<void> updateDescription(FirewallDescriptionUpdate request) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      await _repository.updateDescription(client, request);
    });
  }

  @override
  Future<void> deleteRules(FirewallBatchRuleRequest request) async {
    return runGuarded(() async {
      final client = await clientManager.getCurrentClient();
      await _repository.batchOperate(client, request);
    });
  }
}
