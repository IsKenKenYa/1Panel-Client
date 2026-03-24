import 'package:flutter/foundation.dart';
import '../../../core/network/api_client_manager.dart';
import '../../../data/models/docker_models.dart';
import '../../../api/v2/docker_v2.dart';
import '../../../data/models/container_models.dart'; // For ImagePull
import '../../../data/models/common_models.dart';

class DockerImageProvider extends ChangeNotifier {
  List<DockerImage> _images = [];
  bool _isLoading = false;
  String? _error;

  List<DockerImage> get images => _images;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<DockerV2Api> _getApi() async {
    return await ApiClientManager.instance.getDockerApi();
  }

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
      final api = await _getApi();
      final response = await api.listImages();
      _images = response.data ?? [];
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
      final api = await _getApi();
      await api.pullImage(ImagePull(image: image, tag: tag));
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
      final api = await _getApi();
      await api.removeImage(imageId, force: force);
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
      final api = await _getApi();
      await api.buildImage(request);
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
      final api = await _getApi();
      await api.loadImage(request);
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
      final api = await _getApi();
      await api.saveImage(request);
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
      final api = await _getApi();
      await api.tagImage(request);
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
      final api = await _getApi();
      await api.pushImage(request);
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
      final api = await _getApi();
      final response = await api.searchImages(
        SearchWithPage(info: keyword, page: 1, pageSize: 20),
      );
      return response.data ?? const PageResult(items: [], total: 0);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return const PageResult(items: [], total: 0);
    }
  }
}
