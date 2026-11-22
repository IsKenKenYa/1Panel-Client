import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/config/app_route_entries.dart';
import 'package:onepanel_client/config/app_router_pages.dart';
import 'package:onepanel_client/features/security/app_lock_gate.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/ui/routing/route_registry.dart';
import 'package:onepanel_client/ui/routing/ui_target_resolver.dart';
import 'package:provider/provider.dart';

export 'package:onepanel_client/config/app_route_constants.dart';
export 'package:onepanel_client/config/app_router_pages.dart';

class AppRouter {
  // Prevents re-registration when generateRoute is called multiple times
  static bool _routeRegistryInitialized = false;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    _ensureRouteRegistryInitialized();
    final registryRoute = _buildRouteFromRegistry(settings);
    if (registryRoute != null) {
      return registryRoute;
    }

    // All routes are now served by the registry. Unknown names get 404.
    return MaterialPageRoute(builder: (_) => const NotFoundPage());
  }

  /// Generates a route that always uses the route entry's `defaultBuilder`,
  /// bypassing any platform-specific override.
  ///
  /// Use this when hosting a route inside a desktop shell via
  /// `DesktopRoutedModuleHost`. The outer `desktopBuilder` has already
  /// wrapped the route in the appropriate shell (`UiRouteHost`); the
  /// inner Navigator should render the actual page, not another shell
  /// (which would cause infinite recursion).
  static Route<dynamic> generateEmbeddedRoute(RouteSettings settings) {
    _ensureRouteRegistryInitialized();
    final registryRoute = _buildRouteFromRegistry(
      settings,
      useDefaultBuilder: true,
    );
    if (registryRoute != null) {
      return registryRoute;
    }
    return MaterialPageRoute(builder: (_) => const NotFoundPage());
  }

  // --- legacy switch block removed; all routes served by registry ---

  static void _ensureRouteRegistryInitialized() {
    if (_routeRegistryInitialized) {
      return;
    }
    RouteRegistry.registerAll(buildRouteRegistryEntries());
    _routeRegistryInitialized = true;
  }

  /// Resets the route registry. Tests use this to discard the default
  /// entries built by [_buildRouteRegistryEntries] and substitute their
  /// own. Production code should never call this.
  @visibleForTesting
  static void resetRouteRegistryForTest() {
    RouteRegistry.clear();
    _routeRegistryInitialized = false;
  }

  /// Registers a single test route. Pairs with
  /// [resetRouteRegistryForTest] so each test gets a minimal registry.
  @visibleForTesting
  static void registerRouteForTest(String name, RouteEntry entry) {
    RouteRegistry.register(name, entry);
  }

  static Route<dynamic>? _buildRouteFromRegistry(
    RouteSettings settings, {
    bool useDefaultBuilder = false,
  }) {
    final entry = RouteRegistry.lookup(settings.name);
    if (entry == null) {
      return null;
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final target = UiTargetResolver.resolve(context);
        if (!AppRoutes.shared.contains(settings.name)) {
          final panelType =
              context.watch<CurrentServerController?>()?.currentServer?.panelType;
          if (!supportsOnePanelModules(panelType)) {
            return const ServerListPage(enableCoach: false);
          }
          if (panelType == null &&
              AppRoutes.panelSettings.contains(settings.name) &&
              (useDefaultBuilder || !target.usesDesktopShell)) {
            final title = context.l10n.systemSettingsPanelSection;
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: NoServerSelectedState(moduleName: title),
            );
          }
        }
        final builder = entry.resolve(target, useDefault: useDefaultBuilder);
        final page = builder(context, settings);
        final module = shellModuleForRoute(settings.name!);
        if (module != null && module.pinnable &&
            (useDefaultBuilder || !target.usesDesktopShell)) {
          return AppLockGate(target: module.storageId, child: page);
        }
        return page;
      },
    );
  }

  // Route table extracted to app_route_entries.dart
  static int readInitialIndex(Object? arguments) {
    if (arguments is int) {
      return arguments;
    }

    if (arguments is Map<String, dynamic>) {
      return (arguments['tab'] as int?) ?? 0;
    }

    return 0;
  }

  static String? readInitialModuleId(Object? arguments) {
    if (arguments is String) {
      return arguments;
    }

    if (arguments is Map<String, dynamic>) {
      return arguments['module'] as String?;
    }

    return null;
  }
}