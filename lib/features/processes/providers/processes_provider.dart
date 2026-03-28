import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/process_models.dart';
import 'package:onepanel_client/features/processes/services/process_service.dart';

class ProcessesProvider extends ChangeNotifier with AsyncStateNotifier {
  ProcessesProvider({
    ProcessService? service,
  }) : _service = service ?? ProcessService();

  final ProcessService _service;

  List<ProcessSummary> _items = const <ProcessSummary>[];
  List<ProcessSummary> _rawItems = const <ProcessSummary>[];
  ProcessListQuery _query = const ProcessListQuery();
  List<ListeningProcess> _listening = const <ListeningProcess>[];
  String _sortField = 'cpu';
  bool _descending = true;
  StreamSubscription<List<ProcessSummary>>? _subscription;
  Timer? _pollTimer;
  bool _isMutating = false;

  List<ProcessSummary> get items => _items;
  ProcessListQuery get query => _query;
  String get sortField => _sortField;
  bool get descending => _descending;
  bool get isMutating => _isMutating;

  Future<void> load() async {
    setLoading();
    await _bindStreamIfNeeded();
    try {
      await _refreshListening();
      await _service.connectProcesses(_query);
      _startPolling();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.processes.providers.list',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <ProcessSummary>[];
      _rawItems = const <ProcessSummary>[];
      setError(error);
    }
  }

  Future<void> applyQuery(ProcessListQuery query) async {
    _query = query;
    await load();
  }

  Future<void> refresh() => load();

  void updateSort(String field) {
    if (_sortField == field) {
      _descending = !_descending;
    } else {
      _sortField = field;
      _descending = field == 'cpu' || field == 'memory';
    }
    _rebuildItems();
    notifyListeners();
  }

  Future<bool> stopProcess(ProcessSummary item) async {
    _isMutating = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.stopProcess(item.pid);
      await load();
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.processes.providers.list',
        'stop failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> _bindStreamIfNeeded() async {
    _subscription ??=
        _service.watchProcesses().listen((List<ProcessSummary> data) {
      _rawItems = data;
      _rebuildItems();
      setSuccess(isEmpty: _items.isEmpty, notify: false);
      notifyListeners();
    }, onError: (Object error, StackTrace stackTrace) {
      appLogger.eWithPackage(
        'features.processes.providers.list',
        'stream failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <ProcessSummary>[];
      _rawItems = const <ProcessSummary>[];
      setError(error);
    });
  }

  Future<void> _refreshListening() async {
    _listening = await _service.loadListening();
    _rebuildItems();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _refreshListening();
      await _service.connectProcesses(_query);
    });
  }

  void _rebuildItems() {
    var merged = _service
        .mergeListeningData(_rawItems, _listening)
        .toList(growable: true);
    if (_query.statuses.isNotEmpty) {
      merged = merged
          .where(
            (item) => _query.statuses.any(
              (status) =>
                  item.status.toLowerCase().contains(status.toLowerCase()),
            ),
          )
          .toList(growable: false);
    }

    merged.sort((a, b) {
      final int result;
      switch (_sortField) {
        case 'pid':
          result = a.pid.compareTo(b.pid);
          break;
        case 'name':
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'memory':
          result = a.memoryValue.compareTo(b.memoryValue);
          break;
        case 'cpu':
        default:
          result = a.cpuValue.compareTo(b.cpuValue);
          break;
      }
      return _descending ? -result : result;
    });
    _items = merged;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _subscription?.cancel();
    _service.closeProcesses();
    super.dispose();
  }
}
