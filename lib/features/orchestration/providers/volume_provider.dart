import 'package:flutter/foundation.dart';
import '../../../data/models/docker_models.dart';
import '../../../data/models/container_models.dart';
import '../services/orchestration_service.dart';

class VolumeProvider extends ChangeNotifier {
  VolumeProvider({OrchestrationService? service})
      : _service = service ?? OrchestrationService();

  final OrchestrationService _service;

  List<DockerVolume> _volumes = [];
  bool _isLoading = false;
  String? _error;

  List<DockerVolume> get volumes => _volumes;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      _volumes = await _service.loadVolumes();
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
      await _service.createVolume(request);
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
      await _service.removeVolume(volumeName);
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
