import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/features/openresty/services/openresty_service.dart';
import 'package:onepanel_client/shared/security_gateway/models/security_gateway_models.dart';
import 'package:onepanel_client/shared/security_gateway/security_gateway_snapshot_store.dart';

part 'openresty_provider_operations.dart';

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
      await _snapshotStore.ensureInitialized();
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

  Map<String, dynamic> _decodeJsonObject(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON must be an object');
    }
    return decoded;
  }

  String _prettyJson(Object? value) {
    if (value == null) {
      return '';
    }
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  void _emitChange() {
    notifyListeners();
  }

  static const String _httpsScope = 'openresty_https';
  static const String _modulesScope = 'openresty_modules';
  static const String _configScope = 'openresty_config';
}
