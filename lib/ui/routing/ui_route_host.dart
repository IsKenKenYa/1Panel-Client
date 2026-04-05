import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';

import '../desktop/common/app/desktop_shell_page.dart';
import '../desktop/macos/app/macos_shell_content_page.dart';
import '../desktop/windows/app/windows_shell_content_page.dart';
import '../mobile/app/mobile_shell_page.dart';
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
  });

  final RouteSettings settings;

  @override
  Widget build(BuildContext context) {
    final routeName = settings.name;

    // Start with a minimal mapping: shell routes only.
    if (routeName == '/home') {
      return _buildHome(context);
    }

    return _UiNotFoundPage(routeName: routeName);
  }

  Widget _buildHome(BuildContext context) {
    final initialIndex = _readInitialIndex(settings.arguments);
    final initialModuleId = _readInitialModuleId(settings.arguments);

    if (PlatformUtils.isDesktop(context)) {
      if (PlatformUtils.isMacOS) {
        return MacosShellContentPage(
          initialIndex: initialIndex,
          initialModuleId: initialModuleId,
        );
      } else if (PlatformUtils.isWindows) {
        return WindowsShellContentPage(
          initialIndex: initialIndex,
          initialModuleId: initialModuleId,
        );
      }
      return DesktopShellPage(
        initialIndex: initialIndex,
        initialModuleId: initialModuleId,
      );
    } else {
      final tabletKind = PlatformUtils.isTablet(context)
          ? (PlatformUtils.isIOS ? TabletKind.ipad : TabletKind.androidPad)
          : TabletKind.none;
      return MobileShellPage(
        initialIndex: initialIndex,
        initialModuleId: initialModuleId,
        tabletKind: tabletKind,
      );
    }
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
}

class _UiNotFoundPage extends StatelessWidget {
  const _UiNotFoundPage({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
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
