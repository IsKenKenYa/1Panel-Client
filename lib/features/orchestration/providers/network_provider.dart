import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import '../../../data/models/docker_models.dart';
import '../../../data/models/container_models.dart';
import '../services/orchestration_service.dart';

class NetworkProvider extends ChangeNotifier with SafeChangeNotifier {
  NetworkProvider({OrchestrationService? service})
      : _service = service ?? OrchestrationService();

  final OrchestrationService _service;

  List<DockerNetwork> _networks = [];
  bool _isLoading = false;
  String? _error;

  List<DockerNetwork> get networks => _networks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> onServerChanged({bool reload = false}) async {
    _networks = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
    if (reload) {
      await loadNetworks();
    }
  }

  Future<void> loadNetworks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _networks = await _service.loadNetworks();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createNetwork(NetworkCreate request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.createNetwork(request);
      await loadNetworks();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeNetwork(String networkId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.removeNetwork(networkId);
      await loadNetworks();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
