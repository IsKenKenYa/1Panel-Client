import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:onepanelapp_app/config/app_router.dart';
import 'package:onepanelapp_app/core/services/app_settings_controller.dart';
import 'package:onepanelapp_app/core/theme/theme_controller.dart';
import 'package:onepanelapp_app/core/services/transfer/transfer_manager.dart';
import 'package:onepanelapp_app/core/theme/app_theme.dart';
import 'package:onepanelapp_app/l10n/generated/app_localizations.dart';

// Feature Providers
import 'features/dashboard/dashboard_provider.dart';
import 'features/containers/containers_provider.dart';
import 'features/apps/providers/installed_apps_provider.dart';
import 'features/apps/app_service.dart';
import 'features/apps/providers/app_store_provider.dart';
import 'features/websites/websites_provider.dart';
import 'features/server/server_provider.dart';
import 'features/monitoring/monitoring_provider.dart';
import 'features/orchestration/providers/compose_provider.dart';
import 'features/orchestration/providers/image_provider.dart';
import 'features/orchestration/providers/network_provider.dart';
import 'features/orchestration/providers/volume_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
          create: (_) => AppSettingsController()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeController()..load(),
        ),
        // Server Management
        ChangeNotifierProvider(
          create: (_) => ServerProvider(),
        ),
        // Dashboard
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),
        // Containers
        ChangeNotifierProvider(
          create: (_) => ContainersProvider(),
        ),
        // Apps
        Provider<AppService>(
          create: (_) => AppService(),
        ),
        ChangeNotifierProvider(
          create: (_) => InstalledAppsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppStoreProvider(),
        ),
        // Websites
        ChangeNotifierProvider(
          create: (_) => WebsitesProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MonitoringProvider(),
        ),
        // Orchestration
        ChangeNotifierProvider(create: (_) => ComposeProvider()),
        ChangeNotifierProvider(create: (_) => DockerImageProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ChangeNotifierProvider(create: (_) => VolumeProvider()),
        // Transfer Manager
        ChangeNotifierProvider(
          create: (_) => TransferManager()..init(),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
              title: '1Panel Open',
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
