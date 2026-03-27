import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/services/backup_recover_service.dart';

class BackupRecoverProvider extends ChangeNotifier with AsyncStateNotifier {
  BackupRecoverProvider({
    BackupRecoverService? service,
  }) : _service = service ?? BackupRecoverService();

  final BackupRecoverService _service;

  String _resourceType = 'app';
  String _resourceName = '';
  String _resourceDetailName = '';
  String _databaseType = 'mysql';
  List<AppInstallInfo> _apps = const <AppInstallInfo>[];
  List<Map<String, dynamic>> _websites = const <Map<String, dynamic>>[];
  List<DatabaseItemOption> _databaseItems = const <DatabaseItemOption>[];
  List<BackupRecord> _records = const <BackupRecord>[];
  BackupRecord? _selectedRecord;
  String _secret = '';
  int _timeout = 3600;
  bool _isSubmitting = false;
  bool _isLoadingRecords = false;

  String get resourceType => _resourceType;
  String get resourceName => _resourceName;
  String get resourceDetailName => _resourceDetailName;
  String get databaseType => _databaseType;
  List<AppInstallInfo> get apps => _apps;
  List<Map<String, dynamic>> get websites => _websites;
  List<DatabaseItemOption> get databaseItems => _databaseItems;
  List<BackupRecord> get records => _records;
  BackupRecord? get selectedRecord => _selectedRecord;
  String get secret => _secret;
  int get timeout => _timeout;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingRecords => _isLoadingRecords;
  bool get hasResourceSelection =>
      _resourceName.trim().isNotEmpty && _resourceDetailName.trim().isNotEmpty;
  bool get canSubmit => hasResourceSelection && _selectedRecord != null;
  String get effectiveResourceType =>
      _resourceType == 'database' ? _databaseType : _resourceType;

  Future<void> initialize(BackupRecoverArgs? args) async {
    _resourceType = args?.type ?? 'app';
    _resourceName = args?.name ?? '';
    _resourceDetailName = args?.detailName ?? '';
    _selectedRecord = args?.initialRecord;
    setLoading();
    try {
      final values = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.loadAppOptions(),
        _service.loadWebsiteOptions(),
        _service.loadDatabaseOptions(_databaseType),
      ]);
      _apps = values[0] as List<AppInstallInfo>;
      _websites = values[1] as List<Map<String, dynamic>>;
      _databaseItems = values[2] as List<DatabaseItemOption>;
      setSuccess(isEmpty: false);
      if (hasResourceSelection) {
        await loadRecords();
      }
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.recover',
        'initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    }
  }

  void updateResourceType(String value) {
    _resourceType = value;
    _resourceName = '';
    _resourceDetailName = '';
    _records = const <BackupRecord>[];
    _selectedRecord = null;
    notifyListeners();
  }

  void selectApp(AppInstallInfo item) {
    _resourceName = item.appKey ?? '';
    _resourceDetailName = item.name ?? '';
    notifyListeners();
  }

  void selectWebsite(Map<String, dynamic> item) {
    final alias = item['alias']?.toString() ?? '';
    _resourceName = alias;
    _resourceDetailName = alias;
    notifyListeners();
  }

  Future<void> updateDatabaseType(String type) async {
    _databaseType = type;
    _databaseItems = await _service.loadDatabaseOptions(type);
    _resourceName = '';
    _resourceDetailName = '';
    _records = const <BackupRecord>[];
    _selectedRecord = null;
    notifyListeners();
  }

  void selectDatabaseItem(DatabaseItemOption item) {
    _resourceName = item.database;
    _resourceDetailName = item.name;
    notifyListeners();
  }

  Future<void> loadRecords() async {
    if (!hasResourceSelection) return;
    _isLoadingRecords = true;
    clearError(notify: false);
    notifyListeners();
    try {
      _records = await _service.loadCandidateRecords(
        type: effectiveResourceType,
        name: _resourceName,
        detailName: _resourceDetailName,
      );
      if (_selectedRecord != null) {
        final match = _records.where((item) => item.id == _selectedRecord!.id);
        if (match.isNotEmpty) {
          _selectedRecord = match.first;
        }
      }
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.recover',
        'loadRecords failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
    } finally {
      _isLoadingRecords = false;
      notifyListeners();
    }
  }

  void selectRecord(BackupRecord? value) {
    _selectedRecord = value;
    notifyListeners();
  }

  void updateSecret(String value) {
    _secret = value;
    notifyListeners();
  }

  void updateTimeout(int value) {
    _timeout = value;
    notifyListeners();
  }

  Future<bool> submitRecover() async {
    if (!canSubmit || _selectedRecord == null) return false;
    _isSubmitting = true;
    clearError(notify: false);
    notifyListeners();
    try {
      final request = _service.buildRecoverRequest(
        record: _selectedRecord!,
        type: effectiveResourceType,
        name: _resourceName,
        detailName: _resourceDetailName,
        secret: _secret,
        timeout: _timeout,
      );
      await _service.recover(request);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.backups.providers.recover',
        'submitRecover failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
