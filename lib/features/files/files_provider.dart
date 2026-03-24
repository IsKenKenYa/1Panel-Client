import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'files_service.dart';
import 'models/models.dart';
import '../../data/models/file_models.dart';
import '../../core/network/api_client_manager.dart';
import '../../core/services/logger/logger_service.dart';

class FilesProvider extends ChangeNotifier {
  final FilesService _service;
  FilesData _data = const FilesData();

  FilesProvider({FilesService? service}) : _service = service ?? FilesService();

  static const int _chunkDownloadThreshold = 50 * 1024 * 1024;

  FilesData get data => _data;

  List<String> _pathSegments(String path) {
    return path.split('/').where((segment) => segment.isNotEmpty).toList();
  }

  String _normalizePath(String path) {
    final segments = _pathSegments(path);
    if (segments.isEmpty) return '/';
    return '/${segments.join('/')}';
  }

  Future<void> initialize() async {
    final targetPath = _normalizePath(_data.currentPath);
    appLogger.dWithPackage(
        'files_provider', 'initialize: 初始化文件首页, path=$targetPath');
    _data = _data.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final results = await Future.wait([
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
        selectedFiles: {},
      );
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
      _data = _data.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    notifyListeners();
    unawaited(loadFavorites());
  }

  Future<void> loadServer() async {
    appLogger.dWithPackage('files_provider', 'loadServer: 开始加载服务器配置');
    final server = await _service.getCurrentServer();
    _data = _data.copyWith(currentServer: server);
    appLogger.iWithPackage(
        'files_provider', 'loadServer: 服务器配置加载完成, serverId=${server?.id}');
    notifyListeners();
  }

  Future<List<FileInfo>> fetchFiles(String path) async {
    appLogger.dWithPackage('files_provider', 'fetchFiles: path=$path');
    try {
      final files = await _service.getFiles(path: path);
      return files;
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'fetchFiles: 加载失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> loadFiles({String? path}) async {
    final targetPath = _normalizePath(path ?? _data.currentPath);
    appLogger.dWithPackage(
        'files_provider', 'loadFiles: 开始加载文件列表, path=$targetPath');
    _data = _data.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final files = await _service.getFiles(
        path: targetPath,
        search: _data.searchQuery,
      );

      _data = _data.copyWith(
        files: files,
        currentPath: targetPath,
        isLoading: false,
        selectedFiles: {},
      );

      if (path != null && !_data.pathHistory.contains(targetPath)) {
        _data = _data.copyWith(
          pathHistory: [..._data.pathHistory, targetPath],
        );
      }
      appLogger.iWithPackage(
          'files_provider', 'loadFiles: 成功加载${files.length}个文件');
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'loadFiles: 加载失败',
          error: e, stackTrace: stackTrace);
      _data = _data.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> loadMountInfo() async {
    try {
      final mounts = await _service.getMountInfo();
      _data = _data.copyWith(mountInfo: mounts);
      notifyListeners();
    } catch (e) {
      appLogger.eWithPackage('files_provider', 'loadMountInfo: 加载挂载信息失败',
          error: e);
    }
  }

  Future<void> loadRecycleBinStatus() async {
    try {
      final api = await ApiClientManager.instance.getFileApi();
      final response = await api.getRecycleBinStatus();
      _data = _data.copyWith(recycleBinStatus: response.data);
      notifyListeners();
    } catch (e) {
      appLogger.eWithPackage(
          'files_provider', 'loadRecycleBinStatus: 加载回收站状态失败',
          error: e);
    }
  }

  Future<List<RecycleBinItem>> loadRecycleBinFiles(
      {int page = 1, int pageSize = 100}) async {
    appLogger.dWithPackage('files_provider', 'loadRecycleBinFiles: 加载回收站文件列表');
    try {
      final api = await ApiClientManager.instance.getFileApi();
      final response = await api.searchRecycleBin(FileSearch(
        path: '/',
        page: page,
        pageSize: pageSize,
      ));
      final files = response.data?.map((f) {
            return RecycleBinItem(
              sourcePath: f.path,
              name: f.name,
              isDir: f.isDir,
              size: f.size,
              deleteTime: f.modifiedAt,
              rName: f.gid ?? f.path.split('/').last,
              from: f.path.substring(0, f.path.lastIndexOf('/')),
            );
          }).toList() ??
          [];
      appLogger.iWithPackage(
          'files_provider', 'loadRecycleBinFiles: 成功加载${files.length}个回收站文件');
      return files;
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'loadRecycleBinFiles: 加载失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> restoreFile(RecycleBinItem file) async {
    appLogger.dWithPackage('files_provider', 'restoreFile: 恢复文件 ${file.name}');
    try {
      await _service.restoreFile(RecycleBinReduceRequest(
        rName: file.rName,
        from: file.from,
        name: file.name,
      ));
      appLogger.iWithPackage(
          'files_provider', 'restoreFile: 成功恢复文件 ${file.name}');
      await loadRecycleBinStatus();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'restoreFile: 恢复失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> restoreFiles(List<RecycleBinItem> files) async {
    appLogger.dWithPackage(
        'files_provider', 'restoreFiles: 恢复${files.length}个文件');
    try {
      final requests = files
          .map((f) => RecycleBinReduceRequest(
                rName: f.rName,
                from: f.from,
                name: f.name,
              ))
          .toList();
      await _service.restoreFiles(requests);
      appLogger.iWithPackage(
          'files_provider', 'restoreFiles: 成功恢复${files.length}个文件');
      await loadRecycleBinStatus();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'restoreFiles: 恢复失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deletePermanently(RecycleBinItem file) async {
    appLogger.dWithPackage(
        'files_provider', 'deletePermanently: 永久删除文件 ${file.name}');
    try {
      await _service.deleteRecycleBinFiles([file]);
      appLogger.iWithPackage(
          'files_provider', 'deletePermanently: 成功永久删除文件 ${file.name}');
      await loadRecycleBinStatus();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'deletePermanently: 删除失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deletePermanentlyFiles(List<RecycleBinItem> files) async {
    appLogger.dWithPackage(
        'files_provider', 'deletePermanentlyFiles: 永久删除${files.length}个文件');
    try {
      await _service.deleteRecycleBinFiles(files);
      appLogger.iWithPackage(
          'files_provider', 'deletePermanentlyFiles: 成功永久删除${files.length}个文件');
      await loadRecycleBinStatus();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'deletePermanentlyFiles: 删除失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> clearRecycleBin() async {
    appLogger.dWithPackage('files_provider', 'clearRecycleBin: 清空回收站');
    try {
      await _service.clearRecycleBin();
      appLogger.iWithPackage('files_provider', 'clearRecycleBin: 成功清空回收站');
      await loadRecycleBinStatus();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'clearRecycleBin: 清空失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  void onServerChanged() {
    appLogger.dWithPackage('files_provider', 'onServerChanged: 服务器变更，重置状态');
    _service.clearCache();
    _data = const FilesData();
    notifyListeners();
    unawaited(initialize());
  }

  Future<void> navigateTo(String path) async {
    await loadFiles(path: _normalizePath(path));
  }

  Future<void> navigateUp() async {
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
    appLogger.dWithPackage('files_provider', 'refresh: 刷新文件列表');
    await loadFiles();
  }

  void setSearchQuery(String? query) {
    _data = _data.copyWith(searchQuery: query);
    notifyListeners();
  }

  void setSorting(String? sortBy, String? sortOrder) {
    _data = _data.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    notifyListeners();
    loadFiles();
  }

  void toggleSelection(String path) {
    final newSelection = Set<String>.from(_data.selectedFiles);
    if (newSelection.contains(path)) {
      newSelection.remove(path);
    } else {
      newSelection.add(path);
    }
    _data = _data.copyWith(selectedFiles: newSelection);
    notifyListeners();
  }

  void selectAll() {
    final allPaths = _data.files.map((f) => f.path).toSet();
    _data = _data.copyWith(selectedFiles: allPaths);
    notifyListeners();
  }

  void clearSelection() {
    _data = _data.copyWith(selectedFiles: {});
    notifyListeners();
  }

  Future<void> createDirectory(String name) async {
    final newPath =
        _data.currentPath == '/' ? '/$name' : '${_data.currentPath}/$name';
    appLogger.dWithPackage(
        'files_provider', 'createDirectory: name=$name, fullPath=$newPath');
    try {
      await _service.createDirectory(newPath);
      appLogger.iWithPackage('files_provider', 'createDirectory: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'createDirectory: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> createFile(String name, {String? content}) async {
    final newPath =
        _data.currentPath == '/' ? '/$name' : '${_data.currentPath}/$name';
    appLogger.dWithPackage('files_provider',
        'createFile: name=$name, fullPath=$newPath, hasContent=${content != null}');
    try {
      await _service.createFile(newPath, content: content);
      appLogger.iWithPackage('files_provider', 'createFile: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'createFile: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> uploadFiles(List<String> filePaths) async {
    appLogger.dWithPackage('files_provider',
        'uploadFiles: filePaths=$filePaths, targetPath=${_data.currentPath}');
    try {
      for (final filePath in filePaths) {
        final file = await MultipartFile.fromFile(filePath);
        await _service.uploadFile(_data.currentPath, file);
      }
      appLogger.iWithPackage(
          'files_provider', 'uploadFiles: 成功上传 ${filePaths.length} 个文件');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'uploadFiles: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteSelected() async {
    if (_data.selectedFiles.isEmpty) {
      appLogger.wWithPackage('files_provider', 'deleteSelected: 没有选中的文件');
      return;
    }
    appLogger.dWithPackage(
        'files_provider', 'deleteSelected: 删除${_data.selectedFiles.length}个文件');
    try {
      await _service.deleteFiles(_data.selectedFiles.toList());
      appLogger.iWithPackage('files_provider', 'deleteSelected: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'deleteSelected: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    appLogger.dWithPackage('files_provider', 'deleteFile: path=$path');
    try {
      await _service.deleteFiles([path]);
      appLogger.iWithPackage('files_provider', 'deleteFile: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'deleteFile: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> renameFile(String oldPath, String newName) async {
    final parentPath = oldPath.substring(0, oldPath.lastIndexOf('/'));
    final newPath = parentPath.isEmpty ? '/$newName' : '$parentPath/$newName';
    appLogger.dWithPackage(
        'files_provider', 'renameFile: oldPath=$oldPath, newPath=$newPath');
    try {
      await _service.renameFile(oldPath, newPath);
      appLogger.iWithPackage('files_provider', 'renameFile: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'renameFile: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> moveSelected(String targetPath) async {
    if (_data.selectedFiles.isEmpty) {
      appLogger.wWithPackage('files_provider', 'moveSelected: 没有选中的文件');
      return;
    }
    appLogger.dWithPackage('files_provider',
        'moveSelected: 移动${_data.selectedFiles.length}个文件到$targetPath');
    try {
      await _service.moveFiles(_data.selectedFiles.toList(), targetPath);
      appLogger.iWithPackage('files_provider', 'moveSelected: 成功');
      clearSelection();
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'moveSelected: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> copySelected(String targetPath) async {
    if (_data.selectedFiles.isEmpty) {
      appLogger.wWithPackage('files_provider', 'copySelected: 没有选中的文件');
      return;
    }
    appLogger.dWithPackage('files_provider',
        'copySelected: 复制${_data.selectedFiles.length}个文件到$targetPath');
    try {
      await _service.copyFiles(_data.selectedFiles.toList(), targetPath);
      appLogger.iWithPackage('files_provider', 'copySelected: 成功');
      clearSelection();
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'copySelected: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> moveFile(String sourcePath, String targetPath) async {
    appLogger.dWithPackage(
        'files_provider', 'moveFile: source=$sourcePath, target=$targetPath');
    try {
      await _service.moveFiles([sourcePath], targetPath);
      appLogger.iWithPackage('files_provider', 'moveFile: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'moveFile: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> copyFile(String sourcePath, String targetPath) async {
    appLogger.dWithPackage(
        'files_provider', 'copyFile: source=$sourcePath, target=$targetPath');
    try {
      await _service.copyFiles([sourcePath], targetPath);
      appLogger.iWithPackage('files_provider', 'copyFile: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'copyFile: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String> getFileContent(String path) async {
    return await _service.getFileContent(path);
  }

  Future<void> saveFileContent(String path, String content) async {
    await _service.updateFileContent(path, content);
  }

  Future<void> compressSelected(String name, String type,
      {String? secret}) async {
    if (_data.selectedFiles.isEmpty) {
      appLogger.wWithPackage('files_provider', 'compressSelected: 没有选中的文件');
      return;
    }
    appLogger.dWithPackage('files_provider',
        'compressSelected: 压缩${_data.selectedFiles.length}个文件, name=$name, type=$type');
    try {
      await _service.compressFiles(
        files: _data.selectedFiles.toList(),
        dst: _data.currentPath,
        name: name,
        type: type,
        secret: secret,
      );
      appLogger.iWithPackage('files_provider', 'compressSelected: 成功');
      clearSelection();
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'compressSelected: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> compressFiles(
      List<String> files, String dst, String name, String type,
      {String? secret}) async {
    appLogger.dWithPackage('files_provider',
        'compressFiles: 压缩${files.length}个文件到$dst/$name, type=$type');
    try {
      await _service.compressFiles(
        files: files,
        dst: dst,
        name: name,
        type: type,
        secret: secret,
      );
      appLogger.iWithPackage('files_provider', 'compressFiles: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'compressFiles: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> extractFile(String path, String dst, String type,
      {String? secret}) async {
    appLogger.dWithPackage(
        'files_provider', 'extractFile: 解压$path到$dst, type=$type');
    try {
      await _service.extractFile(
          path: path, dst: dst, type: type, secret: secret);
      appLogger.iWithPackage('files_provider', 'extractFile: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'extractFile: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<FileSizeInfo> getFileSize(String path) async {
    return await _service.getFileSize(path, recursive: true);
  }

  Future<void> loadFavorites() async {
    appLogger.dWithPackage('files_provider', 'loadFavorites: 开始加载收藏夹');
    try {
      final favorites = await _service.searchFavoriteFiles(path: '/');
      final favoritePaths = favorites.map((f) => f.path).toSet();
      _data = _data.copyWith(
        favorites: favorites,
        favoritePaths: favoritePaths,
      );
      appLogger.iWithPackage(
          'files_provider', 'loadFavorites: 成功加载${favorites.length}个收藏');
      notifyListeners();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'loadFavorites: 加载失败',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> addToFavorites(FileInfo file) async {
    appLogger.dWithPackage(
        'files_provider', 'addToFavorites: path=${file.path}');
    try {
      await _service.favoriteFile(file.path, name: file.name);
      final newFavorites = [..._data.favorites, file];
      final newFavoritePaths = {..._data.favoritePaths, file.path};
      _data = _data.copyWith(
        favorites: newFavorites,
        favoritePaths: newFavoritePaths,
      );
      appLogger.iWithPackage('files_provider', 'addToFavorites: 成功');
      notifyListeners();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'addToFavorites: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String path) async {
    appLogger.dWithPackage('files_provider', 'removeFromFavorites: path=$path');
    try {
      await _service.unfavoriteFile(path);
      final newFavorites =
          _data.favorites.where((f) => f.path != path).toList();
      final newFavoritePaths = Set<String>.from(_data.favoritePaths)
        ..remove(path);
      _data = _data.copyWith(
        favorites: newFavorites,
        favoritePaths: newFavoritePaths,
      );
      appLogger.iWithPackage('files_provider', 'removeFromFavorites: 成功');
      notifyListeners();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'removeFromFavorites: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> toggleFavorite(FileInfo file) async {
    if (_data.isFavorite(file.path)) {
      await removeFromFavorites(file.path);
    } else {
      await addToFavorites(file);
    }
  }

  Future<void> wgetDownload({
    required String url,
    required String name,
    bool? ignoreCertificate,
  }) async {
    appLogger.dWithPackage('files_provider',
        'wgetDownload: url=$url, path=${_data.currentPath}, name=$name');

    _data = _data.copyWith(
      wgetStatus: const WgetDownloadStatus(
        state: WgetDownloadState.downloading,
        message: '正在创建下载任务...',
      ),
    );
    notifyListeners();

    try {
      final result = await _service.wgetDownload(
        url: url,
        path: _data.currentPath,
        name: name,
        ignoreCertificate: ignoreCertificate,
      );

      appLogger.iWithPackage('files_provider',
          'wgetDownload: result.success=${result.success}, filePath=${result.filePath}, key=${result.key}, error=${result.error}');

      if (result.success) {
        final message = result.key != null ? '下载任务已创建' : '下载成功';
        appLogger.iWithPackage('files_provider',
            'wgetDownload: $message, filePath=${result.filePath}');
        _data = _data.copyWith(
          wgetStatus: WgetDownloadStatus(
            state: WgetDownloadState.success,
            message: message,
            filePath: result.filePath,
            downloadedSize: result.downloadedSize,
          ),
        );
        await refresh();
      } else {
        final errorMsg = result.error ?? '下载失败';
        appLogger.eWithPackage(
            'files_provider', 'wgetDownload: 下载失败, error=$errorMsg');
        _data = _data.copyWith(
          wgetStatus: WgetDownloadStatus(
            state: WgetDownloadState.error,
            message: errorMsg,
          ),
        );
      }
    } catch (e, stackTrace) {
      final errorMsg = e.toString();
      appLogger.eWithPackage(
          'files_provider', 'wgetDownload: 下载异常, error=$errorMsg',
          error: e, stackTrace: stackTrace);
      _data = _data.copyWith(
        wgetStatus: WgetDownloadStatus(
          state: WgetDownloadState.error,
          message: errorMsg.contains('Exception:')
              ? errorMsg.split('Exception:').last.trim()
              : errorMsg,
        ),
      );
    }
    notifyListeners();
  }

  void clearWgetStatus() {
    _data = _data.copyWith(wgetStatus: null);
    notifyListeners();
  }

  Future<List<FileInfo>> searchUploadedFiles(
      {int page = 1, int pageSize = 20, String? search}) async {
    appLogger.dWithPackage('files_provider', 'searchUploadedFiles: page=$page');
    try {
      final result = await _service.searchUploadedFiles(
          page: page, pageSize: pageSize, search: search);
      return result;
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'searchUploadedFiles: 获取上传记录失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> batchChangeFileRole({
    required List<String> paths,
    int? mode,
    String? user,
    String? group,
    bool? sub,
  }) async {
    appLogger.dWithPackage(
        'files_provider', 'batchChangeFileRole: paths=$paths');
    try {
      await _service.batchChangeFileRole(
        paths: paths,
        mode: mode,
        user: user,
        group: group,
        sub: sub,
      );
      appLogger.iWithPackage('files_provider', 'batchChangeFileRole: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'batchChangeFileRole: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<FileMountInfo>> getMountInfo() async {
    appLogger.dWithPackage('files_provider', 'getMountInfo');
    return await _service.getMountInfo();
  }

  Future<FileBatchCheckResult> batchCheckFiles(List<String> paths) async {
    appLogger.dWithPackage('files_provider', 'batchCheckFiles: paths=$paths');
    return await _service.batchCheckFiles(paths);
  }

  Future<void> changeFileMode(String path, int mode, {bool? sub}) async {
    appLogger.dWithPackage(
        'files_provider', 'changeFileMode: path=$path, mode=$mode, sub=$sub');
    try {
      await _service.changeFileMode(path, mode, sub: sub);
      appLogger.iWithPackage('files_provider', 'changeFileMode: 成功修改权限模式');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'changeFileMode: 修改权限模式失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> changeFileOwner(String path, String user, String group,
      {bool? sub}) async {
    appLogger.dWithPackage('files_provider',
        'changeFileOwner: path=$path, user=$user, group=$group, sub=$sub');
    try {
      await _service.changeFileOwner(path, user, group, sub: sub);
      appLogger.iWithPackage('files_provider', 'changeFileOwner: 成功修改所有者');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'changeFileOwner: 修改所有者失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<FileUserGroupResponse> getUserGroup() async {
    appLogger.dWithPackage('files_provider', 'getUserGroup: 获取用户和组列表');
    try {
      final result = await _service.getUserGroup();
      appLogger.iWithPackage('files_provider', 'getUserGroup: 成功获取用户和组列表');
      return result;
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'getUserGroup: 获取用户和组列表失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String?> downloadFile(FileInfo file) async {
    if (file.isDir) {
      throw Exception('cannot_download_directory');
    }

    final hasPermission = await _service.checkAndRequestStoragePermission();
    if (!hasPermission) {
      throw Exception('storage_permission_denied');
    }

    if (file.size >= _chunkDownloadThreshold) {
      appLogger.iWithPackage(
          'files_provider', 'downloadFile: 大文件(${file.size} bytes)，建议使用分块下载');
    }

    return await _downloadWithFlutterDownloader(file);
  }

  Future<String?> _downloadWithFlutterDownloader(FileInfo file) async {
    try {
      final config = await ApiConfigManager.getCurrentConfig();
      if (config == null) {
        throw StateError('No server configured');
      }

      // 获取下载目录
      String downloadPath;
      if (Platform.isAndroid) {
        downloadPath = '/storage/emulated/0/Download';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        downloadPath = directory.path;
      }

      final downloadDir = Directory(downloadPath);
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final localFile = File('${downloadDir.path}/${file.name}');

      // 检查文件是否已完全下载
      // /files/download API 使用 http.ServeContent，自动支持 Range 头
      // 如果本地文件大小等于服务器文件大小，说明文件已完全下载
      if (await localFile.exists()) {
        final localFileSize = await localFile.length();
        if (localFileSize == file.size) {
          appLogger.iWithPackage('files_provider',
              '_downloadWithFlutterDownloader: 文件已存在且完整，跳过下载');
          return null; // 返回 null 表示文件已存在
        }
        // 文件存在但不完整，flutter_downloader 会自动断点续传
        appLogger.iWithPackage('files_provider',
            '_downloadWithFlutterDownloader: 文件已存在但不完整($localFileSize/${file.size} bytes)，将断点续传');
      }

      final timestamp =
          (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
      final authToken = _generate1PanelAuthToken(config.apiKey, timestamp);

      final downloadUrl =
          '${config.url}${ApiConstants.buildApiPath('/files/download')}?path=${Uri.encodeComponent(file.path)}';

      appLogger.iWithPackage('files_provider',
          '_downloadWithFlutterDownloader: 下载到外部存储 ${downloadDir.path}');

      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: downloadDir.path,
        fileName: file.name,
        showNotification: true,
        openFileFromNotification: true,
        headers: {
          '1Panel-Token': authToken,
          '1Panel-Timestamp': timestamp,
        },
      );

      if (taskId != null) {
        appLogger.iWithPackage('files_provider',
            '_downloadWithFlutterDownloader: 已创建下载任务 $taskId');
        return taskId;
      }

      return null;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
          'files_provider', '_downloadWithFlutterDownloader: 创建下载任务失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  String _generate1PanelAuthToken(String apiKey, String timestamp) {
    final authString = '1panel$apiKey$timestamp';
    final bytes = utf8.encode(authString);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<void> createFileLink({
    required String sourcePath,
    required String linkPath,
    required String linkType,
    bool? overwrite,
  }) async {
    appLogger.dWithPackage(
        'files_provider', 'createFileLink: source=$sourcePath, link=$linkPath');
    try {
      await _service.createFileLink(
        sourcePath: sourcePath,
        linkPath: linkPath,
        linkType: linkType,
        overwrite: overwrite,
      );
      appLogger.iWithPackage('files_provider', 'createFileLink: 成功创建链接');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'createFileLink: 创建链接失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> isStoragePermissionPermanentlyDenied() async {
    return await _service.isStoragePermissionPermanentlyDenied();
  }

  void cancelDownload() {
    _service.cancelDownload();
    _data = _data.copyWith(
      isDownloading: false,
      downloadProgress: 0.0,
      downloadingFileName: null,
    );
    notifyListeners();
  }
}
