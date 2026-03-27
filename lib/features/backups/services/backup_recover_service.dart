import 'dart:math';

import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/backup_request_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/data/repositories/backup_repository.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/backups/models/backup_records_args.dart';
import 'package:onepanel_client/features/websites/services/website_service.dart';

class BackupRecoverService {
  BackupRecoverService({
    BackupRepository? repository,
    AppService? appService,
    WebsiteService? websiteService,
    ApiClientManager? clientManager,
  })  : _repository = repository ?? BackupRepository(),
        _appService = appService ?? AppService(),
        _websiteService = websiteService ?? WebsiteService(),
        _clientManager = clientManager ?? ApiClientManager.instance;

  final BackupRepository _repository;
  final AppService _appService;
  final WebsiteService _websiteService;
  final ApiClientManager _clientManager;

  Future<List<AppInstallInfo>> loadAppOptions() {
    return _appService.getInstalledApps();
  }

  Future<List<Map<String, dynamic>>> loadWebsiteOptions() {
    return _websiteService.getWebsiteOptions();
  }

  Future<List<DatabaseItemOption>> loadDatabaseOptions(String type) async {
    final api = await _clientManager.getDatabaseApi();
    final response = await api.listDbItems(type);
    return response.data ?? const <DatabaseItemOption>[];
  }

  Future<List<BackupRecord>> loadCandidateRecords({
    required String type,
    required String name,
    required String detailName,
  }) async {
    final page = await _repository.searchRecords(
      BackupRecordQuery(
        type: type,
        name: name,
        detailName: detailName,
      ),
    );
    return page.items;
  }

  Future<void> recover(BackupRecoverRequest request) {
    return _repository.recover(request);
  }

  Future<void> recoverByUpload(BackupRecoverRequest request) {
    return _repository.recoverByUpload(request);
  }

  BackupRecoverRequest buildRecoverRequest({
    required BackupRecord record,
    required String type,
    required String name,
    required String detailName,
    required String secret,
    required int timeout,
  }) {
    return BackupRecoverRequest(
      downloadAccountID: record.downloadAccountID ?? 0,
      type: type,
      name: name,
      detailName: detailName,
      file: '${record.fileDir ?? ''}/${record.fileName ?? ''}',
      secret: secret,
      taskID: _taskId(),
      backupRecordID: record.id,
      timeout: timeout,
    );
  }

  BackupRecordsArgs buildRecordArgs({
    required String type,
    required String name,
    required String detailName,
  }) {
    return BackupRecordsArgs(
      type: type,
      name: name,
      detailName: detailName,
    );
  }

  String _taskId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seed = Random().nextInt(9999);
    return 'backup-recover-$now-$seed';
  }
}
