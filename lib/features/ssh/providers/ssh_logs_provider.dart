import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/ssh_log_models.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

class SshLogsProvider extends ChangeNotifier with AsyncStateNotifier {
  SshLogsProvider({
    SSHService? service,
  }) : _service = service ?? SSHService();

  final SSHService _service;

  List<SshLogEntry> _items = const <SshLogEntry>[];
  String _keyword = '';
  SshLogStatus _statusFilter = SshLogStatus.all;
  bool _isExporting = false;

  List<SshLogEntry> get items => _items;
  String get keyword => _keyword;
  SshLogStatus get statusFilter => _statusFilter;
  bool get isExporting => _isExporting;

  Future<void> load() async {
    setLoading();
    try {
      final result = await _service.searchLogs(
        SshLogSearchRequest(
          info: _keyword.trim().isEmpty ? null : _keyword.trim(),
          status: _statusFilter,
        ),
      );
      _items = result.items;
      setSuccess(isEmpty: _items.isEmpty);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.logs',
        'load failed',
        error: error,
        stackTrace: stackTrace,
      );
      _items = const <SshLogEntry>[];
      setError(error);
    }
  }

  void updateKeyword(String value) {
    _keyword = value;
    notifyListeners();
  }

  void updateStatus(SshLogStatus status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<FileSaveResult?> exportLogs() async {
    _isExporting = true;
    clearError(notify: false);
    notifyListeners();
    try {
      return await _service.exportLogs(
        SshLogSearchRequest(
          info: _keyword.trim().isEmpty ? null : _keyword.trim(),
          status: _statusFilter,
          page: 1,
          pageSize: -1,
        ),
      );
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.ssh.providers.logs',
        'export failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
