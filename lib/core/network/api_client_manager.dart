import '../../api/v2/alert_v2.dart';
import '../../api/v2/app_v2.dart';
import '../../api/v2/auth_v2.dart';
import '../../api/v2/backup_account_v2.dart';
import '../../api/v2/command_v2.dart';
import '../../api/v2/compose_v2.dart';
import '../../api/v2/container_log_stream_v2.dart';
import '../../api/v2/container_v2.dart';
import '../../api/v2/cronjob_v2.dart';
import '../../api/v2/dashboard_v2.dart';
import '../../api/v2/database_v2.dart';
import '../../api/v2/disk_management_v2.dart';
import '../../api/v2/docker_v2.dart';
import '../../api/v2/file_v2.dart';
import '../../api/v2/firewall_v2.dart';
import '../../api/v2/host_v2.dart';
import '../../api/v2/host_tool_v2.dart';
import '../../api/v2/logs_v2.dart';
import '../../api/v2/monitor_v2.dart';
import '../../api/v2/openresty_v2.dart';
import '../../api/v2/process_v2.dart';
import '../../api/v2/runtime_v2.dart';
import '../../api/v2/script_library_v2.dart';
import '../../api/v2/setting_v2.dart';
import '../../api/v2/ssh_v2.dart';
import '../../api/v2/ssl_v2.dart';
import '../../api/v2/system_group_v2.dart';
import '../../api/v2/task_log_v2.dart';
import '../../api/v2/terminal_v2.dart';
import '../../api/v2/toolbox_v2.dart';
import '../../api/v2/update_v2.dart';
import '../../api/v2/vm_v2.dart';
import '../../api/v2/website_v2.dart';
import '../../api/v2/xpack_model_downloader_v2.dart';
import '../../api/v2/ai_v2.dart';
import '../../api/v2/health_v2.dart';
import '../config/api_config.dart';
import 'dio_client.dart';

class ApiClientManager {
  ApiClientManager._internal();

  static final ApiClientManager _instance = ApiClientManager._internal();

  factory ApiClientManager() => _instance;

  static ApiClientManager get instance => _instance;

  final _clients = <String, ({ApiConfig config, DioClient client})>{};

  Future<ApiConfig> _getCurrentConfig() async {
    final config = await ApiConfigManager.getCurrentConfig();
    if (config == null) {
      throw StateError('No API config available');
    }
    return config;
  }

  Future<DioClient> getCurrentClient() async {
    final config = await _getCurrentConfig();
    return getClientForConfig(config);
  }

  DioClient getClientForConfig(ApiConfig config) {
    config.requireOnePanel();
    final existing = _clients[config.id];
    if (existing != null && existing.config.sameConnectionAs(config)) {
      return existing.client;
    }
    removeClient(config.id);
    final client = DioClient(
      baseUrl: config.url,
      apiKey: config.apiKey,
      allowInsecureTls: config.allowInsecureTls,
    );
    _clients[config.id] = (config: config, client: client);
    return client;
  }

  Future<DioClient> _resolveClient(String? serverId) async {
    if (serverId == null) return getCurrentClient();
    return getClientForConfig(await ApiConfigManager.getConfig(serverId));
  }

  Future<DioClient> getClientForServer(ApiConfig expected) async {
    final config = await ApiConfigManager.getConfig(expected.id);
    if (config.revision != expected.revision) {
      throw StateError('Server configuration changed; reopen settings');
    }
    return getClientForConfig(config);
  }

  Future<AppV2Api> getAppApi() async => AppV2Api(await getCurrentClient());

  Future<AuthV2Api> getAuthApi() async => AuthV2Api(await getCurrentClient());

  Future<BackupAccountV2Api> getBackupAccountApi() async =>
      BackupAccountV2Api(await getCurrentClient());

  Future<CommandV2Api> getCommandApi() async =>
      CommandV2Api(await getCurrentClient());

  Future<ComposeV2Api> getComposeApi() async =>
      ComposeV2Api(await getCurrentClient());

  Future<ContainerV2Api> getContainerApi() async =>
      ContainerV2Api(await getCurrentClient());

