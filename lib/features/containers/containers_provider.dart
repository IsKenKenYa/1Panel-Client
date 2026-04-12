import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import '../../data/models/container_models.dart';
import '../../data/models/container_extension_models.dart';
import 'container_service.dart';

/// 容器统计数据
class ContainerStats {
  final int total;
  final int running;
  final int stopped;
  final int paused;

  // Compose 统计
  final int composeTotal;
  final int composeRunning;

  // 全局资源占用（来自 /containers/list/stats 聚合）
  final double totalCpuPercent;
  final double totalMemoryPercent;
  final int totalMemoryUsageBytes;

  const ContainerStats({
    this.total = 0,
    this.running = 0,
    this.stopped = 0,
    this.paused = 0,
    this.composeTotal = 0,
    this.composeRunning = 0,
    this.totalCpuPercent = 0.0,
    this.totalMemoryPercent = 0.0,
    this.totalMemoryUsageBytes = 0,
  });

  ContainerStats copyWith({
    int? total,
    int? running,
    int? stopped,
    int? paused,
    int? composeTotal,
    int? composeRunning,
    double? totalCpuPercent,
    double? totalMemoryPercent,
    int? totalMemoryUsageBytes,
  }) {
    return ContainerStats(
      total: total ?? this.total,
      running: running ?? this.running,
      stopped: stopped ?? this.stopped,
      paused: paused ?? this.paused,
      composeTotal: composeTotal ?? this.composeTotal,
      composeRunning: composeRunning ?? this.composeRunning,
      totalCpuPercent: totalCpuPercent ?? this.totalCpuPercent,
      totalMemoryPercent: totalMemoryPercent ?? this.totalMemoryPercent,
      totalMemoryUsageBytes: totalMemoryUsageBytes ?? this.totalMemoryUsageBytes,
    );
  }
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

class SectionLoadState {
  final bool isLoading;
  final String? error;

  const SectionLoadState({
    this.isLoading = false,
    this.error,
  });

  SectionLoadState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SectionLoadState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
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
class ContainersProvider extends ChangeNotifier with SafeChangeNotifier {
  ContainersProvider({ContainerService? service}) : _service = service;

  ContainerService? _service;

  ContainersData _data = const ContainersData();
  SectionLoadState _overviewState = const SectionLoadState();
  SectionLoadState _containersState = const SectionLoadState();
  SectionLoadState _reposState = const SectionLoadState();
  SectionLoadState _templatesState = const SectionLoadState();
  SectionLoadState _configState = const SectionLoadState();
  SectionLoadState _imagesState = const SectionLoadState();

  ContainersData get data => _data;
  SectionLoadState get overviewState => _overviewState;
  SectionLoadState get containersState => _containersState;
  SectionLoadState get reposState => _reposState;
  SectionLoadState get templatesState => _templatesState;
  SectionLoadState get configState => _configState;
  SectionLoadState get imagesState => _imagesState;

  Future<void> _ensureService() async {
    _service ??= ContainerService();
  }

  Future<void> onServerChanged() async {
    await _ensureService();
    _service!.resetForServerChange();
    _data = const ContainersData();
    _overviewState = const SectionLoadState();
    _containersState = const SectionLoadState();
    _reposState = const SectionLoadState();
    _templatesState = const SectionLoadState();
    _configState = const SectionLoadState();
    _imagesState = const SectionLoadState();
    notifyListeners();
    await loadAll();
  }

  /// 加载容器数据
  Future<void> loadContainers() async {
    _containersState = _containersState.copyWith(
      isLoading: true,
      clearError: true,
    );
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
        containerStats: _data.containerStats.copyWith(
          total: containers.length,
          running: running,
          stopped: stopped,
          paused: paused,
        ),
        lastUpdated: DateTime.now(),
      );
      _containersState = _containersState.copyWith(
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      _data = _data.copyWith(
        containers: const [],
        containerStats: const ContainerStats(),
      );
      _containersState = _containersState.copyWith(
        isLoading: false,
        error: '加载容器失败: $e',
      );
    }
    notifyListeners();
  }

