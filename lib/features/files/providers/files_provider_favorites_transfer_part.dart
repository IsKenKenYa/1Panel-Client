part of '../files_provider.dart';

extension FilesProviderFavoritesTransferMixin on FilesProvider {
  Future<void> loadFavorites() async {
    appLogger.dWithPackage('files_provider', 'loadFavorites: 开始加载收藏夹');
    try {
      final favorites = await _service.searchFavoriteFiles(path: '/');
      final favoritePaths = favorites.map((file) => file.path).toSet();
      _data = _data.copyWith(
        favorites: favorites,
        favoritePaths: favoritePaths,
      );
      appLogger.iWithPackage(
          'files_provider', 'loadFavorites: 成功加载${favorites.length}个收藏');
      _emitChange();
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
      final newFavorites = <FileInfo>[..._data.favorites, file];
      final newFavoritePaths = <String>{..._data.favoritePaths, file.path};
      _data = _data.copyWith(
        favorites: newFavorites,
        favoritePaths: newFavoritePaths,
      );
      appLogger.iWithPackage('files_provider', 'addToFavorites: 成功');
      _emitChange();
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
      final newFavorites = _data.favorites
          .where((file) => file.path != path)
          .toList(growable: false);
      final newFavoritePaths = Set<String>.from(_data.favoritePaths)
        ..remove(path);
      _data = _data.copyWith(
        favorites: newFavorites,
        favoritePaths: newFavoritePaths,
      );
      appLogger.iWithPackage('files_provider', 'removeFromFavorites: 成功');
      _emitChange();
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
    appLogger.dWithPackage(
      'files_provider',
      'wgetDownload: url=$url, path=${_data.currentPath}, name=$name',
    );

    _data = _data.copyWith(
      wgetStatus: const WgetDownloadStatus(
        state: WgetDownloadState.downloading,
        message: '正在创建下载任务...',
      ),
    );
    _emitChange();

    try {
      final result = await _service.wgetDownload(
        url: url,
        path: _data.currentPath,
        name: name,
        ignoreCertificate: ignoreCertificate,
      );

      if (result.success) {
        final message = result.key != null ? '下载任务已创建' : '下载成功';
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
        _data = _data.copyWith(
          wgetStatus: WgetDownloadStatus(
            state: WgetDownloadState.error,
            message: result.error ?? '下载失败',
          ),
        );
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'wgetDownload: 下载异常, error=$e',
          error: e, stackTrace: stackTrace);
      final errorMsg = e.toString();
      _data = _data.copyWith(
        wgetStatus: WgetDownloadStatus(
          state: WgetDownloadState.error,
          message: errorMsg.contains('Exception:')
              ? errorMsg.split('Exception:').last.trim()
              : errorMsg,
        ),
      );
    }
    _emitChange();
  }

  void clearWgetStatus() {
    _data = _data.copyWith(wgetStatus: null);
    _emitChange();
  }

  Future<List<FileInfo>> searchUploadedFiles({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    appLogger.dWithPackage('files_provider', 'searchUploadedFiles: page=$page');
    try {
      return await _service.searchUploadedFiles(
        page: page,
        pageSize: pageSize,
        search: search,
      );
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'searchUploadedFiles: 获取上传记录失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
