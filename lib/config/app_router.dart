import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/features/onboarding/onboarding_page.dart';
import 'package:onepanel_client/features/databases/databases_page.dart';
import 'package:onepanel_client/features/databases/databases_detail_page.dart';
import 'package:onepanel_client/features/databases/databases_form_page.dart';
import 'package:onepanel_client/features/databases/databases_remote_page.dart';
import 'package:onepanel_client/features/databases/databases_redis_page.dart';
import 'package:onepanel_client/features/databases/pages/database_backup_page.dart';
import 'package:onepanel_client/features/databases/pages/database_users_page.dart';
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/firewall/firewall_page.dart';
import 'package:onepanel_client/features/firewall/firewall_rule_form_page.dart';
import 'package:onepanel_client/features/monitoring/monitoring_page.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_form_page.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/security/security_verification_page.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';
import 'package:onepanel_client/features/terminal/terminal_page.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:onepanel_client/features/settings/system_settings_page.dart';
import 'package:onepanel_client/features/apps/apps_page.dart';
import 'package:onepanel_client/features/apps/app_detail_page.dart';
import 'package:onepanel_client/features/apps/installed_app_detail_page.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/features/websites/websites_page.dart';
import 'package:onepanel_client/features/websites/website_detail_page.dart';
import 'package:onepanel_client/features/websites/website_domain_page.dart';
import 'package:onepanel_client/features/websites/pages/website_create_flow_page.dart';
import 'package:onepanel_client/features/websites/pages/website_config_center_page.dart';
import 'package:onepanel_client/features/websites/pages/website_routing_rules_page.dart';
import 'package:onepanel_client/features/websites/pages/website_security_access_page.dart';
import 'package:onepanel_client/features/websites/pages/website_site_ssl_page.dart';
import 'package:onepanel_client/features/websites/pages/website_ssl_center_page.dart';
import 'package:onepanel_client/features/websites/pages/website_certificate_detail_page.dart';
import 'package:onepanel_client/features/openresty/openresty_page.dart';
import 'package:onepanel_client/features/openresty/pages/openresty_source_editor_page.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/features/ai/ai_page.dart';
import 'package:onepanel_client/features/ai/agents/agents_provider.dart';
import 'package:onepanel_client/features/ai/mcp_server_provider.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';
import 'package:onepanel_client/features/settings/menu_settings_page.dart';
import 'package:onepanel_client/features/settings/menu_settings_provider.dart';
import 'package:onepanel_client/features/settings/ssl_settings_page.dart';
import 'package:onepanel_client/features/commands/models/command_form_args.dart';
import 'package:onepanel_client/features/commands/pages/command_form_page.dart';
import 'package:onepanel_client/features/commands/pages/commands_page.dart';
import 'package:onepanel_client/features/commands/providers/command_form_provider.dart';
import 'package:onepanel_client/features/commands/providers/commands_provider.dart';
import 'package:onepanel_client/features/backups/models/backup_account_form_args.dart';
import 'package:onepanel_client/features/backups/models/backup_records_args.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/pages/backup_account_form_page.dart';
import 'package:onepanel_client/features/backups/pages/backup_accounts_page.dart';
import 'package:onepanel_client/features/backups/pages/backup_records_page.dart';
import 'package:onepanel_client/features/backups/pages/backup_recover_page.dart';
import 'package:onepanel_client/features/backups/providers/backup_account_form_provider.dart';
import 'package:onepanel_client/features/backups/providers/backup_accounts_provider.dart';
import 'package:onepanel_client/features/backups/providers/backup_records_provider.dart';
import 'package:onepanel_client/features/backups/providers/backup_recover_provider.dart';
import 'package:onepanel_client/features/group/pages/group_center_page.dart';
import 'package:onepanel_client/features/group/providers/group_center_provider.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_args.dart';
import 'package:onepanel_client/features/cronjobs/pages/cronjob_form_page.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_records_args.dart';
import 'package:onepanel_client/features/cronjobs/pages/cronjob_records_page.dart';
import 'package:onepanel_client/features/cronjobs/pages/cronjobs_page.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjob_form_provider.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjob_records_provider.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjobs_provider.dart';
import 'package:onepanel_client/features/host_assets/models/host_asset_form_args.dart';
import 'package:onepanel_client/features/host_assets/pages/host_asset_form_page.dart';
import 'package:onepanel_client/features/host_assets/pages/host_assets_page.dart';
import 'package:onepanel_client/features/host_assets/providers/host_asset_form_provider.dart';
import 'package:onepanel_client/features/host_assets/providers/host_assets_provider.dart';
import 'package:onepanel_client/features/logs/models/system_log_viewer_args.dart';
import 'package:onepanel_client/features/logs/models/task_log_detail_args.dart';
import 'package:onepanel_client/features/logs/pages/logs_center_page.dart';
import 'package:onepanel_client/features/logs/pages/system_log_viewer_page.dart';
import 'package:onepanel_client/features/logs/pages/task_log_detail_page.dart';
import 'package:onepanel_client/features/logs/providers/logs_provider.dart';
import 'package:onepanel_client/features/logs/providers/system_logs_provider.dart';
import 'package:onepanel_client/features/logs/providers/task_logs_provider.dart';
import 'package:onepanel_client/features/operations_center/pages/operations_center_page.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';
import 'package:onepanel_client/features/runtimes/pages/node_modules_page.dart';
import 'package:onepanel_client/features/runtimes/pages/node_scripts_page.dart';
import 'package:onepanel_client/features/runtimes/pages/php_config_page.dart';
import 'package:onepanel_client/features/runtimes/pages/php_extensions_page.dart';
import 'package:onepanel_client/features/runtimes/pages/php_supervisor_page.dart';
import 'package:onepanel_client/features/processes/pages/process_detail_page.dart';
import 'package:onepanel_client/features/processes/pages/processes_page.dart';
import 'package:onepanel_client/features/processes/providers/process_detail_provider.dart';
import 'package:onepanel_client/features/processes/providers/processes_provider.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_detail_args.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_args.dart';
import 'package:onepanel_client/features/runtimes/providers/node_modules_provider.dart';
import 'package:onepanel_client/features/runtimes/providers/node_scripts_provider.dart';
import 'package:onepanel_client/features/runtimes/providers/php_config_provider.dart';
import 'package:onepanel_client/features/runtimes/providers/php_extensions_provider.dart';
import 'package:onepanel_client/features/runtimes/providers/php_supervisor_provider.dart';
import 'package:onepanel_client/features/runtimes/pages/runtime_detail_page.dart';
import 'package:onepanel_client/features/runtimes/pages/runtime_form_page.dart';
import 'package:onepanel_client/features/runtimes/pages/runtimes_center_page.dart';
import 'package:onepanel_client/features/runtimes/providers/runtime_detail_provider.dart';
import 'package:onepanel_client/features/runtimes/providers/runtime_form_provider.dart';
import 'package:onepanel_client/features/runtimes/providers/runtimes_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/ssh/pages/ssh_certs_page.dart';
import 'package:onepanel_client/features/ssh/pages/ssh_logs_page.dart';
import 'package:onepanel_client/features/ssh/pages/ssh_sessions_page.dart';
import 'package:onepanel_client/features/ssh/pages/ssh_settings_page.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_certs_provider.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_logs_provider.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_sessions_provider.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_settings_provider.dart';
import 'package:onepanel_client/features/script_library/pages/script_library_page.dart';
import 'package:onepanel_client/features/script_library/providers/script_library_provider.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_center_page.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_clam_page.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_device_page.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_disk_page.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_fail2ban_page.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_ftp_page.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_host_tool_page.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_clam_provider.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_device_provider.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_disk_provider.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_fail2ban_provider.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_ftp_provider.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_host_tool_provider.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/features/containers/container_detail_page.dart';
import 'package:onepanel_client/features/containers/container_create_page.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/orchestration/orchestration_page.dart';
import 'package:onepanel_client/data/models/host_models.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String server = '/server';
  static const String serverConfig = '/server-config';
  static const String serverSelection = '/server-selection';
  static const String serverDetail = '/server-detail';
  static const String dashboard = '/dashboard';
  static const String files = '/files';
  static const String databases = '/databases';
  static const String databaseDetail = '/database-detail';
  static const String databaseForm = '/database-form';
  static const String databaseRemote = '/database-remote';
  static const String databaseRedisConfig = '/database-redis-config';
  static const String databaseBackups = '/database-backups';
  static const String databaseUsers = '/database-users';
  static const String firewall = '/firewall';
  static const String firewallRules = '/firewall-rules';
  static const String firewallIps = '/firewall-ips';
  static const String firewallPorts = '/firewall-ports';
  static const String firewallRuleForm = '/firewall-rule-form';
  static const String terminal = '/terminal';
  static const String monitoring = '/monitoring';
  static const String securityVerification = '/security-verification';
  static const String settings = '/settings';
  static const String systemSettings = '/system-settings';
  static const String menuSettings = '/system-settings/menu';
  static const String appStore = '/app-store';
  static const String appDetail = '/app-detail';
  static const String installedAppDetail = '/installed-app-detail';
  static const String containerDetail = '/container-detail';
  static const String ai = '/ai';
  static const String orchestration = '/orchestration';
  static const String websites = '/websites';
  static const String websiteDetail = '/website-detail';
  static const String websiteCreate = '/website-create';
  static const String websiteEdit = '/website-edit';
  static const String websiteConfigCenter = '/website-config-center';
  static const String websiteRoutingRules = '/website-routing-rules';
  static const String websiteSecurityAccess = '/website-security-access';
  static const String websiteDomains = '/website-domains';
  static const String websiteSiteSsl = '/website-site-ssl';
  static const String websiteSslCenter = '/website-ssl-center';
  static const String websiteCertificateDetail = '/website-certificate-detail';
  static const String openrestyCenter = '/openresty';
  static const String openrestySourceEditor = '/openresty-source-editor';
  static const String panelSsl = '/panel-ssl';
  static const String operations = '/operations';
  static const String groupCenter = '/operations/groups';
  static const String toolbox = '/toolbox';
  static const String toolboxDevice = '/toolbox/device';
  static const String toolboxDisk = '/toolbox/disk';
  static const String toolboxClam = '/toolbox/clam';
  static const String toolboxFail2ban = '/toolbox/fail2ban';
  static const String toolboxFtp = '/toolbox/ftp';
  static const String toolboxHostTool = '/toolbox/host-tool';
  static const String commands = '/commands';
  static const String commandForm = '/commands/form';
  static const String hostAssets = '/hosts-assets';
  static const String hostAssetForm = '/hosts-assets/form';
  static const String ssh = '/ssh';
  static const String sshCerts = '/ssh/certs';
  static const String sshLogs = '/ssh/logs';
  static const String sshSessions = '/ssh/sessions';
  static const String processes = '/processes';
  static const String processDetail = '/processes/detail';
  static const String cronjobs = '/cronjobs';
  static const String cronjobForm = '/cronjobs/form';
  static const String cronjobRecords = '/cronjobs/records';
  static const String scripts = '/scripts';
  static const String backups = '/backups';
  static const String backupAccountForm = '/backups/accounts/form';
  static const String backupRecords = '/backups/records';
  static const String backupRecover = '/backups/recover';
  static const String logs = '/logs';
  static const String systemLogViewer = '/logs/system';
  static const String taskLogDetail = '/logs/task/detail';
  static const String runtimes = '/runtimes';
  static const String runtimeDetail = '/runtimes/detail';
  static const String runtimeForm = '/runtimes/form';
  static const String phpExtensions = '/runtimes/php/extensions';
  static const String phpConfig = '/runtimes/php/config';
  static const String phpSupervisor = '/runtimes/php/supervisor';
  static const String nodeModules = '/runtimes/node/modules';
  static const String nodeScripts = '/runtimes/node/scripts';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => AppShellPage(
            initialIndex: _readInitialIndex(settings.arguments),
            initialModuleId: _readInitialModuleId(settings.arguments),
          ),
        );
      case AppRoutes.server:
      case AppRoutes.serverSelection:
        return MaterialPageRoute(
            builder: (_) => const ServerListPage(enableCoach: false));
      case AppRoutes.serverConfig:
        return MaterialPageRoute(builder: (_) => const ServerFormPage());
      case AppRoutes.serverDetail:
        final arg = settings.arguments;
        if (arg is ServerCardViewModel) {
          return MaterialPageRoute(
              builder: (_) => ServerDetailPage(server: arg));
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
      case AppRoutes.files:
        return MaterialPageRoute(
            builder: (_) => const AppShellPage(
                  initialIndex: 1,
                  initialModuleId: 'files',
                ));
      case AppRoutes.databases:
        return MaterialPageRoute(builder: (_) => const DatabasesPage());
      case AppRoutes.databaseDetail:
        final arg = settings.arguments;
        if (arg is DatabaseListItem) {
          return MaterialPageRoute(
            builder: (_) => DatabaseDetailPage(item: arg),
          );
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
      case AppRoutes.databaseForm:
        final arg = settings.arguments;
        final scope = arg is Map<String, dynamic>
            ? _readDatabaseScope(arg['scope'])
            : DatabaseScope.mysql;
        return MaterialPageRoute(
          builder: (_) => DatabaseFormPage(initialScope: scope),
        );
      case AppRoutes.databaseRemote:
        return MaterialPageRoute(builder: (_) => const DatabaseRemotePage());
      case AppRoutes.databaseRedisConfig:
        final arg = settings.arguments;
        if (arg is DatabaseListItem) {
          return MaterialPageRoute(
            builder: (_) => DatabaseRedisPage(item: arg),
          );
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
      case AppRoutes.databaseBackups:
        final backupArg = settings.arguments;
        if (backupArg is DatabaseListItem) {
          return MaterialPageRoute(
            builder: (_) => DatabaseBackupPage(item: backupArg),
          );
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
      case AppRoutes.databaseUsers:
        final userArg = settings.arguments;
        if (userArg is DatabaseListItem) {
          return MaterialPageRoute(
            builder: (_) => DatabaseUsersPage(item: userArg),
          );
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
      case AppRoutes.firewall:
        return MaterialPageRoute(builder: (_) => const FirewallPage());
      case AppRoutes.firewallRules:
        return MaterialPageRoute(
          builder: (_) => const FirewallPage(initialTab: 1),
        );
      case AppRoutes.firewallIps:
        return MaterialPageRoute(
          builder: (_) => const FirewallPage(initialTab: 2),
        );
      case AppRoutes.firewallPorts:
        return MaterialPageRoute(
          builder: (_) => const FirewallPage(initialTab: 3),
        );
      case AppRoutes.firewallRuleForm:
        final arg = settings.arguments;
        if (arg is FirewallRuleFormArguments) {
          return MaterialPageRoute(
            builder: (_) => FirewallRuleFormPage(arguments: arg),
          );
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
      case AppRoutes.terminal:
        return MaterialPageRoute(builder: (_) => const TerminalPage());
      case AppRoutes.monitoring:
        return MaterialPageRoute(builder: (_) => const MonitoringPage());
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const AppShellPage(
            initialIndex: 0,
            initialModuleId: 'servers',
          ),
        );
      case AppRoutes.securityVerification:
        return MaterialPageRoute(
          builder: (_) => const SecurityVerificationPage(),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case AppRoutes.systemSettings:
        return MaterialPageRoute(builder: (_) => const SystemSettingsPage());
      case AppRoutes.menuSettings:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<MenuSettingsProvider>(
            create: (_) => MenuSettingsProvider(),
            child: const MenuSettingsPage(),
          ),
        );

      case AppRoutes.appStore:
        return MaterialPageRoute(
            builder: (_) => const AppsPage(initialTabIndex: 1));

      case AppRoutes.appDetail:
        final arg = settings.arguments;
        if (arg is AppItem) {
          return MaterialPageRoute(builder: (_) => AppDetailPage(app: arg));
        } else if (arg is Map<String, dynamic>) {
          final appItem = AppItem(
            id: int.tryParse(arg['appId']?.toString() ?? ''),
            key: arg['key'] as String?,
            versions:
                arg['version'] != null ? [arg['version'] as String] : null,
            type: arg['type'] as String?,
          );
          return MaterialPageRoute(builder: (_) => AppDetailPage(app: appItem));
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());

      case AppRoutes.installedAppDetail:
        final arg = settings.arguments;
        if (arg is AppInstallInfo) {
          return MaterialPageRoute(
              builder: (_) => InstalledAppDetailPage(appInfo: arg));
        } else if (arg is Map<String, dynamic> && arg.containsKey('appId')) {
          return MaterialPageRoute(
              builder: (_) =>
                  InstalledAppDetailPage(appId: arg['appId'] as String));
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());

      case AppRoutes.containerDetail:
        final arg = settings.arguments;
        if (arg is ContainerInfo) {
          return MaterialPageRoute(
              builder: (_) => ContainerDetailPage(container: arg));
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());

      case AppRoutes.ai:
        return MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AIProvider()),
              ChangeNotifierProvider(create: (_) => AgentsProvider()),
              ChangeNotifierProvider(create: (_) => McpServerProvider()),
            ],
            child: const AIPage(),
          ),
        );

      case AppRoutes.orchestration:
        return MaterialPageRoute(builder: (_) => const OrchestrationPage());
      case AppRoutes.websites:
        return MaterialPageRoute(builder: (_) => const WebsitesPage());

      case AppRoutes.websiteCreate:
        return MaterialPageRoute(builder: (_) => const WebsiteCreateFlowPage());

      case AppRoutes.websiteEdit:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return MaterialPageRoute(builder: (_) => const NotFoundPage());
          }
          return MaterialPageRoute(
            builder: (_) => WebsiteCreateFlowPage.edit(websiteId: websiteId),
          );
        }

      case AppRoutes.websiteDetail:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return MaterialPageRoute(builder: (_) => const NotFoundPage());
          }
          return MaterialPageRoute(
            builder: (_) => WebsiteDetailPage(websiteId: websiteId),
          );
        }

      case AppRoutes.websiteConfigCenter:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return MaterialPageRoute(builder: (_) => const NotFoundPage());
          }
          return MaterialPageRoute(
            builder: (_) => WebsiteConfigCenterPage(
              websiteId: websiteId,
              displayName: arg['displayName'] as String?,
            ),
          );
        }

      case AppRoutes.websiteRoutingRules:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return MaterialPageRoute(builder: (_) => const NotFoundPage());
          }
          return MaterialPageRoute(
            builder: (_) => WebsiteRoutingRulesPage(
              websiteId: websiteId,
              displayName: arg['displayName'] as String?,
            ),
          );
        }

      case AppRoutes.websiteSecurityAccess:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return MaterialPageRoute(builder: (_) => const NotFoundPage());
          }
          return MaterialPageRoute(
            builder: (_) => WebsiteSecurityAccessPage(
              websiteId: websiteId,
              displayName: arg['displayName'] as String?,
            ),
          );
        }

      case AppRoutes.websiteDomains:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return MaterialPageRoute(builder: (_) => const NotFoundPage());
          }
          return MaterialPageRoute(
            builder: (_) => WebsiteDomainPage(
              websiteId: websiteId,
              primaryDomain: arg['primaryDomain'] as String?,
            ),
          );
        }

      case AppRoutes.websiteSiteSsl:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return MaterialPageRoute(builder: (_) => const NotFoundPage());
          }
          return MaterialPageRoute(
            builder: (_) => WebsiteSiteSslPage(
              websiteId: websiteId,
              displayName: arg['displayName'] as String?,
            ),
          );
        }

      case AppRoutes.websiteSslCenter:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          return MaterialPageRoute(
            builder: (_) => WebsiteSslCenterPage(
              initialWebsiteId: arg['websiteId'] as int?,
            ),
          );
        }

      case AppRoutes.websiteCertificateDetail:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          final certificateId = arg['certificateId'] as int?;
          if (certificateId == null) {
            return MaterialPageRoute(builder: (_) => const NotFoundPage());
          }
          return MaterialPageRoute(
            builder: (_) =>
                WebsiteCertificateDetailPage(certificateId: certificateId),
          );
        }

      case AppRoutes.panelSsl:
        return MaterialPageRoute(builder: (_) => const SslSettingsPage());

      case AppRoutes.operations:
        return MaterialPageRoute(builder: (_) => const OperationsCenterPage());
      case AppRoutes.groupCenter:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<GroupCenterProvider>(
            create: (_) => GroupCenterProvider(),
            child: const GroupCenterPage(),
          ),
        );

      case AppRoutes.toolbox:
        return MaterialPageRoute(builder: (_) => const ToolboxCenterPage());

      case AppRoutes.toolboxDevice:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ToolboxDeviceProvider>(
            create: (_) => ToolboxDeviceProvider(),
            child: const ToolboxDevicePage(),
          ),
        );
      case AppRoutes.toolboxDisk:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ToolboxDiskProvider>(
            create: (_) => ToolboxDiskProvider(),
            child: const ToolboxDiskPage(),
          ),
        );

      case AppRoutes.toolboxClam:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ToolboxClamProvider>(
            create: (_) => ToolboxClamProvider(),
            child: const ToolboxClamPage(),
          ),
        );

      case AppRoutes.toolboxFail2ban:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ToolboxFail2banProvider>(
            create: (_) => ToolboxFail2banProvider(),
            child: const ToolboxFail2banPage(),
          ),
        );

      case AppRoutes.toolboxFtp:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ToolboxFtpProvider>(
            create: (_) => ToolboxFtpProvider(),
            child: const ToolboxFtpPage(),
          ),
        );
      case AppRoutes.toolboxHostTool:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ToolboxHostToolProvider>(
            create: (_) => ToolboxHostToolProvider(),
            child: const ToolboxHostToolPage(),
          ),
        );

      case AppRoutes.commands:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<CommandsProvider>(
            create: (_) => CommandsProvider(),
            child: const CommandsPage(),
          ),
        );
      case AppRoutes.commandForm:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<CommandFormProvider>(
            create: (context) {
              final provider = CommandFormProvider();
              final currentServer = Provider.of<CurrentServerController?>(
                context,
                listen: false,
              );
              if (currentServer?.hasServer ?? false) {
                provider.initialize(
                  CommandFormArgs(
                    initialValue: settings.arguments as CommandInfo?,
                  ),
                );
              }
              return provider;
            },
            child: CommandFormPage(
              args: CommandFormArgs(
                initialValue: settings.arguments as CommandInfo?,
              ),
            ),
          ),
        );
      case AppRoutes.hostAssets:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<HostAssetsProvider>(
            create: (_) => HostAssetsProvider(),
            child: const HostAssetsPage(),
          ),
        );
      case AppRoutes.hostAssetForm:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<HostAssetFormProvider>(
            create: (context) {
              final provider = HostAssetFormProvider();
              final currentServer = Provider.of<CurrentServerController?>(
                context,
                listen: false,
              );
              if (currentServer?.hasServer ?? false) {
                provider.initialize(
                  HostAssetFormArgs(
                    initialValue: settings.arguments as HostInfo?,
                  ),
                );
              }
              return provider;
            },
            child: HostAssetFormPage(
              args: HostAssetFormArgs(
                initialValue: settings.arguments as HostInfo?,
              ),
            ),
          ),
        );
      case AppRoutes.ssh:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<SshSettingsProvider>(
            create: (_) => SshSettingsProvider(),
            child: const SshSettingsPage(),
          ),
        );
      case AppRoutes.sshCerts:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<SshCertsProvider>(
            create: (_) => SshCertsProvider(),
            child: const SshCertsPage(),
          ),
        );
      case AppRoutes.sshLogs:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<SshLogsProvider>(
            create: (_) => SshLogsProvider(),
            child: const SshLogsPage(),
          ),
        );
      case AppRoutes.sshSessions:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<SshSessionsProvider>(
            create: (_) => SshSessionsProvider(),
            child: const SshSessionsPage(),
          ),
        );
      case AppRoutes.processes:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ProcessesProvider>(
            create: (_) => ProcessesProvider(),
            child: const ProcessesPage(),
          ),
        );
      case AppRoutes.processDetail:
        final arg = settings.arguments;
        if (arg is int) {
          return MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<ProcessDetailProvider>(
              create: (_) => ProcessDetailProvider(),
              child: ProcessDetailPage(pid: arg),
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
      case AppRoutes.cronjobs:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<CronjobsProvider>(
            create: (_) => CronjobsProvider(),
            child: const CronjobsPage(),
          ),
        );
      case AppRoutes.cronjobForm:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<CronjobFormProvider>(
            create: (context) {
              final provider = CronjobFormProvider();
              final currentServer = Provider.of<CurrentServerController?>(
                context,
                listen: false,
              );
              if (currentServer?.hasServer ?? false) {
                provider.initialize(
                  settings.arguments as CronjobFormArgs? ??
                      const CronjobFormArgs(),
                );
              }
              return provider;
            },
            child: CronjobFormPage(
              args: settings.arguments as CronjobFormArgs? ??
                  const CronjobFormArgs(),
            ),
          ),
        );
      case AppRoutes.cronjobRecords:
        final cronjobRecordArg = settings.arguments;
        if (cronjobRecordArg is CronjobRecordsArgs) {
          return MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<CronjobRecordsProvider>(
              create: (_) => CronjobRecordsProvider(),
              child: CronjobRecordsPage(args: cronjobRecordArg),
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
      case AppRoutes.scripts:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<ScriptLibraryProvider>(
            create: (_) => ScriptLibraryProvider(),
            child: const ScriptLibraryPage(),
          ),
        );
      case AppRoutes.backups:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<BackupAccountsProvider>(
            create: (_) => BackupAccountsProvider(),
            child: const BackupAccountsPage(),
          ),
        );
      case AppRoutes.backupAccountForm:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<BackupAccountFormProvider>(
            create: (context) {
              final provider = BackupAccountFormProvider();
              final currentServer = Provider.of<CurrentServerController?>(
                context,
                listen: false,
              );
              if (currentServer?.hasServer ?? false) {
                provider.initialize(
                  settings.arguments as BackupAccountFormArgs? ??
                      const BackupAccountFormArgs(),
                );
              }
              return provider;
            },
            child: BackupAccountFormPage(
              args: settings.arguments as BackupAccountFormArgs? ??
                  const BackupAccountFormArgs(),
            ),
          ),
        );
      case AppRoutes.backupRecords:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<BackupRecordsProvider>(
            create: (_) => BackupRecordsProvider(),
            child: BackupRecordsPage(
              args: settings.arguments as BackupRecordsArgs? ??
                  const BackupRecordsArgs(),
            ),
          ),
        );
      case AppRoutes.backupRecover:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<BackupRecoverProvider>(
            create: (_) => BackupRecoverProvider(),
            child: BackupRecoverPage(
              args: settings.arguments as BackupRecoverArgs? ??
                  const BackupRecoverArgs(),
            ),
          ),
        );
      case AppRoutes.logs:
        return MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider<LogsProvider>(
                create: (_) => LogsProvider(),
              ),
              ChangeNotifierProvider<TaskLogsProvider>(
                create: (_) => TaskLogsProvider(),
              ),
              ChangeNotifierProvider<SystemLogsProvider>(
                create: (_) => SystemLogsProvider(),
              ),
            ],
            child: const LogsCenterPage(),
          ),
        );
      case AppRoutes.systemLogViewer:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<SystemLogsProvider>(
            create: (_) => SystemLogsProvider(),
            child: SystemLogViewerPage(
              args: settings.arguments as SystemLogViewerArgs? ??
                  const SystemLogViewerArgs(),
            ),
          ),
        );
      case AppRoutes.taskLogDetail:
        final args = settings.arguments;
        if (args is! TaskLogDetailArgs) {
          return MaterialPageRoute(builder: (_) => const NotFoundPage());
        }
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<TaskLogsProvider>(
            create: (_) => TaskLogsProvider(),
            child: TaskLogDetailPage(args: args),
          ),
        );
      case AppRoutes.runtimes:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<RuntimesProvider>(
            create: (_) => RuntimesProvider(),
            child: const RuntimesCenterPage(),
          ),
        );
      case AppRoutes.runtimeDetail:
        final detailArgs = settings.arguments;
        if (detailArgs is! RuntimeDetailArgs) {
          return MaterialPageRoute(builder: (_) => const NotFoundPage());
        }
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<RuntimeDetailProvider>(
            create: (_) => RuntimeDetailProvider(),
            child: RuntimeDetailPage(args: detailArgs),
          ),
        );
      case AppRoutes.runtimeForm:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<RuntimeFormProvider>(
            create: (_) => RuntimeFormProvider(),
            child: RuntimeFormPage(
              args: settings.arguments as RuntimeFormArgs? ??
                  const RuntimeFormArgs(),
            ),
          ),
        );
      case AppRoutes.phpExtensions:
        final phpExtensionsArgs = _readRuntimeManageArgs(
          settings.arguments,
          runtimeKind: 'php',
        );
        if (phpExtensionsArgs == null) {
          return MaterialPageRoute(builder: (_) => const NotFoundPage());
        }
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<PhpExtensionsProvider>(
            create: (_) => PhpExtensionsProvider(),
            child: PhpExtensionsPage(args: phpExtensionsArgs),
          ),
        );
      case AppRoutes.phpConfig:
        final phpConfigArgs = _readRuntimeManageArgs(
          settings.arguments,
          runtimeKind: 'php',
        );
        if (phpConfigArgs == null) {
          return MaterialPageRoute(builder: (_) => const NotFoundPage());
        }
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<PhpConfigProvider>(
            create: (_) => PhpConfigProvider(),
            child: PhpConfigPage(args: phpConfigArgs),
          ),
        );
      case AppRoutes.phpSupervisor:
        final phpSupervisorArgs = _readRuntimeManageArgs(
          settings.arguments,
          runtimeKind: 'php',
        );
        if (phpSupervisorArgs == null) {
          return MaterialPageRoute(builder: (_) => const NotFoundPage());
        }
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<PhpSupervisorProvider>(
            create: (_) => PhpSupervisorProvider(),
            child: PhpSupervisorPage(args: phpSupervisorArgs),
          ),
        );
      case AppRoutes.nodeModules:
        final nodeModulesArgs = _readRuntimeManageArgs(
          settings.arguments,
          runtimeKind: 'node',
        );
        if (nodeModulesArgs == null) {
          return MaterialPageRoute(builder: (_) => const NotFoundPage());
        }
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<NodeModulesProvider>(
            create: (_) => NodeModulesProvider(),
            child: NodeModulesPage(args: nodeModulesArgs),
          ),
        );
      case AppRoutes.nodeScripts:
        final nodeScriptsArgs = _readRuntimeManageArgs(
          settings.arguments,
          runtimeKind: 'node',
        );
        if (nodeScriptsArgs == null) {
          return MaterialPageRoute(builder: (_) => const NotFoundPage());
        }
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider<NodeScriptsProvider>(
            create: (_) => NodeScriptsProvider(),
            child: NodeScriptsPage(args: nodeScriptsArgs),
          ),
        );

      case AppRoutes.openrestySourceEditor:
        {
          final arg = settings.arguments as Map<String, dynamic>? ?? const {};
          return MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => OpenRestyProvider()..loadAll(),
              child: OpenRestySourceEditorPage(
                initialContent: arg['initialContent'] as String?,
              ),
            ),
          );
        }

      case '/containers':
        return MaterialPageRoute(
          builder: (_) => const AppShellPage(
            initialIndex: 2,
            initialModuleId: 'containers',
          ),
        );

      case '/apps':
        return MaterialPageRoute(
          builder: (_) => const AppsPage(),
        );

      case '/container-create':
        return MaterialPageRoute(builder: (_) => const ContainerCreatePage());

      case AppRoutes.openrestyCenter:
        return MaterialPageRoute(builder: (_) => const OpenRestyPage());
      case '/help':
        return MaterialPageRoute(builder: (_) => const LegacyRedirectPage());
      default:
        return MaterialPageRoute(builder: (_) => const NotFoundPage());
    }
  }

  static int _readInitialIndex(Object? arguments) {
    if (arguments is int) {
      return arguments;
    }

    if (arguments is Map<String, dynamic>) {
      return (arguments['tab'] as int?) ?? 0;
    }

    return 0;
  }

  static String? _readInitialModuleId(Object? arguments) {
    if (arguments is String) {
      return arguments;
    }

    if (arguments is Map<String, dynamic>) {
      return arguments['module'] as String?;
    }

    return null;
  }

  static RuntimeManageArgs? _readRuntimeManageArgs(
    Object? arguments, {
    String? runtimeKind,
  }) {
    if (arguments is RuntimeManageArgs) {
      return arguments;
    }
    if (arguments is RuntimeDetailArgs) {
      return RuntimeManageArgs(
        runtimeId: arguments.runtimeId,
        runtimeKind: runtimeKind,
      );
    }
    if (arguments is int) {
      return RuntimeManageArgs(
        runtimeId: arguments,
        runtimeKind: runtimeKind,
      );
    }
    if (arguments is Map<String, dynamic>) {
      final runtimeId = (arguments['runtimeId'] as int?) ??
          (arguments['id'] as int?) ??
          int.tryParse(arguments['runtimeId']?.toString() ?? '');
      if (runtimeId == null) {
        return null;
      }
      return RuntimeManageArgs(
        runtimeId: runtimeId,
        runtimeName: arguments['runtimeName']?.toString(),
        runtimeKind: arguments['runtimeKind']?.toString() ??
            arguments['runtimeType']?.toString() ??
            runtimeKind,
        codeDir: arguments['codeDir']?.toString(),
        packageManager: arguments['packageManager']?.toString(),
      );
    }
    return null;
  }

  static DatabaseScope _readDatabaseScope(Object? value) {
    if (value is String) {
      return DatabaseScope.values.firstWhere(
        (scope) => scope.value == value,
        orElse: () => DatabaseScope.mysql,
      );
    }
    return DatabaseScope.mysql;
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final onboardingService = OnboardingService();
    final shouldShowOnboarding = await onboardingService.shouldShowOnboarding();

    if (!mounted) {
      return;
    }

    if (shouldShowOnboarding) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }

    final configs = await ApiConfigManager.getConfigs();
    if (!mounted) {
      return;
    }

    if (configs.isEmpty) {
      Navigator.pushReplacementNamed(context, AppRoutes.serverConfig);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 64),
            const SizedBox(height: 16),
            Text(l10n.appName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.commonLoading),
          ],
        ),
      ),
    );
  }
}

class LegacyRedirectPage extends StatelessWidget {
  const LegacyRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route_outlined, size: 56),
              const SizedBox(height: 16),
              Text(l10n.legacyRouteRedirect, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.home),
                child: Text(l10n.commonConfirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: Center(child: Text(l10n.notFoundDesc)),
    );
  }
}
