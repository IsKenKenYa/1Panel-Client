part of '../files_provider.dart';

extension FilesProviderRecycleMixin on FilesProvider {
  Future<void> loadRecycleBinStatus() async {
    try {
      _data = _data.copyWith(
        recycleBinStatus: await _service.getRecycleBinStatus(),
      );
      _emitChange();
    } catch (e) {
      appLogger.eWithPackage(
        'files_provider',
        'loadRecycleBinStatus: 加载回收站状态失败',
        error: e,
      );
    }
  }

  Future<List<RecycleBinItem>> loadRecycleBinFiles({
    int page = 1,
    int pageSize = 100,
  }) async {
    appLogger.dWithPackage('files_provider', 'loadRecycleBinFiles: 加载回收站文件列表');
    try {
      final response = await _service.searchRecycleBin(
        path: '/',
        page: page,
        pageSize: pageSize,
      );
      final files = response
          .map(
            (file) => RecycleBinItem(
              sourcePath: file.path,
              name: file.name,
              isDir: file.isDir,
              size: file.size,
              deleteTime: file.modifiedAt,
              rName: file.gid ?? file.path.split('/').last,
              from: file.path.substring(0, file.path.lastIndexOf('/')),
            ),
          )
          .toList(growable: false);
      appLogger.iWithPackage(
        'files_provider',
        'loadRecycleBinFiles: 成功加载${files.length}个回收站文件',
      );
      return files;
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'files_provider',
        'loadRecycleBinFiles: 加载失败',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> restoreFile(RecycleBinItem file) async {
    appLogger.dWithPackage('files_provider', 'restoreFile: 恢复文件 ${file.name}');
    try {
      await _service.restoreFile(
        RecycleBinReduceRequest(rName: file.rName, from: file.from, name: file.name),
      );
      appLogger.iWithPackage('files_provider', 'restoreFile: 成功恢复文件 ${file.name}');
      await loadRecycleBinStatus();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'files_provider',
        'restoreFile: 恢复失败',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> restoreFiles(List<RecycleBinItem> files) async {
    appLogger.dWithPackage('files_provider', 'restoreFiles: 恢复${files.length}个文件');
    try {
      final requests = files
          .map(
            (file) => RecycleBinReduceRequest(
              rName: file.rName,
              from: file.from,
              name: file.name,
            ),
          )
          .toList(growable: false);
      await _service.restoreFiles(requests);
      appLogger.iWithPackage('files_provider', 'restoreFiles: 成功恢复${files.length}个文件');
      await loadRecycleBinStatus();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'files_provider',
        'restoreFiles: 恢复失败',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deletePermanently(RecycleBinItem file) async {
    appLogger.dWithPackage('files_provider', 'deletePermanently: 永久删除文件 ${file.name}');
    try {
      await _service.deleteRecycleBinFiles(<RecycleBinItem>[file]);
      appLogger.iWithPackage('files_provider', 'deletePermanently: 成功永久删除文件 ${file.name}');
      await loadRecycleBinStatus();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'files_provider',
        'deletePermanently: 删除失败',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deletePermanentlyFiles(List<RecycleBinItem> files) async {
    appLogger.dWithPackage('files_provider', 'deletePermanentlyFiles: 永久删除${files.length}个文件');
    try {
      await _service.deleteRecycleBinFiles(files);
      appLogger.iWithPackage(
        'files_provider',
        'deletePermanentlyFiles: 成功永久删除${files.length}个文件',
      );
      await loadRecycleBinStatus();
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'files_provider',
        'deletePermanentlyFiles: 删除失败',
        error: e,
        stackTrace: stackTrace,
      );
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
      appLogger.eWithPackage(
        'files_provider',
        'clearRecycleBin: 清空失败',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
