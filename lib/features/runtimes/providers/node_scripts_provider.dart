import 'package:flutter/material.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/services/node_runtime_service.dart';

class NodeScriptsProvider extends ChangeNotifier with AsyncStateNotifier {
  NodeScriptsProvider({
    NodeRuntimeService? service,
  }) : _service = service ?? NodeRuntimeService();

  final NodeRuntimeService _service;

  int? _runtimeId;
  String _runtimeName = '';
  String _codeDir = '';
  String _packageManager = 'npm';
  List<NodeScriptInfo> _items = const <NodeScriptInfo>[];
  bool _isRunning = false;

  String get runtimeName => _runtimeName;
  String get codeDir => _codeDir;
  String get packageManager => _packageManager;
  List<NodeScriptInfo> get items => _items;
  bool get isRunning => _isRunning;

  Future<void> initialize(RuntimeManageArgs args) async {
    _runtimeId = args.runtimeId;
    _runtimeName = args.runtimeName ?? '';
    _codeDir = args.codeDir?.trim() ?? '';
    _packageManager = (args.packageManager?.trim().isEmpty ?? true)
        ? 'npm'
        : args.packageManager!.trim();
    await load();
  }

  Future<void> load() async {
    if (_codeDir.isEmpty) {
      _items = const <NodeScriptInfo>[];
      setSuccess(isEmpty: true);
      return;
    }
    setLoading();
    try {
      _items = await _service.loadScripts(_codeDir);
      setSuccess(isEmpty: _items.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.node_scripts',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <NodeScriptInfo>[];
      setError('runtime.detail.loadFailed');
    }
  }

  Future<bool> runScript(String scriptName) async {
    final runtimeId = _runtimeId;
    if (runtimeId == null || scriptName.trim().isEmpty) {
      return false;
    }
    _isRunning = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.runScript(
        runtimeId: runtimeId,
        scriptName: scriptName.trim(),
        packageManager: _packageManager,
      );
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.node_scripts',
        'run script failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError('runtime.detail.operateFailed', notify: false);
      return false;
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }
}
