import 'package:flutter/foundation.dart';
import 'package:onepanel_client/core/presentation/async_state_notifier.dart';
import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_args.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_draft.dart';
import 'package:onepanel_client/features/cronjobs/services/cronjob_form_service.dart';

class CronjobFormProvider extends ChangeNotifier with AsyncStateNotifier {
  CronjobFormProvider({
    CronjobFormService? service,
  }) : _service = service ?? CronjobFormService();

  final CronjobFormService _service;

  CronjobFormDraft _draft = const CronjobFormDraft();
  List<GroupInfo> _groups = const <GroupInfo>[];
  List<CronjobScriptOption> _scriptOptions = const <CronjobScriptOption>[];
  List<BackupOption> _backupOptions = const <BackupOption>[];
  List<AppInstallInfo> _appOptions = const <AppInstallInfo>[];
  List<Map<String, dynamic>> _websiteOptions = const <Map<String, dynamic>>[];
  List<DatabaseItemOption> _databaseItems = const <DatabaseItemOption>[];
  List<String> _nextPreview = const <String>[];
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isPreviewLoading = false;

  CronjobFormDraft get draft => _draft;
  List<GroupInfo> get groups => _groups;
  List<CronjobScriptOption> get scriptOptions => _scriptOptions;
  List<BackupOption> get backupOptions => _backupOptions;
  List<AppInstallInfo> get appOptions => _appOptions;
  List<Map<String, dynamic>> get websiteOptions => _websiteOptions;
  List<DatabaseItemOption> get databaseItems => _databaseItems;
  List<String> get nextPreview => _nextPreview;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  bool get isPreviewLoading => _isPreviewLoading;
  bool get isEditing => _draft.isEditing;

  bool get canSave {
    if (_isSaving || _isDeleting) return false;
    if (_draft.name.trim().isEmpty || _draft.groupID == null) return false;
    if (_draft.useRawSpec &&
        _draft.rawSpecs.every((item) => item.trim().isEmpty)) {
      return false;
    }
    return switch (_draft.primaryType) {
      'shell' => _draft.executor.trim().isNotEmpty &&
          _draft.user.trim().isNotEmpty &&
          ((_draft.scriptMode == 'library' && _draft.scriptID != null) ||
              (_draft.scriptMode != 'library' &&
                  _draft.script.trim().isNotEmpty)),
      'curl' => _draft.urlItems.isNotEmpty &&
          _draft.urlItems.every((item) => item.trim().isNotEmpty),
      _ => _canSaveBackupType(),
    };
  }

  Future<void> initialize(CronjobFormArgs? args) async {
    setLoading();
    try {
      final values = await Future.wait<dynamic>(<Future<dynamic>>[
        _service.loadDraft(args),
        _service.loadGroups(),
        _service.loadScriptOptions(),
        _service.loadBackupOptions(),
        _service.loadInstalledApps(),
        _service.loadWebsiteOptions(),
      ]);
      _draft = values[0] as CronjobFormDraft;
      _groups = values[1] as List<GroupInfo>;
      _scriptOptions = values[2] as List<CronjobScriptOption>;
      _backupOptions = values[3] as List<BackupOption>;
      _appOptions = values[4] as List<AppInstallInfo>;
      _websiteOptions = values[5] as List<Map<String, dynamic>>;
      if (_draft.groupID == null && _groups.isNotEmpty) {
        _draft = _draft.copyWith(groupID: _resolveDefaultGroupId());
      }
      await _reloadDatabaseItems();
      setSuccess(isEmpty: false);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.cronjobs.providers.form',
        'initialize failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
    }
  }

  void updateBasic({
    String? name,
    int? groupID,
    String? primaryType,
    String? backupType,
  }) {
    _draft = _draft.copyWith(
      name: name,
      groupID: groupID,
      primaryType: primaryType,
      backupType: backupType,
    );
    notifyListeners();
  }

  Future<void> updateBackupType(String type) async {
    _draft = _draft.copyWith(backupType: type);
    if (type == 'database') {
      await _reloadDatabaseItems();
    } else {
      _databaseItems = const <DatabaseItemOption>[];
    }
    notifyListeners();
  }

  void updateScheduleMode(bool useRawSpec) {
    _draft = _draft.copyWith(useRawSpec: useRawSpec);
    _nextPreview = const <String>[];
    notifyListeners();
  }

  void updateRawSpecAt(int index, String value) {
    final specs = List<String>.from(_draft.rawSpecs);
    specs[index] = value;
    _draft = _draft.copyWith(rawSpecs: specs);
    notifyListeners();
  }

  void addRawSpec() {
    _draft = _draft.copyWith(
      rawSpecs: <String>[..._draft.rawSpecs, ''],
    );
    notifyListeners();
  }

  void removeRawSpec(int index) {
    final specs = List<String>.from(_draft.rawSpecs)..removeAt(index);
    _draft = _draft.copyWith(rawSpecs: specs.isEmpty ? <String>[''] : specs);
    notifyListeners();
  }

  void updateScheduleBuilder(CronjobScheduleBuilder value) {
    _draft = _draft.copyWith(schedule: value);
    _nextPreview = const <String>[];
    notifyListeners();
  }

