import 'package:flutter/foundation.dart';

import '../../../data/models/common_models.dart';
import '../../../data/models/firewall_models.dart';
import '../firewall_service.dart';

class FirewallRuleListProvider extends ChangeNotifier {
  FirewallRuleListProvider({
    this.type,
    this.useFilterApi = false,
    String initialFilterChain = '1PANEL_INPUT',
    FirewallServiceInterface? service,
  })  : _service = service ?? FirewallService(),
        _filterChain = initialFilterChain;

  final FirewallServiceInterface _service;
  final String? type;
  final bool useFilterApi;

  String _filterChain;
  bool _filterChainBound = false;
  String _filterDefaultStrategy = '';

  PageResult<FirewallRule>? _page;
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  int _pageSize = 20;
  String? _lastSearch;
  String? _lastStrategy;
  bool _isMutating = false;

  List<FirewallRule> get items => _page?.items ?? const [];
  bool get isLoading => _loading;
  bool get isMutating => _isMutating;
  String? get error => _error;
  int get total => _page?.total ?? 0;
  bool get hasResults => items.isNotEmpty;
  String get filterChain => _filterChain;
  bool get isFilterChainBound => _filterChainBound;
  String get filterDefaultStrategy => _filterDefaultStrategy;

  Future<void> load({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? strategy,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    _currentPage = page;
    _pageSize = pageSize;
    _lastSearch = search;
    _lastStrategy = strategy;

    try {
      if (useFilterApi) {
        _page = await _service.searchFilterRules(
          page: page,
          pageSize: pageSize,
          type: _filterChain,
          info: search,
        );
        final chainStatus = await _service.loadFilterChainStatus(
          name: _filterChain,
        );
        _filterChainBound = chainStatus.isBind;
        _filterDefaultStrategy = chainStatus.defaultStrategy;
      } else {
        _page = await _service.searchRules(
          page: page,
          pageSize: pageSize,
          type: type,
          info: search,
          strategy: strategy,
        );
      }
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
      strategy: _lastStrategy,
    );
  }

  Future<void> switchFilterChain(String chain) async {
    if (!useFilterApi || _filterChain == chain) {
      return;
    }
    _filterChain = chain;
    await refresh();
  }

  Future<bool> toggleFilterChainBinding(bool bind) async {
    if (!useFilterApi) {
      return false;
    }
    return _runMutation(() async {
      await _service.operateFilterChain(
        operation: FirewallFilterChainOperation(
          name: _filterChain,
          operate: bind ? 'bind' : 'unbind',
        ),
      );
      final chainStatus = await _service.loadFilterChainStatus(
        name: _filterChain,
      );
      _filterChainBound = chainStatus.isBind;
      _filterDefaultStrategy = chainStatus.defaultStrategy;
      await refresh();
    });
  }

  Future<bool> updateDescription(
    FirewallRule rule,
    String description,
  ) async {
    if (useFilterApi) {
      return _runMutation(() async {
        final removeRule = _buildFilterRuleOperation(
          rule,
          operation: 'remove',
        );
        final addRule = _buildFilterRuleOperation(
          rule,
          operation: 'add',
          description: description,
        );
        await _service.batchOperateFilterRules(
          FirewallFilterBatchOperation(rules: [removeRule, addRule]),
        );
        await refresh();
      });
    }

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
    if (useFilterApi) {
      return _runMutation(() async {
        final removeRule = _buildFilterRuleOperation(
          rule,
          operation: 'remove',
        );
        final addRule = _buildFilterRuleOperation(
          rule,
          operation: 'add',
          strategy: nextStrategy,
        );
        await _service.batchOperateFilterRules(
          FirewallFilterBatchOperation(rules: [removeRule, addRule]),
        );
        await refresh();
      });
    }

    final inferredType = type ?? _inferType(rule);
    if (inferredType == 'forward') {
      _error = 'Forward rules do not support strategy toggling.';
      notifyListeners();
      return false;
    }

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
    if (useFilterApi) {
      return _runMutation(() async {
        await _service.batchOperateFilterRules(
          FirewallFilterBatchOperation(
            rules: [
              for (final rule in rules)
                _buildFilterRuleOperation(
                  rule,
                  operation: 'remove',
                ),
            ],
          ),
        );
        await refresh();
      });
    }

    final inferredType =
        type ?? (rules.isNotEmpty ? _inferType(rules.first) : 'port');
    return _runMutation(() async {
      if (inferredType == 'forward') {
        await _service.operateForwardRules(
          FirewallForwardOperateRequest(
            rules: [
              for (final rule in rules) _buildForwardRemoveRule(rule),
            ],
          ),
        );
      } else {
        await _service.deleteRules(
          FirewallBatchRuleRequest(
            type: inferredType,
            rules: [
              for (final rule in rules) _buildRemoveRule(rule, inferredType),
            ],
          ),
        );
      }
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
    if ((rule.targetIP ?? '').isNotEmpty || (rule.targetPort ?? '').isNotEmpty) {
      return 'forward';
    }
    if ((rule.address ?? '').isNotEmpty && (rule.port ?? '').isEmpty) {
      return 'address';
    }
    return 'port';
  }

  FirewallForwardRule _buildForwardRemoveRule(FirewallRule rule) {
    return FirewallForwardRule(
      operation: 'remove',
      protocol: rule.protocol ?? 'tcp',
      port: rule.port ?? '',
      targetPort: rule.targetPort ?? rule.destPort ?? '',
      targetIP: rule.targetIP,
      interface: rule.interface,
    );
  }

  FirewallFilterRuleOperation _buildFilterRuleOperation(
    FirewallRule rule, {
    required String operation,
    String? strategy,
    String? description,
  }) {
    final srcPort = int.tryParse(rule.srcPort ?? '');
    final dstPort = int.tryParse(rule.destPort ?? rule.port ?? '');
    final protocol = (rule.protocol ?? '').trim();
    final chain = (rule.chain ?? '').trim().isEmpty ? _filterChain : rule.chain!;

    return FirewallFilterRuleOperation(
      operation: operation,
      id: rule.id,
      chain: chain,
      protocol: protocol.toLowerCase() == 'all' ? '' : protocol,
      srcIP: _emptyToNull(rule.srcIP ?? rule.address),
      srcPort: srcPort,
      dstIP: _emptyToNull(rule.dstIP ?? rule.destination),
      dstPort: dstPort,
      strategy: strategy ?? (rule.strategy ?? 'accept'),
      description: description ?? rule.description,
    );
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
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
  FirewallRulesProvider({super.service})
      : super(type: null, useFilterApi: true);
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
