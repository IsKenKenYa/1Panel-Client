import 'package:flutter/foundation.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/docker_models.dart';
import '../../../api/v2/docker_v2.dart';
import '../../../data/models/container_models.dart';

class VolumeProvider extends ChangeNotifier {
  List<DockerVolume> _volumes = [];
  bool _isLoading = false;
  String? _error;

  List<DockerVolume> get volumes => _volumes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<DockerV2Api> _getApi() async {
    return await ApiClientManager.instance.getDockerApi();
  }

  Future<void> onServerChanged({bool reload = false}) async {
    _volumes = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
    if (reload) {
      await loadVolumes();
    }
  }

  Future<void> loadVolumes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await _getApi();
      final response = await api.listVolumes();
      _volumes = response.data ?? [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createVolume(VolumeCreate request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await _getApi();
      await api.createVolume(request);
      await loadVolumes();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeVolume(String volumeName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final api = await _getApi();
      await api.removeVolume(volumeName);
      await loadVolumes();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
