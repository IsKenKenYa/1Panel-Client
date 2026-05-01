import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import '../../../data/models/docker_models.dart';
import '../../../data/models/container_models.dart';
import '../services/orchestration_service.dart';

class ComposeProvider extends ChangeNotifier with SafeChangeNotifier {
  ComposeProvider({OrchestrationService? service})
      : _service = service ?? OrchestrationService();

  final OrchestrationService _service;

  List<ComposeProject> _composes = [];
  bool _isLoading = false;
  String? _error;

  List<ComposeProject> get composes => _composes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> onServerChanged({bool reload = false}) async {
    _composes = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
    if (reload) {
      await loadComposes();
    }
  }

  Future<void> loadComposes({int page = 1, int pageSize = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _composes = await _service.loadComposes(page: page, pageSize: pageSize);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCompose(ContainerComposeCreate compose) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createCompose(compose);
      await loadComposes();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> upCompose(ComposeProject compose) async {
    return _operateCompose(compose, _service.upCompose);
  }

  Future<bool> downCompose(ComposeProject compose) async {
    return _operateCompose(compose, _service.downCompose);
  }

  Future<bool> startCompose(ComposeProject compose) async {
    return _operateCompose(compose, _service.startCompose);
  }

  Future<bool> stopCompose(ComposeProject compose) async {
    return _operateCompose(compose, _service.stopCompose);
  }

  Future<bool> restartCompose(ComposeProject compose) async {
    return _operateCompose(compose, _service.restartCompose);
  }

  Future<bool> _operateCompose(
    ComposeProject compose,
    Future<void> Function(ComposeProject compose) operation,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await operation(compose);
      await loadComposes();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCompose(ContainerComposeUpdateRequest request) async {
    try {
      await _service.updateCompose(request);
      await loadComposes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> testCompose(ContainerComposeCreate request) async {
    try {
      await _service.testCompose(request);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cleanComposeLog(ContainerComposeLogCleanRequest request) async {
    try {
      await _service.cleanComposeLog(request);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
