import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/platform/services/ohos_download_service.dart';
import 'package:onepanel_client/core/platform/services/platform_download_service.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/network/onepanel_auth_headers.dart';
import 'package:onepanel_client/core/services/transfer/one_panel_download_source.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/transfer/transfer_manager.dart';

const _tag = 'features.files.transfer_provider';

enum TransferChannel { downloads, uploads }

class TransferManagerProvider extends ChangeNotifier with SafeChangeNotifier {
  TransferManagerProvider({
    TransferManager? transferManager,
    Future<List<DownloadTask>?> Function()? loadTasksOverride,
    Future<void> Function()? clearCompletedOverride,
    PlatformCapabilitiesSnapshot? capabilities,
    OhosDownloadService? ohosDownloadService,
  })  : _transferManager = transferManager ?? TransferManager(),
        _loadTasksOverride = loadTasksOverride,
        _clearCompletedOverride = clearCompletedOverride,
        _capabilities = capabilities ?? PlatformCapabilities.current(),
        _ohosDownloadService = ohosDownloadService;

  final TransferManager _transferManager;
  final Future<List<DownloadTask>?> Function()? _loadTasksOverride;
  final Future<void> Function()? _clearCompletedOverride;
  final PlatformCapabilitiesSnapshot _capabilities;
  OhosDownloadService? _ohosDownloadService;
  StreamSubscription<OhosDownloadProgress>? _ohosProgressSub;

  TransferChannel _channel = TransferChannel.downloads;
  List<DownloadTask>? _downloadTasks;
  bool _isLoading = true;
  Timer? _refreshTimer;

  bool get _useOhosDownloader =>
      _capabilities.supportsNativeDownloader && _ohosDownloadService != null;

  TransferChannel get channel => _channel;
  List<DownloadTask>? get downloadTasks => _downloadTasks;
  bool get isLoading => _isLoading;
  bool get isDownloadSupported =>
      _capabilities.supportsBackgroundDownloader ||
      _capabilities.supportsNativeDownloader;
  String? get unsupportedReason =>
      isDownloadSupported ? null : 'transferBackgroundDownloadUnsupported';

  Future<void> initialize() async {
    if (_capabilities.supportsNativeDownloader) {
      _initOhosDownloadService();
    }
    if (!isDownloadSupported) {
      _downloadTasks = const <DownloadTask>[];
      _isLoading = false;
      notifyListeners();
      return;
    }
    await loadTasks();
    // OHOS native downloader pushes progress via EventChannel, so polling is wasteful.
    // Android/flutter_downloader has no push mechanism, so we poll every 2s instead.
    if (!_capabilities.supportsNativeDownloader) {
      _startAutoRefresh();
    }
  }

  void _initOhosDownloadService() {
    if (_ohosDownloadService != null) return;
    // The factory wires the canonical channel names from OhosChannelNames,
    // keeping channel literals inside the platform layer (AGENTS.md: business
    // code must not construct raw MethodChannel/EventChannel).
    _ohosDownloadService = OhosDownloadService.defaultChannels(
      PlatformFileService(),
    );
    _ohosProgressSub = _ohosDownloadService!.onProgress.listen((_) {
      loadTasks();
    });
  }

  void setChannel(TransferChannel channel) {
    _channel = channel;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    if (!isDownloadSupported) {
      _downloadTasks = const <DownloadTask>[];
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_useOhosDownloader) {
      final ohosTasks = await _ohosDownloadService!.listTasks();
      _downloadTasks = ohosTasks.map(_ohosTaskToDownloadTask).toList();
    } else {
      final tasks = await (_loadTasksOverride?.call() ??
          _transferManager.getDownloaderTasks());
      _downloadTasks = tasks;
    }
    _isLoading = false;
    notifyListeners();
  }

  DownloadTask _ohosTaskToDownloadTask(PlatformDownloadTask task) {
    return DownloadTask(
      taskId: task.id,
      status: _mapOhosStatus(task.status),
      progress: task.progress,
      url: task.url,
      filename: task.fileName,
      savedDir: task.savedDir,
      timeCreated: DateTime.now().millisecondsSinceEpoch,
      allowCellular: true,
    );
  }

  @visibleForTesting
  static DownloadTaskStatus mapOhosStatusForTest(String status) =>
      _mapOhosStatus(status);

  static DownloadTaskStatus _mapOhosStatus(String status) {
    switch (status) {
      case 'running':
        return DownloadTaskStatus.running;
      case 'paused':
        return DownloadTaskStatus.paused;
      case 'completed':
        return DownloadTaskStatus.complete;
      case 'failed':
        return DownloadTaskStatus.failed;
      case 'cancelled':
        return DownloadTaskStatus.canceled;
      default:
        return DownloadTaskStatus.undefined;
    }
  }

