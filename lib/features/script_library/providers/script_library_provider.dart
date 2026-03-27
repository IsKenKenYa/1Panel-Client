import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/script_library/services/script_library_service.dart';

class ScriptLibraryProvider extends ChangeNotifier with AsyncStateNotifier {
  ScriptLibraryProvider({
    ScriptLibraryService? service,
  }) : _service = service ?? ScriptLibraryService();

  final ScriptLibraryService _service;

  List<ScriptLibraryInfo> _items = const <ScriptLibraryInfo>[];
  List<GroupInfo> _groups = const <GroupInfo>[];
  String _searchQuery = '';
  int? _selectedGroupId;
  bool _isSyncing = false;
  bool _isDeleting = false;
  bool _isRunning = false;
  String _runOutput = '';
  String? _runError;
  StreamSubscription<String>? _runSubscription;
  StreamSubscription<bool>? _runStateSubscription;

  List<ScriptLibraryInfo> get items => _items;
  List<GroupInfo> get groups => _groups;
  String get searchQuery => _searchQuery;
  int? get selectedGroupId => _selectedGroupId;
  bool get isSyncing => _isSyncing;
  bool get isDeleting => _isDeleting;
  bool get isRunning => _isRunning;
  String get runOutput => _runOutput;
  String? get runError => _runError;

  Future<void> load({bool forceRefresh = false}) async {
    setLoading();
    try {
      _groups = await _service.loadGroups(forceRefresh: forceRefresh);
      final result = await _service.searchScripts(
        ScriptLibraryQuery(
          info: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
          groupId: _selectedGroupId,
        ),
      );
      _items = result.items;
      setSuccess(isEmpty: _items.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.script_library.providers.list',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <ScriptLibraryInfo>[];
      setError(error);
    }
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void updateGroupFilter(int? value) {
    _selectedGroupId = value;
    notifyListeners();
  }

  Future<bool> syncScripts() async {
    _isSyncing = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.syncScripts();
      await load(forceRefresh: true);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.script_library.providers.list',
        'sync failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> deleteScript(ScriptLibraryInfo item) async {
    _isDeleting = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.deleteScripts(<int>[item.id]);
      await load(forceRefresh: true);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.script_library.providers.list',
        'delete failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<void> startRun(ScriptLibraryInfo item) async {
    _runOutput = '';
    _runError = null;
    _isRunning = true;
    notifyListeners();
    try {
      await _runSubscription?.cancel();
      await _runStateSubscription?.cancel();
      _runStateSubscription = _service.watchRunState().listen((bool isRunning) {
        _isRunning = isRunning;
        notifyListeners();
      });
      _runSubscription = _service.watchRunOutput().listen(
        (String chunk) {
          _runOutput = '$_runOutput$chunk';
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          appLogger.eWithPackage(
            'features.script_library.providers.list',
            'run stream failed',
            error: error,
            stackTrace: stackTrace,
          );
          _runError = error.toString();
          _isRunning = false;
          notifyListeners();
        },
      );
      await _service.startRun(item.id);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.script_library.providers.list',
        'startRun failed',
        error: error,
        stackTrace: stackTrace,
      );
      _runError = error.toString();
      _isRunning = false;
      notifyListeners();
    }
  }

  Future<void> stopRun() async {
    await _runSubscription?.cancel();
    await _runStateSubscription?.cancel();
    _runSubscription = null;
    _runStateSubscription = null;
    await _service.stopRun();
    _isRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _runSubscription?.cancel();
    _runStateSubscription?.cancel();
    _service.stopRun();
    super.dispose();
  }
}
