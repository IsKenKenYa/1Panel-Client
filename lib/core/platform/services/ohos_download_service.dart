import 'dart:async';

import 'package:flutter/services.dart';
import 'package:onepanel_client/core/platform/services/ohos_channel_names.dart';
import 'package:onepanel_client/core/platform/services/platform_download_service.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';

class OhosDownloadProgress {
  final String taskId;
  final int bytesReceived;
  final int totalBytes;
  final String status;
  final int progress;

  const OhosDownloadProgress({
    required this.taskId,
    required this.bytesReceived,
    required this.totalBytes,
    required this.status,
    required this.progress,
  });
}

class OhosDownloadService implements PlatformDownloadService {
  OhosDownloadService({
    required this.methodChannel,
    required this.eventChannel,
    required this.platformFileService,
  });

  /// Convenience factory wiring the canonical channel names from
  /// [OhosChannelNames]. Business code should prefer this over constructing
  /// raw [MethodChannel]/[EventChannel] literals, which leaks channel names
  /// outside the platform layer (violates AGENTS.md).
  factory OhosDownloadService.defaultChannels(
    PlatformFileService platformFileService,
  ) {
    return OhosDownloadService(
      methodChannel: const MethodChannel(OhosChannelNames.ohosDownload),
      eventChannel:
          const EventChannel(OhosChannelNames.ohosDownloadProgress),
      platformFileService: platformFileService,
    );
  }

  final MethodChannel methodChannel;
  final EventChannel eventChannel;
  final PlatformFileService platformFileService;

  StreamController<OhosDownloadProgress>? _progressController;
  StreamSubscription? _eventSubscription;
  // Caches last-seen progress per task so late subscribers can replay state.
  final Map<String, OhosDownloadProgress> _latestProgress = {};

  Stream<OhosDownloadProgress> get onProgress {
    _progressController ??= StreamController<OhosDownloadProgress>.broadcast();
    _startListeningEvents();
    return _progressController!.stream;
  }

  void _startListeningEvents() {
    if (_eventSubscription != null) return;
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          final progress = OhosDownloadProgress(
            taskId: event['taskId'] as String,
            bytesReceived: event['bytesReceived'] as int,
            totalBytes: event['totalBytes'] as int,
            status: event['status'] as String,
            progress: event['progress'] as int,
          );
          _latestProgress[progress.taskId] = progress;
          _progressController?.add(progress);
        }
      },
      onError: (error) {
        appLogger.wWithPackage(
          'core.platform.ohos_download',
          'Progress stream error: $error',
        );
      },
    );
  }

  @override
  Future<String?> enqueue({
    required String url,
    required String savedDir,
    String? fileName,
    Map<String, String>? headers,
  }) async {
    return methodChannel.invokeMethod<String>('enqueue', <String, Object?>{
      'url': url,
      'savedDir': savedDir,
      'fileName': fileName,
      'headers': headers ?? <String, String>{},
      'usePicker': await AppPreferencesService().loadUseFilePickerForFileOperations(),
    });
  }

  @override
  Future<void> pause(String taskId) async {
    await methodChannel.invokeMethod<void>('pause', <String, Object?>{
      'taskId': taskId,
    });
  }

  @override
  Future<void> resume(String taskId) async {
    await methodChannel.invokeMethod<void>('resume', <String, Object?>{
      'taskId': taskId,
    });
  }

  @override
  Future<void> cancel(String taskId) async {
    await methodChannel.invokeMethod<void>('cancel', <String, Object?>{
      'taskId': taskId,
    });
    _latestProgress.remove(taskId);
  }

  @override
  Future<void> delete(String taskId) async {
    await methodChannel.invokeMethod<void>('delete', <String, Object?>{
      'taskId': taskId,
    });
    _latestProgress.remove(taskId);
  }

  @override
  Future<List<PlatformDownloadTask>> listTasks() async {
    final raw = await methodChannel.invokeListMethod<Map>('listTasks');
    return raw!.map((map) {
      return PlatformDownloadTask(
        id: map['taskId'] as String,
        url: map['url'] as String,
        savedDir: map['savedDir'] as String,
        fileName: map['fileName'] as String,
        status: map['status'] as String,
        progress: map['progress'] as int,
      );
    }).toList();
  }

  @override
  Future<String?> retryWithFreshAuth({
    required PlatformDownloadTask task,
    required Map<String, String> headers,
  }) {
    return enqueue(
      url: task.url,
      savedDir: task.savedDir,
      fileName: task.fileName,
      headers: headers,
    );
  }

  /// 返回原生下载器已经保存的文件路径或用户选择的 URI。
  Future<String?> saveDownloadedFile(String taskId) async {
    return methodChannel.invokeMethod<String>(
      'saveDownloadedFile',
      <String, Object?>{'taskId': taskId},
    );
  }

  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _progressController?.close();
    _progressController = null;
  }
}
