part of 'agents_provider.dart';

extension AgentsProviderAgentActions on AgentsProvider {
  Future<bool> createAgentSimple({
    required String name,
    required String appVersion,
    required int webUIPort,
    required String agentType,
    int? accountId,
    String? model,
    String? token,
  }) async {
    _isMutating = true;
    _error = null;
    _emitChange();

    try {
      final request = AgentCreateReq(
        name: name,
        appVersion: appVersion,
        webUIPort: webUIPort,
        allowedOrigins: agentType == 'openclaw'
            ? <String>['http://127.0.0.1:$webUIPort']
            : null,
        agentType: agentType,
        model: model,
        accountId: accountId,
        token: token,
        taskID: DateTime.now().millisecondsSinceEpoch.toString(),
        advanced: true,
        containerName: '',
        allowPort: true,
        specifyIP: '',
        restartPolicy: 'unless-stopped',
        cpuQuota: 0,
        memoryLimit: 0,
        memoryUnit: 'M',
        pullImage: true,
        editCompose: false,
        dockerCompose: '',
      );
      final created = await _repository.createAgent(request);
      await _loadAgents();
      await selectAgent(created, notifyBeforeLoad: false);
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'create agent failed');
      return false;
    } finally {
      _isMutating = false;
      _emitChange();
    }
  }

  Future<bool> deleteAgent(int id, {bool forceDelete = false}) async {
    _isMutating = true;
    _error = null;
    _emitChange();

    try {
      await _repository.deleteAgent(
        AgentDeleteReq(
          id: id,
          taskID: DateTime.now().millisecondsSinceEpoch.toString(),
          forceDelete: forceDelete,
        ),
      );
      if (_selectedAgent?.id == id) {
        _selectedAgent = null;
      }
      await _loadAgents();
      if (_selectedAgent == null && _agents.isNotEmpty) {
        await selectAgent(_agents.first, notifyBeforeLoad: false);
      }
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'delete agent failed');
      return false;
    } finally {
      _isMutating = false;
      _emitChange();
    }
  }

  Future<void> selectAgent(
    AgentItem agent, {
    bool notifyBeforeLoad = true,
  }) async {
    _selectedAgent = agent;
    _skillSearchResults = const <AgentSkillSearchItem>[];
    if (notifyBeforeLoad) {
      _emitChange();
    }
    await refreshSelectedAgent();
  }

  Future<void> refreshSelectedAgent() async {
    final agentId = _selectedAgent?.id;
    if (agentId == null || agentId <= 0) {
      return;
    }

    _isLoading = true;
    _error = null;
    _emitChange();

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _repository.getAgentOverview(agentId),
        _repository.listSkills(agentId),
        _repository.getSecurityConfig(agentId),
        _repository.getOtherConfig(agentId),
        _repository.getBrowserConfig(agentId),
        _repository.getConfigFile(agentId),
        _repository.getFeishuConfig(agentId),
        _repository.getTelegramConfig(agentId),
        _repository.getDiscordConfig(agentId),
        _repository.getWecomConfig(agentId),
        _repository.getDingTalkConfig(agentId),
        _repository.getQQBotConfig(agentId),
      ]);

      _overview = results[0] as AgentOverview;
      _skills = results[1] as List<AgentSkillItem>;
      _securityConfig = results[2] as AgentSecurityConfig;
      _otherConfig = results[3] as AgentOtherConfig;
      _browserConfig = results[4] as AgentBrowserConfig;
      _configFile = results[5] as AgentConfigFile;

      final feishu = results[6] as AgentFeishuConfig;
      final telegram = results[7] as AgentTelegramConfig;
      final discord = results[8] as AgentDiscordConfig;
      final wecom = results[9] as AgentWecomConfig;
      final dingtalk = results[10] as AgentDingTalkConfig;
      final qqbot = results[11] as AgentQQBotConfig;

      _channels = <String, AgentChannelSnapshot>{
        'feishu': AgentChannelSnapshot(
          key: 'feishu',
          enabled: feishu.enabled,
          policy: feishu.dmPolicy,
        ),
        'telegram': AgentChannelSnapshot(
          key: 'telegram',
          enabled: telegram.enabled,
          policy: telegram.dmPolicy,
        ),
        'discord': AgentChannelSnapshot(
          key: 'discord',
          enabled: discord.enabled,
          policy: discord.dmPolicy,
        ),
        'wecom': AgentChannelSnapshot(
          key: 'wecom',
          enabled: wecom.enabled,
          installed: wecom.installed,
          policy: wecom.dmPolicy,
        ),
        'dingtalk': AgentChannelSnapshot(
          key: 'dingtalk',
          enabled: dingtalk.enabled,
          installed: dingtalk.installed,
          policy: dingtalk.dmPolicy,
        ),
        'qqbot': AgentChannelSnapshot(
          key: 'qqbot',
          enabled: qqbot.enabled,
          installed: qqbot.installed,
        ),
      };
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'load selected agent detail failed');
    } finally {
      _isLoading = false;
      _emitChange();
    }
  }

  Future<bool> updateSkillEnabled(AgentSkillItem item, bool enabled) async {
    final agentId = _selectedAgent?.id;
    if (agentId == null || agentId <= 0) {
      return false;
    }

    try {
      await _repository.updateSkill(
        agentId: agentId,
        name: item.name,
        enabled: enabled,
      );
      _skills = await _repository.listSkills(agentId);
      _emitChange();
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'update skill failed');
      _emitChange();
      return false;
    }
  }

  Future<void> searchSkills({
    required String source,
    required String keyword,
  }) async {
    final agentId = _selectedAgent?.id;
    if (agentId == null || agentId <= 0 || keyword.trim().isEmpty) {
      _skillSearchResults = const <AgentSkillSearchItem>[];
      _emitChange();
      return;
    }

    try {
      _skillSearchResults = await _repository.searchSkills(
        agentId: agentId,
        source: source,
        keyword: keyword.trim(),
      );
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'search skills failed');
    }
    _emitChange();
  }

  Future<bool> installSkill({
    required String source,
    required String slug,
  }) async {
    final agentId = _selectedAgent?.id;
    if (agentId == null || agentId <= 0) {
      return false;
    }

    try {
      await _repository.installSkill(
        agentId: agentId,
        source: source,
        slug: slug,
        taskId: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      await refreshSelectedAgent();
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'install skill failed');
      _emitChange();
      return false;
    }
  }

  Future<bool> saveSecurityOrigins(List<String> allowedOrigins) async {
    final agentId = _selectedAgent?.id;
    if (agentId == null || agentId <= 0) {
      return false;
    }

    try {
      await _repository.updateSecurityConfig(
        agentId: agentId,
        allowedOrigins: allowedOrigins,
      );
      _securityConfig = await _repository.getSecurityConfig(agentId);
      _emitChange();
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'save security config failed');
      _emitChange();
      return false;
    }
  }

  Future<bool> saveOtherConfig({
    required String timezone,
    required bool browserEnabled,
    required String npmRegistry,
  }) async {
    final agentId = _selectedAgent?.id;
    if (agentId == null || agentId <= 0) {
      return false;
    }

    try {
      await _repository.updateOtherConfig(
        agentId: agentId,
        userTimezone: timezone,
        browserEnabled: browserEnabled,
        npmRegistry: npmRegistry,
      );
      _otherConfig = await _repository.getOtherConfig(agentId);
      _emitChange();
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'save other config failed');
      _emitChange();
      return false;
    }
  }

  Future<bool> saveBrowserConfig({
    required bool enabled,
    required bool headless,
    required bool noSandbox,
    required String defaultProfile,
  }) async {
    final agentId = _selectedAgent?.id;
    if (agentId == null || agentId <= 0) {
      return false;
    }

    try {
      await _repository.updateBrowserConfig(
        agentId: agentId,
        enabled: enabled,
        headless: headless,
        noSandbox: noSandbox,
        defaultProfile: defaultProfile,
      );
      _browserConfig = await _repository.getBrowserConfig(agentId);
      _emitChange();
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'save browser config failed');
      _emitChange();
      return false;
    }
  }

  Future<bool> approveFeishuPairing(String pairingCode) async {
    final agentId = _selectedAgent?.id;
    if (agentId == null || agentId <= 0 || pairingCode.trim().isEmpty) {
      return false;
    }

    try {
      await _repository.approveFeishuPairing(
        agentId: agentId,
        pairingCode: pairingCode.trim(),
      );
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'approve feishu pairing failed');
      _emitChange();
      return false;
    }
  }

  Future<bool> saveConfigFile(String content) async {
    final agentId = _selectedAgent?.id;
    if (agentId == null || agentId <= 0) {
      return false;
    }

    try {
      await _repository.updateConfigFile(agentId: agentId, content: content);
      _configFile = await _repository.getConfigFile(agentId);
      _emitChange();
      return true;
    } catch (error, stackTrace) {
      _captureError(error, stackTrace, 'save config file failed');
      _emitChange();
      return false;
    }
  }
}