  /// 加载镜像数据
  Future<void> loadImages() async {
    _imagesState = _imagesState.copyWith(
      isLoading: true,
      clearError: true,
    );
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
        lastUpdated: DateTime.now(),
      );
      _imagesState = _imagesState.copyWith(
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      _imagesState = _imagesState.copyWith(
        isLoading: false,
        error: '加载镜像失败: $e',
      );
    }
    notifyListeners();
  }

  /// 加载所有数据
  Future<void> loadAll() async {
    _data = _data.copyWith(isLoading: true, error: null);
    _containersState =
        _containersState.copyWith(isLoading: true, clearError: true);
    _imagesState = _imagesState.copyWith(isLoading: true, clearError: true);
    _reposState = _reposState.copyWith(isLoading: true, clearError: true);
    _templatesState =
        _templatesState.copyWith(isLoading: true, clearError: true);
    _configState = _configState.copyWith(isLoading: true, clearError: true);
    _overviewState = _overviewState.copyWith(isLoading: true, clearError: true);
    notifyListeners();

    try {
      await _ensureService();
      var containers = const <ContainerInfo>[];
      var images = const <ContainerImage>[];
      var repos = const <ContainerRepo>[];
      var templates = const <ContainerTemplate>[];
      ContainerStatus? status;
      var daemonJson = '';

      try {
        containers = await _service!.listContainers();
        _containersState = _containersState.copyWith(
          isLoading: false,
          clearError: true,
        );
      } catch (e) {
        _containersState = _containersState.copyWith(
          isLoading: false,
          error: '加载容器失败: $e',
        );
      }

      try {
        images = await _service!.listImages();
        _imagesState = _imagesState.copyWith(
          isLoading: false,
          clearError: true,
        );
      } catch (e) {
        _imagesState = _imagesState.copyWith(
          isLoading: false,
          error: '加载镜像失败: $e',
        );
      }

      try {
        repos = await _service!.listRepos();
        _reposState = _reposState.copyWith(
          isLoading: false,
          clearError: true,
        );
      } catch (e) {
        _reposState = _reposState.copyWith(
          isLoading: false,
          error: 'Load repos failed: $e',
        );
      }

      try {
        templates = await _service!.listTemplates();
        _templatesState = _templatesState.copyWith(
          isLoading: false,
          clearError: true,
        );
      } catch (e) {
        _templatesState = _templatesState.copyWith(
          isLoading: false,
          error: 'Load templates failed: $e',
        );
      }

      try {
        status = await _service!.getContainerStatus();
        _overviewState = _overviewState.copyWith(
          isLoading: false,
          clearError: true,
        );
      } catch (e) {
        _overviewState = _overviewState.copyWith(
          isLoading: false,
          error: 'Load status failed: $e',
        );
      }

      // 加载 Compose 项目列表
      int composeTotal = 0, composeRunning = 0;
      try {
        final composePage = await _service!.listComposesPage();
        composeTotal = composePage.total;
        composeRunning = composePage.items
            .where((c) => c.status?.toLowerCase() == 'running')
            .length;
      } catch (_) {
        // compose 加载失败不影响主流程
      }

      // 加载容器实时资源统计
      double totalCpu = 0.0, totalMemPct = 0.0;
      int totalMemBytes = 0;
      try {
        final statsList = await _service!.listContainerStats();
        for (final s in statsList) {
          totalCpu += s.cpuPercent;
          totalMemPct += s.memoryPercent;
          totalMemBytes += s.memoryUsage;
        }
      } catch (_) {
        // stats 加载失败不影响主流程
      }

      try {
        daemonJson = await _service!.getDaemonJson();
        _configState = _configState.copyWith(
          isLoading: false,
          clearError: true,
        );
      } catch (e) {
        _configState = _configState.copyWith(
          isLoading: false,
          error: 'Load daemon config failed: $e',
        );
      }

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
          composeTotal: composeTotal,
          composeRunning: composeRunning,
          totalCpuPercent: totalCpu,
          totalMemoryPercent: totalMemPct,
          totalMemoryUsageBytes: totalMemBytes,
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
      if (e is NetworkException) {
        _data = ContainersData(
          isLoading: false,
          error: e.message,
        );
      } else {
        _data = ContainersData(
          isLoading: false,
          error: '加载数据失败: $e',
        );
      }

      _containersState = _containersState.copyWith(isLoading: false);
      _imagesState = _imagesState.copyWith(isLoading: false);
      _reposState = _reposState.copyWith(isLoading: false);
      _templatesState = _templatesState.copyWith(isLoading: false);
      _configState = _configState.copyWith(isLoading: false);
      _overviewState = _overviewState.copyWith(isLoading: false);
    }
    notifyListeners();
  }

