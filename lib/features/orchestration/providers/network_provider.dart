import 'package:flutter/foundation.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/docker_models.dart';
import '../../../api/v2/docker_v2.dart';
import '../../../data/models/container_models.dart';

class NetworkProvider extends ChangeNotifier {
  List<DockerNetwork> _networks = [];
  bool _isLoading = false;
  String? _error;

  List<DockerNetwork> get networks => _networks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<DockerV2Api> _getApi() async {
    return await ApiClientManager.instance.getDockerApi();
  }

  Future<void> loadNetworks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await _getApi();
      final response = await api.listNetworks();
      _networks = response.data ?? [];
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
      final api = await _getApi();
      await api.createNetwork(request);
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
      final api = await _getApi();
      await api.removeNetwork(networkId);
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
