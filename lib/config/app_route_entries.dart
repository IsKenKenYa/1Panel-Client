// Route table extracted from app_router.dart to keep the file under
// the 1000 LOC hard limit (architecture review R5 candidate 2).
// This is a declarative route registry -- essentially data, not logic.
import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/config/app_router_pages.dart';
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
import 'package:onepanel_client/features/firewall/pages/firewall_v2_page.dart';
import 'package:onepanel_client/features/firewall/pages/firewall_v2_section_page.dart';
import 'package:onepanel_client/features/firewall/providers/firewall_v2_provider.dart';
import 'package:onepanel_client/features/ai/pages/ai_agent_plugins_page.dart';
import 'package:onepanel_client/features/host_assets/pages/host_diagnostics_page.dart';
import 'package:onepanel_client/features/monitoring/monitoring_page.dart';
import 'package:onepanel_client/features/server/server_detail_page.dart';
import 'package:onepanel_client/features/server/server_form_page.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/server/server_models.dart';
import 'package:onepanel_client/features/security/security_verification_page.dart';
import 'package:onepanel_client/features/security_gateway/pages/security_gateway_center_page.dart';
import 'package:onepanel_client/features/security_gateway/providers/security_gateway_center_provider.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/module_registry.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/ui/routing/ui_route_host.dart';
import 'package:onepanel_client/ui/routing/route_registry.dart';
import 'package:onepanel_client/ui/routing/ui_target.dart';
import 'package:onepanel_client/ui/routing/ui_target_resolver.dart';
import 'package:onepanel_client/features/terminal/terminal_page.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:onepanel_client/features/settings/system_settings_page.dart';
import 'package:onepanel_client/features/settings/feedback_center_page.dart';
import 'package:onepanel_client/features/settings/language_settings_page.dart';
import 'package:onepanel_client/features/settings/legal_center_page.dart';
import 'package:onepanel_client/features/settings/mainland_sdk_disclosure_page.dart';
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
import 'package:onepanel_client/features/websites/pages/website_templates_page.dart';
import 'package:onepanel_client/features/websites/pages/website_template_form_page.dart';
import 'package:onepanel_client/features/websites/pages/website_template_outputs_page.dart';
import 'package:onepanel_client/features/websites/pages/website_template_output_create_page.dart';
import 'package:onepanel_client/features/openresty/openresty_page.dart';
import 'package:onepanel_client/features/openresty/pages/openresty_source_editor_page.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/features/websites/providers/website_template_provider.dart';
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
import 'package:onepanel_client/features/websites/pages/website_https_page.dart';
import 'package:onepanel_client/features/websites/pages/website_redirect_page.dart';
import 'package:onepanel_client/features/websites/pages/website_cors_page.dart';
import 'package:onepanel_client/features/websites/pages/website_leech_page.dart';
import 'package:onepanel_client/features/websites/pages/website_log_page.dart';
import 'package:onepanel_client/features/websites/pages/website_auth_basic_page.dart';
import 'package:onepanel_client/features/websites/pages/website_resource_page.dart';
import 'package:onepanel_client/features/websites/pages/website_load_balancer_page.dart';
import 'package:onepanel_client/features/files/file_share_page.dart';
import 'package:onepanel_client/features/files/wget_manager_page.dart';
import 'package:onepanel_client/features/files/file_history_page.dart';
import 'package:onepanel_client/features/files/file_permission_page.dart';
import 'package:onepanel_client/features/files/recycle_bin_status_page.dart';
import 'package:onepanel_client/features/ai/pages/ai_gpu_history_page.dart';
import 'package:onepanel_client/features/ai/pages/mcp_server_detail_page.dart';
import 'package:onepanel_client/features/ai/pages/ai_accounts_page.dart';
import 'package:onepanel_client/features/ai/pages/ai_ollama_models_page.dart';
import 'package:onepanel_client/features/ai/pages/ai_agents_page.dart';
import 'package:onepanel_client/features/databases/pages/database_mongodb_page.dart';
import 'package:onepanel_client/features/databases/pages/database_mysql_variables_page.dart';
import 'package:onepanel_client/features/databases/pages/database_pg_privileges_page.dart';
import 'package:onepanel_client/features/databases/pages/database_redis_persistence_page.dart';
import 'package:onepanel_client/features/databases/pages/database_slow_log_page.dart';
import 'package:onepanel_client/features/databases/pages/database_remote_config_page.dart';
import 'package:onepanel_client/features/containers/pages/container_inspect_page.dart';
import 'package:onepanel_client/features/containers/pages/docker_config_page.dart';
import 'package:onepanel_client/features/containers/pages/container_maintenance_page.dart';
import 'package:onepanel_client/features/containers/pages/container_files_page.dart';
import 'package:onepanel_client/features/containers/pages/image_operations_page.dart';
import 'package:onepanel_client/features/toolbox/pages/toolbox_supervisor_page.dart';

  Map<String, RouteEntry> buildRouteRegistryEntries() {
    return <String, RouteEntry>{
      AppRoutes.splash: RouteEntry(
        defaultBuilder: (_, __) => const SplashPage(),
      ),
      AppRoutes.onboarding: RouteEntry(
        defaultBuilder: (_, __) => const OnboardingPage(),
      ),
      AppRoutes.home: RouteEntry(
        defaultBuilder: (_, settings) => UiRouteHost(settings: settings),
      ),
      AppRoutes.server: shellAwareModuleEntry(
        routeName: AppRoutes.server,
        defaultBuilder: (_, __) => const ServerListPage(enableCoach: false),
      ),
      AppRoutes.serverSelection: shellAwareModuleEntry(
        routeName: AppRoutes.serverSelection,
        defaultBuilder: (_, __) => const ServerListPage(enableCoach: false),
      ),
      AppRoutes.serverConfig: shellAwareModuleEntry(
        routeName: AppRoutes.serverConfig,
        defaultBuilder: (_, __) => const ServerFormPage(),
      ),
      AppRoutes.serverDetail: shellAwareModuleEntry(
        routeName: AppRoutes.serverDetail,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is ServerCardViewModel) {
            return ServerDetailPage(server: arg);
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.dashboard: shellAwareModuleEntry(
        routeName: AppRoutes.dashboard,
        defaultBuilder: (_, __) => const UiRouteHost(
          settings: RouteSettings(
            name: AppRoutes.home,
            arguments: {'tab': 0, 'module': 'servers'},
          ),
        ),
      ),
      AppRoutes.files: shellAwareModuleEntry(
        routeName: AppRoutes.files,
        defaultBuilder: (_, __) => const UiRouteHost(
          settings: RouteSettings(
            name: AppRoutes.home,
            arguments: {'tab': 1, 'module': 'files'},
          ),
        ),
      ),
      AppRoutes.containers: shellAwareModuleEntry(
        routeName: AppRoutes.containers,
        defaultBuilder: (_, __) => const UiRouteHost(
          settings: RouteSettings(
            name: AppRoutes.home,
            arguments: {'tab': 2, 'module': 'containers'},
          ),
        ),
      ),
      '/container-create': shellAwareModuleEntry(
        routeName: '/container-create',
        defaultBuilder: (_, __) => const ContainerCreatePage(),
      ),
      AppRoutes.apps: shellAwareModuleEntry(
        routeName: AppRoutes.apps,
        defaultBuilder: (_, __) => const AppsPage(),
      ),
      AppRoutes.appStore: shellAwareModuleEntry(
        routeName: AppRoutes.appStore,
        defaultBuilder: (_, __) => const AppsPage(initialTabIndex: 1),
      ),
      AppRoutes.appDetail: shellAwareModuleEntry(
        routeName: AppRoutes.appDetail,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is AppItem) {
            return AppDetailPage(app: arg);
          }
          if (arg is Map<String, dynamic>) {
            final appItem = AppItem(
              id: int.tryParse(arg['appId']?.toString() ?? ''),
              key: arg['key'] as String?,
              versions:
                  arg['version'] != null ? [arg['version'] as String] : null,
              type: arg['type'] as String?,
            );
            return AppDetailPage(app: appItem);
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.installedAppDetail: shellAwareModuleEntry(
        routeName: AppRoutes.installedAppDetail,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is AppInstallInfo) {
            return InstalledAppDetailPage(appInfo: arg);
          }
          if (arg is Map<String, dynamic> && arg.containsKey('appId')) {
            return InstalledAppDetailPage(appId: arg['appId'] as String);
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.containerDetail: shellAwareModuleEntry(
        routeName: AppRoutes.containerDetail,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is ContainerInfo) {
            return ContainerDetailPage(container: arg);
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.websites: shellAwareModuleEntry(
        routeName: AppRoutes.websites,
        defaultBuilder: (_, __) => const WebsitesPage(),
      ),
      AppRoutes.websiteCreate: shellAwareModuleEntry(
        routeName: AppRoutes.websiteCreate,
        defaultBuilder: (_, __) => const WebsiteCreateFlowPage(),
      ),
      AppRoutes.websiteEdit: shellAwareModuleEntry(
        routeName: AppRoutes.websiteEdit,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteCreateFlowPage.edit(websiteId: websiteId);
        },
      ),
      AppRoutes.websiteDetail: shellAwareModuleEntry(
        routeName: AppRoutes.websiteDetail,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteDetailPage(websiteId: websiteId);
        },
      ),
      AppRoutes.websiteConfigCenter: shellAwareModuleEntry(
        routeName: AppRoutes.websiteConfigCenter,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteConfigCenterPage(
            websiteId: websiteId,
            displayName: arg['displayName'] as String?,
          );
        },
      ),
      AppRoutes.websiteRoutingRules: shellAwareModuleEntry(
        routeName: AppRoutes.websiteRoutingRules,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteRoutingRulesPage(
            websiteId: websiteId,
            displayName: arg['displayName'] as String?,
          );
        },
      ),
      AppRoutes.websiteSecurityAccess: shellAwareModuleEntry(
        routeName: AppRoutes.websiteSecurityAccess,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteSecurityAccessPage(
            websiteId: websiteId,
            displayName: arg['displayName'] as String?,
          );
        },
      ),
      AppRoutes.websiteDomains: shellAwareModuleEntry(
        routeName: AppRoutes.websiteDomains,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteDomainPage(
            websiteId: websiteId,
            primaryDomain: arg['primaryDomain'] as String?,
          );
        },
      ),
      AppRoutes.websiteSiteSsl: shellAwareModuleEntry(
        routeName: AppRoutes.websiteSiteSsl,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteSiteSslPage(
            websiteId: websiteId,
            displayName: arg['displayName'] as String?,
          );
        },
      ),
      AppRoutes.websiteSslCenter: shellAwareModuleEntry(
        routeName: AppRoutes.websiteSslCenter,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          return WebsiteSslCenterPage(
            initialWebsiteId: arg['websiteId'] as int?,
          );
        },
      ),
      AppRoutes.websiteCertificateDetail: shellAwareModuleEntry(
        routeName: AppRoutes.websiteCertificateDetail,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final certificateId = arg['certificateId'] as int?;
          if (certificateId == null) {
            return const NotFoundPage();
          }
          return WebsiteCertificateDetailPage(certificateId: certificateId);
        },
      ),
      AppRoutes.websiteTemplates: shellAwareModuleEntry(
        routeName: AppRoutes.websiteTemplates,
        defaultBuilder: (_, __) =>
            ChangeNotifierProvider<WebsiteTemplateProvider>(
          create: (_) => WebsiteTemplateProvider(),
          child: const WebsiteTemplatesPage(),
        ),
      ),
      AppRoutes.websiteTemplateForm: shellAwareModuleEntry(
        routeName: AppRoutes.websiteTemplateForm,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          return ChangeNotifierProvider<WebsiteTemplateProvider>(
            create: (_) => WebsiteTemplateProvider(),
            child: WebsiteTemplateFormPage(
              templateId: arg['templateId'] as int?,
            ),
          );
        },
      ),
      AppRoutes.websiteTemplateOutputs: shellAwareModuleEntry(
        routeName: AppRoutes.websiteTemplateOutputs,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          return ChangeNotifierProvider<WebsiteTemplateProvider>(
            create: (_) => WebsiteTemplateProvider(),
            child: WebsiteTemplateOutputsPage(
              templateId: arg['templateId'] as int?,
            ),
          );
        },
      ),
      AppRoutes.websiteTemplateOutputCreate: shellAwareModuleEntry(
        routeName: AppRoutes.websiteTemplateOutputCreate,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final templateId = arg['templateId'] as int?;
          if (templateId == null) {
            return const NotFoundPage();
          }
          return ChangeNotifierProvider<WebsiteTemplateProvider>(
            create: (_) => WebsiteTemplateProvider(),
            child: WebsiteTemplateOutputCreatePage(templateId: templateId),
          );
        },
      ),
      AppRoutes.ai: shellAwareModuleEntry(
        routeName: AppRoutes.ai,
        // Delegate to ModuleRegistry.buildAiModule so provider registration
        // has a single source of truth (architecture review candidate ⑧).
        defaultBuilder: (context, _) =>
            ModuleRegistry.buildAiModule(context),
      ),
      AppRoutes.securityVerification: shellAwareModuleEntry(
        routeName: AppRoutes.securityVerification,
        defaultBuilder: (_, __) => const SecurityVerificationPage(),
      ),
      AppRoutes.settings: shellAwareModuleEntry(
        routeName: AppRoutes.settings,
        defaultBuilder: (_, __) => const SettingsPage(),
      ),
      AppRoutes.settingsLanguage: shellAwareModuleEntry(
        routeName: AppRoutes.settingsLanguage,
        defaultBuilder: (_, __) => const LanguageSettingsPage(),
      ),
      AppRoutes.settingsFeedbackCenter: shellAwareModuleEntry(
        routeName: AppRoutes.settingsFeedbackCenter,
        defaultBuilder: (_, __) => const FeedbackCenterPage(),
      ),
      AppRoutes.settingsLegalCenter: shellAwareModuleEntry(
        routeName: AppRoutes.settingsLegalCenter,
        defaultBuilder: (_, __) => const LegalCenterPage(),
      ),
      AppRoutes.settingsMainlandSdkDisclosure: shellAwareModuleEntry(
        routeName: AppRoutes.settingsMainlandSdkDisclosure,
        defaultBuilder: (_, __) => const MainlandSdkDisclosurePage(),
      ),
      AppRoutes.systemSettings: shellAwareModuleEntry(
        routeName: AppRoutes.systemSettings,
        defaultBuilder: (_, __) => const SystemSettingsPage(),
      ),
      AppRoutes.menuSettings: shellAwareModuleEntry(
        routeName: AppRoutes.menuSettings,
        defaultBuilder: (_, __) => ChangeNotifierProvider<MenuSettingsProvider>(
          create: (_) => MenuSettingsProvider(),
          child: const MenuSettingsPage(),
        ),
      ),
      AppRoutes.panelSsl: shellAwareModuleEntry(
        routeName: AppRoutes.panelSsl,
        defaultBuilder: (_, __) => const SslSettingsPage(),
      ),
      AppRoutes.databases: shellAwareModuleEntry(
        routeName: AppRoutes.databases,
        defaultBuilder: (_, __) => const DatabasesPage(),
      ),
      AppRoutes.databaseDetail: shellAwareModuleEntry(
        routeName: AppRoutes.databaseDetail,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is DatabaseListItem) {
            return DatabaseDetailPage(item: arg);
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.databaseForm: shellAwareModuleEntry(
        routeName: AppRoutes.databaseForm,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          final scope = arg is Map<String, dynamic>
              ? readDatabaseScope(arg['scope'])
              : DatabaseScope.mysql;
          return DatabaseFormPage(initialScope: scope);
        },
      ),
      AppRoutes.databaseRemote: shellAwareModuleEntry(
        routeName: AppRoutes.databaseRemote,
        defaultBuilder: (_, __) => const DatabaseRemotePage(),
      ),
      AppRoutes.databaseRedisConfig: shellAwareModuleEntry(
        routeName: AppRoutes.databaseRedisConfig,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is DatabaseListItem) {
            return DatabaseRedisPage(item: arg);
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.databaseBackups: shellAwareModuleEntry(
        routeName: AppRoutes.databaseBackups,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is DatabaseListItem) {
            return DatabaseBackupPage(item: arg);
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.databaseUsers: shellAwareModuleEntry(
        routeName: AppRoutes.databaseUsers,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is DatabaseListItem) {
            return DatabaseUsersPage(item: arg);
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.firewall: shellAwareModuleEntry(
        routeName: AppRoutes.firewall,
        defaultBuilder: (_, __) => const FirewallPage(),
      ),
      AppRoutes.firewallRules: shellAwareModuleEntry(
        routeName: AppRoutes.firewallRules,
        defaultBuilder: (_, __) => const FirewallPage(initialTab: 1),
      ),
      AppRoutes.firewallIps: shellAwareModuleEntry(
        routeName: AppRoutes.firewallIps,
        defaultBuilder: (_, __) => const FirewallPage(initialTab: 2),
      ),
      AppRoutes.firewallPorts: shellAwareModuleEntry(
        routeName: AppRoutes.firewallPorts,
        defaultBuilder: (_, __) => const FirewallPage(initialTab: 3),
      ),
      AppRoutes.firewallRuleForm: shellAwareModuleEntry(
        routeName: AppRoutes.firewallRuleForm,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is FirewallRuleFormArguments) {
            return FirewallRuleFormPage(arguments: arg);
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.firewallV2: shellAwareModuleEntry(
        routeName: AppRoutes.firewallV2,
        defaultBuilder: (_, __) => const FirewallV2Page(),
      ),
      AppRoutes.firewallV2Rules: shellAwareModuleEntry(
        routeName: AppRoutes.firewallV2Rules,
        defaultBuilder: (_, __) => _firewallV2Section(
          FirewallV2Section.rules,
        ),
      ),
      AppRoutes.firewallV2Forward: shellAwareModuleEntry(
        routeName: AppRoutes.firewallV2Forward,
        defaultBuilder: (_, __) => _firewallV2Section(
          FirewallV2Section.forward,
        ),
      ),
      AppRoutes.firewallV2Docker: shellAwareModuleEntry(
        routeName: AppRoutes.firewallV2Docker,
        defaultBuilder: (_, __) => _firewallV2Section(
          FirewallV2Section.docker,
        ),
      ),
      AppRoutes.firewallV2Settings: shellAwareModuleEntry(
        routeName: AppRoutes.firewallV2Settings,
        defaultBuilder: (_, __) => _firewallV2Section(
          FirewallV2Section.settings,
        ),
      ),
      AppRoutes.terminal: shellAwareModuleEntry(
        routeName: AppRoutes.terminal,
        defaultBuilder: (_, __) => const TerminalPage(),
      ),
      AppRoutes.monitoring: shellAwareModuleEntry(
        routeName: AppRoutes.monitoring,
        defaultBuilder: (_, __) => const MonitoringPage(),
      ),
      AppRoutes.operations: shellAwareModuleEntry(
        routeName: AppRoutes.operations,
        defaultBuilder: (_, __) => const OperationsCenterPage(),
      ),
      AppRoutes.groupCenter: shellAwareModuleEntry(
        routeName: AppRoutes.groupCenter,
        defaultBuilder: (_, __) => ChangeNotifierProvider<GroupCenterProvider>(
          create: (_) => GroupCenterProvider(),
          child: const GroupCenterPage(),
        ),
      ),
      AppRoutes.toolbox: shellAwareModuleEntry(
        routeName: AppRoutes.toolbox,
        defaultBuilder: (_, __) => const ToolboxCenterPage(),
      ),
      AppRoutes.toolboxDevice: shellAwareModuleEntry(
        routeName: AppRoutes.toolboxDevice,
        defaultBuilder: (_, __) =>
            ChangeNotifierProvider<ToolboxDeviceProvider>(
          create: (_) => ToolboxDeviceProvider(),
          child: const ToolboxDevicePage(),
        ),
      ),
      AppRoutes.toolboxDisk: shellAwareModuleEntry(
        routeName: AppRoutes.toolboxDisk,
        defaultBuilder: (_, __) => ChangeNotifierProvider<ToolboxDiskProvider>(
          create: (_) => ToolboxDiskProvider(),
          child: const ToolboxDiskPage(),
        ),
      ),
      AppRoutes.toolboxClam: shellAwareModuleEntry(
        routeName: AppRoutes.toolboxClam,
        defaultBuilder: (_, __) => ChangeNotifierProvider<ToolboxClamProvider>(
          create: (_) => ToolboxClamProvider(),
          child: const ToolboxClamPage(),
        ),
      ),
      AppRoutes.toolboxFail2ban: shellAwareModuleEntry(
        routeName: AppRoutes.toolboxFail2ban,
        defaultBuilder: (_, __) =>
            ChangeNotifierProvider<ToolboxFail2banProvider>(
          create: (_) => ToolboxFail2banProvider(),
          child: const ToolboxFail2banPage(),
        ),
      ),
      AppRoutes.toolboxFtp: shellAwareModuleEntry(
        routeName: AppRoutes.toolboxFtp,
        defaultBuilder: (_, __) => ChangeNotifierProvider<ToolboxFtpProvider>(
          create: (_) => ToolboxFtpProvider(),
          child: const ToolboxFtpPage(),
        ),
      ),
      AppRoutes.toolboxHostTool: shellAwareModuleEntry(
        routeName: AppRoutes.toolboxHostTool,
        defaultBuilder: (_, __) =>
            ChangeNotifierProvider<ToolboxHostToolProvider>(
          create: (_) => ToolboxHostToolProvider(),
          child: const ToolboxHostToolPage(),
        ),
      ),
      AppRoutes.commands: shellAwareModuleEntry(
        routeName: AppRoutes.commands,
        defaultBuilder: (_, __) => ChangeNotifierProvider<CommandsProvider>(
          create: (_) => CommandsProvider(),
          child: const CommandsPage(),
        ),
      ),
      AppRoutes.commandForm: shellAwareModuleEntry(
        routeName: AppRoutes.commandForm,
        defaultBuilder: (context, settings) =>
            ChangeNotifierProvider<CommandFormProvider>(
          create: (context) {
            final provider = CommandFormProvider();
            final currentServer = Provider.of<CurrentServerController?>(
              context,
              listen: false,
            );
            if (currentServer?.hasServer ?? false) {
              provider.initialize(
                CommandFormArgs(
                  initialValue: readRouteArg<CommandInfo>(settings.arguments),
                ),
              );
            }
            return provider;
          },
          child: CommandFormPage(
            args: CommandFormArgs(
              initialValue: readRouteArg<CommandInfo>(settings.arguments),
            ),
          ),
        ),
      ),
      AppRoutes.hostAssets: shellAwareModuleEntry(
        routeName: AppRoutes.hostAssets,
        defaultBuilder: (_, __) => ChangeNotifierProvider<HostAssetsProvider>(
          create: (_) => HostAssetsProvider(),
          child: const HostAssetsPage(),
        ),
      ),
      AppRoutes.hostAssetForm: shellAwareModuleEntry(
        routeName: AppRoutes.hostAssetForm,
        defaultBuilder: (context, settings) =>
            ChangeNotifierProvider<HostAssetFormProvider>(
          create: (context) {
            final provider = HostAssetFormProvider();
            final currentServer = Provider.of<CurrentServerController?>(
              context,
              listen: false,
            );
            if (currentServer?.hasServer ?? false) {
              provider.initialize(
                HostAssetFormArgs(
                  initialValue: readRouteArg<HostInfo>(settings.arguments),
                ),
              );
            }
            return provider;
          },
          child: HostAssetFormPage(
            args: HostAssetFormArgs(
              initialValue: readRouteArg<HostInfo>(settings.arguments),
            ),
          ),
        ),
      ),
      AppRoutes.ssh: shellAwareModuleEntry(
        routeName: AppRoutes.ssh,
        defaultBuilder: (_, __) => ChangeNotifierProvider<SshSettingsProvider>(
          create: (_) => SshSettingsProvider(),
          child: const SshSettingsPage(),
        ),
      ),
      AppRoutes.sshCerts: shellAwareModuleEntry(
        routeName: AppRoutes.sshCerts,
        defaultBuilder: (_, __) => ChangeNotifierProvider<SshCertsProvider>(
          create: (_) => SshCertsProvider(),
          child: const SshCertsPage(),
        ),
      ),
      AppRoutes.sshLogs: shellAwareModuleEntry(
        routeName: AppRoutes.sshLogs,
        defaultBuilder: (_, __) => ChangeNotifierProvider<SshLogsProvider>(
          create: (_) => SshLogsProvider(),
          child: const SshLogsPage(),
        ),
      ),
      AppRoutes.sshSessions: shellAwareModuleEntry(
        routeName: AppRoutes.sshSessions,
        defaultBuilder: (_, __) => ChangeNotifierProvider<SshSessionsProvider>(
          create: (_) => SshSessionsProvider(),
          child: const SshSessionsPage(),
        ),
      ),
      AppRoutes.processes: shellAwareModuleEntry(
        routeName: AppRoutes.processes,
        defaultBuilder: (_, __) => ChangeNotifierProvider<ProcessesProvider>(
          create: (_) => ProcessesProvider(),
          child: const ProcessesPage(),
        ),
      ),
      AppRoutes.processDetail: shellAwareModuleEntry(
        routeName: AppRoutes.processDetail,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is int) {
            return ChangeNotifierProvider<ProcessDetailProvider>(
              create: (_) => ProcessDetailProvider(),
              child: ProcessDetailPage(pid: arg),
            );
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.cronjobs: shellAwareModuleEntry(
        routeName: AppRoutes.cronjobs,
        defaultBuilder: (_, __) => ChangeNotifierProvider<CronjobsProvider>(
          create: (_) => CronjobsProvider(),
          child: const CronjobsPage(),
        ),
      ),
      AppRoutes.cronjobForm: shellAwareModuleEntry(
        routeName: AppRoutes.cronjobForm,
        defaultBuilder: (context, settings) =>
            ChangeNotifierProvider<CronjobFormProvider>(
          create: (context) {
            final provider = CronjobFormProvider();
            final currentServer = Provider.of<CurrentServerController?>(
              context,
              listen: false,
            );
            if (currentServer?.hasServer ?? false) {
              provider.initialize(
                readRouteArg<CronjobFormArgs>(settings.arguments) ??
                    const CronjobFormArgs(),
              );
            }
            return provider;
          },
          child: CronjobFormPage(
            args: readRouteArg<CronjobFormArgs>(settings.arguments) ??
                const CronjobFormArgs(),
          ),
        ),
      ),
      AppRoutes.cronjobRecords: shellAwareModuleEntry(
        routeName: AppRoutes.cronjobRecords,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is CronjobRecordsArgs) {
            return ChangeNotifierProvider<CronjobRecordsProvider>(
              create: (_) => CronjobRecordsProvider(),
              child: CronjobRecordsPage(args: arg),
            );
          }
          return const NotFoundPage();
        },
      ),
      AppRoutes.scripts: shellAwareModuleEntry(
        routeName: AppRoutes.scripts,
        defaultBuilder: (_, __) =>
            ChangeNotifierProvider<ScriptLibraryProvider>(
          create: (_) => ScriptLibraryProvider(),
          child: const ScriptLibraryPage(),
        ),
      ),
      AppRoutes.backups: shellAwareModuleEntry(
        routeName: AppRoutes.backups,
        defaultBuilder: (_, __) =>
            ChangeNotifierProvider<BackupAccountsProvider>(
          create: (_) => BackupAccountsProvider(),
          child: const BackupAccountsPage(),
        ),
      ),
      AppRoutes.backupAccountForm: shellAwareModuleEntry(
        routeName: AppRoutes.backupAccountForm,
        defaultBuilder: (context, settings) =>
            ChangeNotifierProvider<BackupAccountFormProvider>(
          create: (context) {
            final provider = BackupAccountFormProvider();
            final currentServer = Provider.of<CurrentServerController?>(
              context,
              listen: false,
            );
            if (currentServer?.hasServer ?? false) {
              provider.initialize(
                readRouteArg<BackupAccountFormArgs>(settings.arguments) ??
                    const BackupAccountFormArgs(),
              );
            }
            return provider;
          },
          child: BackupAccountFormPage(
            args: readRouteArg<BackupAccountFormArgs>(settings.arguments) ??
                const BackupAccountFormArgs(),
          ),
        ),
      ),
      AppRoutes.backupRecords: shellAwareModuleEntry(
        routeName: AppRoutes.backupRecords,
        defaultBuilder: (_, settings) =>
            ChangeNotifierProvider<BackupRecordsProvider>(
          create: (_) => BackupRecordsProvider(),
          child: BackupRecordsPage(
            args: readRouteArg<BackupRecordsArgs>(settings.arguments) ??
                const BackupRecordsArgs(),
          ),
        ),
      ),
      AppRoutes.backupRecover: shellAwareModuleEntry(
        routeName: AppRoutes.backupRecover,
        defaultBuilder: (_, settings) =>
            ChangeNotifierProvider<BackupRecoverProvider>(
          create: (_) => BackupRecoverProvider(),
          child: BackupRecoverPage(
            args: readRouteArg<BackupRecoverArgs>(settings.arguments) ??
                const BackupRecoverArgs(),
          ),
        ),
      ),
      AppRoutes.logs: shellAwareModuleEntry(
        routeName: AppRoutes.logs,
        defaultBuilder: (_, __) => MultiProvider(
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
      ),
      AppRoutes.systemLogViewer: shellAwareModuleEntry(
        routeName: AppRoutes.systemLogViewer,
        defaultBuilder: (_, settings) =>
            ChangeNotifierProvider<SystemLogsProvider>(
          create: (_) => SystemLogsProvider(),
          child: SystemLogViewerPage(
            args: readRouteArg<SystemLogViewerArgs>(settings.arguments) ??
                const SystemLogViewerArgs(),
          ),
        ),
      ),
      AppRoutes.taskLogDetail: shellAwareModuleEntry(
        routeName: AppRoutes.taskLogDetail,
        defaultBuilder: (_, settings) {
          final arg = settings.arguments;
          if (arg is! TaskLogDetailArgs) {
            return const NotFoundPage();
          }
          return ChangeNotifierProvider<TaskLogsProvider>(
            create: (_) => TaskLogsProvider(),
            child: TaskLogDetailPage(args: arg),
          );
        },
      ),
      AppRoutes.runtimes: shellAwareModuleEntry(
        routeName: AppRoutes.runtimes,
        defaultBuilder: (_, __) => ChangeNotifierProvider<RuntimesProvider>(
          create: (_) => RuntimesProvider(),
          child: const RuntimesCenterPage(),
        ),
      ),
      AppRoutes.runtimeDetail: shellAwareModuleEntry(
        routeName: AppRoutes.runtimeDetail,
        defaultBuilder: (_, settings) {
          final detailArgs = settings.arguments;
          if (detailArgs is! RuntimeDetailArgs) {
            return const NotFoundPage();
          }
          return ChangeNotifierProvider<RuntimeDetailProvider>(
            create: (_) => RuntimeDetailProvider(),
            child: RuntimeDetailPage(args: detailArgs),
          );
        },
      ),
      AppRoutes.runtimeForm: shellAwareModuleEntry(
        routeName: AppRoutes.runtimeForm,
        defaultBuilder: (_, settings) =>
            ChangeNotifierProvider<RuntimeFormProvider>(
          create: (_) => RuntimeFormProvider(),
          child: RuntimeFormPage(
            args: readRouteArg<RuntimeFormArgs>(settings.arguments) ??
                const RuntimeFormArgs(),
          ),
        ),
      ),
      AppRoutes.phpExtensions: shellAwareModuleEntry(
        routeName: AppRoutes.phpExtensions,
        defaultBuilder: (_, settings) {
          final args = readRuntimeManageArgs(
            settings.arguments,
            runtimeKind: 'php',
          );
          if (args == null) {
            return const NotFoundPage();
          }
          return ChangeNotifierProvider<PhpExtensionsProvider>(
            create: (_) => PhpExtensionsProvider(),
            child: PhpExtensionsPage(args: args),
          );
        },
      ),
      AppRoutes.phpConfig: shellAwareModuleEntry(
        routeName: AppRoutes.phpConfig,
        defaultBuilder: (_, settings) {
          final args = readRuntimeManageArgs(
            settings.arguments,
            runtimeKind: 'php',
          );
          if (args == null) {
            return const NotFoundPage();
          }
          return ChangeNotifierProvider<PhpConfigProvider>(
            create: (_) => PhpConfigProvider(),
            child: PhpConfigPage(args: args),
          );
        },
      ),
      AppRoutes.phpSupervisor: shellAwareModuleEntry(
        routeName: AppRoutes.phpSupervisor,
        defaultBuilder: (_, settings) {
          final args = readRuntimeManageArgs(
            settings.arguments,
            runtimeKind: 'php',
          );
          if (args == null) {
            return const NotFoundPage();
          }
          return ChangeNotifierProvider<PhpSupervisorProvider>(
            create: (_) => PhpSupervisorProvider(),
            child: PhpSupervisorPage(args: args),
          );
        },
      ),
      AppRoutes.nodeModules: shellAwareModuleEntry(
        routeName: AppRoutes.nodeModules,
        defaultBuilder: (_, settings) {
          final args = readRuntimeManageArgs(
            settings.arguments,
            runtimeKind: 'node',
          );
          if (args == null) {
            return const NotFoundPage();
          }
          return ChangeNotifierProvider<NodeModulesProvider>(
            create: (_) => NodeModulesProvider(),
            child: NodeModulesPage(args: args),
          );
        },
      ),
      AppRoutes.nodeScripts: shellAwareModuleEntry(
        routeName: AppRoutes.nodeScripts,
        defaultBuilder: (_, settings) {
          final args = readRuntimeManageArgs(
            settings.arguments,
            runtimeKind: 'node',
          );
          if (args == null) {
            return const NotFoundPage();
          }
          return ChangeNotifierProvider<NodeScriptsProvider>(
            create: (_) => NodeScriptsProvider(),
            child: NodeScriptsPage(args: args),
          );
        },
      ),
      AppRoutes.orchestration: shellAwareModuleEntry(
        routeName: AppRoutes.orchestration,
        defaultBuilder: (_, __) => const OrchestrationPage(),
      ),
      AppRoutes.securityGatewayCenter: shellAwareModuleEntry(
        routeName: AppRoutes.securityGatewayCenter,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final sectionName = arg['initialSection'] as String?;
          final initialSection = SecurityGatewaySection.values.firstWhere(
            (s) => s.name == sectionName,
            orElse: () => SecurityGatewaySection.panelTls,
          );
          return SecurityGatewayCenterPage(
            initialSection: initialSection,
            initialWebsiteId: arg['websiteId'] as int?,
            displayName: arg['displayName'] as String?,
          );
        },
      ),
      AppRoutes.openrestyCenter: shellAwareModuleEntry(
        routeName: AppRoutes.openrestyCenter,
        defaultBuilder: (_, __) => const OpenRestyPage(),
      ),
      AppRoutes.openrestySourceEditor: shellAwareModuleEntry(
        routeName: AppRoutes.openrestySourceEditor,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          return ChangeNotifierProvider(
            create: (_) => OpenRestyProvider()..loadAll(),
            child: OpenRestySourceEditorPage(
              initialContent: arg['initialContent'] as String?,
            ),
          );
        },
      ),
      AppRoutes.websiteHttps: shellAwareModuleEntry(
        routeName: AppRoutes.websiteHttps,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteHttpsPage(
            websiteId: websiteId,
            displayName: arg['displayName']?.toString() ?? '',
          );
        },
      ),
      AppRoutes.websiteRedirect: shellAwareModuleEntry(
        routeName: AppRoutes.websiteRedirect,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteRedirectPage(
            websiteId: websiteId,
            displayName: arg['displayName']?.toString() ?? '',
          );
        },
      ),
      AppRoutes.websiteCors: shellAwareModuleEntry(
        routeName: AppRoutes.websiteCors,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteCorsPage(
            websiteId: websiteId,
            displayName: arg['displayName']?.toString() ?? '',
          );
        },
      ),
      AppRoutes.websiteLeech: shellAwareModuleEntry(
        routeName: AppRoutes.websiteLeech,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteLeechPage(
            websiteId: websiteId,
            displayName: arg['displayName']?.toString() ?? '',
          );
        },
      ),
      AppRoutes.websiteLog: shellAwareModuleEntry(
        routeName: AppRoutes.websiteLog,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteLogPage(
            websiteId: websiteId,
            displayName: arg['displayName']?.toString() ?? '',
          );
        },
      ),
      AppRoutes.websiteAuthBasic: shellAwareModuleEntry(
        routeName: AppRoutes.websiteAuthBasic,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteAuthBasicPage(
            websiteId: websiteId,
            displayName: arg['displayName']?.toString() ?? '',
          );
        },
      ),
      AppRoutes.websiteResource: shellAwareModuleEntry(
        routeName: AppRoutes.websiteResource,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteResourcePage(
            websiteId: websiteId,
            displayName: arg['displayName']?.toString() ?? '',
          );
        },
      ),
      AppRoutes.websiteLoadBalancer: shellAwareModuleEntry(
        routeName: AppRoutes.websiteLoadBalancer,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final websiteId = arg['websiteId'] as int?;
          if (websiteId == null) {
            return const NotFoundPage();
          }
          return WebsiteLoadBalancerPage(
            websiteId: websiteId,
            displayName: arg['displayName']?.toString() ?? '',
          );
        },
      ),
      AppRoutes.fileShare: shellAwareModuleEntry(
        routeName: AppRoutes.fileShare,
        defaultBuilder: (_, __) => const FileSharePage(),
      ),
      AppRoutes.wgetManager: shellAwareModuleEntry(
        routeName: AppRoutes.wgetManager,
        defaultBuilder: (_, __) => const WgetManagerPage(),
      ),
      AppRoutes.fileHistory: shellAwareModuleEntry(
        routeName: AppRoutes.fileHistory,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          return FileHistoryPage(path: arg['path']?.toString() ?? '/');
        },
      ),
      AppRoutes.filePermission: shellAwareModuleEntry(
        routeName: AppRoutes.filePermission,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final paths = (arg['paths'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(growable: false);
          if (paths.isEmpty) {
            return const NotFoundPage();
          }
          return FilePermissionPage(paths: paths);
        },
      ),
      AppRoutes.recycleBinStatus: shellAwareModuleEntry(
        routeName: AppRoutes.recycleBinStatus,
        defaultBuilder: (_, __) => const RecycleBinStatusPage(),
      ),
      AppRoutes.aiAccounts: shellAwareModuleEntry(
        routeName: AppRoutes.aiAccounts,
        defaultBuilder: (_, __) => const AiAccountsPage(),
      ),
      AppRoutes.aiOllamaModels: shellAwareModuleEntry(
        routeName: AppRoutes.aiOllamaModels,
        defaultBuilder: (_, __) => const AiOllamaModelsPage(),
      ),
      AppRoutes.aiAgents: shellAwareModuleEntry(
        routeName: AppRoutes.aiAgents,
        defaultBuilder: (_, __) => const AiAgentsPage(),
      ),
      AppRoutes.aiGpuHistory: shellAwareModuleEntry(
        routeName: AppRoutes.aiGpuHistory,
        defaultBuilder: (_, __) => const AiGpuHistoryPage(),
      ),
      AppRoutes.mcpServerDetail: shellAwareModuleEntry(
        routeName: AppRoutes.mcpServerDetail,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final serverId = arg['serverId'] as int?;
          if (serverId == null) {
            return const NotFoundPage();
          }
          return McpServerDetailPage(
            serverId: serverId,
            serverName: arg['serverName']?.toString() ?? '',
          );
        },
      ),
      AppRoutes.databaseMongodb: shellAwareModuleEntry(
        routeName: AppRoutes.databaseMongodb,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final databaseName = arg['databaseName'] as String?;
          if (databaseName == null) {
            return const NotFoundPage();
          }
          return DatabaseMongodbPage(
                        databaseName: databaseName,
          );
        },
      ),
      AppRoutes.databaseMysqlVariables: shellAwareModuleEntry(
        routeName: AppRoutes.databaseMysqlVariables,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final databaseName = arg['databaseName'] as String?;
          if (databaseName == null) {
            return const NotFoundPage();
          }
          return DatabaseMysqlVariablesPage(
                        databaseName: databaseName,
          );
        },
      ),
      AppRoutes.databasePgPrivileges: shellAwareModuleEntry(
        routeName: AppRoutes.databasePgPrivileges,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final databaseName = arg['databaseName'] as String?;
          if (databaseName == null) {
            return const NotFoundPage();
          }
          return DatabasePgPrivilegesPage(
                        databaseName: databaseName,
          );
        },
      ),
      AppRoutes.databaseRedisPersistence: shellAwareModuleEntry(
        routeName: AppRoutes.databaseRedisPersistence,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final databaseName = arg['databaseName'] as String?;
          if (databaseName == null) {
            return const NotFoundPage();
          }
          return DatabaseRedisPersistencePage(
                        databaseName: databaseName,
          );
        },
      ),
      AppRoutes.databaseSlowLog: shellAwareModuleEntry(
        routeName: AppRoutes.databaseSlowLog,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final databaseName = arg['databaseName'] as String?;
          if (databaseName == null) {
            return const NotFoundPage();
          }
          return DatabaseSlowLogPage(
                        databaseName: databaseName,
          );
        },
      ),
      AppRoutes.databaseRemoteConfig: shellAwareModuleEntry(
        routeName: AppRoutes.databaseRemoteConfig,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final databaseName = arg['databaseName'] as String?;
          final databaseType = arg['databaseType'] as String?;
          if (databaseName == null || databaseType == null) {
            return const NotFoundPage();
          }
          return DatabaseRemoteConfigPage(
                        databaseName: databaseName,
            databaseType: databaseType,
          );
        },
      ),
      AppRoutes.containerInspect: shellAwareModuleEntry(
        routeName: AppRoutes.containerInspect,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final containerId = arg['containerId'] as String?;
          final containerName = arg['containerName'] as String?;
          if (containerId == null || containerName == null) {
            return const NotFoundPage();
          }
          return ContainerInspectPage(
                        containerId: containerId,
            containerName: containerName,
          );
        },
      ),
      AppRoutes.containerFiles: shellAwareModuleEntry(
        routeName: AppRoutes.containerFiles,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final containerId = arg['containerId'] as String?;
          final containerName = arg['containerName'] as String?;
          if (containerId == null || containerName == null) {
            return const NotFoundPage();
          }
          return ContainerFilesPage(
                        containerId: containerId,
            containerName: containerName,
          );
        },
      ),
      AppRoutes.containerMaintenance: shellAwareModuleEntry(
        routeName: AppRoutes.containerMaintenance,
        defaultBuilder: (_, __) => const ContainerMaintenancePage(),
      ),
      AppRoutes.dockerConfig: shellAwareModuleEntry(
        routeName: AppRoutes.dockerConfig,
        defaultBuilder: (_, __) => const DockerConfigPage(),
      ),
      AppRoutes.imageOperations: shellAwareModuleEntry(
        routeName: AppRoutes.imageOperations,
        defaultBuilder: (_, __) => const ImageOperationsPage(),
      ),
      AppRoutes.toolboxSupervisor: shellAwareModuleEntry(
        routeName: AppRoutes.toolboxSupervisor,
        defaultBuilder: (_, __) => const ToolboxSupervisorPage(),
      ),
      AppRoutes.hostDiagnostics: shellAwareModuleEntry(
        routeName: AppRoutes.hostDiagnostics,
        defaultBuilder: (_, __) => const HostDiagnosticsPage(),
      ),
      AppRoutes.aiAgentPlugins: shellAwareModuleEntry(
        routeName: AppRoutes.aiAgentPlugins,
        defaultBuilder: (_, settings) {
          final arg = readRouteArg<Map<String, dynamic>>(settings.arguments) ?? const {};
          final agentId = arg['agentId'];
          if (agentId == null) {
            return const NotFoundPage();
          }
          return AiAgentPluginsPage(agentId: agentId.toString());
        },
      ),
      '/help': RouteEntry(
        defaultBuilder: (_, __) => const LegacyRedirectPage(),
      ),
    };
  }

  // Desktop platforms use a shell host that manages module switching; mobile
  // renders each route independently. The override map lets us swap the builder
  // per-platform without changing the route table structure.
  RouteEntry shellAwareModuleEntry({
    required String routeName,
    required UiRouteBuilder defaultBuilder,
  }) {
    final shellTarget = shellRouteTargetForRoute(routeName);
    if (shellTarget == null) {
      return RouteEntry(defaultBuilder: defaultBuilder);
    }

    Widget desktopBuilder(BuildContext context, RouteSettings settings) {
      final arguments = <String, dynamic>{
        'module': shellTarget.module.storageId,
      };
      // When embedRouteInShell is true, pass the original route + args so the
      // shell host can render the detail page inside the module panel.
      if (shellTarget.embedRouteInShell) {
        arguments['route'] = routeName;
        if (settings.arguments != null) {
          arguments['routeArgs'] = settings.arguments;
        }
      }
      return UiRouteHost(
        settings: RouteSettings(
          name: AppRoutes.home,
          arguments: arguments,
        ),
      );
    }

    return RouteEntry(
      defaultBuilder: defaultBuilder,
      platformOverrides: {
        UiPlatformKind.desktopWindows: desktopBuilder,
        UiPlatformKind.desktopMacos: desktopBuilder,
        UiPlatformKind.desktopLinux: desktopBuilder,
      },
    );
  }

  Widget _firewallV2Section(FirewallV2Section section) {
    return ChangeNotifierProvider<FirewallV2Provider>(
      create: (_) => FirewallV2Provider(),
      child: FirewallV2SectionPage(section: section),
    );
  }


/// Reads runtime manage args from route arguments.
RuntimeManageArgs? readRuntimeManageArgs(
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

/// Reads database scope from route arguments.
DatabaseScope readDatabaseScope(Object? value) {
  if (value is String) {
    return DatabaseScope.values.firstWhere(
      (scope) => scope.value == value,
      orElse: () => DatabaseScope.mysql,
    );
  }
  return DatabaseScope.mysql;
}

/// Type-safe route argument reader: returns null instead of throwing
/// when the arguments are absent or of an unexpected type.
T? readRouteArg<T>(Object? arguments) => arguments is T ? arguments : null;
