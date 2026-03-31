import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../file_save_service.dart';
import 'log_file_manager_service.dart';
import 'logger_service.dart';

class LogExportService {
  static final LogExportService _instance = LogExportService._internal();
  factory LogExportService() => _instance;
  LogExportService._internal();

  final LogFileManagerService _logFileManager = LogFileManagerService();
  final FileSaveService _fileSaveService = FileSaveService();

  Future<FileSaveResult> exportLogs() async {
    try {
      final content = await _logFileManager.readAllLogs();
      final packageInfo = await PackageInfo.fromPlatform();
      final now = DateTime.now();
      final fileName =
          'app_logs_${DateFormat('yyyyMMdd_HHmmss').format(now)}.txt';
      final header = '''
# 1Panel Client Debug Logs
exported_at: ${now.toIso8601String()}
app_name: ${packageInfo.appName}
package_name: ${packageInfo.packageName}
version: ${packageInfo.version}+${packageInfo.buildNumber}

''';
      final bytes = Uint8List.fromList(utf8.encode('$header$content'));
      return await _fileSaveService.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'text/plain',
      );
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'core.services.logger',
        '导出应用日志失败',
        error: e,
        stackTrace: stackTrace,
      );
      return FileSaveResult(success: false, errorMessage: '导出失败: $e');
    }
  }
}
