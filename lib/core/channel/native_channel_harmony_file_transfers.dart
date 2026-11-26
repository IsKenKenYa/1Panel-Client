import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

import '../../data/models/file_models.dart';
import '../../data/models/paged_query.dart';
import '../../data/repositories/files_repository.dart';
import '../../features/files/files_provider.dart';
import '../../features/files/providers/file_preview_provider.dart';
import '../../features/files/providers/transfer_manager_provider.dart';
import '../../features/files/services/file_browser_service.dart';
import '../../features/files/services/file_preview_service.dart';
import '../../features/files/services/file_transfer_service.dart';
import '../config/api_config.dart';
import '../platform/services/ohos_download_service.dart';
import '../platform/services/ohos_platform_channel.dart';
import '../platform/services/platform_file_service.dart';
import '../services/app_preferences_service.dart';
import '../services/cache/file_preview_cache_manager.dart';
import '../services/transfer/transfer_manager.dart';

class NativeChannelHarmonyFileTransfers {
  static final _fileService = PlatformFileService();
  static final _downloads = OhosDownloadService.defaultChannels(_fileService);
  static final _transferManager = TransferManager();
  static final _downloadProvider = TransferManagerProvider(
    ohosDownloadService: _downloads,
  );
  static final _uploads = <String, Map<String, Object?>>{};
  static final _previews = <String, FilePreviewProvider>{};
  static final _previewFiles = <String, String>{};

  static Future<Object?> dispatch(String method, dynamic arguments) async {
    final args = Map<String, Object?>.from(arguments as Map? ?? const {});
    switch (method) {
      case 'getHarmonyFileTransfers':
        return _tasks();
      case 'getHarmonyFileDirectory':
        final page = await FileBrowserService().searchFiles(
          path: args['path'] as String,
          search: args['search'] as String?,
          page: args['page'] as int,
          pageSize: PagedQuery.listPageSize,
          expand: true,
          sortBy: args['sortBy'] as String?,
          sortOrder: args['sortOrder'] as String?,
        );
        return {
          'items': [
            for (final file in page.items)
              {
                'name': file.name,
                'path': file.path,
                'isDir': file.isDir,
                'size': file.size,
                'modTime': file.modifiedAt?.millisecondsSinceEpoch,
              },
          ],
          'hasMore': (args['page'] as int) * PagedQuery.listPageSize < page.total,
        };
      case 'operateHarmonyFileTransfer':
        return _operate(args);
      case 'enqueueHarmonyFileDownload':
        final provider = FilesProvider();
        try {
          return await provider.downloadFile(
            FileInfo(
              name: args['name'] as String,
              path: args['path'] as String,
              size: args['size'] as int,
              type: 'file',
            ),
          );
        } finally {
          provider.dispose();
        }
      case 'uploadHarmonyFiles':
        return _uploadFiles(args['path'] as String);
      case 'moveHarmonyFiles':
        final service = FileBrowserService();
        final sources = (args['oldPaths'] as List).cast<String>();
        final destination = args['newPath'] as String;
        if (args['type'] == 'copy') {
          await service.copyFiles(sources, destination);
        } else {
          await service.moveFiles(sources, destination);
        }
        return {'success': true};
      case 'getHarmonyFileUploadHistory':
        final files = await FileTransferService().searchUploadedFiles(
          path: args['path'] as String,
          page: args['page'] as int,
          pageSize: PagedQuery.searchPageSize,
        );
        return {
          'items': [
            for (final file in files)
              {'name': file.name, 'size': file.size},
          ],
          'hasMore': files.length == PagedQuery.searchPageSize,
        };
      case 'getHarmonyFilePreview':
        return _preview(args);
      case 'releaseHarmonyFilePreview':
        await _releasePreview(args['session'] as String);
        return null;
      case 'getHarmonyFileEditor':
        return FilePreviewService().readFile(
          args['path'] as String,
          encoding: args['encoding'] as String,
        );
      case 'saveHarmonyFileEditor':
        await FilePreviewService().saveFile(
          args['path'] as String,
          args['content'] as String,
          encoding: args['encoding'] as String,
        );
        return null;
      case 'openHarmonyFilePreview':
        return _openSavedPath(args['localPath'] as String);
      default:
        throw MissingPluginException(method);
    }
  }

  static Future<Map<String, Object>> _tasks() async {
    await _downloadProvider.loadTasks();
    return {
      'downloads': [
        for (final task in _downloadProvider.getActiveDownloads())
          _downloadRow(task, isCompleted: false),
        for (final task in _downloadProvider.getCompletedDownloads())
          _downloadRow(task, isCompleted: true),
      ],
      'uploads': [
        ..._uploads.values,
        for (final task in [
          ..._transferManager.activeTasks,
          ..._transferManager.pendingTasks,
        ])
          {
            'id': task.id,
            'name': task.fileName ?? task.path.split('/').last,
            'status': task.status.name,
            'progress': (task.progress * 100).round(),
            'isCompleted': false,
            'canControl': true,
            'error': task.error,
          },
      ],
    };
  }

