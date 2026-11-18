import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/desktop_routed_module_host.dart';
import 'package:onepanel_client/ui/desktop/common/widgets/shell_content_host.dart';

/// Container widget for the desktop/tablet shell's right content area.
///
/// Routes the inner module presentation to [ShellContentHost] so the
/// shared inner `Navigator` is reused by every desktop/tablet shell
/// page. The legacy [DesktopRoutedModuleHost] path is still available
/// for callers that pass an explicit `embeddedRoute` (e.g. the
/// Windows/MacOS "embedded route" breadcrumb that hosts a single
/// detail page instead of a full module tree).
///
/// When the surrounding shell switches between modules (e.g. user
/// clicks a different item in the sidebar), the parent is expected to
/// keep this widget alive for each previously-visited module — either
/// by [IndexedStack] with a per-module [KeyedSubtree] key, or by
/// handing the same `key` through from the parent's state. That way
/// each module's inner stack survives the switch.
class DesktopContentHost extends StatefulWidget {
  const DesktopContentHost({
    super.key,
    required this.module,
    required this.serverId,
    this.embeddedRoute,
    this.embeddedRouteArguments,
  });

  final ClientModule module;
  final String? serverId;
  final String? embeddedRoute;
  final Object? embeddedRouteArguments;

  @override
  State<DesktopContentHost> createState() => DesktopContentHostState();
}

class DesktopContentHostState extends State<DesktopContentHost> {
  final _visitedModules = <ClientModule, GlobalKey<ShellContentHostState>>{};

  void openModuleRoot(ClientModule module) {
    _visitedModules[module]
        ?.currentState
        ?.innerNavigator
        ?.popUntil((route) => route.isFirst);
  }

  @override
  void didUpdateWidget(DesktopContentHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverId != widget.serverId) {
      _visitedModules.updateAll((module, key) =>
          module.requiresServer ? GlobalKey<ShellContentHostState>() : key);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedRoute != null) {
      return KeyedSubtree(
        key: ValueKey('desktop-embedded-route:${widget.embeddedRoute}'),
        child: DesktopRoutedModuleHost(
          routeName: widget.embeddedRoute!,
          routeArguments: widget.embeddedRouteArguments,
        ),
      );
    }

    if (widget.module.requiresServer && widget.serverId == null) {
      return NoServerSelectedState(
          moduleName: widget.module.label(context.l10n));
    }

    _visitedModules.putIfAbsent(
        widget.module, GlobalKey<ShellContentHostState>.new);
    final modules = _visitedModules.keys.toList(growable: false);

    return IndexedStack(
      index: modules.indexOf(widget.module),
      children: [
        for (final module in modules)
          HeroMode(
            enabled: module == widget.module,
            child: ExcludeFocus(
              excluding: module != widget.module,
              child: ShellContentHost(
                key: _visitedModules[module],
                module: module,
                serverId: widget.serverId,
                active: module == widget.module,
              ),
            ),
          ),
      ],
    );
  }
}
