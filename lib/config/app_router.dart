import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/config/api_config.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/core/services/onboarding_service.dart';
import 'package:onepanelapp_app/features/onboarding/onboarding_page.dart';
import 'package:onepanelapp_app/features/databases/databases_page.dart';
import 'package:onepanelapp_app/features/firewall/firewall_page.dart';
import 'package:onepanelapp_app/features/monitoring/monitoring_page.dart';
import 'package:onepanelapp_app/features/server/server_detail_page.dart';
import 'package:onepanelapp_app/features/server/server_form_page.dart';
import 'package:onepanelapp_app/features/server/server_list_page.dart';
import 'package:onepanelapp_app/features/server/server_models.dart';
import 'package:onepanelapp_app/features/security/security_verification_page.dart';
import 'package:onepanelapp_app/features/shell/app_shell_page.dart';
import 'package:onepanelapp_app/features/terminal/terminal_page.dart';
import 'package:onepanelapp_app/pages/settings/settings_page.dart';
import 'package:onepanelapp_app/features/settings/system_settings_page.dart';
import 'package:onepanelapp_app/features/apps/apps_page.dart';
import 'package:onepanelapp_app/features/apps/app_detail_page.dart';
import 'package:onepanelapp_app/features/apps/installed_app_detail_page.dart';
import 'package:onepanelapp_app/data/models/app_models.dart';

import 'package:onepanelapp_app/features/containers/container_detail_page.dart';
import 'package:onepanelapp_app/features/containers/container_create_page.dart';
import 'package:onepanelapp_app/data/models/container_models.dart';
import 'package:onepanelapp_app/features/orchestration/orchestration_page.dart';
import 'package:onepanelapp_app/features/websites/websites_page.dart';

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

      // Legacy routes redirect to the new shell.
      case '/websites':
        return MaterialPageRoute(builder: (_) => const WebsitesPage());
      case '/backups':
      case '/help':
      case '/website-create':
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
