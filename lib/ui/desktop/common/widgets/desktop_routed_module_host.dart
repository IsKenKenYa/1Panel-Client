import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/server_route_observer.dart';
import 'package:provider/provider.dart';

/// Hosts a route-driven module page inside desktop shell content.
///
/// This keeps desktop navigation inside a single shell while reusing
/// existing route builders and provider wiring from [AppRouter].
class DesktopRoutedModuleHost extends StatefulWidget {
  const DesktopRoutedModuleHost({
    super.key,
    required this.routeName,
    this.routeArguments,
  }) : assert(routeName != AppRoutes.home);

  final String routeName;
  final Object? routeArguments;

  @override
  State<DesktopRoutedModuleHost> createState() => _DesktopRoutedModuleHostState();
}

class _DesktopRoutedModuleHostState extends State<DesktopRoutedModuleHost> {
  final _routes = ServerRouteObserver();

  @override
  void dispose() {
    _routes.detachParent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _routes.setParent(context, active: true);
    final connection = context.select((CurrentServerController? controller) =>
        (controller?.currentServerId, controller?.currentServer?.revision));
    _routes.updateConnection(connection.$1, connection.$2);
    final routeName = widget.routeName;
    return Navigator(
      key: ValueKey('desktop-embedded-route:$routeName'),
      observers: [_routes],
      // Use `generateEmbeddedRoute` (not `generateRoute`) so the inner
      // Navigator resolves the route via its `defaultBuilder` instead
      // of the desktop platform override. The override would push a
      // new `UiRouteHost` wrapping `MacosShellContentPage`, which then
      // renders *another* `DesktopRoutedModuleHost` for the same route
      // — stack overflow at `FocusNode.descendants` after a few
      // hundred frames. The outer `desktopBuilder` already hosted
      // us in the shell; we just need to render the actual page here.
      onGenerateRoute: AppRouter.generateEmbeddedRoute,
      onGenerateInitialRoutes: (_, __) {
        return [
          AppRouter.generateEmbeddedRoute(
            RouteSettings(name: routeName, arguments: widget.routeArguments),
          ),
        ];
      },
    );
  }
}
