import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import '../../../data/models/model_downloader_models.dart';
import '../../../data/models/setting_models.dart';
import '../model_downloader_service.dart';

/// 模型下载器状态。
///
/// 四个分区（推荐、搜索、任务、本地）各自维护数据与加载状态；
/// 设置读写经同一服务，供设置抽屉使用。
class ModelDownloaderProvider extends ChangeNotifier with SafeChangeNotifier {
  ModelDownloaderProvider({ModelDownloaderService? service})
      : _service = service ?? ModelDownloaderService();

  final ModelDownloaderService _service;

  // ==================== 推荐 ====================

  FeaturedModelPage _featured =
      const FeaturedModelPage(items: <FeaturedModel>[], total: 0);
  bool _featuredLoading = false;
  String? _featuredError;
  String? _featuredFamily;

  // ==================== 搜索 ====================

  List<ModelItem> _searchResults = const <ModelItem>[];
  int _searchTotal = 0;
  String _searchSource = 'hf';
  String _searchQuery = '';
  String _searchSort = 'trending';
  bool _searchLoading = false;
  String? _searchError;

  // ==================== 任务 ====================

  List<ModelDownloadTaskItem> _tasks = const <ModelDownloadTaskItem>[];
  bool _taskLoading = false;
  String? _taskError;

  // ==================== 本地 ====================

  List<LocalModelItem> _localModels = const <LocalModelItem>[];
  bool _localLoading = false;
  String? _localError;

  // ==================== 设置 ====================

  ModelDownloaderSetting _settings = const ModelDownloaderSetting(modelDir: '');
  bool _settingsLoading = false;
  String? _settingsError;

  bool _isMutating = false;

  FeaturedModelPage get featured => _featured;
  bool get featuredLoading => _featuredLoading;
  String? get featuredError => _featuredError;
  String? get featuredFamily => _featuredFamily;

  List<ModelItem> get searchResults => _searchResults;
  int get searchTotal => _searchTotal;
  String get searchSource => _searchSource;
  String get searchQuery => _searchQuery;
  String get searchSort => _searchSort;
  bool get searchLoading => _searchLoading;
  String? get searchError => _searchError;

  List<ModelDownloadTaskItem> get tasks => _tasks;
  bool get taskLoading => _taskLoading;
  String? get taskError => _taskError;

  List<LocalModelItem> get localModels => _localModels;
  bool get localLoading => _localLoading;
  String? get localError => _localError;

  ModelDownloaderSetting get settings => _settings;
  bool get settingsLoading => _settingsLoading;
  String? get settingsError => _settingsError;

  bool get isMutating => _isMutating;

  /// 是否有进行中的下载任务。
  bool get hasActiveTasks => _tasks.any((task) =>
      task.status == 'running' ||
      task.status == 'Running' ||
      task.status == 'waiting');

  Future<void> onServerChanged() async {
    _service.resetForServerChange();
    _featured =
        const FeaturedModelPage(items: <FeaturedModel>[], total: 0);
    _searchResults = const <ModelItem>[];
    _tasks = const <ModelDownloadTaskItem>[];
    _localModels = const <LocalModelItem>[];
    _featuredError = null;
    _searchError = null;
    _taskError = null;
    _localError = null;
    notifyListeners();
    await loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait(<Future<void>>[
      loadFeatured(),
      loadTasks(),
      loadLocalModels(),
    ]);
  }

  // ==================== 推荐 ====================

