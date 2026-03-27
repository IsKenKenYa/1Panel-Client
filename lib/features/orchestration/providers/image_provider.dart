import 'package:flutter/foundation.dart';
import '../../../data/models/docker_models.dart';
import '../../../data/models/container_models.dart'; // For ImagePull
import '../../../data/models/common_models.dart';
import '../services/orchestration_service.dart';

class DockerImageProvider extends ChangeNotifier {
  DockerImageProvider({OrchestrationService? service})
      : _service = service ?? OrchestrationService();

  final OrchestrationService _service;

  List<DockerImage> _images = [];
  bool _isLoading = false;
  String? _error;

  List<DockerImage> get images => _images;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> onServerChanged({bool reload = false}) async {
    _images = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
    if (reload) {
      await loadImages();
    }
  }

  Future<void> loadImages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _images = await _service.loadImages();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> pullImage(String image, {String? tag}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.pullImage(ImagePull(image: image, tag: tag));
      await loadImages();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeImage(String imageId, {bool force = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.removeImage(imageId, force: force);
      await loadImages();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> buildImage(ImageBuild request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.buildImage(request);
      await loadImages();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadImage(ImageLoad request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.loadImage(request);
      await loadImages();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveImage(ImageSave request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.saveImage(request);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> tagImage(ImageTag request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.tagImage(request);
      await loadImages();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> pushImage(ImagePush request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.pushImage(request);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<PageResult<Map<String, dynamic>>> searchImages(String keyword) async {
    try {
      return await _service.searchImages(
        SearchWithPage(info: keyword, page: 1, pageSize: 20),
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return const PageResult(items: [], total: 0);
    }
  }
}
