import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/module_page_factory.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/server_route_observer.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_routed_module_host.dart';

/// Container widget for the desktop/tablet shell's right content area.
///
/// Hosts a permanently-mounted inner `Navigator` so that:
/// - Opening a sub-page (e.g. `Settings → Language`) only animates the
///   content area; the surrounding `NavigationRail` / `AppBar` stay
///   stable.
/// - The system back gesture first pops the inner stack before falling
///   through to the outer shell.
///
/// This widget is shared by `MacosShellContentPage`,
/// `WindowsShellContentPage`, `DesktopShellPage` (and the tablet shell
/// when present) so all desktop/tablet form factors use a single
/// `ShellContentHost` tree.
///
/// When the same parent switches between modules (e.g. user clicks a
/// different item in the sidebar), the parent is expected to keep this
/// widget alive for each previously-visited module — either by
/// `IndexedStack` with a per-module `KeyedSubtree` key, or by handing
/// the same `key` through from the parent's state. That way each
/// module's inner stack survives the switch.
class ShellContentHost extends StatefulWidget {
  const ShellContentHost({
    super.key,
    required this.module,
    required this.serverId,
    this.serverRevision,
    this.active = true,
    this.embeddedRoute,
    this.embeddedRouteArguments,
  });

  final ClientModule module;
  final String? serverId;
  final String? serverRevision;
  final bool active;
  final String? embeddedRoute;
  final Object? embeddedRouteArguments;

  @override
  State<ShellContentHost> createState() => ShellContentHostState();
}

/// Public State for [ShellContentHost] so that navigation helpers can
/// locate the inner `Navigator` of the *current* module (whichever
/// `ShellContentHost` wraps the caller's `BuildContext`) without
/// relying on a globally-shared `GlobalKey`.
class ShellContentHostState extends State<ShellContentHost> {
  final _routes = ServerRouteObserver();
  final GlobalKey<NavigatorState> _innerNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'ShellContentHostNavigator');

  /// The inner `Navigator`'s state, or `null` if the host has not
  /// finished its first frame yet.
  NavigatorState? get innerNavigator => _innerNavigatorKey.currentState;

  @override
  void didUpdateWidget(ShellContentHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb &&
        widget.module == ClientModule.settings &&
        oldWidget.active != widget.active) {
      final name = widget.active
          ? _routes.currentRouteName ?? AppRoutes.settings
          : AppRoutes.home;
      SystemNavigator.routeInformationUpdated(uri: Uri.parse(name));
    }
  }

  @override
  void dispose() {
    _routes.detachParent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _routes.setParent(context, active: widget.active);
    _routes.updateConnection(widget.serverId, widget.serverRevision);
    final route = widget.embeddedRoute;
    if (route != null && !AppRoutes.localSettings.contains(route)) {
      return DesktopRoutedModuleHost(
        routeName: route,
        routeArguments: widget.embeddedRouteArguments,
      );
    }

    if (widget.module.requiresServer && widget.serverId == null) {
      return NoServerSelectedState(
        moduleName: widget.module.label(context.l10n),
      );
    }

    return NavigatorPopHandler<Object?>(
      enabled: widget.active,
      onPopWithResult: (result) {
        if (widget.active) innerNavigator?.maybePop(result);
      },
      child: _buildInnerNavigator(),
    );
  }

  Widget _buildInnerNavigator() {
    if (widget.module == ClientModule.settings) {
      final destination = widget.embeddedRoute;
      return Navigator(
        key: _innerNavigatorKey,
        observers: [_routes],
        reportsRouteUpdateToEngine: kIsWeb && widget.active,
        onGenerateRoute: AppRouter.generateEmbeddedRoute,
        onGenerateInitialRoutes: (_, __) => [
          AppRouter.generateEmbeddedRoute(
            const RouteSettings(name: AppRoutes.settings),
          ),
          if (destination == AppRoutes.settingsMainlandSdkDisclosure)
            AppRouter.generateEmbeddedRoute(
              const RouteSettings(name: AppRoutes.settingsLegalCenter),
            ),
          if (destination != null && destination != AppRoutes.settings)
            AppRouter.generateEmbeddedRoute(RouteSettings(name: destination)),
        ],
      );
    }
    return KeyedSubtree(
      key: ValueKey('shell-content-host:${widget.module.storageId}'),
      child: Navigator(
        key: _innerNavigatorKey,
        observers: [_routes],
        onGenerateRoute: AppRouter.generateEmbeddedRoute,
        pages: <Page<dynamic>>[
          MaterialPage<void>(
            key: ValueKey('shell-content-host-init:${widget.module.storageId}'),
            child: _buildModuleRoot(),
          ),
        ],
        onDidRemovePage: _onInnerPageRemoved,
      ),
    );
  }

  Widget _buildModuleRoot() {
    return KeyedSubtree(
      key: ValueKey('shell-content-host-module:${widget.module.storageId}'),
      child: buildShellModulePage(
        context,
        module: widget.module,
        serverId: widget.serverId,
        useStableModuleKey: true,
      ),
    );
  }

  void _onInnerPageRemoved(Page<dynamic> page) {
    // Reserved hook. The shell does not currently expose inner-stack
    // snapshots; per-module stack persistence is achieved by the
    // parent keeping this widget alive across module switches.
  }
}
