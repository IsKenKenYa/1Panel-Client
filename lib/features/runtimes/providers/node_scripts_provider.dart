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
  String _activeScriptName = '';
  String _executionStatus = '';
  String? _executionMessage;
  bool? _lastRunSuccess;
  bool _lastRunTimedOut = false;
  int _pollAttempts = 0;
  String? _runErrorMessage;

  String get runtimeName => _runtimeName;
  String get codeDir => _codeDir;
  String get packageManager => _packageManager;
  List<NodeScriptInfo> get items => _items;
  bool get isRunning => _isRunning;
  String get activeScriptName => _activeScriptName;
  String get executionStatus => _executionStatus;
  String? get executionMessage => _executionMessage;
  bool? get lastRunSuccess => _lastRunSuccess;
  bool get lastRunTimedOut => _lastRunTimedOut;
  int get pollAttempts => _pollAttempts;
  String? get runErrorMessage => _runErrorMessage;
  bool get hasExecutionFeedback =>
      _activeScriptName.isNotEmpty && _lastRunSuccess != null;

  Future<void> initialize(RuntimeManageArgs args) async {
    _runtimeId = args.runtimeId;
    _runtimeName = args.runtimeName ?? '';
    _codeDir = args.codeDir?.trim() ?? '';
    _packageManager = (args.packageManager?.trim().isEmpty ?? true)
        ? 'npm'
        : args.packageManager!.trim();
    _resetRunFeedback(notify: false);
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
    final normalizedName = scriptName.trim();
    if (runtimeId == null || normalizedName.isEmpty) {
      return false;
    }
    _isRunning = true;
    _activeScriptName = normalizedName;
    _executionStatus = 'Starting';
    _executionMessage = null;
    _lastRunSuccess = null;
    _lastRunTimedOut = false;
    _pollAttempts = 0;
    _runErrorMessage = null;
    notifyListeners();
    try {
      final feedback = await _service.runScript(
        runtimeId: runtimeId,
        scriptName: normalizedName,
        packageManager: _packageManager,
      );

      _executionStatus = feedback.status;
      _executionMessage = feedback.message?.trim().isNotEmpty == true
          ? feedback.message!.trim()
          : null;
      _lastRunSuccess = feedback.isSuccess;
      _lastRunTimedOut = feedback.timedOut;
      _pollAttempts = feedback.attempts;
      if (feedback.timedOut) {
        _runErrorMessage = 'runtime.nodeScript.waitTimeout';
      }
      return feedback.isSuccess;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.runtimes.providers.node_scripts',
        'run script failed',
        error: error,
        stackTrace: stackTrace,
      );
      _executionStatus = 'Error';
      _executionMessage = null;
      _lastRunSuccess = false;
      _lastRunTimedOut = false;
      _pollAttempts = 0;
      _runErrorMessage = 'runtime.detail.operateFailed';
      return false;
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  void _resetRunFeedback({bool notify = true}) {
    _activeScriptName = '';
    _executionStatus = '';
    _executionMessage = null;
    _lastRunSuccess = null;
    _lastRunTimedOut = false;
    _pollAttempts = 0;
    _runErrorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }
}
