import 'dart:math';

import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/backup_request_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';
import 'package:onepanel_client/data/repositories/backup_repository.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/backups/models/backup_records_args.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_source.dart';
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

  static const Set<String> _databaseTypes = <String>{
    'mysql',
    'mysql-cluster',
    'mariadb',
    'postgresql',
    'postgresql-cluster',
    'redis',
    'redis-cluster',
  };

  static const Set<String> _recoverSupportedTypes = <String>{
    'app',
    'website',
    ..._databaseTypes,
  };

  static const Set<String> _knownOtherTypes = <String>{
    'directory',
    'snapshot',
    'log',
  };

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

  BackupRecoverSource resolveSource(BackupRecoverArgs? args) {
    final name = args?.name ?? '';
    final detailName = args?.detailName ?? '';
    return sourceForRawType(
      args?.type,
      name: name,
      detailName: detailName,
    );
  }

  BackupRecoverSource sourceForCategory(
    String category, {
    String? fallbackOtherType,
  }) {
    switch (category) {
      case 'app':
        return sourceForRawType('app');
      case 'website':
        return sourceForRawType('website');
      case 'database':
        return sourceForRawType('mysql');
      default:
        return sourceForRawType(
          _normalizeType(fallbackOtherType).isEmpty
              ? 'directory'
              : fallbackOtherType,
        );
    }
  }

  BackupRecoverSource sourceForRawType(
    String? type, {
    String name = '',
    String detailName = '',
  }) {
    final rawType = _normalizeType(type);
    if (rawType.isEmpty || rawType == 'app') {
      return BackupRecoverSource(
        category: 'app',
        recordType: 'app',
        requestType: 'app',
        name: name,
        detailName: detailName,
        databaseType: 'mysql',
        supportsRecoverAction: true,
      );
    }
    if (rawType == 'website') {
      return BackupRecoverSource(
        category: 'website',
        recordType: 'website',
        requestType: 'website',
        name: name,
        detailName: detailName,
        databaseType: 'mysql',
        supportsRecoverAction: true,
      );
    }
    if (rawType == 'database') {
      return BackupRecoverSource(
        category: 'database',
        recordType: 'mysql',
        requestType: 'mysql',
        name: name,
        detailName: detailName,
        databaseType: 'mysql',
        supportsRecoverAction: true,
      );
    }
    if (_databaseTypes.contains(rawType)) {
      return BackupRecoverSource(
        category: 'database',
        recordType: rawType,
        requestType: rawType,
        name: name,
        detailName: detailName,
        databaseType: _databaseFamily(rawType),
        supportsRecoverAction: true,
      );
    }
    return BackupRecoverSource(
      category: 'other',
      recordType: rawType,
      requestType: rawType,
      name: name,
      detailName: detailName,
      databaseType: 'mysql',
      supportsRecoverAction: _recoverSupportedTypes.contains(rawType) &&
          !_knownOtherTypes.contains(rawType),
    );
  }

  bool isRecoverSupportedType(String type) {
    return _recoverSupportedTypes.contains(_normalizeType(type));
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

  String _normalizeType(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  String _databaseFamily(String type) {
    switch (type) {
      case 'postgresql':
      case 'postgresql-cluster':
        return 'postgresql';
      case 'redis':
      case 'redis-cluster':
        return 'redis';
      default:
        return 'mysql';
    }
  }
}
