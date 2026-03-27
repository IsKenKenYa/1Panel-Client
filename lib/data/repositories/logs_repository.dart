import 'package:onepanel_client/api/v2/file_v2.dart';
import 'package:onepanel_client/api/v2/logs_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/data/models/logs_models.dart';

class LogsRepository {
  LogsRepository({
    ApiClientManager? clientManager,
    LogsV2Api? logsApi,
    FileV2Api? fileApi,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _logsApi = logsApi,
        _fileApi = fileApi;

  final ApiClientManager _clientManager;
  LogsV2Api? _logsApi;
  FileV2Api? _fileApi;

  Future<LogsV2Api> _ensureLogsApi() async {
    return _logsApi ??= await _clientManager.getLogsApi();
  }

  Future<FileV2Api> _ensureFileApi() async {
    return _fileApi ??= await _clientManager.getFileApi();
  }

  Future<PageResult<OperationLogEntry>> searchOperationLogs(
    OperationLogSearchRequest request,
  ) async {
    final api = await _ensureLogsApi();
    final response = await api.searchOperationLogs(request);
    return response.data ??
        const PageResult<OperationLogEntry>(
          items: <OperationLogEntry>[],
          total: 0,
        );
  }

  Future<PageResult<LoginLogEntry>> searchLoginLogs(
    LoginLogSearchRequest request,
  ) async {
    final api = await _ensureLogsApi();
    final response = await api.searchLoginLogs(request);
    return response.data ??
        const PageResult<LoginLogEntry>(items: <LoginLogEntry>[], total: 0);
  }

  Future<List<String>> loadSystemLogFiles() async {
    final api = await _ensureLogsApi();
    final response = await api.getSystemLogFiles();
    return response.data ?? const <String>[];
  }

  Future<FileReadByLineResponse> readLogLines(
    FileReadByLineRequest request,
  ) async {
    final api = await _ensureFileApi();
    final response = await api.readFileByLine(request);
    return response.data ?? const FileReadByLineResponse();
  }

  Future<void> cleanLogs(LogsCleanRequest request) async {
    final api = await _ensureLogsApi();
    await api.cleanLogs(request);
  }
}
