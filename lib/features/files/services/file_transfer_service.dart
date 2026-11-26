import 'package:onepanel_client/data/models/paged_query.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:onepanel_client/core/network/onepanel_auth_headers.dart';
import 'package:onepanel_client/core/network/onepanel_websocket_connector.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/core/services/transfer/one_panel_download_source.dart';
import 'package:onepanel_client/core/platform/services/platform_system_paths.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/data/repositories/files_repository.dart';
import 'package:onepanel_client/core/platform/services/platform_file_service.dart';

class FileTransferService {
  FileTransferService({FilesRepository? repository})
      : _repository = repository ?? FilesRepository();

  final FilesRepository _repository;
  CancelToken? _downloadCancelToken;

  Future<void> ensureServer() async {
    await _repository.getCurrentServer();
  }

  Future<FileWgetResult> wgetDownload({
    required String url,
    required String path,
    required String name,
    bool? ignoreCertificate,
  }) async {
    final api = await _repository.getApi();
    final response = await api.wgetDownload(
      FileWgetRequest(
        url: url,
        path: path,
        name: name,
        ignoreCertificate: ignoreCertificate,
      ),
    );
    return response.data ??
        const FileWgetResult(success: false, error: '响应为空');
  }

  Future<List<FileInfo>> searchUploadedFiles({
    String path = '/',
    int page = 1,
    int pageSize = PagedQuery.searchPageSize,
    String? search,
  }) async {
    final api = await _repository.getApi();
    final response = await api.searchUploadedFiles(
      FileSearch(
        path: path,
        page: page,
        pageSize: pageSize,
        search: search,
      ),
    );
    return response.data ?? const <FileInfo>[];
  }

