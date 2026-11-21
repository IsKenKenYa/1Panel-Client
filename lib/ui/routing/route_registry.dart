import 'package:flutter/material.dart';

import 'ui_target.dart';

typedef UiRouteBuilder = Widget Function(
  BuildContext context,
  RouteSettings settings,
);

@immutable
class RouteEntry {
  const RouteEntry({
    required this.defaultBuilder,
    this.desktopShellBuilder,
    this.platformOverrides = const <UiPlatformKind, UiRouteBuilder>{},
  });

  final UiRouteBuilder defaultBuilder;
  final UiRouteBuilder? desktopShellBuilder;
  final Map<UiPlatformKind, UiRouteBuilder> platformOverrides;

  /// Resolves the builder to use for the given [target].
  ///
  /// When [useDefault] is true, the platform override is bypassed and
  /// the `defaultBuilder` is returned. The shell-aware routing flow
  /// (see `_shellAwareModuleEntry` in `AppRouter`) sets [useDefault] to
  /// true when resolving a route that is already being hosted inside
  /// a desktop shell via `DesktopRoutedModuleHost`. This prevents the
  /// infinite shell-in-shell recursion that would otherwise happen:
  ///
  ///   outer push `route X` → `desktopBuilder` → `UiRouteHost(home)`
  ///   → `MacosShellContentPage` → embedded Navigator
  ///   → inner push `route X` → `desktopBuilder` → `UiRouteHost(home)`
  ///   → `MacosShellContentPage` → ... (stack overflow)
  ///
  /// By forcing the inner resolution to use `defaultBuilder`, the
  /// embedded Navigator renders the actual page (e.g. `FeedbackCenterPage`)
  /// inside the existing shell, no recursion.
  UiRouteBuilder resolve(UiTarget target, {bool useDefault = false}) {
    if (useDefault) {
      return defaultBuilder;
    }
    return platformOverrides[target.platformKind] ??
        (target.usesDesktopShell ? desktopShellBuilder : null) ??
        defaultBuilder;
  }
}

/// Registry from semantic route name to platform-specific builders.
///
/// Keep this UI-only: builders may return UI shells/pages, but must not contain
/// business logic beyond view composition.
class RouteRegistry {
  const RouteRegistry._();

  static RouteEntry? lookup(String? routeName) {
    if (routeName == null) return null;
    return _routes[routeName];
  }

  // AppRouter registers route entries during startup via registerAll.
  // Keep this empty as a neutral default for tests and early bootstrap.
  static final Map<String, RouteEntry> _routes = <String, RouteEntry>{};

  /// Allows app startup to register entries without creating circular imports.
  static void registerAll(Map<String, RouteEntry> routes) {
    _routes.addAll(routes);
  }

  /// Clears the entire registry. [AppRouter.resetRouteRegistryForTest]
  /// exposes this for tests; production code should not call it
  /// directly. The method is intentionally non-`@visibleForTesting`
  /// because it must be reachable from `app_router.dart`.
  static void clear() {
    _routes.clear();
  }

  /// Registers a single [entry] under [name]. Used by
  /// [AppRouter.registerRouteForTest] for test injection; production
  /// code should prefer [registerAll] from the app's route table.
  static void register(String name, RouteEntry entry) {
    _routes[name] = entry;
  }
}

