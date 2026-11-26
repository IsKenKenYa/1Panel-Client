import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../data/models/backup_account_models.dart';
import '../../data/models/command_models.dart';
import '../../data/models/common_models.dart' show CommandInfo, CommandOperate;
import '../../data/models/cronjob_list_models.dart';
import '../../data/models/cronjob_record_models.dart';
import '../../data/models/logs_models.dart';
import '../../data/models/script_library_models.dart';
import '../../data/repositories/cronjob_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../features/backups/models/backup_account_draft.dart';
import '../../features/backups/models/backup_account_form_args.dart';
import '../../features/backups/models/backup_records_args.dart';
import '../../features/backups/services/backup_account_service.dart';
import '../../features/backups/services/backup_record_service.dart';
import '../../features/backups/services/backup_recover_service.dart';
import '../../features/commands/services/command_service.dart';
import '../../features/cronjobs/services/cronjob_form_service.dart';
import '../../features/cronjobs/models/cronjob_form_draft.dart';
import '../../features/group/services/group_service.dart';
import '../../features/logs/services/logs_service.dart';
import '../../features/script_library/services/script_library_service.dart';
import '../platform/services/platform_file_service.dart';

class NativeChannelHarmonyAutomation {
  static const _channel = MethodChannel('com.onepanel.client/method');
  static ScriptLibraryService? _scriptService;
  static StreamSubscription<String>? _scriptOutput;
  static StreamSubscription<bool>? _scriptState;

