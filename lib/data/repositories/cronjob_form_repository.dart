import 'package:onepanel_client/api/v2/backup_account_v2.dart';
import 'package:onepanel_client/api/v2/cronjob_v2.dart';
import 'package:onepanel_client/api/v2/database_v2.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/cronjob_form_request_models.dart';
import 'package:onepanel_client/data/models/cronjob_form_response_models.dart';
import 'package:onepanel_client/data/models/cronjob_record_models.dart';
import 'package:onepanel_client/data/models/database_option_models.dart';

class CronjobFormRepository {
  CronjobFormRepository({
    ApiClientManager? clientManager,
    CronjobV2Api? cronjobApi,
    WebsiteV2Api? websiteApi,
    DatabaseV2Api? databaseApi,
    BackupAccountV2Api? backupApi,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _cronjobApi = cronjobApi,
        _websiteApi = websiteApi,
        _databaseApi = databaseApi,
        _backupApi = backupApi;

  final ApiClientManager _clientManager;
  CronjobV2Api? _cronjobApi;
  WebsiteV2Api? _websiteApi;
  DatabaseV2Api? _databaseApi;
  BackupAccountV2Api? _backupApi;

  Future<CronjobV2Api> _ensureCronjobApi() async {
    return _cronjobApi ??= await _clientManager.getCronjobApi();
  }

  Future<WebsiteV2Api> _ensureWebsiteApi() async {
    return _websiteApi ??= await _clientManager.getWebsiteApi();
  }

  Future<DatabaseV2Api> _ensureDatabaseApi() async {
    return _databaseApi ??= await _clientManager.getDatabaseApi();
  }

  Future<BackupAccountV2Api> _ensureBackupApi() async {
    return _backupApi ??= await _clientManager.getBackupAccountApi();
  }

  Future<List<AppInstallInfo>> loadInstalledApps() async {
    final api = await _clientManager.getAppApi();
    return api.getInstalledApps();
  }

  Future<List<Map<String, dynamic>>> loadWebsiteOptions() async {
    final api = await _ensureWebsiteApi();
    return api.getWebsiteOptions(<String, dynamic>{'type': 'all'});
  }

  Future<List<DatabaseItemOption>> loadDatabaseItems(String type) async {
    final api = await _ensureDatabaseApi();
    final response = await api.listDbItems(type);
    return response.data ?? const <DatabaseItemOption>[];
  }

  Future<List<BackupOption>> loadBackupOptions() async {
    final api = await _ensureBackupApi();
    final response = await api.getBackupAccountOptions();
    return response.data ?? const <BackupOption>[];
  }

  Future<List<CronjobScriptOption>> loadScriptOptions() async {
    final api = await _ensureCronjobApi();
    final response = await api.getScriptOptions();
    return response.data ?? const <CronjobScriptOption>[];
  }

  Future<CronjobOperateResponse> loadCronjobInfo(int id) async {
    final api = await _ensureCronjobApi();
    final response = await api.loadCronjobInfo(id);
    return response.data ?? const CronjobOperateResponse();
  }

  Future<List<String>> loadNextPreview(String spec) async {
    final api = await _ensureCronjobApi();
    final response =
        await api.loadNextHandle(CronjobNextPreviewRequest(spec: spec));
    return response.data ?? const <String>[];
  }

  Future<void> createCronjob(CronjobOperateRequest request) async {
    final api = await _ensureCronjobApi();
    await api.createCronjob(request);
  }

  Future<void> updateCronjob(CronjobOperateRequest request) async {
    final api = await _ensureCronjobApi();
    await api.updateCronjob(request);
  }

  Future<void> deleteCronjob(CronjobBatchDeleteRequest request) async {
    final api = await _ensureCronjobApi();
    await api.deleteCronjob(request);
  }

  Future<void> importCronjobs(List<CronjobTransItem> items) async {
    final api = await _ensureCronjobApi();
    await api.importCronjobs(CronjobImportRequest(cronjobs: items));
  }

  Future<List<int>> exportCronjobs(List<int> ids) async {
    final api = await _ensureCronjobApi();
    final response = await api.exportCronjobs(CronjobExportRequest(ids: ids));
    return response.data ?? const <int>[];
  }
}
