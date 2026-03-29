part of '../files_provider.dart';

extension FilesProviderBrowserMixin on FilesProvider {
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

  Future<void> uploadFiles(List<String> filePaths, {String? targetPath}) async {
    final resolvedTargetPath = _normalizePath(targetPath ?? _data.currentPath);
    appLogger.dWithPackage('files_provider',
        'uploadFiles: filePaths=$filePaths, targetPath=$resolvedTargetPath');
    try {
      for (final filePath in filePaths) {
        final file = await MultipartFile.fromFile(filePath);
        await _service.uploadFile(resolvedTargetPath, file);
      }
      appLogger.iWithPackage(
          'files_provider', 'uploadFiles: 成功上传 ${filePaths.length} 个文件');
      _rememberPathForServer(_data.currentServer?.id, resolvedTargetPath);

      if (_normalizePath(_data.currentPath) == resolvedTargetPath) {
        await refresh();
      }
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
      await _service.deleteFiles(<String>[path]);
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
      await _service.moveFiles(<String>[sourcePath], targetPath);
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
      await _service.copyFiles(<String>[sourcePath], targetPath);
      appLogger.iWithPackage('files_provider', 'copyFile: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'copyFile: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<String> getFileContent(String path) async =>
      _service.getFileContent(path);

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
    List<String> files,
    String dst,
    String name,
    String type, {
    String? secret,
  }) async {
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
    return _service.getFileSize(path, recursive: true);
  }
}
