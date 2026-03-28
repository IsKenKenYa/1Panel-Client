import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_ftp_service.dart';

class ToolboxFtpProvider extends ChangeNotifier {
  ToolboxFtpProvider({ToolboxFtpService? service})
      : _service = service ?? ToolboxFtpService();

  final ToolboxFtpService _service;

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _error;
  FtpBaseInfo _baseInfo = const FtpBaseInfo();
  List<FtpInfo> _users = const <FtpInfo>[];

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get error => _error;
  FtpBaseInfo get baseInfo => _baseInfo;
  List<FtpInfo> get users => _users;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final snapshot = await _service.loadSnapshot();
      _baseInfo = snapshot.baseInfo;
      _users = snapshot.users;
      _error = null;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_ftp',
        'load ftp failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> syncUsers() async {
    _isSyncing = true;
    _error = null;
    notifyListeners();

    try {
      await _service.syncUsers();
      await load(silent: true);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_ftp',
        'sync ftp users failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
