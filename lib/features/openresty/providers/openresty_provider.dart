import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/features/openresty/services/openresty_service.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/security_gateway_snapshot_store.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';

class OpenRestyProvider extends ChangeNotifier {
  OpenRestyProvider({
    OpenRestyService? service,
    SecurityGatewaySnapshotStore? snapshotStore,
  })  : _service = service ?? OpenRestyService(),
        _snapshotStore = snapshotStore ?? SecurityGatewaySnapshotStore.instance;

  final OpenRestyService _service;
  final SecurityGatewaySnapshotStore _snapshotStore;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  Map<String, dynamic>? _status;
  Map<String, dynamic>? _modules;
  Map<String, dynamic>? _https;
  String _configContent = '';
  List<OpenrestyParam> _scopeParams = const [];
  String? _lastBuildMessage;

  ConfigDraftState<Map<String, dynamic>>? _httpsDraft;
  ConfigDraftState<Map<String, dynamic>>? _moduleDraft;
  ConfigDraftState<String>? _configDraft;
  ConfigRollbackSnapshot<Object>? _httpsRollbackSnapshot;
  ConfigRollbackSnapshot<Object>? _moduleRollbackSnapshot;
  ConfigRollbackSnapshot<Object>? _configRollbackSnapshot;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  Map<String, dynamic>? get status => _status;
  Map<String, dynamic>? get modules => _modules;
  Map<String, dynamic>? get https => _https;
  String get configContent => _configContent;
  List<OpenrestyParam> get scopeParams => _scopeParams;
  String? get lastBuildMessage => _lastBuildMessage;
  ConfigDraftState<Map<String, dynamic>>? get httpsDraft => _httpsDraft;
  ConfigDraftState<Map<String, dynamic>>? get moduleDraft => _moduleDraft;
  ConfigDraftState<String>? get configDraft => _configDraft;
  ConfigRollbackSnapshot<Object>? get httpsRollbackSnapshot =>
      _httpsRollbackSnapshot;
  ConfigRollbackSnapshot<Object>? get moduleRollbackSnapshot =>
      _moduleRollbackSnapshot;
  ConfigRollbackSnapshot<Object>? get configRollbackSnapshot =>
      _configRollbackSnapshot;

  bool get hasData =>
      _status != null ||
      _modules != null ||
      _https != null ||
      _configContent.isNotEmpty;
  bool get isRunning => ((_status?['active'] as num?)?.toInt() ?? 0) > 0;
  bool get httpsEnabled => _https?['https'] == true;

  String get statusJson => _prettyJson(_status);
  String get modulesJson => _prettyJson(_modules);
  String get httpsJson => _prettyJson(_https);
  String get scopeParamsJson =>
      _prettyJson(_scopeParams.map((e) => e.toJson()).toList());
  String get statusSummary => isRunning
      ? 'Running · active ${(_status?['active'] as num?)?.toInt() ?? 0}'
      : 'Not running';
  String get httpsSummary => httpsEnabled ? 'HTTPS enabled' : 'HTTPS disabled';
  String get modulesSummary =>
      '${moduleList.where((module) => module.enable == true).length}/${moduleList.length} modules enabled';
  String get buildSummary =>
      _modules?['mirror']?.toString() ?? 'No mirror configured';
  String get configSummary => _configContent.trim().isEmpty
      ? 'Config not loaded'
      : '${_configContent.split('\n').length} lines loaded';

  List<OpenrestyModule> get moduleList {
    final rawModules = _modules?['modules'];
    if (rawModules is! List) {
      return const <OpenrestyModule>[];
    }
    return rawModules
        .whereType<Map<String, dynamic>>()
        .map(OpenrestyModule.fromJson)
        .toList(growable: false);
  }

