import 'package:flutter/foundation.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/docker_models.dart';
import '../../../api/v2/compose_v2.dart';
import '../../../data/models/container_models.dart';

class ComposeProvider extends ChangeNotifier {
  List<ComposeProject> _composes = [];
  bool _isLoading = false;
  String? _error;

  List<ComposeProject> get composes => _composes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<ComposeV2Api> _getApi() async {
    return await ApiClientManager.instance.getComposeApi();
  }

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
      final api = await _getApi();
      final response = await api.listComposes(page: page, pageSize: pageSize);
      if (response.data != null) {
        _composes = response.data!.items;
      } else {
        _composes = [];
      }
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
      final api = await _getApi();
      await api.createCompose(compose);
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
    return _operateCompose(compose, (api, target) => api.upCompose(target));
  }

  Future<bool> downCompose(ComposeProject compose) async {
    return _operateCompose(compose, (api, target) => api.downCompose(target));
  }

  Future<bool> startCompose(ComposeProject compose) async {
    return _operateCompose(compose, (api, target) => api.startCompose(target));
  }

  Future<bool> stopCompose(ComposeProject compose) async {
    return _operateCompose(compose, (api, target) => api.stopCompose(target));
  }

  Future<bool> restartCompose(ComposeProject compose) async {
    return _operateCompose(
        compose, (api, target) => api.restartCompose(target));
  }

  Future<bool> _operateCompose(
    ComposeProject compose,
    Future<void> Function(ComposeV2Api api, ComposeProject compose) operation,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await _getApi();
      await operation(api, compose);
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
      final api = await _getApi();
      await api.updateCompose(request);
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
      final api = await _getApi();
      await api.testCompose(request);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cleanComposeLog(ContainerComposeLogCleanRequest request) async {
    try {
      final api = await _getApi();
      await api.cleanComposeLog(request);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
