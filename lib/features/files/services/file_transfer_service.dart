import 'dart:convert';
import 'package:onepanel_client/data/models/paged_query.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
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
    int page = 1,
    int pageSize = PagedQuery.searchPageSize,
    String? search,
  }) async {
    final api = await _repository.getApi();
    final response = await api.searchUploadedFiles(
      FileSearch(
        path: '',
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

    final downloadUrl =
        '${config.url}${ApiConstants.buildApiPath('/files/download')}?path=${Uri.encodeComponent(filePath)}';

    final timestamp =
        (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
    final authToken = _generate1PanelAuthToken(config.apiKey, timestamp);

    _downloadCancelToken = CancelToken();
    final dio = Dio();
    dio.options.headers['1Panel-Token'] = authToken;
    dio.options.headers['1Panel-Timestamp'] = timestamp;

    try {
      await dio.download(
        downloadUrl,
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

  String _generate1PanelAuthToken(String apiKey, String timestamp) {
    final authString = '1panel$apiKey$timestamp';
    final digest = md5.convert(utf8.encode(authString));
    return digest.toString();
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
  Future<void> deleteShare(String shareId) async {
    final api = await _repository.getApi();
    await api.deleteShare({'id': shareId});
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
}
