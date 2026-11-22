import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart'
    show shellModuleForRoute;
import 'package:provider/provider.dart';

bool routeNeedsServerConnection(String? name) =>
    name != null && !AppRoutes.shared.contains(name);

/// 连接变更时关闭旧连接的详情、表单及其后续页面。
class ServerRouteObserver extends NavigatorObserver {
  ServerRouteObserver({this.isAppNavigator = false, this.lockTarget});

  final bool isAppNavigator;
  final ValueNotifier<String?>? lockTarget;
  static final _moduleRoots =
      Expando<({bool needsServer, ClientModule module})>();
  static final _routeTargets = Expando<String>();
  static final _nestedNavigation = Expando<ServerRouteObserver>();
  final _routes = <Route<dynamic>, bool>{};
  Route<dynamic>? get _current =>
      _routes.keys.where((route) => route.isCurrent).firstOrNull;
  String? get currentRouteName => _current?.settings.name;
  bool _targetUpdateScheduled = false;
  Route<dynamic>? _parent;
  (String?, String?)? _connection;
  // NavigatorObserver.navigator 在 post-frame 回调里可能尚未就绪，
  // 因此在入栈时记录每个路由所属的导航器。
  final _owners = <Route<dynamic>, NavigatorState>{};

  static void setActiveModule(
    BuildContext context, {
    required ClientModule module,
    required bool needsServer,
  }) {
    final route = ModalRoute.of(context);
    final root = (needsServer: needsServer, module: module);
    if (route == null || _moduleRoots[route] == root) return;
    _moduleRoots[route] = root;
    _updateLockTarget(context);
  }

  void setParent(BuildContext context, {required bool active}) {
    final parent = active ? ModalRoute.of(context) : null;
    if (identical(parent, _parent)) return;
    detachParent();
    _parent = parent;
    if (parent != null) _nestedNavigation[parent] = this;
    _updateLockTarget(context);
  }

  void detachParent() {
    final parent = _parent;
    if (parent != null && identical(_nestedNavigation[parent], this)) {
      _nestedNavigation[parent] = null;
    }
    _parent = null;
  }

  void updateConnection(String? id, String? revision) {
    final next = (id, revision);
    final previous = _connection;
    _connection = next;
    if (previous?.$1 == null || previous == next) return;
    final stale = _routes.entries
        .where((entry) => entry.value && _moduleRoots[entry.key] == null)
        .map((entry) => entry.key)
        .toList(growable: false);
    if (stale.isEmpty) return;
    final staleSet = stale.toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final owners = <NavigatorState>{
        ..._owners.values,
        if (navigator != null) navigator!,
      };
      for (final owner in owners) {
        if (!owner.mounted) continue;
        owner.popUntil((route) => !staleSet.contains(route));
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  bool _dependsOnServer(Route<dynamic> route, Route<dynamic>? source) {
    final name = route.settings.name;
    if (name != null) return routeNeedsServerConnection(name);
    if (source == null) return false;
    return _sourceNeedsServer(source);
  }

  bool _sourceNeedsServer(Route<dynamic> source) {
    if (_moduleRoots[source]?.needsServer ?? _routes[source] ?? false) {
      return true;
    }
    final nested = _nestedNavigation[source];
    if (nested == null) return false;
    final top = nested._routes.keys.where((route) => route.isCurrent).firstOrNull;
    return top != null && nested._sourceNeedsServer(top);
  }

  static String? _visibleTarget(Route<dynamic>? route) {
    if (route == null) return null;
    return _visibleTarget(_nestedNavigation[route]?._current) ??
        _moduleRoots[route]?.module.storageId ??
        _routeTargets[route];
  }

  static void _recordTarget(Route<dynamic> route, Route<dynamic>? previous) {
    final name = route.settings.name;
    _routeTargets[route] = name == AppRoutes.settingsAppLock
        ? name
        : name == null
            ? _visibleTarget(previous)
            : shellModuleForRoute(name)?.storageId;
  }

  static void _updateLockTarget(BuildContext? context) {
    if (context == null) return;
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    final root =
        navigator?.widget.observers.whereType<ServerRouteObserver>().firstOrNull;
    if (root == null || root.lockTarget == null || root._targetUpdateScheduled) {
      return;
    }
    root._targetUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      root._targetUpdateScheduled = false;
      if (root.navigator != null) {
        root.lockTarget!.value = _visibleTarget(root._current);
      }
    });
  }

  @override
  void didChangeTop(Route<dynamic> topRoute, Route<dynamic>? previousTopRoute) {
    _updateLockTarget(navigator?.context);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // 首次入栈时观察者可能尚未拿到 navigator，退回用前一条路由的导航器。
    final owner = navigator ?? previousRoute?.navigator;
    if (owner != null) _owners[route] = owner;
    final controller = owner?.context.read<CurrentServerController?>();
    if (controller != null) {
      updateConnection(
        controller.currentServerId,
        controller.currentServer?.revision,
      );
    }
    _routes[route] = _dependsOnServer(route, previousRoute);
    _recordTarget(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      final owner = navigator;
      if (owner != null) _owners[newRoute] = owner;
      _routes[newRoute] = _dependsOnServer(newRoute, oldRoute);
      _recordTarget(newRoute, oldRoute);
    }
    _routes.remove(oldRoute);
    _owners.remove(oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _owners.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _owners.remove(route);
  }
}

/// 桌面深链接只能在打开时使用的服务器连接内继续显示。
class ShellEmbeddedRoute {
  ShellEmbeddedRoute(this.name, this.arguments);

  String? name;
  Object? arguments;
  (String?, String?)? _connection;

  void updateConnection(String? id, String? revision) {
    final next = (id, revision);
    if (_connection?.$1 != null &&
        _connection != next &&
        routeNeedsServerConnection(name)) {
      clear();
    }
    _connection = next;
  }

  void clear() {
    name = null;
    arguments = null;
  }
}