  Future<void> downloadFile(String path, String savePath) async {
    final api = await _repository.getApi();
    final response = await api.downloadFile(path);
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('下载文件失败: 响应为空');
    }
    if (kIsWeb) {
      await PlatformFileService().saveBytes(
        fileName: savePath.split('/').last,
        bytes: Uint8List.fromList(bytes),
      );
      return;
    }
    final file = await File(savePath).create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  Future<String> downloadFileToDevice(
    String filePath,
    String fileName, {
    Function(int received, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      final api = await _repository.getApi();
      final response = await api.downloadFile(filePath);
      final bytes = response.data;
      if (bytes == null) throw StateError('文件响应为空');
      onProgress?.call(bytes.length, bytes.length);
      return PlatformFileService().saveBytes(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );
    }
    final savePath = await _getDownloadPath(fileName);
    final config = await _repository.getCurrentServer();
    if (config == null) {
      throw StateError('No server configured');
    }

    final downloadUrl = OnePanelDownloadSource.urlFor(config, filePath);

    _downloadCancelToken = CancelToken();
    final dio = Dio();
    dio.options.headers.addAll(OnePanelAuthHeaders.build(config.apiKey));

    try {
      await dio.download(
        downloadUrl.toString(),
        savePath,
        cancelToken: _downloadCancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress?.call(received, total);
          }
        },
      );
      return savePath;
    } finally {
      _downloadCancelToken = null;
    }
  }

  void cancelDownload() {
    if (_downloadCancelToken != null && !_downloadCancelToken!.isCancelled) {
      _downloadCancelToken!.cancel('User cancelled');
    }
  }

  Future<bool> checkAndRequestStoragePermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      
      final result = await Permission.storage.request();
      if (result.isGranted) return true;

      // From Android 10 (API 29), writing new files to the public Downloads
      // directory does not require storage permission — Scoped Storage handles it.
      // On Android 13+, Permission.storage returns denied unconditionally, so we
      // always return true and let the OS enforce access control.
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<String> _getDownloadPath(String fileName) async {
    Directory downloadDir;
    if (Platform.isAndroid) {
      downloadDir = Directory('/storage/emulated/0/Download');
      if (!await downloadDir.exists()) {
        // getExternalStorageDirectory throws on non-Android hosts; wrap
        // in try/catch so test runs on macOS/Linux do not crash.
        try {
          downloadDir = await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        } catch (_) {
          downloadDir = await getApplicationDocumentsDirectory();
        }
      }
    } else if (Platform.isIOS) {
      downloadDir = await getApplicationDocumentsDirectory();
    } else {
      // Desktop + OHOS: route through PlatformSystemPaths so we never
      // hit `getDownloadsDirectory()` (which throws on non-macOS).
      final resolved = await PlatformSystemPaths.defaultDownloadDir();
      downloadDir = resolved ?? await getApplicationDocumentsDirectory();
    }

    // Sanitize characters that are illegal on most filesystems (Windows + Linux).
    final safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final filePath = '${downloadDir.path}/$safeFileName';

    // Auto-increment filename to avoid overwriting existing downloads
    // (e.g. "file.txt" -> "file (1).txt" -> "file (2).txt").
    var counter = 1;
    var finalPath = filePath;
    while (await File(finalPath).exists()) {
      final lastDot = filePath.lastIndexOf('.');
      if (lastDot > 0) {
        finalPath =
            '${filePath.substring(0, lastDot)} ($counter)${filePath.substring(lastDot)}';
      } else {
        finalPath = '$filePath ($counter)';
      }
      counter++;
    }
    return finalPath;
  }

  // ==================== New share/wget management methods (R5 frontend alignment) ====================

  /// Search file shares.
  Future<List<Map<String, dynamic>>> searchShares() async {
    final api = await _repository.getApi();
    final response = await api.searchShares({
      'page': 1,
      'pageSize': PagedQuery.listPageSize,
    });
    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Delete a file share.
  Future<void> deleteShare(String path) async {
    final api = await _repository.getApi();
    await api.deleteShare({'path': path});
  }

  Future<Map<String, dynamic>> createShare({
    required String path,
    required int expireMinutes,
    required String password,
  }) async {
    final config = await _repository.getCurrentServer();
    if (config == null) throw StateError('No server configured');
    final response = await _repository.getApiForConfig(config).createShare({
      'path': path,
      'expireMinutes': expireMinutes,
      'password': password,
    });
    final share = response.data!;
    return {...share, 'link': _shareLink(config.url, share['code'] as String)};
  }

  Future<String> shareLink(String code) async {
    final config = await _repository.getCurrentServer();
    if (config == null) throw StateError('No server configured');
    return _shareLink(config.url, code);
  }

  String _shareLink(String serverUrl, String code) {
    final origin = Uri.parse(serverUrl).origin;
    return Uri.parse(origin).replace(
      pathSegments: ['s', code],
      queryParameters: {'operateNode': 'local'},
    ).toString();
  }

  Future<List<dynamic>> searchHistory(String path, {required int page}) async {
    final api = await _repository.getApi();
    final response = await api.searchHistory({
      'path': path,
      'scope': 'current',
      'page': page,
      'pageSize': PagedQuery.listPageSize,
    });
    return response.data ?? const [];
  }

  Future<String?> getHistoryContent(int id) async {
    final api = await _repository.getApi();
    return (await api.getHistoryContent({'id': id})).data;
  }

  Future<void> restoreHistory(int id) async {
    final api = await _repository.getApi();
    await api.restoreHistory({'id': id});
  }

  Future<void> deleteHistory(int id) async {
    final api = await _repository.getApi();
    await api.deleteHistory({'ids': [id]});
  }

  Future<List<String>> getWgetKeys() async {
    final api = await _repository.getApi();
    final response = await api.getWgetProcessKeys();
    return response.data?.cast<String>() ?? const [];
  }

  Future<List<dynamic>> getWgetProgress({List<String>? keys}) async {
    final requestedKeys = keys ?? await getWgetKeys();
    if (requestedKeys.isEmpty) return const [];
    final connector = OnePanelWebSocketConnector();
    final response = Completer<List<dynamic>>();
    try {
      final socket = await connector.connect(
        path: ApiConstants.buildApiPath('/files/wget/process'),
        onData: (frame) {
          final data = jsonDecode(frame as String);
          if (!response.isCompleted) {
            response.complete(data as List<dynamic>? ?? const []);
          }
        },
        onError: (error, stackTrace) {
          if (!response.isCompleted) response.completeError(error, stackTrace);
        },
        onDone: () {
          if (!response.isCompleted) {
            response.completeError(StateError('Download progress connection closed'));
          }
        },
      );
      if (socket == null) throw StateError('Download progress connection unavailable');
      socket.add(jsonEncode({'type': 'wget', 'keys': requestedKeys}));
      return await response.future.timeout(const Duration(seconds: 10));
    } finally {
      await connector.close();
    }
  }

  /// Get wget download process status.
  Future<Map<String, dynamic>> getWgetProcess() async {
    final api = await _repository.getApi();
    final response = await api.getWgetProcess();
    return response.data ?? const <String, dynamic>{};
  }

  /// Stop a wget download by key.
  Future<void> stopWget(String key) async {
    final api = await _repository.getApi();
    await api.stopWgetDownload(FileWgetStopRequest(key: key));
  }

  // ==================== 分片上传 ====================

  /// 分片大小：与服务端临时分片目录的单片上限保持一致。
  static const int chunkSize = 1024 * 1024;

  /// 上传本地文件到面板目标目录（分片路径）。
  ///
  /// 小于 [chunkSize] 的文件走单次上传；大文件按 [chunkSize] 分片，
  /// 每片完成后回调 [onProgress]（0~1）。[cancelled] 返回 true 时
  /// 终止后续分片并通知服务端清理临时目录。
  ///
  /// [uploadID] 用于服务端把同一文件的分片放入同一临时目录；调用方
  /// 需要为每次上传生成稳定且唯一的标识，缺省时由路径与时间戳派生。
  Future<void> uploadChunkedLocalFile({
    required String localPath,
    required String targetPath,
    String? fileName,
    String? uploadID,
    bool overwrite = true,
    void Function(double progress)? onProgress,
    bool Function()? cancelled,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', localPath);
    }
    final resolvedName = fileName ?? localPath.split(Platform.pathSeparator).last;
    final api = await _repository.getApi();
    final size = await file.length();
    final resolvedUploadID = uploadID ??
        '${DateTime.now().microsecondsSinceEpoch}-${file.uri.pathSegments.last}';

    if (size <= chunkSize) {
      await api.uploadFile(
        targetPath,
        await MultipartFile.fromFile(localPath, filename: resolvedName),
      );
      onProgress?.call(1);
      return;
    }

    final totalChunks = (size / chunkSize).ceil();
    final randomAccessFile = await file.open();
    try {
      for (var index = 0; index < totalChunks; index++) {
        if (cancelled?.call() ?? false) {
          await api.stopChunkUpload(resolvedUploadID);
          throw const _UploadCancelled();
        }
        final start = index * chunkSize;
        final end = (start + chunkSize > size) ? size : start + chunkSize;
        await randomAccessFile.setPosition(start);
        final bytes = await randomAccessFile.read(end - start);
        await api.chunkUpload(FileChunkUpload(
          uploadID: resolvedUploadID,
          filename: resolvedName,
          path: targetPath,
          chunkBytes: bytes,
          chunkIndex: index,
          chunkCount: totalChunks,
          offset: start,
          fileSize: size,
          overwrite: overwrite,
        ));
        onProgress?.call((index + 1) / totalChunks);
      }
    } finally {
      await randomAccessFile.close();
    }
  }

  /// 通知服务端放弃一次分片上传并清理临时分片。
  Future<void> cancelChunkedUpload(String uploadID) async {
    final api = await _repository.getApi();
    await api.stopChunkUpload(uploadID);
  }
}

class _UploadCancelled implements Exception {
  const _UploadCancelled();

  @override
  String toString() => '上传已取消';
}
