import 'dart:convert';
import 'dart:typed_data';

import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/cronjob_form_request_models.dart';
import 'package:onepanel_client/data/models/cronjob_form_response_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/data/repositories/cronjob_form_repository.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_args.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_draft.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';

class CronjobFormService {
  CronjobFormService({
    CronjobFormRepository? repository,
    GroupService? groupService,
    FileSaveService? fileSaveService,
  })  : _repository = repository ?? CronjobFormRepository(),
        _groupService = groupService ?? GroupService(),
        _fileSaveService = fileSaveService ?? FileSaveService();

  final CronjobFormRepository _repository;
  final GroupService _groupService;
  final FileSaveService _fileSaveService;

  Future<List<GroupInfo>> loadGroups({bool forceRefresh = false}) {
    return _groupService.listGroups('cronjob', forceRefresh: forceRefresh);
  }

  Future<List<CronjobScriptOption>> loadScriptOptions() {
    return _repository.loadScriptOptions();
  }

  Future<List<AppInstallInfo>> loadInstalledApps() {
    return _repository.loadInstalledApps();
  }

  Future<List<Map<String, dynamic>>> loadWebsiteOptions() {
    return _repository.loadWebsiteOptions();
  }

  Future<List<DatabaseItemOption>> loadDatabaseItems(String type) {
    return _repository.loadDatabaseItems(type);
  }

  Future<List<BackupOption>> loadBackupOptions() {
    return _repository.loadBackupOptions();
  }

  Future<CronjobFormDraft> loadDraft(CronjobFormArgs? args) async {
    final cronjobId = args?.cronjobId;
    if (cronjobId == null) {
      return const CronjobFormDraft();
    }
    final response = await _repository.loadCronjobInfo(cronjobId);
    return _toDraft(response);
  }

  Future<List<String>> loadNextPreview(CronjobFormDraft draft) {
    return _repository.loadNextPreview(buildSpec(draft));
  }

  Future<void> saveDraft(CronjobFormDraft draft) async {
    final request = _toRequest(draft);
    if (draft.isEditing) {
      await _repository.updateCronjob(request);
      return;
    }
    await _repository.createCronjob(request);
  }

  Future<void> deleteCronjob(
    int id, {
    bool cleanData = false,
    bool cleanRemoteData = false,
  }) {
    return _repository.deleteCronjob(
      CronjobBatchDeleteRequest(
        ids: <int>[id],
        cleanData: cleanData,
        cleanRemoteData: cleanRemoteData,
      ),
    );
  }

  Future<List<CronjobTransItem>> parseImportFile(Uint8List bytes) async {
    final content = utf8.decode(bytes, allowMalformed: true);
    final decoded = jsonDecode(content);
    if (decoded is! List) {
      throw Exception('cronjob.importInvalidJson');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CronjobTransItem.fromJson)
        .toList(growable: false);
  }

  Future<void> importCronjobs(List<CronjobTransItem> items) {
    return _repository.importCronjobs(items);
  }

  Future<FileSaveResult> exportCronjobs(List<int> ids) async {
    final bytes = await _repository.exportCronjobs(ids);
    if (bytes.isEmpty) {
      throw Exception('cronjob.exportEmpty');
    }
    return _fileSaveService.saveFile(
      fileName: 'cronjobs.json',
      bytes: Uint8List.fromList(bytes),
      mimeType: 'application/json',
    );
  }

  String buildSpec(CronjobFormDraft draft) {
    if (draft.useRawSpec) {
      final specs = draft.rawSpecs
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (specs.isEmpty) {
        throw Exception('cronjob.specRequired');
      }
      return specs.join('&&');
    }

    final schedule = draft.schedule;
    return switch (schedule.mode) {
      'weekly' =>
        '${schedule.minute} ${schedule.hour} * * ${schedule.dayOfWeek}',
      'monthly' =>
        '${schedule.minute} ${schedule.hour} ${schedule.dayOfMonth} * *',
      'every_hours' => '${schedule.minute} */${schedule.interval} * * *',
      'every_minutes' => '*/${schedule.interval} * * * *',
      _ => '${schedule.minute} ${schedule.hour} * * *',
    };
  }

