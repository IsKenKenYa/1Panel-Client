import 'package:flutter/foundation.dart';
import 'package:onepanelapp_app/core/services/logger/logger_service.dart';
import '../../data/models/container_models.dart';
import '../../data/models/container_extension_models.dart';
import 'container_service.dart';

/// 容器统计数据
class ContainerStats {
  final int total;
  final int running;
  final int stopped;
  final int paused;

  const ContainerStats({
    this.total = 0,
    this.running = 0,
    this.stopped = 0,
    this.paused = 0,
  });
}

/// 镜像统计数据
class ImageStats {
  final int total;
  final int used;
  final int unused;

  const ImageStats({
    this.total = 0,
    this.used = 0,
    this.unused = 0,
  });
}

/// 容器数据状态
class ContainersData {
  final List<ContainerInfo> containers;
  final List<ContainerImage> images;
  final List<ContainerRepo> repos;
  final List<ContainerTemplate> templates;
  final String daemonJson;
  final ContainerStatus? status;
  final ContainerStats containerStats;
  final ImageStats imageStats;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ContainersData({
    this.containers = const [],
    this.images = const [],
    this.repos = const [],
    this.templates = const [],
    this.daemonJson = '',
    this.status,
    this.containerStats = const ContainerStats(),
    this.imageStats = const ImageStats(),
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ContainersData copyWith({
    List<ContainerInfo>? containers,
    List<ContainerImage>? images,
    List<ContainerRepo>? repos,
    List<ContainerTemplate>? templates,
    String? daemonJson,
    ContainerStatus? status,
    ContainerStats? containerStats,
    ImageStats? imageStats,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ContainersData(
      containers: containers ?? this.containers,
      images: images ?? this.images,
      repos: repos ?? this.repos,
      templates: templates ?? this.templates,
      daemonJson: daemonJson ?? this.daemonJson,
      status: status ?? this.status,
      containerStats: containerStats ?? this.containerStats,
      imageStats: imageStats ?? this.imageStats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// 容器管理状态管理器
class ContainersProvider extends ChangeNotifier {
  ContainersProvider({ContainerService? service}) : _service = service;

  ContainerService? _service;

  ContainersData _data = const ContainersData();

  ContainersData get data => _data;

  Future<void> _ensureService() async {
    _service ??= ContainerService();
  }

  /// 加载容器数据
  Future<void> loadContainers() async {
    _data = _data.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      await _ensureService();

      final containers = await _service!.listContainers();

      // 计算统计
      int running = 0, stopped = 0, paused = 0;
      for (final container in containers) {
        switch (container.state.toLowerCase()) {
          case 'running':
            running++;
            break;
          case 'exited':
          case 'stopped':
            stopped++;
            break;
          case 'paused':
            paused++;
            break;
        }
      }

      _data = _data.copyWith(
        containers: containers,
        containerStats: ContainerStats(
          total: containers.length,
          running: running,
          stopped: stopped,
          paused: paused,
        ),
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _data = _data.copyWith(
        isLoading: false,
        error: '加载容器失败: $e',
      );
    }
    notifyListeners();
  }

  /// 加载镜像数据
  Future<void> loadImages() async {
    _data = _data.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      await _ensureService();

      final images = await _service!.listImages();

      // 计算统计（简化处理，实际应该根据是否被使用来判断）
      _data = _data.copyWith(
        images: images,
        imageStats: ImageStats(
          total: images.length,
          used: images.length, // 简化处理
          unused: 0,
        ),
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _data = _data.copyWith(
        isLoading: false,
        error: '加载镜像失败: $e',
      );
    }
    notifyListeners();
  }

  /// 加载所有数据
  Future<void> loadAll() async {
    _data = _data.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      await _ensureService();

      // 并行加载所有数据
      final results = await Future.wait([
        _service!.listContainers(),
        _service!.listImages(),
        _service!.listRepos(),
        _service!.listTemplates(),
        _service!.getContainerStatus(),
        _service!.getDaemonJson(),
      ]);

      final containers = results[0] as List<ContainerInfo>;
      final images = results[1] as List<ContainerImage>;
      final repos = results[2] as List<ContainerRepo>;
      final templates = results[3] as List<ContainerTemplate>;
      final status = results[4] as ContainerStatus;
      final daemonJson = results[5] as String;

      // 计算统计
      int running = 0, stopped = 0, paused = 0;
      for (final container in containers) {
        switch (container.state.toLowerCase()) {
          case 'running':
            running++;
            break;
          case 'exited':
          case 'stopped':
            stopped++;
            break;
          case 'paused':
            paused++;
            break;
        }
      }

      _data = _data.copyWith(
        containers: containers,
        images: images,
        repos: repos,
        templates: templates,
        daemonJson: daemonJson,
        status: status,
        containerStats: ContainerStats(
          total: containers.length,
          running: running,
          stopped: stopped,
          paused: paused,
        ),
        imageStats: ImageStats(
          total: images.length,
          used: images.length,
          unused: 0,
        ),
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _data = _data.copyWith(
        isLoading: false,
        error: '加载数据失败: $e',
      );
    }
    notifyListeners();
  }

  /// 加载配置
  Future<void> loadConfig() async {
    try {
      await _ensureService();
      final config = await _service!.getDaemonJson();
      _data = _data.copyWith(daemonJson: config);
      notifyListeners();
    } catch (e) {
      // 忽略配置加载错误，避免阻断其他功能
      appLogger.wWithPackage(
        'features.containers.containers_provider',
        'Load config failed',
        error: e,
      );
    }
  }

  /// 启动容器
  Future<bool> startContainer(String containerId) async {
    try {
      await _ensureService();
      await _service!.startContainer(containerId);
      await loadContainers(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '启动容器失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 停止容器
  Future<bool> stopContainer(String containerId) async {
    try {
      await _ensureService();
      await _service!.stopContainer(containerId);
      await loadContainers(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '停止容器失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 强制停止容器 (Kill)
  Future<bool> killContainer(String containerId) async {
    try {
      await _ensureService();
      await _service!.killContainer(containerId);
      await loadContainers(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '强制停止容器失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 重启容器
  Future<bool> restartContainer(String containerId) async {
    try {
      await _ensureService();
      await _service!.restartContainer(containerId);
      await loadContainers(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '重启容器失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 删除容器
  Future<bool> deleteContainer(String containerId) async {
    try {
      await _ensureService();
      await _service!.removeContainer(containerId);
      await loadContainers(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '删除容器失败: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameContainer(String name, String newName) async {
    try {
      await _ensureService();
      await _service!.renameContainer(ContainerRename(name: name, newName: newName));
      await loadContainers();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> upgradeContainer(ContainerUpgrade request) async {
    try {
      await _ensureService();
      await _service!.upgradeContainer(request);
      await loadContainers();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> commitContainer(ContainerCommit request) async {
    try {
      await _ensureService();
      await _service!.commitContainer(request);
      await loadImages();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<ContainerPruneReport?> pruneContainers(ContainerPrune request) async {
    try {
      await _ensureService();
      final result = await _service!.pruneContainers(request);
      await loadAll();
      return result;
    } catch (e) {
      _data = _data.copyWith(error: e.toString());
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateContainer(ContainerOperate request) async {
    try {
      await _ensureService();
      await _service!.updateContainer(request);
      await loadContainers();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> cleanContainerLog(String name) async {
    try {
      await _ensureService();
      await _service!.cleanContainerLog(name);
      return true;
    } catch (e) {
      _data = _data.copyWith(error: e.toString());
      notifyListeners();
      return false;
    }
  }

  /// 删除镜像
  Future<bool> deleteImage(String imageId) async {
    try {
      await _ensureService();
      final id = int.tryParse(imageId);
      if (id == null) {
        _data = _data.copyWith(error: '删除镜像失败: 无效镜像ID');
        notifyListeners();
        return false;
      }
      await _service!.removeImage(id);
      await loadImages(); // 刷新列表
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '删除镜像失败: $e');
      notifyListeners();
      return false;
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadAll();
  }

  /// 加载仓库列表
  Future<void> loadRepos() async {
    try {
      await _ensureService();
      final repos = await _service!.listRepos();
      _data = _data.copyWith(repos: repos);
      notifyListeners();
    } catch (e) {
      _data = _data.copyWith(error: 'Load repos failed: $e');
      notifyListeners();
    }
  }

  /// 创建仓库
  Future<bool> createRepo(ContainerRepoOperate request) async {
    try {
      await _ensureService();
      await _service!.createRepo(request);
      await loadRepos();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: 'Create repo failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// 更新仓库
  Future<bool> updateRepo(ContainerRepoOperate request) async {
    try {
      await _ensureService();
      await _service!.updateRepo(request);
      await loadRepos();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: 'Update repo failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// 删除仓库
  Future<bool> deleteRepo(List<int> ids) async {
    try {
      await _ensureService();
      await _service!.deleteRepo(ids);
      await loadRepos();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: 'Delete repo failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// 加载模板列表
  Future<void> loadTemplates() async {
    try {
      await _ensureService();
      final templates = await _service!.listTemplates();
      _data = _data.copyWith(templates: templates);
      notifyListeners();
    } catch (e) {
      _data = _data.copyWith(error: 'Load templates failed: $e');
      notifyListeners();
    }
  }

  /// 创建模板
  Future<bool> createTemplate(ContainerTemplateOperate request) async {
    try {
      await _ensureService();
      await _service!.createTemplate(request);
      await loadTemplates();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: 'Create template failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// 更新模板
  Future<bool> updateTemplate(ContainerTemplateOperate request) async {
    try {
      await _ensureService();
      await _service!.updateTemplate(request);
      await loadTemplates();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: 'Update template failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// 删除模板
  Future<bool> deleteTemplate(List<int> ids) async {
    try {
      await _ensureService();
      await _service!.deleteTemplate(ids);
      await loadTemplates();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: 'Delete template failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// 更新Daemon配置
  Future<bool> updateDaemonJson(String content) async {
    try {
      await _ensureService();
      await _service!.updateDaemonJson(content);
      await loadConfig();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: 'Update daemon config failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// 清除错误
  void clearError() {
    _data = _data.copyWith(error: null);
    notifyListeners();
  }
}
