import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:glass/glass.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
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
import 'package:onepanel_client/core/platform/services/browser_document_service.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/core/services/transfer/transfer_manager.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/core/utils/intents.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/harmony_entry_presentation.dart';
import 'package:onepanel_client/core/channel/native_channel_harmony_privacy.dart';
import 'package:onepanel_client/core/channel/native_channel_port.dart';
import 'package:onepanel_client/core/channel/native_terminal_bridge.dart';
import 'package:onepanel_client/core/channel/harmony_ui_bridge.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/config/debug_seed_config.dart';

// Feature Providers
import 'features/security/app_lock_controller.dart';
import 'features/security/app_lock_gate.dart';
import 'features/security/browser_vault_gate.dart';
import 'features/server/server_provider.dart';
import 'features/shell/controllers/current_server_controller.dart';
import 'features/shell/connection_service_providers.dart';
import 'features/shell/server_route_observer.dart';
import 'features/shell/controllers/pinned_modules_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final launchPath = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final initialSettings = kIsWeb && AppRoutes.localSettings.contains(launchPath)
      ? launchPath
      : null;
  await applyDebugSeedConfig();
  applyDebugSemanticsIfRequested();

  // Initialize Native Channel Manager for headless/engine-only communication
  // as early as possible. Uses the instance path via NativeChannelPort so
  // the dispatch can be substituted in tests (architecture review R5 ⑬).
  final NativeChannelPort nativeChannel = NativeChannelManager.instance;
  nativeChannel.initInstance();
  NativeTerminalBridge.init();

  final capabilities = PlatformCapabilities.current();
  final isAndroid = capabilities.supportsBackgroundDownloader;
  if (isAndroid) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
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

  final nativeHostMissing = !kIsWeb &&
      Platform.isWindows &&
      uiRenderMode == UIRenderMode.native &&
      (!windowsNativeHostActive || forceMd3ByBootstrap);
  if (nativeHostMissing) {
    uiRenderMode = UIRenderMode.md3;
  }

  final useFlutterUI = UIRenderPolicy.shouldUseFlutterUI(uiRenderMode);
  final nativeModeFallback = UIRenderPolicy.isNativeModeFallback(uiRenderMode);
  UIRenderPolicy.setLiquidGlassEnabled(uiRenderMode);

  // 预加载玻璃 shader：运行期可随时从 MDUI3 切到液态玻璃，因此不再按启动
  // 模式条件跳过。premium 多 pass 折射仅 Apple Metal 预热；GLES 低端设备
  // 用 never（premium 管线会阻塞主线程并丢失 GPU 上下文）。
  await LiquidGlass.precache();
  await LiquidGlassWidgets.initialize(
    enablePerformanceMonitor: false,
    warmUpMode: UIRenderPolicy.premiumGlassAllowed
        ? GlassWarmUpMode.auto
        : GlassWarmUpMode.never,
  );

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

    final settings = AppSettingsController(preferencesService: prefs)
      ..markNativeHostMissing(value: nativeHostMissing);
    final appearance = ThemeController(preferencesService: prefs);
    await Future.wait([settings.load(), appearance.load()]);
    final appShell = AppBootstrap(child: MyApp(initialSettings: initialSettings));
    final app = MultiProvider(
        providers: [
          // App Settings
          ChangeNotifierProvider(create: (_) => settings),
          ChangeNotifierProvider(create: (_) => appearance),
          ChangeNotifierProvider(
            create: (_) => AppLockController(),
          ),
          // Server Management
          ChangeNotifierProvider(
            create: (_) => CurrentServerController(),
          ),
          ChangeNotifierProvider(
            create: (context) => ServerProvider(
              directory: context.read<CurrentServerController>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => PinnedModulesController(),
          ),
          ProxyProvider<CurrentServerController, (String?, String?)>(
            update: (_, controller, __) =>
                (controller.currentServerId, controller.currentServer?.revision),
          ),
          ...connectionServiceProviders(),
          // Transfer Manager
          ChangeNotifierProvider(
            create: (_) => TransferManager(),
          ),
        ],
        child: kIsWeb ? BrowserVaultGate(child: appShell) : appShell,
      );
    // 始终套玻璃包装：它只注册全局配置与亮度解析，是否渲染玻璃由各组件
    // 按当前渲染模式决定。运行期在 MDUI3 与液态玻璃之间切换时无需重建根节点。
    runApp(
      LiquidGlassWidgets.wrap(
        // MaterialApp 主题亮度解析：玻璃明暗跟随 ThemeMode 而非系统。
        brightnessResolver: Theme.maybeBrightnessOf,
        child: app,
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 首屏已经渲染；后续初始化失败只记录，不再让应用整体崩溃。
      Future<void> guarded(String name, Future<void> Function() step) async {
        try {
          await step();
        } catch (error, stackTrace) {
          appLogger.eWithPackage(
            'app.bootstrap',
            'Init step failed: $name',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }

      await guarded('appLock', () => context.read<AppLockController>().load());
      if (!mounted) return;
      await guarded(
        'currentServer',
        () => context.read<CurrentServerController>().ensureLoaded(),
      );
      if (!mounted) return;
      await guarded(
        'pinnedModules',
        () => context.read<PinnedModulesController>().load(),
      );
      if (!mounted) return;
      await guarded(
        'transferManager',
        () async => context.read<TransferManager>().init(),
      );
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

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialSettings});

  final String? initialSettings;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigator = GlobalKey<NavigatorState>();
  final _lockTarget = ValueNotifier<String?>(null);
  HarmonyUIBridge? _harmonyUI;
  late final _routes = ServerRouteObserver(
    isAppNavigator: true,
    lockTarget: _lockTarget,
  );

  @override
  void initState() {
    super.initState();
    if (PlatformCapabilities.current().isOhos) {
      NativeChannelHarmonyPrivacy.bind(
        context.read<AppLockController>(),
        context.read<AppSettingsController>(),
      );
      _harmonyUI = HarmonyUIBridge(
        navigatorKey: _navigator,
        requiresUnlock: (module) => AppLockGate.requiresUnlock(
          context.read<AppLockController?>(),
          module,
        ),
        unlock: () {
          final context = _navigator.currentContext!;
          return context.read<AppLockController>().authenticateForUnlock(
            reason: AppLocalizations.of(context).appLockUnlockReasonAppOpen,
          );
        },
        refreshSettings: () async {
          await Future.wait([
            context.read<AppSettingsController>().load(),
            context.read<ThemeController>().load(),
          ]);
        },
      );
    }
  }

  @override
  void dispose() {
    _harmonyUI?.dispose();
    _lockTarget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.select((CurrentServerController? controller) =>
        (controller?.currentServerId, controller?.currentServer?.revision));
    _routes.updateConnection(connection.$1, connection.$2);
    final locale = context.select((AppSettingsController settings) => settings.locale);
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        _harmonyUI?.updatePresentation(
          mode: context.watch<AppSettingsController>().uiRenderMode,
          locale: locale,
          themeMode: themeController.themeMode,
        );
        final density = AdaptiveLayoutSpec.of(context).adaptiveDensity;
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final lightScheme = themeController.useDynamicColor
                ? lightDynamic?.harmonized()
                : null;
            final darkScheme = themeController.useDynamicColor
                ? darkDynamic?.harmonized()
                : null;

            return MaterialApp(
              navigatorKey: _navigator,
              navigatorObservers: [_routes, if (_harmonyUI != null) _harmonyUI!],
              title: 'KenPanel',
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                if (_harmonyUI case final harmonyUI?) {
                  final appLock = context.watch<AppLockController?>();
                  harmonyUI.updateUnlockState(
                    busy: appLock?.isUnlocking ?? false,
                    error: appLock?.lastError,
                  );
                }
                final content = Provider<HarmonyEntryPresentation?>.value(
                  value: _harmonyUI?.entry,
                  child: Provider<ColorScheme?>.value(
                    value: lightDynamic,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _lockTarget,
                        if (_harmonyUI != null) _harmonyUI!,
                      ]),
                      child: child ?? const SizedBox(),
                      builder: (_, navigator) => AppLockGate(
                        target: _harmonyUI?.nativeRootEnabled == true
                            ? _harmonyUI!.lockTarget
                            : _lockTarget.value,
                        onVisibilityChanged: _harmonyUI?.setGateVisible,
                        child: navigator!,
                      ),
                    ),
                  ),
                );
                if (kIsWeb) {
                  BrowserDocumentService.updateLanguage(
                      Localizations.localeOf(context).toLanguageTag());
                  return content;
                }
                final isAndroid =
                    defaultTargetPlatform == TargetPlatform.android &&
                    _harmonyUI == null;
                final l10n = AppLocalizations.of(context);
                return PlatformMenuBar(
                  menus: [
                    PlatformMenu(
                      label: 'KenPanel',
                      menus: [
                        PlatformMenuItem(
                          label: l10n.aboutPageTitle,
                          onSelected: () {
                            _navigator.currentState?.push(
                              AppRouter.generateEmbeddedRoute(
                                const RouteSettings(
                                  name: AppRoutes.settingsAbout,
                                ),
                              ),
                            );
                          },
                        ),
                        if (Platform.isMacOS)
                          PlatformMenuItem(
                            label: '${l10n.settingsPageTitle}…',
                            shortcut: const SingleActivator(
                              LogicalKeyboardKey.comma,
                              meta: true,
                            ),
                            onSelectedIntent: const OpenSettingsIntent(),
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
                  child: isAndroid
                      ? AnnotatedRegion<SystemUiOverlayStyle>(
                          value: SystemUiOverlayStyle(
                            systemNavigationBarColor: Colors.transparent,
                            systemNavigationBarDividerColor: Colors.transparent,
                            systemNavigationBarIconBrightness:
                                Theme.brightnessOf(context) == Brightness.dark
                                    ? Brightness.light
                                    : Brightness.dark,
                          ),
                          child: content,
                        )
                      : content,
                );
              },
              theme: AppTheme.getLightTheme(
                visualDensity: density,
                dynamicScheme: lightScheme,
                seedColor: themeController.seedColor,
              ),
              darkTheme: AppTheme.getDarkTheme(
                visualDensity: density,
                dynamicScheme: darkScheme,
                seedColor: themeController.seedColor,
              ),
              themeMode: themeController.themeMode,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              onGenerateRoute: AppRouter.generateRoute,
              onGenerateInitialRoutes: widget.initialSettings == null
                  ? null
                  : (_) => [
                        MaterialPageRoute<void>(
                          settings: RouteSettings(name: widget.initialSettings),
                          builder: (_) => SplashPage(
                            settingsDestination: widget.initialSettings,
                          ),
                        ),
                      ],
              initialRoute: AppRoutes.splash,
            );
          },
        );
      },
    );
  }
}
