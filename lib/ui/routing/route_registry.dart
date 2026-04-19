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
    this.platformOverrides = const <UiPlatformKind, UiRouteBuilder>{},
  });

  final UiRouteBuilder defaultBuilder;
  final Map<UiPlatformKind, UiRouteBuilder> platformOverrides;

  UiRouteBuilder resolve(UiTarget target) {
    return platformOverrides[target.platformKind] ?? defaultBuilder;
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
}