  static Map<String, Object?> _downloadRow(
    DownloadTask task, {
    required bool isCompleted,
  }) {
    final status = switch (task.status) {
      DownloadTaskStatus.running => 'running',
      DownloadTaskStatus.paused => 'paused',
      DownloadTaskStatus.enqueued => 'pending',
      DownloadTaskStatus.canceled => 'cancelled',
      _ => isCompleted ? 'completed' : 'failed',
    };
    return {
      'id': task.taskId,
      'name': task.filename,
      'status': status,
      'progress': task.progress,
      'isCompleted': isCompleted,
      'canControl': true,
    };
  }

  static Future<String?> _operate(Map<String, Object?> args) async {
    final action = args['action'] as String;
    if (action == 'clear') {
      await _downloadProvider.clearCompletedDownloads();
      return null;
    }
    final id = args['id'] as String;
    if (args['upload'] == true) {
      switch (action) {
        case 'pause':
          _transferManager.pauseTask(id);
        case 'resume':
          _transferManager.resumeTask(id);
        case 'cancel':
          _transferManager.cancelUploadTask(id);
        default:
          throw ArgumentError.value(action, 'action');
      }
      return null;
    }

    switch (action) {
      case 'pause':
        await _downloadProvider.pauseTask(id);
      case 'resume':
        await _downloadProvider.resumeTask(id);
      case 'cancel':
        await _downloadProvider.cancelTask(id);
      case 'delete':
        await _downloadProvider.deleteTask(id);
      case 'retry':
        await _downloadProvider.loadTasks();
        final task = _downloadProvider.getActiveDownloads().firstWhere(
          (item) => item.taskId == id,
        );
        final result = await _downloadProvider.retryTaskWithNewAuth(task);
        if (result == RetryDownloadTaskWithNewAuthResult.fileAlreadyDownloaded) {
          return 'transferFileAlreadyDownloaded';
        }
        if (result == RetryDownloadTaskWithNewAuthResult.failed) {
          return 'transferStatusFailed';
        }
      case 'open':
        final path = await _downloadProvider.savedDownloadLocation(id);
        if (path == null) return 'transferFileNotFound';
        if (!await _openSavedPath(path)) {
          return 'transferOpenFileError';
        }
      default:
        throw ArgumentError.value(action, 'action');
    }
    return null;
  }

  static Future<bool> _openSavedPath(String path) {
    final uri = Uri.parse(path);
    return _fileService.openSaveOutcome(SaveOutcome(
      uri: path,
      displayName: uri.pathSegments.last,
      kind: uri.hasScheme ? SaveLocationKind.pickerUri : SaveLocationKind.other,
    ));
  }

  static Future<Map<String, Object?>> _preview(Map<String, Object?> args) async {
    final session = args['session'] as String;
    if (args['next'] == true) {
      final provider = _previews[session];
      if (provider == null) throw StateError('Preview is closed');
      final previousLength = provider.pagedLines.length;
      await provider.loadMorePreviewLines();
      return {
        'content': provider.pagedLines.skip(previousLength).join('\n'),
        'hasMore': provider.hasMoreLines,
      };
    }
    await _releasePreview(session);
    final fileName = args['name'] as String;
    final provider = FilePreviewProvider(
      filePath: args['path'] as String,
      fileName: fileName,
      fileSize: args['size'] as int?,
      initialLine: args['line'] as int?,
    );
    _previews[session] = provider;
    final preferences = AppPreferencesService();
    await provider.initialize(
      cacheStrategy: await preferences.loadCacheStrategy(),
      cacheMaxSizeMB: await preferences.loadCacheMaxSizeMB(),
    );
    if (provider.error case final error?) throw StateError(error);
    var localPath = provider.localFilePath;
    final bytes = provider.binaryData;
    if (localPath == null && bytes != null) {
      localPath = await FilePreviewCacheManager().saveToTempFile(bytes, fileName);
      if (localPath != null) {
        if (_previews[session] != provider) {
          await FilePreviewCacheManager().releaseViewerFile(localPath);
        } else {
          _previewFiles[session] = localPath;
        }
      }
    }
    return {
      'kind': provider.fileType.name,
      'content': provider.usePagedTextPreview
          ? provider.pagedLines.join('\n')
          : provider.content,
      'hasMore': provider.usePagedTextPreview && provider.hasMoreLines,
      'localPath': localPath,
    };
  }

  static Future<void> _releasePreview(String session) async {
    final provider = _previews.remove(session);
    if (provider != null) {
      provider.dispose();
      await provider.releaseViewerFile();
    }
    final path = _previewFiles.remove(session);
    if (path != null) await FilePreviewCacheManager().releaseViewerFile(path);
  }

  static Future<int> _uploadFiles(String path) async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) throw StateError('No server configured');
    final repository = FilesRepository(
      api: FilesRepository().getApiForConfig(config),
    );
    final service = FileBrowserService(repository: repository);
    final selected = await _fileService.pickFiles();
    final batchId = DateTime.now().microsecondsSinceEpoch.toString();
    for (final localPath in selected) {
      final name = localPath.split('/').last;
      final row = <String, Object?>{
        'id': batchId,
        'name': name,
        'status': 'running',
        'progress': 0,
        'isCompleted': false,
        'canControl': false,
      };
      _uploads[batchId] = row;
      try {
        await service.uploadLocalFile(
          dir: path,
          localPath: localPath,
          onProgress: (progress) => row['progress'] = (progress * 100).round(),
        );
      } finally {
        _uploads.remove(batchId);
      }
    }
    return selected.length;
  }
}
