import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
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
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    await Window.initialize();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1000, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (Platform.isMacOS) {
        await Window.setEffect(effect: WindowEffect.sidebar, dark: false);
      } else if (Platform.isWindows) {
        await Window.setEffect(effect: WindowEffect.mica, dark: false);
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }

  appLogger.init();
  try {
    await appLogger.loadPreferences();
    await appLogger.applyReleaseChannelPolicy();
  } catch (error, stackTrace) {
    appLogger.wWithPackage(
      'main',
      'Failed to load logger preferences, using default log level',
      error: error,
      stackTrace: stackTrace,
    );
  }

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

  // Initialize Flutter Downloader only on Mobile platforms
  if (Platform.isAndroid || Platform.isIOS) {
    await FlutterDownloader.initialize(
      debug: true,
      ignoreSsl: true,
    );
  }

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
            final lightScheme = themeController.useDynamicColor
                ? lightDynamic?.harmonized()
                : null;
            final darkScheme = themeController.useDynamicColor
                ? darkDynamic?.harmonized()
                : null;

            return MaterialApp(
              title: '1Panel Client',
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                return PlatformMenuBar(
                  menus: [
                    PlatformMenu(
                      label: '1Panel Client',
                      menus: [
                        PlatformProvidedMenuItem(
                          type: PlatformProvidedMenuItemType.about,
                        ),
                        PlatformProvidedMenuItem(
                          type: PlatformProvidedMenuItemType.quit,
                        ),
                      ],
                    ),
                    PlatformMenu(
                      label: 'View',
                      menus: [
                        PlatformMenuItem(
                          label: 'Toggle Fullscreen',
                          shortcut: const SingleActivator(
                            LogicalKeyboardKey.keyF,
                            meta: true,
                            control: true,
                          ),
                          onSelected: () async {
                            bool isFullScreen = await windowManager.isFullScreen();
                            windowManager.setFullScreen(!isFullScreen);
                          },
                        ),
                      ],
                    ),
                    PlatformMenu(
                      label: 'Window',
                      menus: [
                        PlatformProvidedMenuItem(
                          type: PlatformProvidedMenuItemType.minimizeWindow,
                        ),
                        PlatformProvidedMenuItem(
                          type: PlatformProvidedMenuItemType.zoomWindow,
                        ),
                      ],
                    ),
                  ],
                  child: child ?? const SizedBox(),
                );
              },
              theme: AppTheme.getLightTheme(
                dynamicScheme: lightScheme,
                seedColor: themeController.seedColor,
              ),
              darkTheme: AppTheme.getDarkTheme(
                dynamicScheme: darkScheme,
                seedColor: themeController.seedColor,
              ),
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