  CronjobFormDraft _toDraft(CronjobOperateResponse response) {
    final rawSpecs = response.spec
        .split('&&')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final parsed = !response.specCustom && rawSpecs.length == 1
        ? _parseBuilder(rawSpecs.first)
        : null;
    final primaryType = _resolvePrimaryType(response.type);
    return CronjobFormDraft(
      id: response.id,
      name: response.name,
      groupID: response.groupID == 0 ? null : response.groupID,
      primaryType: primaryType,
      backupType: primaryType == 'backup' ? response.type : 'website',
      useRawSpec: response.specCustom || parsed == null,
      rawSpecs: rawSpecs.isEmpty ? const <String>['0 0 * * *'] : rawSpecs,
      schedule: parsed ?? const CronjobScheduleBuilder(),
      executor: response.executor.isEmpty ? 'bash' : response.executor,
      scriptMode: response.scriptMode.isEmpty ? 'input' : response.scriptMode,
      script: response.script,
      scriptID: response.scriptID == 0 ? null : response.scriptID,
      user: response.user.isEmpty ? 'root' : response.user,
      urlItems: _splitCsv(response.url, fallbackEmpty: true),
      appIdList: _splitCsv(response.appID),
      websiteList: _splitCsv(response.website),
      dbType: response.dbType.isEmpty ? 'mysql' : response.dbType,
      dbNameList: _splitCsv(response.dbName),
      ignoreFiles: _splitCsv(response.exclusionRules),
      isDir: response.isDir,
      sourceDir: response.isDir ? response.sourceDir : '',
      files: response.isDir ? const <String>[] : _splitCsv(response.sourceDir),
      withImage: response.snapshotRule.withImage,
      ignoreAppIDs: response.snapshotRule.ignoreAppIDs,
      scopes: response.scopes,
      sourceAccountItems: _splitCsv(response.sourceAccountIDs)
          .map((item) => int.tryParse(item))
          .whereType<int>()
          .toList(growable: false),
      downloadAccountID:
          response.downloadAccountID == 0 ? null : response.downloadAccountID,
      retainCopies: response.retainCopies == 0 ? 1 : response.retainCopies,
      retryTimes: response.retryTimes,
      timeoutValue: _timeoutValue(response.timeout),
      timeoutUnit: _timeoutUnit(response.timeout),
      ignoreErr: response.ignoreErr,
      secret: response.secret,
      argItems: _splitCsv(response.args),
      alertEnabled: response.alertCount > 0,
      alertCount: response.alertCount == 0 ? 3 : response.alertCount,
      alertMethods: _splitCsv(response.alertMethod),
    );
  }

  CronjobOperateRequest _toRequest(CronjobFormDraft draft) {
    return CronjobOperateRequest(
      id: draft.id,
      name: draft.name.trim(),
      groupID: draft.groupID ?? 0,
      type: draft.resolvedType,
      specCustom: draft.useRawSpec,
      spec: buildSpec(draft),
      executor: draft.primaryType == 'shell' ? draft.executor.trim() : '',
      scriptMode: draft.primaryType == 'shell' ? draft.scriptMode : 'input',
      script: draft.primaryType == 'shell' ? draft.script.trim() : '',
      command: '',
      containerName: '',
      user: draft.primaryType == 'shell' ? draft.user.trim() : '',
      scriptID: draft.primaryType == 'shell' ? draft.scriptID : null,
      appID: draft.resolvedType == 'app' ? draft.appIdList.join(',') : '',
      website:
          draft.resolvedType == 'website' ? draft.websiteList.join(',') : '',
      exclusionRules: draft.ignoreFiles.join(','),
      dbType: draft.resolvedType == 'database' ? draft.dbType : '',
      dbName:
          draft.resolvedType == 'database' ? draft.dbNameList.join(',') : '',
      url: draft.primaryType == 'curl' ? draft.urlItems.join(',') : '',
      isDir: draft.resolvedType == 'directory' ? draft.isDir : false,
      sourceDir: draft.resolvedType == 'directory'
          ? (draft.isDir ? draft.sourceDir.trim() : draft.files.join(','))
          : '',
      snapshotRule: CronjobSnapshotRule(
        withImage: draft.withImage,
        ignoreAppIDs: draft.ignoreAppIDs,
      ),
      sourceAccountIDs: _requiresBackupAccounts(draft.resolvedType)
          ? draft.sourceAccountItems.join(',')
          : '',
      downloadAccountID: _requiresBackupAccounts(draft.resolvedType)
          ? draft.downloadAccountID
          : null,
      retainCopies:
          _requiresBackupAccounts(draft.resolvedType) ? draft.retainCopies : 1,
      retryTimes: draft.retryTimes,
      timeout: _timeoutToSeconds(draft.timeoutValue, draft.timeoutUnit),
      ignoreErr: draft.ignoreErr,
      secret: draft.secret.trim(),
      args: draft.argItems.join(','),
      alertCount: draft.alertEnabled ? draft.alertCount : 0,
      alertTitle: draft.alertEnabled ? draft.name.trim() : '',
      alertMethod: draft.alertMethods.join(','),
      scopes: const <String>[],
    );
  }

