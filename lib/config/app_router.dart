import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/config/app_route_entries.dart';
import 'package:onepanel_client/config/app_router_pages.dart';

export 'package:onepanel_client/config/app_route_constants.dart';
export 'package:onepanel_client/config/app_router_pages.dart';
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
import 'package:onepanel_client/features/security/app_lock_gate.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/module_registry.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
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
import 'package:onepanel_client/features/openresty/openresty_page.dart';
import 'package:onepanel_client/features/openresty/pages/openresty_source_editor_page.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/features/settings/menu_settings_page.dart';
import 'package:onepanel_client/features/settings/menu_settings_provider.dart';
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

class AppRouter {
  // Prevents re-registration when generateRoute is called multiple times
  static bool _routeRegistryInitialized = false;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    _ensureRouteRegistryInitialized();
    final registryRoute = _buildRouteFromRegistry(settings);
    if (registryRoute != null) {
      return registryRoute;
    }

    // All routes are now served by the registry. Unknown names get 404.
    return MaterialPageRoute(builder: (_) => const NotFoundPage());
  }

  /// Generates a route that always uses the route entry's `defaultBuilder`,
  /// bypassing any platform-specific override.
  ///
  /// Use this when hosting a route inside a desktop shell via
  /// `DesktopRoutedModuleHost`. The outer `desktopBuilder` has already
  /// wrapped the route in the appropriate shell (`UiRouteHost`); the
  /// inner Navigator should render the actual page, not another shell
  /// (which would cause infinite recursion).
  static Route<dynamic> generateEmbeddedRoute(RouteSettings settings) {
    _ensureRouteRegistryInitialized();
    final registryRoute = _buildRouteFromRegistry(
      settings,
      useDefaultBuilder: true,
    );
    if (registryRoute != null) {
      return registryRoute;
    }
    return MaterialPageRoute(builder: (_) => const NotFoundPage());
  }

  // --- legacy switch block removed; all routes served by registry ---

  static void _ensureRouteRegistryInitialized() {
    if (_routeRegistryInitialized) {
      return;
    }
    RouteRegistry.registerAll(buildRouteRegistryEntries());
    _routeRegistryInitialized = true;
  }

  /// Resets the route registry. Tests use this to discard the default
  /// entries built by [_buildRouteRegistryEntries] and substitute their
  /// own. Production code should never call this.
  @visibleForTesting
  static void resetRouteRegistryForTest() {
    RouteRegistry.clear();
    _routeRegistryInitialized = false;
  }

  /// Registers a single test route. Pairs with
  /// [resetRouteRegistryForTest] so each test gets a minimal registry.
  @visibleForTesting
  static void registerRouteForTest(String name, RouteEntry entry) {
    RouteRegistry.register(name, entry);
  }

  static Route<dynamic>? _buildRouteFromRegistry(
    RouteSettings settings, {
    bool useDefaultBuilder = false,
  }) {
    final entry = RouteRegistry.lookup(settings.name);
    if (entry == null) {
      return null;
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final target = UiTargetResolver.resolve(context);
        if (!AppRoutes.shared.contains(settings.name)) {
          final panelType =
              context.watch<CurrentServerController?>()?.currentServer?.panelType;
          if (!supportsOnePanelModules(panelType)) {
            return const ServerListPage(enableCoach: false);
          }
          if (panelType == null &&
              AppRoutes.panelSettings.contains(settings.name) &&
              (useDefaultBuilder || !target.usesDesktopShell)) {
            final title = context.l10n.systemSettingsPanelSection;
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: NoServerSelectedState(moduleName: title),
            );
          }
        }
        final builder = entry.resolve(target, useDefault: useDefaultBuilder);
        final page = builder(context, settings);
        final module = shellModuleForRoute(settings.name!);
        if (module != null && module.pinnable &&
            (useDefaultBuilder || !target.usesDesktopShell)) {
          return AppLockGate(target: module.storageId, child: page);
        }
        return page;
      },
    );
  }

  // Route table extracted to app_route_entries.dart
  static int readInitialIndex(Object? arguments) {
    if (arguments is int) {
      return arguments;
    }

    if (arguments is Map<String, dynamic>) {
      return (arguments['tab'] as int?) ?? 0;
    }

    return 0;
  }

  static String? readInitialModuleId(Object? arguments) {
    if (arguments is String) {
      return arguments;
    }

    if (arguments is Map<String, dynamic>) {
      return arguments['module'] as String?;
    }

    return null;
  }
}
