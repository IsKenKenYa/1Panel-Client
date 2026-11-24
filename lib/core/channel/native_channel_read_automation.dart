
import '../network/api_client_manager.dart';
import '../../data/models/backup_request_models.dart';
import '../../data/repositories/backup_repository.dart';
import '../../data/repositories/cronjob_repository.dart';
import '../../data/models/cronjob_list_models.dart';
import '../../data/models/cronjob_record_models.dart';
import '../../features/backups/services/backup_record_service.dart';
import '../services/logger/logger_service.dart';

/// 读通道自动化域：计划任务与备份记录、备份账户。
class NativeChannelAutomationReadHandlers {
  /// 定时任务：返回任务列表（含下次执行时间预览）。
  static Future<dynamic> getCronJobs(dynamic arguments) async {
    try {
      final service = CronjobRepository();
      final page = await service.searchCronjobsWithPreview(
        const CronjobListQuery(page: 1, pageSize: 100),
      );
      return page.items
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'type': c.type,
                'status': c.status,
                'spec': c.spec,
                'lastRecordStatus': c.lastRecordStatus,
                'lastRecordTime': c.lastRecordTime,
                'nextHandle': c.nextHandlePreview ?? '',
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get cronjobs for native: $e');
      return [];
    }
  }

  /// 计划任务详情。参数：`{id: int}`。POST /cronjobs/load/info。
  static Future<dynamic> getCronJobInfo(dynamic arguments) async {
    final id = int.tryParse('${arguments['id'] ?? ''}');
    if (id == null) {
      throw ArgumentError('id is required');
    }
    final api = await ApiClientManager.instance.getCronjobApi();
    final response = await api.loadCronjobInfo(id);
    final info = response.data;
    if (info == null) {
      return <String, dynamic>{};
    }
    return {
      'id': info.id,
      'name': info.name,
      'type': info.type,
      'groupID': info.groupID,
      'spec': info.spec,
      'specCustom': info.specCustom,
      'script': info.script,
      'command': info.command,
      'scriptMode': info.scriptMode,
      'status': info.status,
      // 编辑表单回写时需要这些字段，缺失会被服务端按空值覆盖。
      'executor': info.executor,
      'containerName': info.containerName,
      'user': info.user,
      'scriptID': info.scriptID,
      'appID': info.appID,
      'website': info.website,
      'exclusionRules': info.exclusionRules,
      'dbType': info.dbType,
      'dbName': info.dbName,
      'url': info.url,
      'isDir': info.isDir,
      'sourceDir': info.sourceDir,
      'snapshotRule': info.snapshotRule.toJson(),
      'sourceAccountIDs': info.sourceAccountIDs,
      'downloadAccountID': info.downloadAccountID,
      'retainCopies': info.retainCopies,
      'retryTimes': info.retryTimes,
      'timeout': info.timeout,
      'ignoreErr': info.ignoreErr,
      'secret': info.secret,
      'args': info.args,
      'alertCount': info.alertCount,
      'alertTitle': info.alertTitle,
      'alertMethod': info.alertMethod,
      'scopes': info.scopes,
    };
  }

  /// 计划任务执行记录。参数：`{id: int, page?: int, pageSize?: int}`。
  static Future<dynamic> getCronJobRecords(dynamic arguments) async {
    final id = int.tryParse('${arguments['id'] ?? ''}');
    if (id == null) {
      throw ArgumentError('id is required');
    }
    final page = int.tryParse('${arguments['page'] ?? 1}') ?? 1;
    final pageSize = int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50;
    final result = await CronjobRepository().searchRecords(
      CronjobRecordQuery(cronjobId: id, page: page, pageSize: pageSize),
    );
    return {
      'total': result.total,
      'items': result.items
          .map((record) => {
                'id': record.id,
                'taskId': record.taskId,
                'startTime': record.startTime,
                'status': record.status,
                'message': record.message,
                'file': record.file,
              })
          .toList(),
    };
  }

  /// 备份：返回备份记录列表。
  static Future<dynamic> getBackups(dynamic arguments) async {
    try {
      final service = BackupRecordService();
      final records = await service.loadRecords();
      return records
          .map((item) => {
                'id': item.record.id ?? 0,
                'name': item.record.name,
                'type': item.record.type,
                'size': item.size ?? item.record.size,
                'status': item.record.status,
                'createdAt': item.record.createdAt ?? '',
                'backupTime': item.record.backupTime ?? '',
                // 恢复操作所需字段（B13）：
                'detailName': item.record.detailName ?? '',
                'fileName': item.record.fileName ?? '',
                'fileDir': item.record.fileDir ?? '',
                'downloadAccountID': item.record.downloadAccountID ?? 0,
              })
          .toList();
    } catch (e) {
      appLogger.e('Failed to get backups for native: $e');
      return [];
    }
  }

  /// 备份账户列表。参数：`{page?: int, pageSize?: int, keyword?: String}`。
  static Future<dynamic> getBackupAccounts(dynamic arguments) async {
    try {
      final repository = BackupRepository();
      final page = await repository.searchAccounts(
        BackupAccountSearchRequest(
          page: int.tryParse('${arguments?['page'] ?? 1}') ?? 1,
          pageSize: int.tryParse('${arguments?['pageSize'] ?? 50}') ?? 50,
          keyword: arguments?['keyword'] as String?,
        ),
      );
      return {
        'items': page.items.map((account) => account.toJson()).toList(),
        'total': page.total,
      };
    } catch (e) {
      appLogger.e('Failed to get backup accounts for native: $e');
      return <String, dynamic>{'items': <dynamic>[], 'total': 0};
    }
  }

  /// 备份账户可选类型与本地目录。参数：无。
  static Future<dynamic> getBackupAccountOptions(dynamic arguments) async {
    try {
      final repository = BackupRepository();
      final options = await repository.getOptions();
      final localDir = await repository.getLocalDir();
      return {
        'options': options
            .map((option) => {
                  'id': option.id,
                  'name': option.name,
                  'type': option.type,
                  'isPublic': option.isPublic,
                })
            .toList(),
        'localDir': localDir,
      };
    } catch (e) {
      appLogger.e('Failed to get backup account options for native: $e');
      return <String, dynamic>{'types': <dynamic>[]};
    }
  }
}