import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';

/// Hosts a route-driven module page inside desktop shell content.
///
/// This keeps desktop navigation inside a single shell while reusing
/// existing route builders and provider wiring from [AppRouter].
class DesktopRoutedModuleHost extends StatelessWidget {
  const DesktopRoutedModuleHost({
    super.key,
    required this.routeName,
    this.routeArguments,
  }) : assert(routeName != AppRoutes.home);

  final String routeName;
  final Object? routeArguments;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: AppRouter.generateRoute,
      onGenerateInitialRoutes: (_, __) {
        return [
          AppRouter.generateRoute(
            RouteSettings(name: routeName, arguments: routeArguments),
          ),
        ];
      },
    );
  }
}
