part of 'openresty_provider.dart';

extension OpenRestyProviderOperations on OpenRestyProvider {
  void stageHttpsUpdate({
    required bool httpsEnabled,
    required bool sslRejectHandshake,
  }) {
    final current = _currentHttpsRequest();
    final next = <String, dynamic>{
      'operate': httpsEnabled ? 'enable' : 'disable',
      'sslRejectHandshake': sslRejectHandshake,
    };
    _httpsDraft = ConfigDraftState<Map<String, dynamic>>(
      currentValue: current,
      draftValue: next,
      diffItems: _buildLabeledDiff(
        current: current,
        next: next,
        labels: const <String, String>{
          'operate': 'HTTPS',
          'sslRejectHandshake': 'Reject Handshake',
        },
      ),
      risks: <RiskNotice>[
        if (!httpsEnabled)
          const RiskNotice(
            level: RiskLevel.high,
            title: 'HTTPS disabled',
            message:
                'Disabling HTTPS reduces the default gateway security baseline.',
          ),
        if (sslRejectHandshake)
          const RiskNotice(
            level: RiskLevel.medium,
            title: 'Reject handshake enabled',
            message:
                'This may block clients with invalid TLS negotiation settings.',
          ),
      ],
    );
    _emitChange();
  }

  void discardHttpsDraft() {
    _httpsDraft = null;
    _emitChange();
  }

  Future<bool> applyHttpsDraft() async {
    final draft = _httpsDraft;
    if (draft == null || !draft.hasChanges) {
      return false;
    }
    return _runSavingTask(() async {
      _saveSnapshot(
        scope: OpenRestyProvider._httpsScope,
        title: 'OpenResty HTTPS',
        summary: 'Rollback to the previous successful OpenResty HTTPS config.',
        data: _currentHttpsRequest(),
      );
      await _service.updateHttps(draft.draftValue);
      _httpsDraft = null;
      await loadAll(silent: true);
    });
  }

  Future<bool> rollbackHttps() async {
    final snapshot = _httpsRollbackSnapshot;
    if (snapshot == null || snapshot.data is! Map) {
      return false;
    }
    return _runSavingTask(() async {
      await _service
          .updateHttps(Map<String, dynamic>.from(snapshot.data as Map));
      _httpsDraft = null;
      await loadAll(silent: true);
    });
  }

  void stageModuleUpdate({
    required OpenrestyModule module,
    bool? enable,
    String? packages,
    String? params,
    String? script,
  }) {
    final current = <String, dynamic>{
      'name': module.name,
      'operate': 'update',
      'enable': module.enable,
      'packages': module.packages,
      'params': module.params,
      'script': module.script,
    };
    final next = <String, dynamic>{
      'name': module.name,
      'operate': 'update',
      'enable': enable ?? module.enable,
      'packages': packages ?? module.packages,
      'params': params ?? module.params,
      'script': script ?? module.script,
    };

    final risks = <RiskNotice>[];
    if ((enable ?? module.enable) == false) {
      risks.add(
        RiskNotice(
          level: RiskLevel.medium,
          title: 'Module disabled',
          message:
              'Disabling ${module.name ?? 'this module'} may change gateway behavior immediately.',
        ),
      );
    }
    if ((packages ?? module.packages) != module.packages ||
        (script ?? module.script) != module.script) {
      risks.add(
        RiskNotice(
          level: RiskLevel.high,
          title: 'Dependency change',
          message:
              'Package or script changes can introduce dependency conflicts for ${module.name ?? 'this module'}.',
        ),
      );
    }

    _moduleDraft = ConfigDraftState<Map<String, dynamic>>(
      currentValue: current,
      draftValue: next,
      diffItems: _buildLabeledDiff(
        current: current,
        next: next,
        labels: const <String, String>{
          'enable': 'Enabled',
          'packages': 'Packages',
          'params': 'Params',
          'script': 'Script',
        },
      ),
      risks: risks,
    );
    _emitChange();
  }

  void discardModuleDraft() {
    _moduleDraft = null;
    _emitChange();
  }

  Future<bool> applyModuleDraft() async {
    final draft = _moduleDraft;
    if (draft == null || !draft.hasChanges) {
      return false;
    }
    return _runSavingTask(() async {
      final currentModule =
          _findModuleByName(draft.draftValue['name']?.toString());
      if (currentModule != null) {
        _saveSnapshot(
          scope: OpenRestyProvider._modulesScope,
          title: 'OpenResty Module',
          summary: 'Rollback to the previous successful module config.',
          data: <String, dynamic>{
            'name': currentModule.name,
            'operate': 'update',
            'enable': currentModule.enable,
            'packages': currentModule.packages,
            'params': currentModule.params,
            'script': currentModule.script,
          },
        );
      }
      await _service.updateModules(draft.draftValue);
      _moduleDraft = null;
      await loadAll(silent: true);
    });
  }

  Future<bool> rollbackModules() async {
    final snapshot = _moduleRollbackSnapshot;
    if (snapshot == null || snapshot.data is! Map) {
      return false;
    }
    return _runSavingTask(() async {
      await _service
          .updateModules(Map<String, dynamic>.from(snapshot.data as Map));
      _moduleDraft = null;
      await loadAll(silent: true);
    });
  }

