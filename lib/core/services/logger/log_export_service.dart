import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../file_save_service.dart';
import 'log_format.dart';
import 'log_level.dart';
import 'log_file_manager_service.dart';
import 'logger_service.dart';

class LogExportService {
  static final LogExportService _instance = LogExportService._internal();
  factory LogExportService() => _instance;
  LogExportService._internal();

  final LogFileManagerService _logFileManager = LogFileManagerService();
  final FileSaveService _fileSaveService = FileSaveService();

  /// 导出日志到用户选择的目录。
  ///
  /// - [format] = `LogFormat.humanReadable`（默认）：人读风格，emoji + 缩进
  /// - [format] = `LogFormat.aiAgent`：单行结构化，无装饰字符
  ///
  /// AI Agent 格式导出时，文件名后缀加 `_ai.txt`。
  Future<FileSaveResult> exportLogs({
    AppLogLevel? minLevel,
    LogFormat format = LogFormat.humanReadable,
  }) async {
    try {
      final content = await _logFileManager.readAllLogs(
        minLevel: minLevel ?? appLogger.minLogLevel,
        format: format,
      );
      final packageInfo = await PackageInfo.fromPlatform();
      final now = DateTime.now();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final suffix = format == LogFormat.aiAgent ? '_ai' : '';
      final fileName = 'app_logs_$stamp$suffix.txt';
      final header = '''
# KenPanel Debug Logs
exported_at: ${now.toIso8601String()}
app_name: ${packageInfo.appName}
package_name: ${packageInfo.packageName}
version: ${packageInfo.version}+${packageInfo.buildNumber}
log_format: ${format.shortTag}

''';
      final bytes = Uint8List.fromList(utf8.encode('$header$content'));
      return await _fileSaveService.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'text/plain',
        category: 'logs',
      );
    } catch (e, stackTrace) {
      appLogger.eWithPackage(
        'core.services.logger',
        'Failed to export app logs',
        error: e,
        stackTrace: stackTrace,
      );
      return FileSaveResult(success: false, errorMessage: 'Export failed: $e');
    }
  }

  /// 仅读取日志文件最后 N 行（不读全部），用于预览。
  Future<String> tailRecentLogs(int maxLines,
      {LogFormat format = LogFormat.aiAgent}) async {
    final raw = await _logFileManager.tailCurrentLog(maxLines);
    if (format == LogFormat.aiAgent) return raw;
    return reformatAiAgentToHumanReadable(raw);
  }
}
