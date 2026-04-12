import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/data/models/container_models.dart'
    hide Container;
import 'package:onepanel_client/features/containers/container_service.dart';

import 'package:onepanel_client/core/network/network_exceptions.dart';

class ContainerDetailProvider extends ChangeNotifier with SafeChangeNotifier {
  ContainerDetailProvider({
    required this.container,
    ContainerService? service,
  }) : _service = service ?? ContainerService();

  final ContainerInfo container;
  final ContainerService _service;

  bool _inspectLoading = false;
  bool _logsLoading = false;
  bool _statsLoading = false;

  String? _inspectError;
  String? _logsError;
  String? _statsError;

  String? _inspectData;
  String _logs = '';
  ContainerStats? _stats;

  bool get inspectLoading => _inspectLoading;
  bool get logsLoading => _logsLoading;
  bool get statsLoading => _statsLoading;

  String? get inspectError => _inspectError;
  String? get logsError => _logsError;
  String? get statsError => _statsError;

  String? get inspectData => _inspectData;
  String get logs => _logs;
  ContainerStats? get stats => _stats;

  Future<void> loadAll() async {
    if (isDisposed) return;
    await Future.wait([
      loadInspect(),
      loadLogs(),
      loadStats(),
    ]);
  }

  Future<void> loadInspect() async {
    if (isDisposed) return;
    
    _inspectLoading = true;
    _inspectError = null;
    notifyListeners();

    try {
      _inspectData = await _service.inspectContainer(container.id);
      if (isDisposed) return;
    } catch (e) {
      if (!isDisposed) {
        _inspectError = e.toString();
      }
    } finally {
      if (!isDisposed) {
        _inspectLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadLogs({String tail = '1000'}) async {
    if (isDisposed) return;
    
    _logsLoading = true;
    _logsError = null;
    notifyListeners();

    try {
      _logs = await _service.getContainerLogs(container.name, tail: tail);
      if (isDisposed) return;
    } catch (e) {
      if (!isDisposed) {
        _logsError = e.toString();
      }
    } finally {
      if (!isDisposed) {
        _logsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadStats() async {
    if (isDisposed) return;
    
    _statsLoading = true;
    _statsError = null;
    notifyListeners();

    try {
      _stats = await _service.getContainerStats(container.id);
      if (isDisposed) return;
    } catch (e) {
      if (!isDisposed) {
        if (e is NetworkException) {
          _statsError = e.message;
        } else {
          _statsError = e.toString();
        }
      }
    } finally {
      if (!isDisposed) {
        _statsLoading = false;
        notifyListeners();
      }
    }
  }
}