  List<DownloadTask> getActiveDownloads() {
    if (_downloadTasks == null) return const <DownloadTask>[];
    return _downloadTasks!
        .where(
          (task) =>
              task.status == DownloadTaskStatus.running ||
              task.status == DownloadTaskStatus.paused ||
              task.status == DownloadTaskStatus.enqueued ||
              task.status == DownloadTaskStatus.undefined ||
              // failed + progress<100 = genuinely incomplete
              (task.status == DownloadTaskStatus.failed &&
                  (_useOhosDownloader || task.progress != 100)),
        )
        .toList(growable: false);
  }

  List<DownloadTask> getCompletedDownloads() {
    if (_downloadTasks == null) return const <DownloadTask>[];
    return _downloadTasks!
        .where(
          (task) =>
              task.status == DownloadTaskStatus.complete ||
              task.status == DownloadTaskStatus.canceled ||
              // flutter_downloader marks tasks "failed" with progress=100 when
              // the download finished but post-processing (e.g. checksum, move)
              // failed — the file is usable, so treat as completed.
              (task.status == DownloadTaskStatus.failed &&
                  !_useOhosDownloader &&
                  task.progress == 100),
        )
        .toList(growable: false);
  }

  Future<String?> savedDownloadLocation(String taskId) async {
    return _ohosDownloadService?.saveDownloadedFile(taskId);
  }

  Future<void> pauseTask(String taskId) async {
    try {
      if (_useOhosDownloader) {
        await _ohosDownloadService!.pause(taskId);
      } else {
        await _transferManager.pauseDownloadTask(taskId);
      }
    } catch (e, st) {
      appLogger.eWithPackage(_tag, 'pauseTask failed', error: e, stackTrace: st);
    }
    await loadTasks();
  }

  Future<void> resumeTask(String taskId) async {
    try {
      if (_useOhosDownloader) {
        final tasks = await _ohosDownloadService!.listTasks();
        final task = tasks.firstWhere((item) => item.id == taskId);
        await OnePanelDownloadSource.owner(taskId, Uri.parse(task.url));
        await _ohosDownloadService!.resume(taskId);
      } else {
        await _transferManager.resumeDownloadTask(taskId);
      }
    } catch (e, st) {
      appLogger.eWithPackage(_tag, 'resumeTask failed',
          error: e, stackTrace: st);
    }
    await loadTasks();
  }

  Future<void> cancelTask(String taskId) async {
    try {
      if (_useOhosDownloader) {
        await _ohosDownloadService!.cancel(taskId);
      } else {
        await _transferManager.cancelDownloadTask(taskId);
      }
    } catch (e, st) {
      appLogger.eWithPackage(_tag, 'cancelTask failed',
          error: e, stackTrace: st);
    }
    await loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    try {
      if (_useOhosDownloader) {
        await _ohosDownloadService!.delete(taskId);
        await OnePanelDownloadSource.forget(taskId);
      } else {
        await _transferManager.deleteDownloadTask(taskId);
      }
    } catch (e, st) {
      appLogger.eWithPackage(_tag, 'deleteTask failed',
          error: e, stackTrace: st);
    }
    await loadTasks();
  }

  Future<RetryDownloadTaskWithNewAuthResult> retryTaskWithNewAuth(
    DownloadTask task,
  ) async {
    try {
      if (_useOhosDownloader) {
        final config = await OnePanelDownloadSource.owner(task.taskId, Uri.parse(task.url));
        final newTaskId = await _ohosDownloadService!.retryWithFreshAuth(
          task: PlatformDownloadTask(
            id: task.taskId,
            url: task.url,
            savedDir: task.savedDir,
            fileName: task.filename,
          ),
          headers: OnePanelAuthHeaders.build(config.apiKey),
        );
        if (newTaskId != null) {
          await OnePanelDownloadSource.remember(newTaskId, config.id);
          await loadTasks();
          return RetryDownloadTaskWithNewAuthResult.recreated;
        }
        return RetryDownloadTaskWithNewAuthResult.failed;
      }
      return _transferManager.retryDownloadTaskWithNewAuth(task);
    } catch (e, st) {
      appLogger.eWithPackage(_tag, 'retryTaskWithNewAuth failed',
          error: e, stackTrace: st);
      return RetryDownloadTaskWithNewAuthResult.failed;
    }
  }

  Future<void> clearCompletedDownloads() async {
    if (!isDownloadSupported) return;
    try {
      if (_useOhosDownloader) {
        final tasks = getCompletedDownloads();
        for (final task in tasks) {
          await _ohosDownloadService!.delete(task.taskId);
          await OnePanelDownloadSource.forget(task.taskId);
        }
      } else if (_clearCompletedOverride != null) {
        await _clearCompletedOverride.call();
      } else {
        await _transferManager.clearCompleted();
      }
    } catch (e, st) {
      appLogger.eWithPackage(_tag, 'clearCompletedDownloads failed',
          error: e, stackTrace: st);
    }
    await loadTasks();
  }

  // 2-second interval balances responsiveness with battery/network overhead.
  // flutter_downloader has no push notification for progress changes,
  // so polling is the only option on Android/iOS.
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      loadTasks();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ohosProgressSub?.cancel();
    _ohosDownloadService?.dispose();
    super.dispose();
  }
}