  void updateShell({
    String? executor,
    String? scriptMode,
    String? script,
    int? scriptID,
    bool clearScriptId = false,
    String? user,
  }) {
    _draft = _draft.copyWith(
      executor: executor,
      scriptMode: scriptMode,
      script: script,
      scriptID: clearScriptId ? null : scriptID,
      user: user,
    );
    notifyListeners();
  }

  void updateUrlItems(List<String> items) {
    _draft = _draft.copyWith(urlItems: items);
    notifyListeners();
  }

  void updateAppIds(List<String> ids) {
    _draft = _draft.copyWith(appIdList: ids);
    notifyListeners();
  }

  void updateWebsiteIds(List<String> ids) {
    _draft = _draft.copyWith(websiteList: ids);
    notifyListeners();
  }

  Future<void> updateDatabaseType(String type) async {
    _draft = _draft.copyWith(dbType: type, dbNameList: const <String>[]);
    await _reloadDatabaseItems();
    notifyListeners();
  }

  void updateDatabaseIds(List<String> ids) {
    _draft = _draft.copyWith(dbNameList: ids);
    notifyListeners();
  }

  void updateDirectory({
    bool? isDir,
    String? sourceDir,
    List<String>? files,
    List<String>? ignoreFiles,
  }) {
    _draft = _draft.copyWith(
      isDir: isDir,
      sourceDir: sourceDir,
      files: files,
      ignoreFiles: ignoreFiles,
    );
    notifyListeners();
  }

  void updateSnapshot({
    bool? withImage,
    List<int>? ignoreAppIDs,
  }) {
    _draft = _draft.copyWith(
      withImage: withImage,
      ignoreAppIDs: ignoreAppIDs,
    );
    notifyListeners();
  }

  void updateScopes(List<String> scopes) {
    _draft = _draft.copyWith(scopes: scopes);
    notifyListeners();
  }

  void updateBackupAccounts({
    List<int>? sourceAccountItems,
    int? downloadAccountID,
  }) {
    _draft = _draft.copyWith(
      sourceAccountItems: sourceAccountItems,
      downloadAccountID: downloadAccountID,
    );
    notifyListeners();
  }

  void updatePolicy({
    int? retainCopies,
    int? retryTimes,
    int? timeoutValue,
    String? timeoutUnit,
    bool? ignoreErr,
    String? secret,
    List<String>? argItems,
    bool? alertEnabled,
    int? alertCount,
    List<String>? alertMethods,
  }) {
    _draft = _draft.copyWith(
      retainCopies: retainCopies,
      retryTimes: retryTimes,
      timeoutValue: timeoutValue,
      timeoutUnit: timeoutUnit,
      ignoreErr: ignoreErr,
      secret: secret,
      argItems: argItems,
      alertEnabled: alertEnabled,
      alertCount: alertCount,
      alertMethods: alertMethods,
    );
    notifyListeners();
  }

  Future<void> previewNext() async {
    _isPreviewLoading = true;
    clearError(notify: false);
    notifyListeners();
    try {
      _nextPreview = await _service.loadNextPreview(_draft);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.cronjobs.providers.form',
        'previewNext failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save() async {
    if (!canSave) return false;
    _isSaving = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.saveDraft(_draft);
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.cronjobs.providers.form',
        'save failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> delete({
    bool cleanData = false,
    bool cleanRemoteData = false,
  }) async {
    if (_draft.id == null) return false;
    _isDeleting = true;
    clearError(notify: false);
    notifyListeners();
    try {
      await _service.deleteCronjob(
        _draft.id!,
        cleanData: cleanData,
        cleanRemoteData: cleanRemoteData,
      );
      return true;
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.cronjobs.providers.form',
        'delete failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error, notify: false);
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<FileSaveResult?> exportSelected(List<int> ids) async {
    try {
      return await _service.exportCronjobs(ids);
    } catch (error, stackTrace) {
      appLogger.eWithPackage(
        'features.cronjobs.providers.form',
        'export failed',
        error: error,
        stackTrace: stackTrace,
      );
      setError(error);
      return null;
    }
  }

  int? _resolveDefaultGroupId() {
    for (final group in _groups) {
      if (group.isDefault == true) {
        return group.id;
      }
    }
    return _groups.isEmpty ? null : _groups.first.id;
  }

  Future<void> _reloadDatabaseItems() async {
    if (_draft.resolvedType != 'database') {
      _databaseItems = const <DatabaseItemOption>[];
      return;
    }
    _databaseItems = await _service.loadDatabaseItems(_draft.dbType);
  }

  bool _canSaveBackupType() {
    if (_draft.sourceAccountItems.isEmpty || _draft.downloadAccountID == null) {
      return false;
    }
    return switch (_draft.backupType) {
      'app' => _draft.appIdList.isNotEmpty,
      'website' => _draft.websiteList.isNotEmpty,
      'database' => _draft.dbNameList.isNotEmpty,
      'directory' => _draft.isDir
          ? _draft.sourceDir.trim().isNotEmpty
          : _draft.files.isNotEmpty,
      'snapshot' => true,
      'log' => true,
      _ => false,
    };
  }
}