  CronjobScheduleBuilder? _parseBuilder(String spec) {
    final daily = RegExp(r'^(\d{1,2}) (\d{1,2}) \* \* \*$');
    final weekly = RegExp(r'^(\d{1,2}) (\d{1,2}) \* \* (\d)$');
    final monthly = RegExp(r'^(\d{1,2}) (\d{1,2}) (\d{1,2}) \* \*$');
    final hourly = RegExp(r'^(\d{1,2}) \*/(\d{1,3}) \* \* \*$');
    final minutes = RegExp(r'^\*/(\d{1,6}) \* \* \* \*$');

    Match? match = daily.firstMatch(spec);
    if (match != null) {
      return CronjobScheduleBuilder(
        mode: 'daily',
        minute: int.parse(match.group(1)!),
        hour: int.parse(match.group(2)!),
      );
    }
    match = weekly.firstMatch(spec);
    if (match != null) {
      return CronjobScheduleBuilder(
        mode: 'weekly',
        minute: int.parse(match.group(1)!),
        hour: int.parse(match.group(2)!),
        dayOfWeek: int.parse(match.group(3)!),
      );
    }
    match = monthly.firstMatch(spec);
    if (match != null) {
      return CronjobScheduleBuilder(
        mode: 'monthly',
        minute: int.parse(match.group(1)!),
        hour: int.parse(match.group(2)!),
        dayOfMonth: int.parse(match.group(3)!),
      );
    }
    match = hourly.firstMatch(spec);
    if (match != null) {
      return CronjobScheduleBuilder(
        mode: 'every_hours',
        minute: int.parse(match.group(1)!),
        interval: int.parse(match.group(2)!),
      );
    }
    match = minutes.firstMatch(spec);
    if (match != null) {
      return CronjobScheduleBuilder(
        mode: 'every_minutes',
        interval: int.parse(match.group(1)!),
      );
    }
    return null;
  }

  String _resolvePrimaryType(String type) {
    if (type == 'shell') return 'shell';
    if (type == 'curl') return 'curl';
    if (_supportedBackupTypes.contains(type)) return 'backup';
    throw Exception('cronjob.unsupportedType');
  }

  List<String> _splitCsv(String input, {bool fallbackEmpty = false}) {
    final items = input
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (items.isEmpty && fallbackEmpty) {
      return const <String>[''];
    }
    return items;
  }

  int _timeoutValue(int timeout) {
    if (timeout % 3600 == 0) return timeout ~/ 3600;
    if (timeout % 60 == 0) return timeout ~/ 60;
    return timeout;
  }

  String _timeoutUnit(int timeout) {
    if (timeout % 3600 == 0) return 'h';
    if (timeout % 60 == 0) return 'm';
    return 's';
  }

  int _timeoutToSeconds(int value, String unit) {
    return switch (unit) {
      'h' => value * 3600,
      'm' => value * 60,
      _ => value,
    };
  }

  bool _requiresBackupAccounts(String type) {
    return _supportedBackupTypes.contains(type);
  }

  static const Set<String> _supportedBackupTypes = <String>{
    'app',
    'website',
    'database',
    'directory',
    'snapshot',
    'log',
  };
}
