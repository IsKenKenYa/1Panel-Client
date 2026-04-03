part of '../files_provider.dart';

extension FilesProviderLifecycleMixin on FilesProvider {
  Future<void> initialize() async {
    if (isDisposed) return;
    final targetPath = _normalizePath(_data.currentPath);
    appLogger.dWithPackage(
      'files_provider',
      'initialize: 初始化文件首页, path=$targetPath',
    );
    _data = _data.copyWith(isLoading: true, error: null);
    _emitChange();

    try {
      final results = await Future.wait<dynamic>([
        _service.getCurrentServer(),
        _service.getFiles(
          path: targetPath,
          search: _data.searchQuery,
        ),
      ]);
      final server = results[0] as ApiConfig?;
      final files = results[1] as List<FileInfo>;
      _data = _data.copyWith(
        currentServer: server,
        files: files,
        currentPath: targetPath,
        isLoading: false,
        selectedFiles: <String>{},
      );
      _rememberPathForServer(server?.id, targetPath);
      appLogger.iWithPackage(
        'files_provider',
        'initialize: 初始化完成, files=${files.length}, serverId=${server?.id}',
      );
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'files_provider',
        'initialize: 初始化失败',
        error: e,
        stackTrace: stackTrace,
      );
      _data = _data.copyWith(isLoading: false, error: e.toString());
    }
    _emitChange();
    unawaited(loadFavorites());
  }

  Future<void> loadServer() async {
    if (isDisposed) return;
    appLogger.dWithPackage('files_provider', 'loadServer: 开始加载服务器配置');
    final server = await _service.getCurrentServer();
    _data = _data.copyWith(currentServer: server);
    appLogger.iWithPackage(
      'files_provider',
      'loadServer: 服务器配置加载完成, serverId=${server?.id}',
    );
    _emitChange();
  }

  Future<List<FileInfo>> fetchFiles(String path) async {
    if (isDisposed) return const <FileInfo>[];
    appLogger.dWithPackage('files_provider', 'fetchFiles: path=$path');
    try {
      return await _service.getFiles(path: path);
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'files_provider',
        'fetchFiles: 加载失败',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> loadFiles({String? path}) async {
    if (isDisposed) return;
    final targetPath = _normalizePath(path ?? _data.currentPath);
    appLogger.dWithPackage(
      'files_provider',
      'loadFiles: 开始加载文件列表, path=$targetPath',
    );
    _data = _data.copyWith(isLoading: true, error: null);
    _emitChange();

    try {
      final files = await _service.getFiles(
        path: targetPath,
        search: _data.searchQuery,
      );

      _data = _data.copyWith(
        files: files,
        currentPath: targetPath,
        isLoading: false,
        selectedFiles: <String>{},
      );
      _rememberPathForServer(_data.currentServer?.id, targetPath);

      if (path != null && !_data.pathHistory.contains(targetPath)) {
        _data = _data.copyWith(
          pathHistory: <String>[..._data.pathHistory, targetPath],
        );
      }
      appLogger.iWithPackage(
          'files_provider', 'loadFiles: 成功加载${files.length}个文件');
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'files_provider',
        'loadFiles: 加载失败',
        error: e,
        stackTrace: stackTrace,
      );
      _data = _data.copyWith(isLoading: false, error: e.toString());
    }
    _emitChange();
  }

  Future<void> loadMountInfo() async {
    if (isDisposed) return;
    try {
      final mounts = await _service.getMountInfo();
      _data = _data.copyWith(mountInfo: mounts);
      _emitChange();
    } catch (e) {
      appLogger.eWithPackage(
        'files_provider',
        'loadMountInfo: 加载挂载信息失败',
        error: e,
      );
    }
  }

  void onServerChanged() {
    onServerChangedWithIds();
  }

  void onServerChangedWithIds({
    String? previousServerId,
    String? nextServerId,
  }) {
    if (isDisposed) return;
    if (previousServerId != null && previousServerId.isNotEmpty) {
      _rememberPathForServer(previousServerId, _data.currentPath);
    }
    final restoredPath = _restorePathForServer(nextServerId);
    appLogger.dWithPackage(
      'files_provider',
      'onServerChanged: server=$previousServerId->$nextServerId, restoredPath=$restoredPath',
    );
    _service.clearCache();
    _data = FilesData(
      currentPath: restoredPath,
      pathHistory: <String>[restoredPath],
    );
    _emitChange();
    unawaited(initialize());
  }

  Future<void> navigateTo(String path) async {
    if (isDisposed) return;
    await loadFiles(path: _normalizePath(path));
  }

  Future<void> navigateUp() async {
    if (isDisposed) return;
    if (_data.currentPath == '/') return;

    final segments = _pathSegments(_data.currentPath);
    if (segments.isEmpty) {
      await loadFiles(path: '/');
      return;
    }
    segments.removeLast();
    final parentPath = segments.isEmpty ? '/' : '/${segments.join('/')}';
    await loadFiles(path: parentPath);
  }

  Future<void> refresh() async {
    if (isDisposed) return;
    appLogger.dWithPackage('files_provider', 'refresh: 刷新文件列表');
    await loadFiles();
  }

  void setSearchQuery(String? query) {
    if (isDisposed) return;
    _data = _data.copyWith(searchQuery: query);
    _emitChange();
  }

  void setSorting(String? sortBy, String? sortOrder) {
    if (isDisposed) return;
    _data = _data.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    _emitChange();
    loadFiles();
  }

  void toggleSelection(String path) {
    if (isDisposed) return;
    final newSelection = Set<String>.from(_data.selectedFiles);
    if (newSelection.contains(path)) {
      newSelection.remove(path);
    } else {
      newSelection.add(path);
    }
    _data = _data.copyWith(selectedFiles: newSelection);
    _emitChange();
  }

  void selectAll() {
    if (isDisposed) return;
    final allPaths = _data.files.map((file) => file.path).toSet();
    _data = _data.copyWith(selectedFiles: allPaths);
    _emitChange();
  }

  void clearSelection() {
    if (isDisposed) return;
    _data = _data.copyWith(selectedFiles: <String>{}, lastSelectedIndex: null);
    _emitChange();
  }

  void setLastSelectedIndex(int index) {
    if (isDisposed) return;
    _data = _data.copyWith(lastSelectedIndex: index);
  }

  void selectOnly(String path) {
    if (isDisposed) return;
    _data = _data.copyWith(selectedFiles: {path});
    _emitChange();
  }

  void selectRange(int currentIndex) {
    if (isDisposed) return;
    if (_data.lastSelectedIndex == null) {
      selectOnly(_data.files[currentIndex].path);
      setLastSelectedIndex(currentIndex);
      return;
    }

    final start = _data.lastSelectedIndex!;
    final end = currentIndex;

    final lower = start < end ? start : end;
    final upper = start > end ? start : end;

    final newSelection = Set<String>.from(_data.selectedFiles);
    for (int i = lower; i <= upper; i++) {
      if (i >= 0 && i < _data.files.length) {
        newSelection.add(_data.files[i].path);
      }
    }

    _data = _data.copyWith(selectedFiles: newSelection);
    _emitChange();
  }
}
