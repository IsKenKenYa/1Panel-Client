import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/safe_change_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/logs_models.dart';
import 'package:onepanel_client/features/logs/services/logs_service.dart';

class LogsProvider extends ChangeNotifier with SafeChangeNotifier {
  LogsProvider({
    LogsService? service,
  }) : _service = service ?? LogsService();

  final LogsService _service;

  List<OperationLogEntry> _operationItems = const <OperationLogEntry>[];
  bool _operationLoading = false;
  String? _operationError;
  String _operationKeyword = '';
  String _operationSource = '';
  String _operationStatus = '';

  List<LoginLogEntry> _loginItems = const <LoginLogEntry>[];
  bool _loginLoading = false;
  String? _loginError;
  String _loginIp = '';
  String _loginStatus = '';

  List<OperationLogEntry> get operationItems => _operationItems;
  bool get operationLoading => _operationLoading;
  String? get operationError => _operationError;
  bool get operationEmpty =>
      !_operationLoading && _operationError == null && _operationItems.isEmpty;
  String get operationKeyword => _operationKeyword;
  String get operationSource => _operationSource;
  String get operationStatus => _operationStatus;

  List<LoginLogEntry> get loginItems => _loginItems;
  bool get loginLoading => _loginLoading;
  String? get loginError => _loginError;
  bool get loginEmpty =>
      !_loginLoading && _loginError == null && _loginItems.isEmpty;
  String get loginIp => _loginIp;
  String get loginStatus => _loginStatus;

  Future<void> loadAll() {
    return Future.wait<void>(<Future<void>>[
      loadOperationLogs(),
      loadLoginLogs(),
    ]);
  }

  Future<void> loadOperationLogs() async {
    if (isDisposed) return;
    
    _operationLoading = true;
    _operationError = null;
    notifyListeners();
    try {
      final result = await _service.searchOperationLogs(
        OperationLogSearchRequest(
          operation: _operationKeyword.trim().isEmpty
              ? null
              : _operationKeyword.trim(),
          source:
              _operationSource.trim().isEmpty ? null : _operationSource.trim(),
          status:
              _operationStatus.trim().isEmpty ? null : _operationStatus.trim(),
        ),
      );
      if (isDisposed) return;
      _operationItems = result.items;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.logs.providers.logs',
        'loadOperationLogs failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!isDisposed) {
        _operationItems = const <OperationLogEntry>[];
        _operationError = 'logs.operation.loadFailed';
      }
    } finally {
      if (!isDisposed) {
        _operationLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadLoginLogs() async {
    if (isDisposed) return;
    
    _loginLoading = true;
    _loginError = null;
    notifyListeners();
    try {
      final result = await _service.searchLoginLogs(
        LoginLogSearchRequest(
          ip: _loginIp.trim().isEmpty ? null : _loginIp.trim(),
          status: _loginStatus.trim().isEmpty ? null : _loginStatus.trim(),
        ),
      );
      if (isDisposed) return;
      _loginItems = result.items;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.logs.providers.logs',
        'loadLoginLogs failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (!isDisposed) {
        _loginItems = const <LoginLogEntry>[];
        _loginError = 'logs.login.loadFailed';
      }
    } finally {
      if (!isDisposed) {
        _loginLoading = false;
        notifyListeners();
      }
    }
  }

  void updateOperationKeyword(String value) {
    _operationKeyword = value;
    notifyListeners();
  }

  void updateOperationSource(String value) {
    _operationSource = value;
    notifyListeners();
  }

  void updateOperationStatus(String value) {
    _operationStatus = value;
    notifyListeners();
  }

  void updateLoginIp(String value) {
    _loginIp = value;
    notifyListeners();
  }

  void updateLoginStatus(String value) {
    _loginStatus = value;
    notifyListeners();
  }
}
