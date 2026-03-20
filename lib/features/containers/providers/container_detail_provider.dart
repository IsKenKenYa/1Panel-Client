import 'package:flutter/foundation.dart';
import 'package:onepanelapp_app/data/models/container_models.dart' hide Container;
import 'package:onepanelapp_app/features/containers/container_service.dart';

class ContainerDetailProvider extends ChangeNotifier {
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
    await Future.wait([
      loadInspect(),
      loadLogs(),
      loadStats(),
    ]);
  }

  Future<void> loadInspect() async {
    _inspectLoading = true;
    _inspectError = null;
    notifyListeners();

    try {
      _inspectData = await _service.inspectContainer(container.id);
    } catch (e) {
      _inspectError = e.toString();
    } finally {
      _inspectLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLogs({String tail = '1000'}) async {
    _logsLoading = true;
    _logsError = null;
    notifyListeners();

    try {
      _logs = await _service.getContainerLogs(container.name, tail: tail);
    } catch (e) {
      _logsError = e.toString();
    } finally {
      _logsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    _statsLoading = true;
    _statsError = null;
    notifyListeners();

    try {
      _stats = await _service.getContainerStats(container.id);
    } catch (e) {
      _statsError = e.toString();
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }
}
