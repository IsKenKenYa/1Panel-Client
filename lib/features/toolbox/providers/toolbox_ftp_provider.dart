import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/toolbox_models.dart';
import 'package:onepanel_client/features/toolbox/services/toolbox_ftp_service.dart';

class ToolboxFtpProvider extends ChangeNotifier {
  ToolboxFtpProvider({ToolboxFtpService? service})
      : _service = service ?? ToolboxFtpService();

  final ToolboxFtpService _service;

  static const int _pageSize = 50;

  bool _isLoading = false;
  bool _isMutating = false;
  bool _isSyncing = false;
  String? _error;
  String _keyword = '';
  int _page = 1;
  bool _hasMoreUsers = false;
  FtpBaseInfo _baseInfo = const FtpBaseInfo();
  List<FtpInfo> _users = const <FtpInfo>[];

  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  bool get isSyncing => _isSyncing;
  bool get isBusy => _isSyncing || _isMutating;
  String? get error => _error;
  String get keyword => _keyword;
  int get page => _page;
  bool get hasMoreUsers => _hasMoreUsers;
  FtpBaseInfo get baseInfo => _baseInfo;
  List<FtpInfo> get users => _users;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final snapshot = await _service.loadSnapshot(
        page: _page,
        pageSize: _pageSize,
        keyword: _keyword.isEmpty ? null : _keyword,
      );
      _baseInfo = snapshot.baseInfo;
      _users = snapshot.users;
      _hasMoreUsers = snapshot.users.length >= _pageSize;
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

  void setKeyword(String keyword) {
    _keyword = keyword.trim();
    _page = 1;
    notifyListeners();
  }

  Future<void> nextPage() async {
    if (!_hasMoreUsers) {
      return;
    }
    _page += 1;
    await load();
  }

  Future<void> previousPage() async {
    if (_page <= 1) {
      return;
    }
    _page -= 1;
    await load();
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

  Future<bool> createUser(FtpCreate request) {
    return _runMutation(action: () => _service.createUser(request));
  }

  Future<bool> updateUser(FtpUpdate request) {
    return _runMutation(action: () => _service.updateUser(request));
  }

  Future<bool> deleteUser(int id) {
    return _runMutation(action: () => _service.deleteUsers(<int>[id]));
  }

  Future<bool> operateService(String operation) {
    return _runMutation(action: () => _service.operateService(operation));
  }

  Future<bool> _runMutation({
    required Future<void> Function() action,
    bool reload = true,
  }) async {
    _isMutating = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      if (reload) {
        await load(silent: true);
      }
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.toolbox.providers.toolbox_ftp',
        'ftp mutation failed',
        error: error,
        stackTrace: stackTrace,
      );
      _error = error.toString();
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }
}
