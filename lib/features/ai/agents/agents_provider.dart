import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/ai/agent_models.dart';

import 'agents_repository.dart';

part 'agents_provider_agent_actions.dart';
part 'agents_provider_account_actions.dart';

class AgentChannelSnapshot {
  const AgentChannelSnapshot({
    required this.key,
    required this.enabled,
    this.installed = true,
    this.policy = '',
  });

  final String key;
  final bool enabled;
  final bool installed;
  final String policy;
}

class AgentsProvider extends ChangeNotifier {
  AgentsProvider({AgentsRepository? repository})
      : _repository = repository ?? AgentsRepository();

  final AgentsRepository _repository;

  bool _isLoading = false;
  bool _isMutating = false;
  String? _error;

  List<AgentItem> _agents = const <AgentItem>[];
  int _agentTotal = 0;
  String _agentKeyword = '';

  AgentItem? _selectedAgent;
  AgentOverview _overview = const AgentOverview();
  List<AgentSkillItem> _skills = const <AgentSkillItem>[];
  List<AgentSkillSearchItem> _skillSearchResults =
      const <AgentSkillSearchItem>[];
  AgentSecurityConfig _securityConfig = const AgentSecurityConfig();
  AgentOtherConfig _otherConfig = const AgentOtherConfig();
  AgentConfigFile _configFile = const AgentConfigFile();
  Map<String, AgentChannelSnapshot> _channels =
      const <String, AgentChannelSnapshot>{};

  List<ProviderInfo> _providers = const <ProviderInfo>[];
  List<AgentAccountItem> _accounts = const <AgentAccountItem>[];
  int _accountTotal = 0;
  String _accountKeyword = '';
  String _accountProvider = '';

  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get error => _error;

  List<AgentItem> get agents => _agents;
  int get agentTotal => _agentTotal;
  String get agentKeyword => _agentKeyword;

  AgentItem? get selectedAgent => _selectedAgent;
  AgentOverview get overview => _overview;
  List<AgentSkillItem> get skills => _skills;
  List<AgentSkillSearchItem> get skillSearchResults => _skillSearchResults;
  AgentSecurityConfig get securityConfig => _securityConfig;
  AgentOtherConfig get otherConfig => _otherConfig;
  AgentConfigFile get configFile => _configFile;
  Map<String, AgentChannelSnapshot> get channels => _channels;

  List<ProviderInfo> get providers => _providers;
  List<AgentAccountItem> get accounts => _accounts;
  int get accountTotal => _accountTotal;
  String get accountKeyword => _accountKeyword;
  String get accountProvider => _accountProvider;

  Future<void> loadInitial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _providers = await _repository.getAgentProviders();
      await _loadAgents();
      await _loadAccounts();
      if (_agents.isNotEmpty) {
        await selectAgent(_agents.first, notifyBeforeLoad: false);
      }
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.agents_provider',
        'load initial agent data failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    await loadInitial();
  }

  Future<void> searchAgents(String keyword) async {
    _agentKeyword = keyword;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadAgents();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.agents_provider',
        'search agents failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterAccounts({String? provider, String? keyword}) async {
    if (provider != null) {
      _accountProvider = provider;
    }
    if (keyword != null) {
      _accountKeyword = keyword;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadAccounts();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAgents() async {
    final page = await _repository.pageAgents(
      page: 1,
      pageSize: 50,
      keyword: _agentKeyword.trim().isEmpty ? null : _agentKeyword.trim(),
    );
    _agents = page.items;
    _agentTotal = page.total;
  }

  Future<void> _loadAccounts() async {
    final page = await _repository.pageAccounts(
      page: 1,
      pageSize: 100,
      provider: _accountProvider,
      name: _accountKeyword,
    );
    _accounts = page.items;
    _accountTotal = page.total;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _emitChange() {
    notifyListeners();
  }

  void _captureError(
    Object error,
    StackTrace stackTrace,
    String action,
  ) {
    appLogger.eWithPackage(
      'features.ai.agents_provider',
      action,
      error: error,
      stackTrace: stackTrace,
    );
    _error = error.toString();
  }
}