  Future<ContainerLogStreamV2Api> getContainerLogStreamApi() async =>
      ContainerLogStreamV2Api(await getCurrentClient());

  Future<AlertV2Api> getAlertApi() async =>
      AlertV2Api(await getCurrentClient());

  Future<VMV2Api> getVMApi() async => VMV2Api(await getCurrentClient());

  Future<XpackModelDownloaderV2Api> getXpackModelDownloaderApi() async =>
      XpackModelDownloaderV2Api(await getCurrentClient());

  Future<HealthV2Api> getHealthApi() async =>
      HealthV2Api(await getCurrentClient());

  Future<CronjobV2Api> getCronjobApi() async =>
      CronjobV2Api(await getCurrentClient());

  Future<DashboardV2Api> getDashboardApi() async =>
      DashboardV2Api(await getCurrentClient());

  Future<DatabaseV2Api> getDatabaseApi() async =>
      DatabaseV2Api(await getCurrentClient());

  Future<DiskManagementV2Api> getDiskManagementApi({String? serverId}) async =>
      DiskManagementV2Api(await _resolveClient(serverId));

  Future<DockerV2Api> getDockerApi() async =>
      DockerV2Api(await getCurrentClient());

  Future<FileV2Api> getFileApi() async => FileV2Api(await getCurrentClient());

  Future<FirewallV2Api> getFirewallApi() async =>
      FirewallV2Api(await getCurrentClient());

  Future<HostV2Api> getHostApi() async => HostV2Api(await getCurrentClient());

  Future<HostToolV2Api> getHostToolApi({String? serverId}) async =>
      HostToolV2Api(await _resolveClient(serverId));

  Future<LogsV2Api> getLogsApi() async => LogsV2Api(await getCurrentClient());

  Future<MonitorV2Api> getMonitorApi() async =>
      MonitorV2Api(await getCurrentClient());

  Future<OpenRestyV2Api> getOpenRestyApi() async =>
      OpenRestyV2Api(await getCurrentClient());

  Future<ProcessV2Api> getProcessApi() async =>
      ProcessV2Api(await getCurrentClient());

  Future<ScriptLibraryV2Api> getScriptLibraryApi() async =>
      ScriptLibraryV2Api(await getCurrentClient());

  Future<RuntimeV2Api> getRuntimeApi() async =>
      RuntimeV2Api(await getCurrentClient());

  Future<SettingV2Api> getSettingApi() async =>
      SettingV2Api(await getCurrentClient());

  Future<SshV2Api> getSshApi() async => SshV2Api(await getCurrentClient());

  Future<SSLV2Api> getSslApi() async => SSLV2Api(await getCurrentClient());

  Future<SystemGroupV2Api> getSystemGroupApi() async =>
      SystemGroupV2Api(await getCurrentClient());

  Future<TaskLogV2Api> getTaskLogApi() async =>
      TaskLogV2Api(await getCurrentClient());

  Future<TerminalV2Api> getTerminalApi() async =>
      TerminalV2Api(await getCurrentClient());

  Future<ToolboxV2Api> getToolboxApi({String? serverId}) async =>
      ToolboxV2Api(await _resolveClient(serverId));

  Future<UpdateV2Api> getUpdateApi() async =>
      UpdateV2Api(await getCurrentClient());

  Future<WebsiteV2Api> getWebsiteApi() async =>
      WebsiteV2Api(await getCurrentClient());

  Future<AIV2Api> getAiApi() async {
    final client = await getCurrentClient();
    return AIV2Api(client);
  }

  void removeClient(String serverId, {DioClient? expected}) {
    if (expected != null && !identical(_clients[serverId]?.client, expected)) {
      return;
    }
    _clients.remove(serverId)?.client.dio.close(force: true);
  }

  void invalidateIfChanged(ApiConfig config) {
    final existing = _clients[config.id];
    if (existing != null && !existing.config.sameConnectionAs(config)) {
      removeClient(config.id);
    }
  }

  void clearAllClients() {
    for (final id in _clients.keys.toList()) {
      removeClient(id);
    }
  }
}
