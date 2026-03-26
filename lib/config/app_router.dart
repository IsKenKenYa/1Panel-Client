import 'package:flutter/material.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/services/onboarding_service.dart';
import 'package:onepanel_client/features/onboarding/onboarding_page.dart';
import 'package:onepanel_client/features/databases/databases_page.dart';
import 'package:onepanel_client/features/firewall/firewall_page.dart';
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
import 'package:onepanel_client/features/settings/ssl_settings_page.dart';
import 'package:onepanel_client/features/commands/models/command_form_args.dart';
import 'package:onepanel_client/features/commands/pages/command_form_page.dart';
import 'package:onepanel_client/features/commands/pages/commands_page.dart';
import 'package:onepanel_client/features/commands/providers/command_form_provider.dart';
import 'package:onepanel_client/features/commands/providers/commands_provider.dart';
import 'package:onepanel_client/features/host_assets/models/host_asset_form_args.dart';
import 'package:onepanel_client/features/host_assets/pages/host_asset_form_page.dart';
import 'package:onepanel_client/features/host_assets/pages/host_assets_page.dart';
import 'package:onepanel_client/features/host_assets/providers/host_asset_form_provider.dart';
import 'package:onepanel_client/features/host_assets/providers/host_assets_provider.dart';
import 'package:onepanel_client/features/operations_center/pages/operations_center_page.dart';
import 'package:onepanel_client/features/operations_center/pages/stage_one_module_placeholder_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
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
  static const String firewall = '/firewall';
  static const String terminal = '/terminal';
  static const String monitoring = '/monitoring';
  static const String securityVerification = '/security-verification';
  static const String settings = '/settings';
  static const String systemSettings = '/system-settings';
  static const String appStore = '/app-store';
  static const String appDetail = '/app-detail';
  static const String installedAppDetail = '/installed-app-detail';
  static const String containerDetail = '/container-detail';
  static const String orchestration = '/orchestration';
  static const String websites = '/websites';
  static const String websiteDetail = '/website-detail';
  static const String websiteCreate = '/website-create';
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
  static const String commands = '/commands';
  static const String commandForm = '/commands/form';
  static const String hostAssets = '/hosts-assets';
  static const String hostAssetForm = '/hosts-assets/form';
  static const String ssh = '/ssh';
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
      case AppRoutes.firewall:
        return MaterialPageRoute(builder: (_) => const FirewallPage());
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

      case AppRoutes.orchestration:
        return MaterialPageRoute(builder: (_) => const OrchestrationPage());
      case AppRoutes.websites:
        return MaterialPageRoute(builder: (_) => const WebsitesPage());

      case AppRoutes.websiteCreate:
        return MaterialPageRoute(builder: (_) => const WebsiteCreateFlowPage());

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
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsSshTitle,
          availableInWeek: 3,
        );
      case AppRoutes.sshLogs:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsSshLogsTitle,
          availableInWeek: 3,
        );
      case AppRoutes.sshSessions:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsSshSessionsTitle,
          availableInWeek: 3,
        );
      case AppRoutes.processes:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsProcessesTitle,
          availableInWeek: 3,
        );
      case AppRoutes.processDetail:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsProcessDetailTitle,
          availableInWeek: 3,
        );
      case AppRoutes.cronjobs:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsCronjobsTitle,
          availableInWeek: 4,
        );
      case AppRoutes.cronjobForm:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsCronjobFormTitle,
          availableInWeek: 5,
        );
      case AppRoutes.cronjobRecords:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsCronjobRecordsTitle,
          availableInWeek: 4,
        );
      case AppRoutes.scripts:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsScriptsTitle,
          availableInWeek: 4,
        );
      case AppRoutes.backups:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsBackupsTitle,
          availableInWeek: 5,
        );
      case AppRoutes.backupAccountForm:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsBackupAccountFormTitle,
          availableInWeek: 5,
        );
      case AppRoutes.backupRecords:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsBackupRecordsTitle,
          availableInWeek: 6,
        );
      case AppRoutes.backupRecover:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsBackupRecoverTitle,
          availableInWeek: 6,
        );
      case AppRoutes.logs:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsLogsTitle,
          availableInWeek: 6,
        );
      case AppRoutes.systemLogViewer:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsSystemLogViewerTitle,
          availableInWeek: 6,
        );
      case AppRoutes.taskLogDetail:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsTaskLogDetailTitle,
          availableInWeek: 6,
        );
      case AppRoutes.runtimes:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsRuntimesTitle,
          availableInWeek: 7,
        );
      case AppRoutes.runtimeDetail:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsRuntimeDetailTitle,
          availableInWeek: 7,
        );
      case AppRoutes.runtimeForm:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsRuntimeFormTitle,
          availableInWeek: 7,
        );
      case AppRoutes.phpExtensions:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsPhpExtensionsTitle,
          availableInWeek: 8,
        );
      case AppRoutes.phpConfig:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsPhpConfigTitle,
          availableInWeek: 8,
        );
      case AppRoutes.nodeModules:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsNodeModulesTitle,
          availableInWeek: 8,
        );
      case AppRoutes.nodeScripts:
        return _buildStageOnePlaceholderRoute(
          titleBuilder: (l10n) => l10n.operationsNodeScriptsTitle,
          availableInWeek: 8,
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

  static Route<dynamic> _buildStageOnePlaceholderRoute({
    required String Function(dynamic l10n) titleBuilder,
    required int availableInWeek,
  }) {
    return MaterialPageRoute(
      builder: (context) => StageOneModulePlaceholderPage(
        title: titleBuilder(context.l10n),
        availableInWeek: availableInWeek,
      ),
    );
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
