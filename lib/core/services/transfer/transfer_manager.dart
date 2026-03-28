import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/transfer/transfer_task.dart';
import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/data/models/file/file_transfer.dart';

enum RetryDownloadTaskWithNewAuthResult {
  recreated,
  fileAlreadyDownloaded,
  failed,
}

@pragma('vm:entry-point')
class TransferManager extends ChangeNotifier {
  static final TransferManager _instance = TransferManager._internal();
  @pragma('vm:entry-point')
  factory TransferManager() => _instance;

  TransferManager._internal();

  void init() {
    // 初始化完成，flutter_downloader 使用内置 SQLite
  }

  /// 获取 flutter_downloader 的所有下载任务（从内置 SQLite 数据库）
  Future<List<DownloadTask>?> getDownloaderTasks() async {
    try {
      return await FlutterDownloader.loadTasks();
    } catch (e) {
      appLogger.wWithPackage('transfer', 'getDownloaderTasks: 查询失败 $e');
      return null;
    }
  }

  /// 获取 flutter_downloader 的进行中任务
  Future<List<DownloadTask>?> getRunningDownloaderTasks() async {
    try {
      return await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE status = 2",
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取 flutter_downloader 的已完成任务
  Future<List<DownloadTask>?> getCompletedDownloaderTasks() async {
    try {
      return await FlutterDownloader.loadTasksWithRawQuery(
        query: "SELECT * FROM task WHERE status = 3",
      );
    } catch (e) {
      return null;
    }
  }

  /// 获取所有下载任务（仅从 flutter_downloader SQLite）
  Future<List<DownloadTask>> getAllDownloadTasks() async {
    final tasks = await getDownloaderTasks();
    return tasks ?? [];
  }

  /// 取消下载任务
  Future<void> cancelDownloadTask(String taskId) async {
    try {
      await FlutterDownloader.cancel(taskId: taskId);
      appLogger.iWithPackage('transfer', 'cancelDownloadTask: 已取消任务 $taskId');
    } catch (e) {
      appLogger.wWithPackage('transfer', 'cancelDownloadTask: 取消任务失败 $e');
    }
  }

  /// 暂停下载任务
  Future<void> pauseDownloadTask(String taskId) async {
    try {
      await FlutterDownloader.pause(taskId: taskId);
      appLogger.iWithPackage('transfer', 'pauseDownloadTask: 已暂停任务 $taskId');
    } catch (e) {
      appLogger.wWithPackage('transfer', 'pauseDownloadTask: 暂停任务失败 $e');
    }
  }

  /// 恢复下载任务
  Future<void> resumeDownloadTask(String taskId) async {
    try {
      await FlutterDownloader.resume(taskId: taskId);
      appLogger.iWithPackage('transfer', 'resumeDownloadTask: 已恢复任务 $taskId');
    } catch (e) {
      appLogger.wWithPackage('transfer', 'resumeDownloadTask: 恢复任务失败 $e');
    }
  }

  String _generate1PanelAuthToken(String apiKey, String timestamp) {
    final authString = '1panel$apiKey$timestamp';
    final bytes = utf8.encode(authString);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 重试下载任务（使用新时间戳）
  /// 不使用 FlutterDownloader.retry()，因为它会复用旧时间戳导致认证失败
  /// 返回值：
  /// - recreated: 成功创建新任务
  /// - fileAlreadyDownloaded: 文件已下载完成，无需重试
  /// - failed: 创建新任务失败
  Future<RetryDownloadTaskWithNewAuthResult> retryDownloadTaskWithNewAuth(
    DownloadTask task,
  ) async {
    try {
      final uri = Uri.tryParse(task.url);
      if (uri == null) {
        appLogger.eWithPackage(
            'transfer', 'retryDownloadTaskWithNewAuth: 无法解析 URL');
        return RetryDownloadTaskWithNewAuthResult.failed;
      }

      final fileName = task.filename ??
          (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null);
      if (fileName == null || fileName.isEmpty) {
        appLogger.eWithPackage(
            'transfer', 'retryDownloadTaskWithNewAuth: 无法确定文件名');
        return RetryDownloadTaskWithNewAuthResult.failed;
      }

      final file = File('${task.savedDir}/$fileName');
      if (await file.exists()) {
        final fileSize = await file.length();
        final isLikelyComplete =
            task.status == DownloadTaskStatus.complete || task.progress == 100;
        if (fileSize > 0 && isLikelyComplete) {
          appLogger.iWithPackage(
            'transfer',
            'retryDownloadTaskWithNewAuth: 文件已下载完成($fileSize bytes)，无需重试',
          );
          return RetryDownloadTaskWithNewAuthResult.fileAlreadyDownloaded;
        }
      }

      // 3. 从 URL 提取文件路径
      final filePath = uri.queryParameters['path'];
      if (filePath == null) {
        appLogger.eWithPackage(
            'transfer', 'retryDownloadTaskWithNewAuth: 无法从 URL 提取文件路径');
        return RetryDownloadTaskWithNewAuthResult.failed;
      }

      // 4. 获取服务器配置并生成新的认证
      final config = await ApiConfigManager.getCurrentConfig();
      if (config == null) {
        appLogger.eWithPackage(
            'transfer', 'retryDownloadTaskWithNewAuth: 未找到服务器配置');
        return RetryDownloadTaskWithNewAuthResult.failed;
      }

      final timestamp =
          (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
      final authToken = _generate1PanelAuthToken(config.apiKey, timestamp);

      // 5. 创建新任务（不删除部分文件，支持断点续传）
      final newTaskId = await FlutterDownloader.enqueue(
        url: task.url,
        savedDir: task.savedDir,
        fileName: fileName,
        headers: {
          '1Panel-Token': authToken,
          '1Panel-Timestamp': timestamp,
        },
        showNotification: true,
        openFileFromNotification: true,
      );

      if (newTaskId != null) {
        try {
          await FlutterDownloader.remove(taskId: task.taskId);
          appLogger.iWithPackage(
            'transfer',
            'retryDownloadTaskWithNewAuth: 已创建新任务 $newTaskId，并删除旧任务 ${task.taskId}',
          );
        } catch (e) {
          appLogger.wWithPackage(
            'transfer',
            'retryDownloadTaskWithNewAuth: 已创建新任务 $newTaskId，但删除旧任务失败: $e',
          );
        }
        return RetryDownloadTaskWithNewAuthResult.recreated;
      }

      return RetryDownloadTaskWithNewAuthResult.failed;
    } catch (e, stackTrace) {
      appLogger.eWithPackage('transfer', 'retryDownloadTaskWithNewAuth: 失败',
          error: e, stackTrace: stackTrace);
      return RetryDownloadTaskWithNewAuthResult.failed;
    }
  }

  /// 删除下载任务记录
  Future<void> deleteDownloadTask(String taskId) async {
    try {
      await FlutterDownloader.remove(taskId: taskId);
      appLogger.iWithPackage('transfer', 'deleteDownloadTask: 已删除任务 $taskId');
    } catch (e) {
      appLogger.wWithPackage('transfer', 'deleteDownloadTask: 删除任务失败 $e');
    }
  }

  /// 清除已完成的下载任务
  Future<void> clearCompletedDownloads() async {
    try {
      final completedTasks = await getCompletedDownloaderTasks();
      if (completedTasks != null) {
        for (final task in completedTasks) {
          await FlutterDownloader.remove(taskId: task.taskId);
        }
      }
      appLogger.iWithPackage('transfer', 'clearCompletedDownloads: 已清除已完成任务');
    } catch (e) {
      appLogger.wWithPackage('transfer', 'clearCompletedDownloads: 清除失败 $e');
    }
  }

  // ============ 上传相关代码（保留，因为 1Panel API 需要分块上传） ============

  final Queue<TransferTask> _pendingQueue = Queue();
  final Map<String, TransferTask> _activeTasks = {};

  static const int _maxConcurrent = 3;
  static const int _defaultChunkSize = 1024 * 1024;

  FileV2Api? _api;

  Function(TransferTask task)? onTaskCompleted;
  Function(TransferTask task)? onTaskFailed;

  List<TransferTask> get pendingTasks => _pendingQueue.toList();
  List<TransferTask> get activeTasks => _activeTasks.values.toList();

  int get activeCount => _activeTasks.length;
  int get pendingCount => _pendingQueue.length;

  void setApi(FileV2Api api) {
    _api = api;
  }

  Future<String> _generateTaskId(String path, TransferType type) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final hash = md5.convert(utf8.encode('$path$type$timestamp')).toString();
    return hash.substring(0, 8);
  }

  void _processQueue() {
    while (_activeTasks.length < _maxConcurrent && _pendingQueue.isNotEmpty) {
      final task = _pendingQueue.removeFirst();
      _startUploadTask(task);
    }
  }

  Future<void> _startUploadTask(TransferTask task) async {
    task = task.copyWith(
      status: TransferStatus.running,
      startedAt: DateTime.now(),
    );
    _activeTasks[task.id] = task;
    notifyListeners();

    try {
      await _executeUpload(task);

      task = task.copyWith(
        status: TransferStatus.completed,
        completedAt: DateTime.now(),
      );
      _activeTasks.remove(task.id);
      onTaskCompleted?.call(task);
    } catch (e, stackTrace) {
      appLogger.eWithPackage('transfer', '_startUploadTask: 上传失败',
          error: e, stackTrace: stackTrace);
      task = task.copyWith(
        status: TransferStatus.failed,
        error: e.toString(),
      );
      _activeTasks.remove(task.id);
      onTaskFailed?.call(task);
    }

    notifyListeners();
    _processQueue();
  }

  Future<void> _executeUpload(TransferTask task) async {
    if (_api == null) throw Exception('API not initialized');

    final file = File(task.path);
    if (!await file.exists()) throw Exception('File not found: ${task.path}');

    final totalChunks = task.totalChunks;
    final uploadedChunks = Set<int>.from(task.uploadedChunks);

    for (var i = 0; i < totalChunks; i++) {
      if (uploadedChunks.contains(i)) continue;

      final activeTask = _activeTasks[task.id];
      if (activeTask?.status == TransferStatus.paused ||
          activeTask?.status == TransferStatus.cancelled) {
        throw Exception('Transfer ${activeTask?.status}');
      }

      final start = i * _defaultChunkSize;
      final end = (start + _defaultChunkSize > task.totalSize)
          ? task.totalSize
          : start + _defaultChunkSize;

      final randomAccessFile = await file.open();
      await randomAccessFile.setPosition(start);
      final bytes = await randomAccessFile.read(end - start);
      await randomAccessFile.close();

      final base64Data = base64Encode(bytes);
      final isLastChunk = i == totalChunks - 1;

      final response = await _api!.chunkUpload(FileChunkUpload(
        path: task.path,
        data: base64Data,
        chunkNumber: i + 1,
        isLastChunk: isLastChunk,
      ));

      if (response.data?.success == true) {
        uploadedChunks.add(i);

        task = task.copyWith(
          uploadedChunks: uploadedChunks,
          completedChunks: uploadedChunks.length,
          transferredSize: uploadedChunks.length * _defaultChunkSize,
        );
        _activeTasks[task.id] = task;
        notifyListeners();
      }
    }
  }

  Future<TransferTask> createUploadTask({
    required String path,
    required File file,
    String? fileName,
  }) async {
    final stat = await file.stat();
    final totalSize = stat.size;
    final totalChunks = (totalSize / _defaultChunkSize).ceil();

    final task = TransferTask(
      id: await _generateTaskId(path, TransferType.upload),
      path: path,
      fileName: fileName ?? file.path.split('/').last,
      totalSize: totalSize,
      type: TransferType.upload,
      totalChunks: totalChunks,
      createdAt: DateTime.now(),
    );

    _pendingQueue.add(task);
    notifyListeners();
    _processQueue();

    return task;
  }

  void pauseTask(String taskId) {
    final task = _activeTasks[taskId];
    if (task != null) {
      _activeTasks[taskId] = task.copyWith(status: TransferStatus.paused);
      notifyListeners();
    }
  }

  void resumeTask(String taskId) {
    TransferTask? task = _activeTasks[taskId];
    if (task != null && task.status == TransferStatus.paused) {
      _activeTasks[taskId] = task.copyWith(status: TransferStatus.running);
      notifyListeners();
      _processQueue();
    }
  }

  void cancelUploadTask(String taskId) {
    TransferTask? task = _activeTasks[taskId];
    if (task != null) {
      _activeTasks[taskId] = task.copyWith(status: TransferStatus.cancelled);
      _activeTasks.remove(taskId);
      notifyListeners();
      _processQueue();
    }
  }

  /// 统一取消任务（自动判断是下载还是上传）
  Future<void> cancelTask(String taskId) async {
    // 先检查是否是上传任务
    if (_activeTasks.containsKey(taskId)) {
      cancelUploadTask(taskId);
      return;
    }

    // 否则作为下载任务处理
    await cancelDownloadTask(taskId);
  }

  /// 清除已完成任务（上传和下载）
  Future<void> clearCompleted() async {
    // 清除已完成的下载任务
    await clearCompletedDownloads();

    // 清除已完成的上传任务（从内存中移除）
    _activeTasks.removeWhere((key, task) =>
        task.status == TransferStatus.completed ||
        task.status == TransferStatus.cancelled);

    notifyListeners();
  }

  /// 获取所有任务（合并上传和下载）
  /// 注意：此方法返回 Future，UI 层需要使用 FutureBuilder
  Future<List<dynamic>> getAllTasks() async {
    final downloadTasks = await getAllDownloadTasks();
    final uploadTasks = [..._activeTasks.values, ..._pendingQueue];
    return [...downloadTasks, ...uploadTasks];
  }

  /// 获取已完成的任务
  Future<List<dynamic>> getCompletedTasks() async {
    final downloadTasks = await getCompletedDownloaderTasks() ?? [];
    final uploadTasks = _activeTasks.values
        .where((t) => t.status == TransferStatus.completed)
        .toList();
    return [...downloadTasks, ...uploadTasks];
  }

  @override
  void dispose() {
    _pendingQueue.clear();
    _activeTasks.clear();
    super.dispose();
  }
}