  Future<void> loadFeatured({String? family}) async {
    if (isDisposed) return;
    _featuredLoading = true;
    _featuredError = null;
    _featuredFamily = family;
    notifyListeners();
    try {
      _featured = await _service.searchFeatured(family: family);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.model_downloader',
        'loadFeatured failed',
        error: error,
        stackTrace: stackTrace,
      );
      _featured = const FeaturedModelPage(
        items: <FeaturedModel>[],
        total: 0,
      );
      _featuredError = ErrorMessageUtils.userFacingMessage(error);
    } finally {
      if (!isDisposed) {
        _featuredLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> syncFeatured() async {
    await _mutate(() async {
      await _service.syncFeatured();
      await loadFeatured(family: _featuredFamily);
    });
  }

  Future<void> setFeaturedSync(bool enabled) async {
    await _mutate(() => _service.updateFeaturedSyncStatus(enabled));
  }

  Future<void> downloadFeatured(FeaturedModel model, {String? source}) async {
    final sourceKey = source ??
        (model.sources.isEmpty ? 'hf' : model.sources.first);
    final repoID = model.sourceModelIds[sourceKey] ?? model.repoID;
    await _mutate(() => _download(repoID, sourceKey));
  }

  // ==================== 搜索 ====================

  Future<void> search({
    required String source,
    String? query,
    String? sort,
  }) async {
    if (isDisposed) return;
    _searchSource = source;
    _searchQuery = query ?? _searchQuery;
    _searchSort = sort ?? _searchSort;
    _searchLoading = true;
    _searchError = null;
    notifyListeners();
    try {
      final result = source == 'hf'
          ? await _service.searchHuggingFace(
              query: _searchQuery.isEmpty ? null : _searchQuery,
              sort: _searchSort,
            )
          : await _service.searchModelScope(
              query: _searchQuery.isEmpty ? null : _searchQuery,
              sort: _searchSort,
            );
      _searchResults = result.items;
      _searchTotal = result.total;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.model_downloader',
        'search failed',
        error: error,
        stackTrace: stackTrace,
      );
      _searchResults = const <ModelItem>[];
      _searchError = ErrorMessageUtils.userFacingMessage(error);
    } finally {
      if (!isDisposed) {
        _searchLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setSearchSource(String source) async {
    await search(source: source, query: _searchQuery);
  }

  Future<void> setSearchSort(String sort) async {
    await search(source: _searchSource, sort: sort);
  }

  Future<ModelInfo> loadModelInfo(String repoID, {String source = 'hf'}) async {
    return source == 'hf'
        ? _service.getHuggingFaceInfo(repoID)
        : _service.getModelScopeInfo(repoID);
  }

  Future<void> downloadModel({
    required String repoID,
    required String source,
    String downloadType = 'all',
  }) async {
    await _mutate(() => _download(repoID, source, downloadType: downloadType));
  }

  Future<void> _download(
    String repoID,
    String source, {
    String downloadType = 'all',
  }) async {
    if (source == 'hf') {
      await _service.downloadHuggingFace(
        repoID: repoID,
        downloadType: downloadType,
      );
    } else {
      await _service.downloadModelScope(
        repoID: repoID,
        downloadType: downloadType,
      );
    }
    await loadTasks();
  }

  // ==================== 任务 ====================

  Future<void> loadTasks() async {
    if (isDisposed) return;
    _taskLoading = true;
    _taskError = null;
    notifyListeners();
    try {
      final result = await _service.searchTasks();
      _tasks = result.items;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.model_downloader',
        'loadTasks failed',
        error: error,
        stackTrace: stackTrace,
      );
      _tasks = const <ModelDownloadTaskItem>[];
      _taskError = ErrorMessageUtils.userFacingMessage(error);
    } finally {
      if (!isDisposed) {
        _taskLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> cancelTask(int id, {bool withFile = false}) async {
    await _mutate(() async {
      await _service.cancelTask(id, withFile: withFile);
      await loadTasks();
    });
  }

  Future<void> retryTask(int id) async {
    await _mutate(() async {
      await _service.retryTask(id);
      await loadTasks();
    });
  }

  Future<void> removeTask(int id, {bool withFile = false}) async {
    await _mutate(() async {
      await _service.removeTask(id, withFile: withFile);
      await loadTasks();
      await loadLocalModels();
    });
  }

  // ==================== 本地 ====================

  Future<void> loadLocalModels({String? info}) async {
    if (isDisposed) return;
    _localLoading = true;
    _localError = null;
    notifyListeners();
    try {
      final result = await _service.searchLocal(info: info);
      _localModels = result.items;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.model_downloader',
        'loadLocalModels failed',
        error: error,
        stackTrace: stackTrace,
      );
      _localModels = const <LocalModelItem>[];
      _localError = ErrorMessageUtils.userFacingMessage(error);
    } finally {
      if (!isDisposed) {
        _localLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> deleteLocalModel(
    String name, {
    String? downloadType,
    bool withFile = true,
  }) async {
    await _mutate(() async {
      await _service.deleteLocalModel(
        name: name,
        downloadType: downloadType,
        withFile: withFile,
      );
      await loadLocalModels();
    });
  }

  // ==================== 设置 ====================

  Future<void> loadSettings() async {
    if (isDisposed) return;
    _settingsLoading = true;
    _settingsError = null;
    notifyListeners();
    try {
      _settings = await _service.getSettings();
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ai.model_downloader',
        'loadSettings failed',
        error: error,
        stackTrace: stackTrace,
      );
      _settingsError = ErrorMessageUtils.userFacingMessage(error);
    } finally {
      if (!isDisposed) {
        _settingsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> updateSettings(ModelDownloaderSetting setting) async {
    await _mutate(() async {
      await _service.updateSettings(setting);
      _settings = setting;
    });
  }

  Future<T> _mutate<T>(Future<T> Function() action) async {
    if (isDisposed) throw StateError('Provider 已释放');
    _isMutating = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      if (!isDisposed) {
        _isMutating = false;
        notifyListeners();
      }
    }
  }
}
