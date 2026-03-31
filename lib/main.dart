import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/core/services/transfer/transfer_manager.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

// Feature Providers
import 'features/dashboard/dashboard_provider.dart';
import 'features/apps/app_service.dart';
import 'features/websites/websites_provider.dart';
import 'features/security/app_lock_controller.dart';
import 'features/server/server_provider.dart';
import 'features/shell/controllers/current_server_controller.dart';
import 'features/shell/controllers/pinned_modules_controller.dart';
import 'features/monitoring/monitoring_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appLogger.init();
  await appLogger.loadPreferences();

  FlutterError.onError = (details) {
    appLogger.eWithPackage(
      'main',
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    appLogger.eWithPackage(
      'main',
      'Unhandled Error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Flutter Downloader
  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );

  runApp(
    MultiProvider(
      providers: [
        // App Settings
        ChangeNotifierProvider(
          create: (_) => AppSettingsController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppLockController(),
        ),
        // Server Management
        ChangeNotifierProvider(
          create: (_) => ServerProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CurrentServerController(),
        ),
        ChangeNotifierProvider(
          create: (_) => PinnedModulesController(),
        ),
        // Dashboard
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),
        // Apps
        Provider<AppService>(
          create: (_) => AppService(),
        ),
        // Websites
        ChangeNotifierProvider(
          create: (_) => WebsitesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MonitoringProvider(),
        ),
        // Transfer Manager
        ChangeNotifierProvider(
          create: (_) => TransferManager(),
        ),
      ],
      child: const AppBootstrap(child: MyApp()),
    ),
  );
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AppSettingsController>().load();
      if (!mounted) return;
      await context.read<ThemeController>().load();
      if (!mounted) return;
      await context.read<AppLockController>().load();
      if (!mounted) return;
      await context.read<CurrentServerController>().load();
      if (!mounted) return;
      await context.read<PinnedModulesController>().load();
      if (!mounted) return;
      context.read<TransferManager>().init();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }
    context.read<AppLockController>().onAppLifecycleChanged(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppSettingsController, ThemeController>(
      builder: (context, settings, themeController, _) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            ThemeData lightTheme;
            ThemeData darkTheme;

            if (lightDynamic != null &&
                darkDynamic != null &&
                themeController.useDynamicColor) {
              lightTheme = AppTheme.create(lightDynamic.harmonized());
              darkTheme = AppTheme.create(darkDynamic.harmonized());
            } else {
              lightTheme = AppTheme.create(
                ColorScheme.fromSeed(
                  seedColor: themeController.seedColor,
                  brightness: Brightness.light,
                ),
              );
              darkTheme = AppTheme.create(
                ColorScheme.fromSeed(
                  seedColor: themeController.seedColor,
                  brightness: Brightness.dark,
                ),
              );
            }

            return MaterialApp(
              title: '1Panel Client',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeController.themeMode,
              locale: settings.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('zh'),
              ],
              onGenerateRoute: AppRouter.generateRoute,
              initialRoute: AppRoutes.splash,
            );
          },
        );
      },
    );
  }
}
