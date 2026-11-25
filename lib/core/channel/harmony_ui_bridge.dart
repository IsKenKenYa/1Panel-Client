import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_route_constants.dart';
import '../../features/security/app_lock_gate.dart';
import '../../features/shell/models/client_module.dart';
import '../../features/shell/module_registry.dart';
import '../theme/ui_render_mode.dart';

/// HarmonyOS 原生页面与既有 Flutter 导航、应用锁之间的表示层通道。
class HarmonyUIBridge extends NavigatorObserver
    with ChangeNotifier, WidgetsBindingObserver {
  HarmonyUIBridge({
    required GlobalKey<NavigatorState> navigatorKey,
    required Future<void> Function() refreshSettings,
  })  : _navigatorKey = navigatorKey,
        _refreshSettings = refreshSettings {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _channel.setMethodCallHandler(_handleMethodCall);
    WidgetsBinding.instance.addObserver(this);
  }

  static const _channel = MethodChannel('com.onepanel.client/harmony_ui');
  final GlobalKey<NavigatorState> _navigatorKey;
  final Future<void> Function() _refreshSettings;

  Route<dynamic>? _topRoute;
  UIRenderMode? _mode;
  String _locale = 'system';
  ThemeMode _themeMode = ThemeMode.system;
  String _activeModule = ClientModule.servers.storageId;
  bool _gateVisible = false;
  bool _resumed = true;
  bool _disposed = false;
  bool _notificationScheduled = false;
  int _refresh = 0;
  (bool, String, ThemeMode, int)? _lastPresentation;

  bool get isAtNativeRoot {
    final route = _topRoute;
    return route != null &&
        route.isFirst &&
        const {AppRoutes.home, AppRoutes.server, AppRoutes.serverConfig}
            .contains(route.settings.name);
  }

  bool get nativeRootEnabled =>
      _mode == UIRenderMode.native && isAtNativeRoot;

  String get activeModule => _activeModule;

  void updatePresentation({
    required UIRenderMode mode,
    required Locale? locale,
    required ThemeMode themeMode,
  }) {
    final language = locale?.toLanguageTag() ?? 'system';
    if (_mode == mode && _locale == language && _themeMode == themeMode) return;
    if (_mode != mode) _gateVisible = false;
    _mode = mode;
    _locale = language;
    _themeMode = themeMode;
    _refresh++;
    _synchronizePresentation();
  }

  void setGateVisible(bool visible) {
    if (_gateVisible == visible) return;
    _gateVisible = visible;
    _synchronizePresentation();
  }

  void openFlutterRoute(String route, {Map<String, dynamic>? arguments}) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) throw StateError('App navigator is unavailable');
    _gateVisible = false;
    _synchronizePresentation();

    final module = switch (route) {
      AppRoutes.files => ClientModule.files,
      AppRoutes.containers => ClientModule.containers,
      _ => null,
    };
    if (module == null) {
      unawaited(navigator.pushNamed<void>(route, arguments: arguments));
      return;
    }
    unawaited(navigator.push<void>(MaterialPageRoute<void>(
      settings: RouteSettings(name: route, arguments: arguments),
      builder: (context) => AppLockGate(
        target: module.storageId,
        child: ModuleRegistry.registrationFor(module)!.builder(context),
      ),
    )));
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    _topRoute = topRoute;
    _gateVisible = false;
    _synchronizePresentation();
    _scheduleNotification();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _gateVisible = false;
    _synchronizePresentation();
    _scheduleNotification();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'openRoute':
        if (!nativeRootEnabled || !_gateVisible || !_resumed) {
          throw StateError('Native presentation is unavailable');
        }
        final payload = Map<String, dynamic>.from(call.arguments as Map);
        final route = payload['route'] as String;
        final arguments = payload['arguments'] == null
            ? null
            : Map<String, dynamic>.from(payload['arguments'] as Map);
        openFlutterRoute(route, arguments: arguments);
        return null;
      case 'refreshSettings':
        await _refreshSettings();
        if (!_disposed) {
          _refresh++;
          _synchronizePresentation();
        }
        return null;
      case 'setActiveModule':
        final payload = Map<String, dynamic>.from(call.arguments as Map);
        final module = clientModuleFromId(payload['module'] as String?);
        if (!const {
          ClientModule.servers,
          ClientModule.files,
          ClientModule.containers,
          ClientModule.settings,
        }.contains(module)) {
          throw ArgumentError.value(payload['module'], 'module');
        }
        if (_activeModule == module!.storageId) return null;
        _activeModule = module.storageId;
        _gateVisible = false;
        _synchronizePresentation();
        _scheduleNotification();
        return null;
      default:
        throw MissingPluginException('Unknown Harmony UI method: ${call.method}');
    }
  }

  void _scheduleNotification() {
    if (_disposed || _notificationScheduled) return;
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (!_disposed) notifyListeners();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  void _synchronizePresentation() {
    if (_disposed || _mode == null) return;
    final visible = nativeRootEnabled && _gateVisible && _resumed;
    final presentation = (visible, _locale, _themeMode, _refresh);
    if (_lastPresentation == presentation) return;
    _lastPresentation = presentation;
    unawaited(_channel.invokeMethod<void>('setPresentation', {
      'visible': visible,
      'locale': _locale,
      'themeMode': _themeMode.name,
      'refresh': _refresh,
    }));
  }

  @override
  void dispose() {
    _gateVisible = false;
    _synchronizePresentation();
    _disposed = true;
    _channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