  /// 加载配置
  Future<void> loadConfig() async {
    _configState = _configState.copyWith(
      isLoading: true,
      clearError: true,
    );
    notifyListeners();

    try {
      await _ensureService();
      final config = await _service!.getDaemonJson();
      _data = _data.copyWith(daemonJson: config);
      _configState = _configState.copyWith(
        isLoading: false,
        clearError: true,
      );
      notifyListeners();
    } catch (e) {
      _configState = _configState.copyWith(
        isLoading: false,
        error: 'Load daemon config failed: $e',
      );
      notifyListeners();
      // 忽略配置加载错误，避免阻断其他功能
      appLogger.wWithPackage(
        'features.containers.containers_provider',
        'Load config failed',
        error: e,
      );
    }
  }

  Future<void> loadStatus() async {
    _overviewState = _overviewState.copyWith(
      isLoading: true,
      clearError: true,
    );
    notifyListeners();

    try {
      await _ensureService();
      final status = await _service!.getContainerStatus();
      _data = _data.copyWith(status: status, lastUpdated: DateTime.now());
      _overviewState = _overviewState.copyWith(
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      _overviewState = _overviewState.copyWith(
        isLoading: false,
        error: 'Load status failed: $e',
      );
    }
    notifyListeners();
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

  Future<bool> createContainer(ContainerOperate request) async {
    try {
      await _ensureService();
      await _service!.createContainer(request);
      await loadContainers();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '创建容器失败: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> createContainerByCommand(
      ContainerCreateByCommand request) async {
    try {
      await _ensureService();
      await _service!.createContainerByCommand(request);
      await loadContainers();
      return true;
    } catch (e) {
      _data = _data.copyWith(error: '创建容器失败: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameContainer(String name, String newName) async {
    try {
      await _ensureService();
      await _service!
          .renameContainer(ContainerRename(name: name, newName: newName));
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
    _reposState = _reposState.copyWith(
      isLoading: true,
      clearError: true,
    );
    notifyListeners();

    try {
      await _ensureService();
      final repos = await _service!.listRepos();
      _data = _data.copyWith(repos: repos);
      _reposState = _reposState.copyWith(
        isLoading: false,
        clearError: true,
      );
      notifyListeners();
    } catch (e) {
      _reposState = _reposState.copyWith(
        isLoading: false,
        error: 'Load repos failed: $e',
      );
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
    _templatesState = _templatesState.copyWith(
      isLoading: true,
      clearError: true,
    );
    notifyListeners();

    try {
      await _ensureService();
      final templates = await _service!.listTemplates();
      _data = _data.copyWith(templates: templates);
      _templatesState = _templatesState.copyWith(
        isLoading: false,
        clearError: true,
      );
      notifyListeners();
    } catch (e) {
      _templatesState = _templatesState.copyWith(
        isLoading: false,
        error: 'Load templates failed: $e',
      );
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
    _overviewState = _overviewState.copyWith(clearError: true);
    _containersState = _containersState.copyWith(clearError: true);
    _reposState = _reposState.copyWith(clearError: true);
    _templatesState = _templatesState.copyWith(clearError: true);
    _configState = _configState.copyWith(clearError: true);
    _imagesState = _imagesState.copyWith(clearError: true);
    notifyListeners();
  }
}
