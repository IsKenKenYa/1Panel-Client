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

  Future<void> moveFiles(List<String> sourcePaths, String targetPath) async {
    appLogger.dWithPackage('files_provider',
        'moveFiles: sources=${sourcePaths.length}, target=$targetPath');
    try {
      await _service.moveFiles(sourcePaths, targetPath);
      appLogger.iWithPackage('files_provider', 'moveFiles: 成功');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'moveFiles: 失败',
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

  Future<Map<String, String>> loadFileRemarks(List<String> paths) async {
    appLogger.dWithPackage(
        'files_provider', 'loadFileRemarks: paths=${paths.length}');
    try {
      return await _service.getFileRemarks(paths);
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'loadFileRemarks: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateFileRemark(
    String path,
    String remark, {
    bool refreshAfterSave = true,
  }) async {
    appLogger.dWithPackage(
      'files_provider',
      'updateFileRemark: path=$path, remarkLength=${remark.length}',
    );
    try {
      await _service.setFileRemark(path, remark);
      appLogger.iWithPackage('files_provider', 'updateFileRemark: 成功');
      if (refreshAfterSave) {
        await refresh();
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'updateFileRemark: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> convertFile(
    FileInfo file, {
    required String outputFormat,
    String? outputPath,
    bool deleteSource = false,
    String? taskId,
  }) async {
    if (file.isDir) {
      throw ArgumentError('Directory cannot be converted');
    }

    final normalizedOutputFormat = outputFormat.trim().toLowerCase();
    if (normalizedOutputFormat.isEmpty) {
      throw ArgumentError('Output format is required');
    }

    final extension = _resolveFileExtension(file);
    if (extension.isEmpty) {
      throw ArgumentError('File extension is required for conversion');
    }

    final slashIndex = file.path.lastIndexOf('/');
    final parentPath =
        slashIndex <= 0 ? '/' : file.path.substring(0, slashIndex);
    final resolvedOutputPath = _normalizePath(outputPath ?? _data.currentPath);
    final resolvedTaskId = taskId?.isNotEmpty == true
        ? taskId
        : 'file-convert-${DateTime.now().millisecondsSinceEpoch}';

    appLogger.dWithPackage(
      'files_provider',
      'convertFile: file=${file.path}, output=$normalizedOutputFormat, dst=$resolvedOutputPath',
    );

    try {
      await _service.convertFiles(
        files: <FileMediaConvertItem>[
          FileMediaConvertItem(
            path: parentPath,
            type: file.type,
            inputFile: file.name,
            extension: extension,
            outputFormat: normalizedOutputFormat,
          ),
        ],
        outputPath: resolvedOutputPath,
        deleteSource: deleteSource,
        taskId: resolvedTaskId,
      );
      appLogger.iWithPackage('files_provider', 'convertFile: 转换任务已提交');
      await refresh();
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', 'convertFile: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  String _resolveFileExtension(FileInfo file) {
    final modelExtension = file.extension;
    if (modelExtension != null && modelExtension.trim().isNotEmpty) {
      final trimmed = modelExtension.trim();
      return trimmed.startsWith('.') ? trimmed : '.$trimmed';
    }

    final dotIndex = file.name.lastIndexOf('.');
    if (dotIndex > 0 && dotIndex < file.name.length - 1) {
      return file.name.substring(dotIndex);
    }
    return '';
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
