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
import 'package:onepanel_client/config/app_router.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:onepanel_client/core/platform/runner_data_path.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/core/services/transfer/transfer_manager.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/features/settings/about_page.dart';

import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_port.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/config/api_config_migration.dart';

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

  // Initialize Native Channel Manager for headless/engine-only communication
  // as early as possible. Uses the instance path via NativeChannelPort so
  // the dispatch can be substituted in tests (architecture review R5 ⑬).
  final NativeChannelPort nativeChannel = NativeChannelManager.instance;
  nativeChannel.initInstance();

  final capabilities = PlatformCapabilities.current();
  final isAndroid = capabilities.supportsBackgroundDownloader;
  final isDesktopHost =
      !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  // Windows native mode requires a WinUI3 host process; if it's absent or the
  // bootstrap launcher explicitly requests MD3, fall back to Flutter rendering.
  final windowsNativeHostActive = !kIsWeb &&
      Platform.isWindows &&
      Platform.environment['ONEPANEL_NATIVE_HOST_ACTIVE'] == '1';
  final forceMd3ByBootstrap = !kIsWeb &&
      Platform.isWindows &&
      Platform.environment['ONEPANEL_FORCE_MD3'] == '1';

  if (windowsNativeHostActive) {
    // headless 引擎寄生在宿主进程内，应用支持目录必须与 Flutter runner
    // 对齐，否则服务器配置等数据读不到（见 RunnerDataPath 文档）。
    // 必须在任何存储读取（loadUIRenderMode 等）之前完成覆盖。
    final runnerSupportDir = RunnerDataPath.resolveRunnerSupportDirectory(
      appDataDir: Platform.environment['APPDATA'],
    );
    if (runnerSupportDir != null) {
      RunnerDataPath.alignAllPathProviders(
        fallback: PathProviderPlatform.instance,
        supportPath: runnerSupportDir,
      );
    }
  }

  final prefs = AppPreferencesService();
  var uiRenderMode = await prefs.loadUIRenderMode();

  if (!kIsWeb &&
      Platform.isWindows &&
      uiRenderMode == UIRenderMode.native &&
      (!windowsNativeHostActive || forceMd3ByBootstrap)) {
    uiRenderMode = UIRenderMode.md3;
  }

  final useFlutterUI = UIRenderPolicy.shouldUseFlutterUI(uiRenderMode);
  final nativeModeFallback = UIRenderPolicy.isNativeModeFallback(uiRenderMode);

  // window_manager must be initialized before any window API calls;
  // only needed when Flutter renders its own UI (not in native/headless mode).
  // 宿主 headless 进程内永不初始化（window_manager 插件在无窗口环境崩溃，
  // 2026-09-09 实证：宿主内偏好 md3 时 useFlutterUI=true 会误触）。
  if (useFlutterUI && isDesktopHost && !windowsNativeHostActive) {
    await windowManager.ensureInitialized();
  }

  appLogger.init();
  if (nativeModeFallback) {
    appLogger.iWithPackage(
      'main',
      UIRenderPolicy.fallbackReason(),
    );
  }
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

  // Migrate API keys from SharedPreferences fallback to secure storage
  try {
    await ApiConfigMigration.runMigrationIfNeeded();
  } catch (error, stackTrace) {
    appLogger.wWithPackage(
      'main',
      'Failed to run API config migration',
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

  if (useFlutterUI) {
    // FlutterDownloader only supports Android; iOS uses native download managers
    if (isAndroid) {
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
            create: (_) => AppSettingsController()
              // 冷启动宿主缺失（bootstrap 强制 MD3）标记，设置页可见化。
              ..markNativeHostMissing(value: forceMd3ByBootstrap),
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
  } else {
    // Engine-only mode (Headless)
    appLogger.iWithPackage(
        'main', 'Running in Headless/Engine-only mode for Native UI');

    // Core services can be instantiated here if needed by NativeChannelManager
    // e.g. ServerProvider, AppSettingsController, etc.
  }
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
    // Load sequentially: each controller may depend on the previous one
    // (e.g. ThemeController needs AppSettingsController for locale context).
    // mounted checks after every await guard against disposal during async gaps.
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
    context.read<MonitoringProvider>().onAppLifecycleChanged(state);
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
                final l10n = AppLocalizations.of(context);
                return PlatformMenuBar(
                  menus: [
                    PlatformMenu(
                      label: '1Panel Client',
                      menus: [
                        PlatformMenuItem(
                          label: l10n.aboutPageTitle,
                          onSelected: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AboutPage(),
                              ),
                            );
                          },
                        ),
                        PlatformMenuItem(
                          label: l10n.commonClose,
                          onSelected: () => SystemNavigator.pop(),
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
                            bool isFullScreen =
                                await windowManager.isFullScreen();
                            windowManager.setFullScreen(!isFullScreen);
                          },
                        ),
                      ],
                    ),
                    PlatformMenu(
                      label: 'Window',
                      menus: [
                        PlatformMenuItem(
                          label: 'Minimize',
                          onSelected: () => windowManager.minimize(),
                        ),
                        PlatformMenuItem(
                          label: 'Maximize / Restore',
                          onSelected: () async {
                            final isMaximized =
                                await windowManager.isMaximized();
                            if (isMaximized) {
                              await windowManager.unmaximize();
                            } else {
                              await windowManager.maximize();
                            }
                          },
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
