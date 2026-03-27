part of '../files_provider.dart';

extension FilesProviderSystemMixin on FilesProvider {
  Future<void> batchChangeFileRole({
    required List<String> paths,
    int? mode,
    String? user,
    String? group,
    bool? sub,
  }) async {
    appLogger.dWithPackage('files_provider', 'batchChangeFileRole: paths=$paths');
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
    return _service.getMountInfo();
  }

  Future<FileBatchCheckResult> batchCheckFiles(List<String> paths) async {
    appLogger.dWithPackage('files_provider', 'batchCheckFiles: paths=$paths');
    return _service.batchCheckFiles(paths);
  }

  Future<void> changeFileMode(String path, int mode, {bool? sub}) async {
    appLogger.dWithPackage(
      'files_provider',
      'changeFileMode: path=$path, mode=$mode, sub=$sub',
    );
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

  Future<void> changeFileOwner(
    String path,
    String user,
    String group, {
    bool? sub,
  }) async {
    appLogger.dWithPackage(
      'files_provider',
      'changeFileOwner: path=$path, user=$user, group=$group, sub=$sub',
    );
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
        'files_provider',
        'downloadFile: 大文件(${file.size} bytes)，建议使用分块下载',
      );
    }

    return _downloadWithFlutterDownloader(file);
  }

  Future<String?> _downloadWithFlutterDownloader(FileInfo file) async {
    try {
      final config = await ApiConfigManager.getCurrentConfig();
      if (config == null) {
        throw StateError('No server configured');
      }

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
      if (await localFile.exists()) {
        final localFileSize = await localFile.length();
        final isLikelyComplete =
            file.size == localFileSize && localFileSize > 0;
        if (isLikelyComplete) {
          appLogger.iWithPackage('files_provider', 'downloadFile: 文件已存在且完整');
          return localFile.path;
        }
      }

      final timestamp =
          (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
      final authToken = _generate1PanelAuthToken(config.apiKey, timestamp);
      final taskId = await FlutterDownloader.enqueue(
        url:
            '${config.url}${ApiConstants.buildApiPath('/files/download')}?path=${Uri.encodeComponent(file.path)}',
        savedDir: downloadPath,
        fileName: file.name,
        headers: <String, String>{
          '1Panel-Token': authToken,
          '1Panel-Timestamp': timestamp,
        },
        showNotification: true,
        openFileFromNotification: true,
      );

      if (taskId == null) {
        appLogger.eWithPackage(
          'files_provider',
          '_downloadWithFlutterDownloader: 创建下载任务失败',
        );
        return null;
      }
      return taskId;
    } catch (e, stackTrace) {
      appLogger.eWithPackage('files_provider', '_downloadWithFlutterDownloader: 失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> createFileLink({
    required String sourcePath,
    required String linkPath,
    required String linkType,
    bool? overwrite,
  }) async {
    appLogger.dWithPackage('files_provider', 'createFileLink: source=$sourcePath, link=$linkPath');
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
    return _service.isStoragePermissionPermanentlyDenied();
  }

  void cancelDownload() {
    _service.cancelDownload();
  }

  String _generate1PanelAuthToken(String apiKey, String timestamp) {
    final authString = '1panel$apiKey$timestamp';
    final bytes = utf8.encode(authString);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}
