import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/features/shell/app_shell_page.dart';

import '../desktop/common/app/desktop_shell_page.dart';
import '../desktop/macos/app/macos_shell_content_page.dart';
import '../desktop/windows/app/windows_shell_content_page.dart';
import 'ui_target.dart';

/// Route host that resolves the current UI target (platform + form factor)
/// and builds the correct page implementation for a semantic route name.
///
/// Important: this widget runs inside a [BuildContext], so it may safely use
/// [MediaQuery] to resolve form factor (unlike `onGenerateRoute`).
class UiRouteHost extends StatelessWidget {
  const UiRouteHost({
    super.key,
    required this.settings,
    this.debugTargetOverride,
  });

  final RouteSettings settings;
  final UiTarget? debugTargetOverride;

  @override
  Widget build(BuildContext context) {
    final routeName = settings.name;

    // Start with a minimal mapping: shell routes only.
    if (routeName == '/home') {
      return AdaptiveLayoutViewport(child: Builder(builder: _buildHome));
    }

    return _UiNotFoundPage(routeName: routeName);
  }

  Widget _buildHome(BuildContext context) {
    final target = debugTargetOverride ?? AdaptiveLayoutSpec.of(context).target;
    final initialIndex = _readInitialIndex(settings.arguments);
    final initialModuleId = _readInitialModuleId(settings.arguments);
    final initialEmbeddedRouteName =
        _readInitialEmbeddedRouteName(settings.arguments);
    final initialEmbeddedRouteArguments =
        _readInitialEmbeddedRouteArguments(settings.arguments);

    if (target.usesDesktopShell) {
      if (target.platformKind == UiPlatformKind.desktopMacos) {
        return MacosShellContentPage(
          initialIndex: initialIndex,
          initialModuleId: initialModuleId,
          initialEmbeddedRouteName: initialEmbeddedRouteName,
          initialEmbeddedRouteArguments: initialEmbeddedRouteArguments,
        );
      } else if (target.platformKind == UiPlatformKind.desktopWindows) {
        return WindowsShellContentPage(
          initialIndex: initialIndex,
          initialModuleId: initialModuleId,
          initialEmbeddedRouteName: initialEmbeddedRouteName,
          initialEmbeddedRouteArguments: initialEmbeddedRouteArguments,
        );
      }
      return DesktopShellPage(
        useWebNavigation: target.platformKind == UiPlatformKind.web,
        initialIndex: initialIndex,
        initialModuleId: initialModuleId,
        initialEmbeddedRouteName: initialEmbeddedRouteName,
        initialEmbeddedRouteArguments: initialEmbeddedRouteArguments,
      );
    }

    return AppShellPage(
      initialIndex: initialIndex,
      initialModuleId: initialModuleId,
      tabletKind: target.tabletKind,
    );
  }

  int _readInitialIndex(Object? arguments) {
    if (arguments is int) {
      return arguments;
    }
    if (arguments is Map<String, dynamic>) {
      return (arguments['tab'] as int?) ?? 0;
    }
    return 0;
  }

  String? _readInitialModuleId(Object? arguments) {
    if (arguments is String) {
      return arguments;
    }
    if (arguments is Map<String, dynamic>) {
      return arguments['module'] as String?;
    }
    return null;
  }

  String? _readInitialEmbeddedRouteName(Object? arguments) {
    if (arguments is Map<String, dynamic>) {
      return arguments['route'] as String?;
    }
    return null;
  }

  Object? _readInitialEmbeddedRouteArguments(Object? arguments) {
    if (arguments is Map<String, dynamic>) {
      return arguments['routeArgs'];
    }
    return null;
  }
}

class _UiNotFoundPage extends StatelessWidget {
  const _UiNotFoundPage({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${l10n.notFoundDesc}\n$routeName',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
