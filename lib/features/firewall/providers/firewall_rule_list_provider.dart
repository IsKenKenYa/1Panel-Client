import 'package:flutter/foundation.dart';

import '../../../data/models/common_models.dart';
import '../../../data/models/firewall_models.dart';
import '../firewall_service.dart';

class FirewallRuleListProvider extends ChangeNotifier {
  FirewallRuleListProvider({
    this.type,
    FirewallServiceInterface? service,
  }) : _service = service ?? FirewallService();

  final FirewallServiceInterface _service;
  final String? type;

  PageResult<FirewallRule>? _page;
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  int _pageSize = 20;
  String? _lastSearch;
  bool _isMutating = false;

  List<FirewallRule> get items => _page?.items ?? const [];
  bool get isLoading => _loading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  int get total => _page?.total ?? 0;
  bool get hasResults => items.isNotEmpty;

  Future<void> load({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    _currentPage = page;
    _pageSize = pageSize;
    _lastSearch = search;

    try {
      _page = await _service.searchRules(
        page: page,
        pageSize: pageSize,
        type: type,
        info: search,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load(
      page: _currentPage,
      pageSize: _pageSize,
      search: _lastSearch,
    );
  }

  Future<bool> updateDescription(
    FirewallRule rule,
    String description,
  ) async {
    return _runMutation(() async {
      await _service.updateDescription(
        FirewallDescriptionUpdate(
          type: type ?? _inferType(rule),
          description: description,
          srcIP: rule.address ?? '',
          dstIP: rule.destination ?? '',
          srcPort: rule.srcPort ?? '',
          dstPort: rule.destPort ?? rule.port ?? '',
          protocol: rule.protocol ?? '',
          strategy: rule.strategy ?? '',
        ),
      );
      await refresh();
    });
  }

  Future<bool> toggleStrategy(
    FirewallRule rule,
    String nextStrategy,
  ) async {
    final inferredType = type ?? _inferType(rule);
    if (inferredType == 'address') {
      return _runMutation(() async {
        await _service.updateIpRule(
          FirewallUpdateIpRequest(
            oldRule: FirewallIpRulePayload(
              operation: 'remove',
              address: rule.address ?? '',
              strategy: rule.strategy ?? '',
              description: rule.description,
            ),
            newRule: FirewallIpRulePayload(
              operation: 'add',
              address: rule.address ?? '',
              strategy: nextStrategy,
              description: rule.description,
            ),
          ),
        );
        await refresh();
      });
    }

    return _runMutation(() async {
      await _service.updatePortRule(
        FirewallUpdatePortRequest(
          oldRule: FirewallPortRulePayload(
            operation: 'remove',
            address: rule.address ?? '',
            port: rule.port ?? '',
            source: '',
            protocol: rule.protocol ?? '',
            strategy: rule.strategy ?? '',
            description: rule.description,
          ),
          newRule: FirewallPortRulePayload(
            operation: 'add',
            address: rule.address ?? '',
            port: rule.port ?? '',
            source: '',
            protocol: rule.protocol ?? '',
            strategy: nextStrategy,
            description: rule.description,
          ),
        ),
      );
      await refresh();
    });
  }

  Future<bool> deleteRules(List<FirewallRule> rules) async {
    final inferredType =
        type ?? (rules.isNotEmpty ? _inferType(rules.first) : 'port');
    return _runMutation(() async {
      await _service.deleteRules(
        FirewallBatchRuleRequest(
          type: inferredType,
          rules: [
            for (final rule in rules) _buildRemoveRule(rule, inferredType),
          ],
        ),
      );
      await refresh();
    });
  }

  Map<String, dynamic> _buildRemoveRule(
      FirewallRule rule, String inferredType) {
    if (inferredType == 'address') {
      return FirewallIpRulePayload(
        operation: 'remove',
        address: rule.address ?? '',
        strategy: rule.strategy ?? '',
        description: rule.description,
      ).toJson();
    }
    return FirewallPortRulePayload(
      operation: 'remove',
      address: rule.address ?? '',
      port: rule.port ?? '',
      source: '',
      protocol: rule.protocol ?? '',
      strategy: rule.strategy ?? '',
      description: rule.description,
    ).toJson();
  }

  String _inferType(FirewallRule rule) {
    if ((rule.address ?? '').isNotEmpty && (rule.port ?? '').isEmpty) {
      return 'address';
    }
    return 'port';
  }

  Future<bool> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}

class FirewallRulesProvider extends FirewallRuleListProvider {
  FirewallRulesProvider({super.service}) : super(type: null);
}

class FirewallIpProvider extends FirewallRuleListProvider {
  FirewallIpProvider({super.service}) : super(type: 'address');
}

class FirewallPortsProvider extends FirewallRuleListProvider {
  FirewallPortsProvider({super.service}) : super(type: 'port');
}

class FirewallRuleFormProvider extends ChangeNotifier {
  FirewallRuleFormProvider({FirewallServiceInterface? service})
      : _service = service ?? FirewallService();

  final FirewallServiceInterface _service;

  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Future<bool> submitPort({
    required FirewallPortRulePayload payload,
    FirewallPortRulePayload? oldRule,
  }) {
    return _run(() async {
      if (oldRule == null) {
        await _service.createPortRule(payload);
      } else {
        await _service.updatePortRule(
          FirewallUpdatePortRequest(oldRule: oldRule, newRule: payload),
        );
      }
    });
  }

  Future<bool> submitIp({
    required FirewallIpRulePayload payload,
    FirewallIpRulePayload? oldRule,
  }) {
    return _run(() async {
      if (oldRule == null) {
        await _service.createIpRule(payload);
      } else {
        await _service.updateIpRule(
          FirewallUpdateIpRequest(oldRule: oldRule, newRule: payload),
        );
      }
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
