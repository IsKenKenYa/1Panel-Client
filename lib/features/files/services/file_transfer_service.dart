import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:onepanel_client/core/config/api_constants.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/data/repositories/files_repository.dart';

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
    int pageSize = 20,
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
    final file = await File(savePath).create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  Future<String> downloadFileToDevice(
    String filePath,
    String fileName, {
    Function(int received, int total)? onProgress,
  }) async {
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
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      
      final result = await Permission.storage.request();
      if (result.isGranted) return true;

      // 从 Android 10 (API 29) 开始，向公共 Downloads 目录写入新文件不需要存储权限。
      // 在 Android 13+ 上，Permission.storage 会直接返回 denied。
      // 因此，即使被拒绝，我们也返回 true 放行，让下载操作依赖系统的 Scoped Storage 机制。
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
        downloadDir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isIOS) {
      downloadDir = await getApplicationDocumentsDirectory();
    } else {
      downloadDir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }

    final safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final filePath = '${downloadDir.path}/$safeFileName';

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
}