  static Future<dynamic> dispatch(String method, dynamic arguments) async {
    final args = arguments == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(arguments as Map);
    switch (method) {
      case 'searchNativeCommands':
        final result = await CommandService().searchCommands(
          CommandSearchRequest(
            page: args['page'] as int? ?? 1,
            pageSize: args['pageSize'] as int? ?? 50,
            info: args['info'] as String?,
            groupID: args['groupID'] as int?,
          ),
        );
        return {
          'items': result.items.map((item) => item.toJson()).toList(),
          'total': result.total,
        };
      case 'saveNativeCommand':
        final request = CommandOperate.fromJson(args);
        final service = CommandService();
        if (request.id == null) {
          await service.createCommand(request);
        } else {
          await service.updateCommand(request);
        }
        return {'success': true};
      case 'deleteNativeCommands':
        await CommandService().deleteCommands(List<int>.from(args['ids'] as List));
        return {'success': true};
      case 'previewNativeCommandsImport':
        final path = await PlatformFileService().pickFile();
        if (path == null) return null;
        final items = await CommandService().parseImportPreviewCsv(
          bytes: await File(path).readAsBytes(),
          fileName: path.split('/').last,
        );
        return items.map((item) => item.toJson()).toList();
      case 'importNativeCommands':
        await CommandService().importCommands(
          (args['items'] as List)
              .map((item) => CommandService().toOperate(
                    CommandInfo.fromJson(Map<String, dynamic>.from(item as Map)),
                  ))
              .toList(),
        );
        return {'success': true};
      case 'exportNativeCommands':
        final result = await CommandService().exportCommandsCsv();
        return {
          'success': result.success,
          'cancelled': result.wasCancelled,
          'path': result.filePath,
        };
      case 'listNativeGroups':
        final groups = await GroupService().listGroups(
          args['type'] as String,
          forceRefresh: true,
          scope: GroupApiScope.values.byName(args['scope'] as String? ?? 'core'),
        );
        return groups.map((item) => item.toJson()).toList();
      case 'saveNativeGroup':
        final service = GroupService();
        final id = args['id'] as int?;
        final type = args['type'] as String;
        final name = args['name'] as String;
        final scope = GroupApiScope.values.byName(args['scope'] as String? ?? 'core');
        if (id == null) {
          await service.createGroup(type: type, name: name, scope: scope);
        } else {
          await service.updateGroup(
            id: id,
            type: type,
            name: name,
            isDefault: args['isDefault'] as bool? ?? false,
            scope: scope,
          );
        }
        return {'success': true};
      case 'deleteNativeGroup':
        await GroupService().deleteGroup(
          id: args['id'] as int,
          type: args['type'] as String,
          scope: GroupApiScope.values.byName(args['scope'] as String? ?? 'core'),
        );
        return {'success': true};
      case 'searchNativeScripts':
        final result = await ScriptLibraryService().searchScripts(
          ScriptLibraryQuery(
            page: args['page'] as int? ?? 1,
            pageSize: args['pageSize'] as int? ?? 50,
            info: args['info'] as String?,
            groupId: args['groupID'] as int?,
          ),
        );
        return {
          'items': result.items.map((item) => {
                'id': item.id,
                'name': item.name,
                'script': item.script,
                'label': item.label,
                'description': item.description,
                'isInteractive': item.isInteractive,
                'isSystem': item.isSystem,
                'groupBelong': item.groupBelong,
                'createdAt': item.createdAt?.toIso8601String(),
              }).toList(),
          'total': result.total,
        };
      case 'syncNativeScripts':
        final state = await ScriptLibraryService().syncScripts();
        return {'success': true, 'taskId': state.taskId};
      case 'startNativeScript':
        await _releaseScript();
        final service = ScriptLibraryService();
        _scriptService = service;
        _scriptOutput = service.watchRunOutput().listen((text) {
          unawaited(_channel.invokeMethod<void>('nativeScriptOutput', text));
        });
        _scriptState = service.watchRunState().listen((running) {
          unawaited(_channel.invokeMethod<void>('nativeScriptState', running));
        });
        await service.startRun(args['id'] as int);
        return {'success': true};
      case 'stopNativeScript':
        await _releaseScript();
        return {'success': true};
      case 'searchNativeCronjobs':
        final result = await CronjobRepository().searchCronjobsWithPreview(
          CronjobListQuery(
            page: args['page'] as int? ?? 1,
            pageSize: args['pageSize'] as int? ?? 50,
            info: args['info'] as String?,
            groupIds: args['groupID'] == null ? const <int>[] : [args['groupID'] as int],
          ),
        );
        return {
          'items': result.items.map((item) => {
                'id': item.id,
                'name': item.name,
                'type': item.type,
                'groupID': item.groupId,
                'groupBelong': item.groupBelong,
                'spec': item.spec,
                'status': item.status,
                'lastRecordStatus': item.lastRecordStatus,
                'lastRecordTime': item.lastRecordTime,
                'nextHandle': item.nextHandlePreview,
              }).toList(),
          'total': result.total,
        };
      case 'getNativeCronjobOptions':
        final service = CronjobFormService();
        final groups = await service.loadGroups();
        final scripts = await service.loadScriptOptions();
        final accounts = await service.loadBackupOptions();
        final apps = await service.loadInstalledApps();
        final websites = await service.loadWebsiteOptions();
        return {
          'groups': groups.map((item) => item.toJson()).toList(),
          'scripts': scripts.map((item) => {'id': item.id, 'name': item.name}).toList(),
          'accounts': accounts.map((item) => item.toJson()).toList(),
          'apps': apps.map((item) => item.toJson()).toList(),
          'websites': websites,
        };
      case 'getNativeCronjobDatabaseOptions':
        final items = await CronjobFormService().loadDatabaseItems(args['type'] as String);
        return items.map((item) => item.toJson()).toList();
      case 'previewNativeCronjobSpec':
        return CronjobRepository().loadNextHandle(args['spec'] as String);
      case 'buildNativeCronjobSpec':
        return CronjobFormService().buildSpec(CronjobFormDraft(
          schedule: CronjobScheduleBuilder(
            mode: args['mode'] as String,
            minute: args['minute'] as int,
            hour: args['hour'] as int,
            dayOfWeek: args['dayOfWeek'] as int,
            dayOfMonth: args['dayOfMonth'] as int,
            interval: args['interval'] as int,
          ),
        ));
      case 'deleteNativeCronjob':
        await CronjobFormService().deleteCronjob(
          args['id'] as int,
          cleanData: args['cleanData'] as bool? ?? false,
          cleanRemoteData: args['cleanRemoteData'] as bool? ?? false,
        );
        return {'success': true};
      case 'stopNativeCronjob':
        await CronjobRepository().stop(args['id'] as int);
        return {'success': true};
      case 'getNativeCronjobRecordLog':
        return CronjobRepository().loadRecordLog(args['id'] as int);
      case 'cleanNativeCronjobRecords':
        await CronjobRepository().cleanRecords(CronjobRecordCleanRequest(
          cronjobId: args['id'] as int,
          cleanData: args['cleanData'] as bool? ?? false,
          cleanRemoteData: args['cleanRemoteData'] as bool? ?? false,
        ));
        return {'success': true};
      case 'importNativeCronjobs':
        final path = await PlatformFileService().pickFile();
        if (path == null) return null;
        final service = CronjobFormService();
        await service.importCronjobs(await service.parseImportFile(await File(path).readAsBytes()));
        return {'success': true};
      case 'exportNativeCronjobs':
        final result = await CronjobFormService().exportCronjobs(List<int>.from(args['ids'] as List));
        return {'success': result.success, 'cancelled': result.wasCancelled, 'path': result.filePath};
      case 'getNativeBackupAccounts':
        final accounts = await BackupAccountService().searchAccounts(
          keyword: args['keyword'] as String?, type: args['type'] as String?,
        );
        return accounts.map((item) => item.toJson()).toList();
      case 'getNativeBackupAccountDraft':
        final service = BackupAccountService();
        final initial = args['account'] == null
            ? null
            : BackupAccountFormArgs(initialValue: BackupAccountInfo.fromJson(Map<String, dynamic>.from(args['account'] as Map)));
        return _backupDraftPayload(await service.preloadClientInfo(await service.initializeDraft(initial)));
      case 'saveNativeBackupAccount':
        await BackupAccountService().saveDraft(_backupDraft(args));
        return {'success': true};
      case 'testNativeBackupAccount':
        return (await BackupAccountService().testConnection(_backupDraft(args))).toJson();
      case 'loadNativeBackupBuckets':
        return BackupAccountService().loadBuckets(_backupDraft(args));
      case 'authorizeNativeBackupAccount':
        await BackupAccountService().openOAuthAuthorizePage(_backupDraft(args));
        return {'success': true};
      case 'prepareNativeBackupAccount':
        return _backupDraftPayload(await BackupAccountService().preloadClientInfo(_backupDraft(args)));
      case 'applyNativeBackupAliyunToken':
        return _backupDraftPayload(BackupAccountService().applyAliyunToken(
          _backupDraft(args), args['token'] as String,
        ));
      case 'refreshNativeBackupAccountToken':
        await BackupAccountService().refreshToken(BackupAccountInfo.fromJson(args));
        return {'success': true};
      case 'getNativeBackupFiles':
        return BackupAccountService().listFiles(args['id'] as int);
      case 'searchNativeBackupRecords':
        final items = await BackupRecordService().loadRecords(
          args: args['cronjobId'] == null
              ? null
              : BackupRecordsArgs(cronjobId: args['cronjobId'] as int),
          type: args['type'] as String,
          name: args['name'] as String? ?? '',
          detailName: args['detailName'] as String? ?? '',
        );
        return items.map((item) => {...item.record.toJson(), 'size': item.size ?? item.record.size}).toList();
      case 'getNativeBackupRecoveryOptions':
        final service = BackupRecoverService();
        final type = args['type'] as String;
        if (type == 'app') {
          return [
            for (final item in await service.loadAppOptions())
              if (item.appKey != null && item.name != null)
                {'name': item.appKey, 'detailName': item.name},
          ];
        }
        if (type == 'website') {
          return [
            for (final item in await service.loadWebsiteOptions())
              {'name': item['alias'], 'detailName': item['alias']},
          ];
        }
        final source = service.sourceForRawType(type);
        return [
          for (final item in await service.loadDatabaseOptions(source.databaseType))
            {'name': item.database, 'detailName': item.name},
        ];
      case 'getNativeBackupRecoveryRecords':
        final records = await BackupRecoverService().loadCandidateRecords(
          type: args['type'] as String,
          name: args['name'] as String,
          detailName: args['detailName'] as String,
        );
        return records.map((item) => item.toJson()).toList();
      case 'recoverNativeBackup':
        final service = BackupRecoverService();
        final record = BackupRecord.fromJson(
          Map<String, dynamic>.from(args['record'] as Map),
        );
        await service.recover(service.buildRecoverRequest(
          record: record,
          type: args['type'] as String,
          name: args['name'] as String,
          detailName: args['detailName'] as String,
          secret: args['secret'] as String,
          timeout: args['timeout'] as int,
        ));
        return {'success': true};
      case 'searchNativeLoginLogs':
        final result = await LogsService().searchLoginLogs(LoginLogSearchRequest.fromJson(args));
        return {'items': result.items.map((item) => item.toJson()).toList(), 'total': result.total};
      case 'searchNativeOperationLogs':
        final result = await LogsService().searchOperationLogs(OperationLogSearchRequest.fromJson(args));
        return {'items': result.items.map((item) => item.toJson()).toList(), 'total': result.total};
      default:
        throw MissingPluginException(method);
    }
  }

  static Future<void> _releaseScript() async {
    await _scriptOutput?.cancel();
    await _scriptState?.cancel();
    _scriptOutput = null;
    _scriptState = null;
    await _scriptService?.stopRun();
    _scriptService = null;
  }

  static BackupAccountDraft _backupDraft(Map<String, dynamic> args) => BackupAccountDraft(
        id: args['id'] as int?, name: args['name'] as String,
        type: args['type'] as String, isPublic: args['isPublic'] as bool,
        accessKey: args['accessKey'] as String, credential: args['credential'] as String,
        bucket: args['bucket'] as String, backupPath: args['backupPath'] as String,
        rememberAuth: args['rememberAuth'] as bool,
        vars: Map<String, dynamic>.from(args['vars'] as Map),
      );

  static Map<String, dynamic> _backupDraftPayload(BackupAccountDraft draft) => {
        'id': draft.id, 'name': draft.name, 'type': draft.type,
        'isPublic': draft.isPublic, 'accessKey': draft.accessKey,
        'credential': draft.credential, 'bucket': draft.bucket,
        'backupPath': draft.backupPath, 'rememberAuth': draft.rememberAuth,
        'vars': draft.vars,
      };
}
