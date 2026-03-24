import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/features/openresty/services/openresty_service.dart';

class OpenRestyProvider extends ChangeNotifier {
  final OpenRestyService _service;

  OpenRestyProvider({OpenRestyService? service}) : _service = service ?? OpenRestyService();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  Map<String, dynamic>? _status;
  Map<String, dynamic>? _modules;
  Map<String, dynamic>? _https;
  String _configContent = '';
  List<OpenrestyParam> _scopeParams = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;
  Map<String, dynamic>? get status => _status;
  Map<String, dynamic>? get modules => _modules;
  Map<String, dynamic>? get https => _https;
  String get configContent => _configContent;
  List<OpenrestyParam> get scopeParams => _scopeParams;

  bool get hasData => _status != null || _modules != null || _https != null || _configContent.isNotEmpty;

  String get statusJson => _prettyJson(_status);
  String get modulesJson => _prettyJson(_modules);
  String get httpsJson => _prettyJson(_https);
  String get scopeParamsJson => _prettyJson(_scopeParams.map((e) => e.toJson()).toList());

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

  Future<void> updateHttpsFromJson(String jsonText) async {
    await _runSavingTask(() async {
      final request = _decodeJsonObject(jsonText);
      await _service.updateHttps(request);
      await loadAll(silent: true);
    });
  }

  Future<void> updateModulesFromJson(String jsonText) async {
    await _runSavingTask(() async {
      final request = _decodeJsonObject(jsonText);
      await _service.updateModules(request);
      await loadAll(silent: true);
    });
  }

  Future<void> updateConfigSource(String content) async {
    await _runSavingTask(() async {
      await _service.updateConfigSource(content);
      _configContent = content;
      notifyListeners();
    });
  }

  Future<void> buildOpenResty({
    required String mirror,
    required String taskId,
  }) async {
    await _service.buildOpenResty(mirror: mirror, taskId: taskId);
  }

  Future<void> loadScope({
    required NginxKey scope,
    int? websiteId,
  }) async {
    try {
      _scopeParams = await _service.loadScope(scope: scope, websiteId: websiteId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> _runSavingTask(Future<void> Function() task) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await task();
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

  String _prettyJson(Object? value) {
    if (value == null) {
      return '';
    }
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}