  List<RiskNotice> get riskNotices {
    final notices = <RiskNotice>[];
    if (!isRunning) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.high,
          title: 'Gateway inactive',
          message: 'OpenResty is not reporting active connections.',
        ),
      );
    }
    if (!httpsEnabled) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.medium,
          title: 'HTTPS disabled',
          message: 'Default HTTPS is currently disabled for the gateway.',
        ),
      );
    }
    if (moduleList.isEmpty) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.medium,
          title: 'No modules loaded',
          message:
              'OpenResty modules are empty. Review build and module config.',
        ),
      );
    }
    if ((_modules?['mirror']?.toString().trim().isEmpty ?? true)) {
      notices.add(
        const RiskNotice(
          level: RiskLevel.low,
          title: 'Build mirror missing',
          message:
              'No build mirror is configured. Build speed may be affected.',
        ),
      );
    }
    notices.addAll(_httpsDraft?.risks ?? const <RiskNotice>[]);
    notices.addAll(_moduleDraft?.risks ?? const <RiskNotice>[]);
    notices.addAll(_configDraft?.risks ?? const <RiskNotice>[]);
    return notices;
  }

  Future<void> loadAll({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final snapshot = await _service.loadSnapshot();
      _status = snapshot.status;
      _modules = snapshot.modules;
      _https = snapshot.https;
      _configContent = snapshot.configContent;
      _httpsRollbackSnapshot = _snapshotStore.read(_httpsScope);
      _moduleRollbackSnapshot = _snapshotStore.read(_modulesScope);
      _configRollbackSnapshot = _snapshotStore.read(_configScope);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadAll();
  }

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
      diffItems: buildLabeledDiff(
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
    notifyListeners();
  }

  void discardHttpsDraft() {
    _httpsDraft = null;
    notifyListeners();
  }

  Future<bool> applyHttpsDraft() async {
    final draft = _httpsDraft;
    if (draft == null || !draft.hasChanges) {
      return false;
    }
    return _runSavingTask(() async {
      _saveSnapshot(
        scope: _httpsScope,
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
      diffItems: buildLabeledDiff(
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
    notifyListeners();
  }

  void discardModuleDraft() {
    _moduleDraft = null;
    notifyListeners();
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
          scope: _modulesScope,
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
      risks: detectConfigContentRisks(content),
    );
    notifyListeners();
  }

  void discardConfigDraft() {
    _configDraft = null;
    notifyListeners();
  }

  Future<bool> applyConfigDraft() async {
    final draft = _configDraft;
    if (draft == null || !draft.hasChanges) {
      return false;
    }
    return _runSavingTask(() async {
      _saveSnapshot(
        scope: _configScope,
        title: 'OpenResty Config',
        summary: 'Rollback to the previous successful source config.',
        data: _configContent,
      );
      await _service.updateConfigSource(draft.draftValue);
      _configContent = draft.draftValue;
      _configDraft = null;
      _configRollbackSnapshot = _snapshotStore.read(_configScope);
      notifyListeners();
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
      notifyListeners();
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

  Future<void> buildOpenResty({
    required String mirror,
    required String taskId,
  }) async {
    await _service.buildOpenResty(mirror: mirror, taskId: taskId);
    _lastBuildMessage =
        'Build submitted${mirror.trim().isEmpty ? '' : ' with mirror $mirror'}.';
    notifyListeners();
  }

  Future<void> loadScope({
    required NginxKey scope,
    int? websiteId,
  }) async {
    try {
      _scopeParams =
          await _service.loadScope(scope: scope, websiteId: websiteId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<bool> _runSavingTask(Future<void> Function() task) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await task();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _decodeJsonObject(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON must be an object');
    }
    return decoded;
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
    _httpsRollbackSnapshot = _snapshotStore.read(_httpsScope);
    _moduleRollbackSnapshot = _snapshotStore.read(_modulesScope);
    _configRollbackSnapshot = _snapshotStore.read(_configScope);
  }

  String _prettyJson(Object? value) {
    if (value == null) {
      return '';
    }
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  static const String _httpsScope = 'openresty_https';
  static const String _modulesScope = 'openresty_modules';
  static const String _configScope = 'openresty_config';
}