  void stageConfigUpdate(String content) {
    _configDraft = ConfigDraftState<String>(
      currentValue: _configContent,
      draftValue: content,
      diffItems: _configContent == content
          ? const <ConfigDiffItem>[]
          : <ConfigDiffItem>[
              ConfigDiffItem(
                field: 'content',
                label: 'Config Source',
                currentValue: '${_configContent.split('\n').length} lines',
                nextValue: '${content.split('\n').length} lines',
              ),
            ],
      risks: _detectConfigContentRisks(content),
    );
    _emitChange();
  }

  void discardConfigDraft() {
    _configDraft = null;
    _emitChange();
  }

  Future<bool> applyConfigDraft() async {
    final draft = _configDraft;
    if (draft == null || !draft.hasChanges) {
      return false;
    }
    return _runSavingTask(() async {
      _saveSnapshot(
        scope: OpenRestyProvider._configScope,
        title: 'OpenResty Config',
        summary: 'Rollback to the previous successful source config.',
        data: _configContent,
      );
      await _service.updateConfigSource(draft.draftValue);
      _configContent = draft.draftValue;
      _configDraft = null;
      _configRollbackSnapshot =
          _snapshotStore.read(OpenRestyProvider._configScope);
      _emitChange();
    });
  }

  Future<bool> rollbackConfig() async {
    final snapshot = _configRollbackSnapshot;
    if (snapshot == null || snapshot.data is! String) {
      return false;
    }
    return _runSavingTask(() async {
      final content = snapshot.data as String;
      await _service.updateConfigSource(content);
      _configContent = content;
      _configDraft = null;
      _emitChange();
    });
  }

  Future<void> updateHttpsFromJson(String jsonText) async {
    final request = _decodeJsonObject(jsonText);
    stageHttpsUpdate(
      httpsEnabled: request['operate'] == 'enable',
      sslRejectHandshake: request['sslRejectHandshake'] == true,
    );
    await applyHttpsDraft();
  }

  Future<void> updateModulesFromJson(String jsonText) async {
    final request = _decodeJsonObject(jsonText);
    final module = _findModuleByName(request['name']?.toString());
    if (module == null) {
      throw StateError('Module not found');
    }
    stageModuleUpdate(
      module: module,
      enable: request['enable'] as bool?,
      packages: request['packages']?.toString(),
      params: request['params']?.toString(),
      script: request['script']?.toString(),
    );
    await applyModuleDraft();
  }

  Future<void> updateConfigSource(String content) async {
    stageConfigUpdate(content);
    await applyConfigDraft();
  }

  Future<bool> _runSavingTask(Future<void> Function() task) async {
    _isSaving = true;
    _error = null;
    _emitChange();
    try {
      await task();
      return true;
    } catch (e) {
      _error = e.toString();
      _emitChange();
      return false;
    } finally {
      _isSaving = false;
      _emitChange();
    }
  }

  Map<String, dynamic> _currentHttpsRequest() {
    return <String, dynamic>{
      'operate': httpsEnabled ? 'enable' : 'disable',
      'sslRejectHandshake': _https?['sslRejectHandshake'] == true,
    };
  }

  OpenrestyModule? _findModuleByName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }
    for (final module in moduleList) {
      if (module.name == name) {
        return module;
      }
    }
    return null;
  }

  void _saveSnapshot({
    required String scope,
    required String title,
    required String summary,
    required Object data,
  }) {
    _snapshotStore.save(
      ConfigRollbackSnapshot<Object>(
        scope: scope,
        title: title,
        summary: summary,
        data: data,
        createdAt: DateTime.now(),
      ),
    );
    _httpsRollbackSnapshot = _snapshotStore.read(OpenRestyProvider._httpsScope);
    _moduleRollbackSnapshot =
        _snapshotStore.read(OpenRestyProvider._modulesScope);
    _configRollbackSnapshot =
        _snapshotStore.read(OpenRestyProvider._configScope);
  }

  List<RiskNotice> _detectConfigContentRisks(String content) {
    final notices = <RiskNotice>[];
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.high,
          title: 'Empty config',
          message:
              'Saving an empty config will break the current gateway setup.',
        ),
      );
      return notices;
    }
    final openBraces = '{'.allMatches(content).length;
    final closeBraces = '}'.allMatches(content).length;
    if (openBraces != closeBraces) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.high,
          title: 'Brace mismatch',
          message:
              'The config appears to have unmatched braces. Validate before saving.',
        ),
      );
    }
    if (!content.contains('http')) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.medium,
          title: 'Missing http block',
          message: 'No http block was detected in the config source.',
        ),
      );
    }
    if (content.contains('TODO') || content.contains('FIXME')) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.low,
          title: 'Temporary markers found',
          message: 'The config still contains TODO or FIXME markers.',
        ),
      );
    }
    return notices;
  }

  List<ConfigDiffItem> _buildLabeledDiff({
    required Map<String, Object?> current,
    required Map<String, Object?> next,
    required Map<String, String> labels,
  }) {
    final items = <ConfigDiffItem>[];
    for (final entry in labels.entries) {
      final before = _stringifyValue(current[entry.key]);
      final after = _stringifyValue(next[entry.key]);
      if (before == after) {
        continue;
      }
      items.add(
        ConfigDiffItem(
          field: entry.key,
          label: entry.value,
          currentValue: before,
          nextValue: after,
        ),
      );
    }
    return items;
  }

  String _stringifyValue(Object? value) {
    if (value == null) {
      return '-';
    }
    if (value is bool) {
      return value ? 'Enabled' : 'Disabled';
    }
    if (value is List) {
      if (value.isEmpty) {
        return '-';
      }
      return value.join(', ');
    }
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }
}
