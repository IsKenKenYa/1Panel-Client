import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/module_page_factory.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';

class DesktopContentHost extends StatefulWidget {
  const DesktopContentHost({
    super.key,
    required this.module,
    required this.serverId,
  });

  final ClientModule module;
  final String? serverId;

  @override
  State<DesktopContentHost> createState() => _DesktopContentHostState();
}

class _DesktopContentHostState extends State<DesktopContentHost> {
  final Map<ClientModule, Widget> _moduleCache = <ClientModule, Widget>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureModuleInCache(widget.module);
  }

  @override
  void didUpdateWidget(covariant DesktopContentHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.module != widget.module || oldWidget.serverId != widget.serverId) {
      _ensureModuleInCache(widget.module);
    }
  }

  void _ensureModuleInCache(ClientModule module) {
    if (_moduleCache.containsKey(module)) {
      return;
    }
    if (module.requiresServer && widget.serverId == null) {
      return;
    }
    _moduleCache[module] = buildShellModulePage(
      context,
      module: module,
      serverId: widget.serverId,
      useStableModuleKey: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.module.requiresServer && widget.serverId == null) {
      return NoServerSelectedState(moduleName: widget.module.label(context.l10n));
    }

    _ensureModuleInCache(widget.module);
    final modules = _moduleCache.keys.toList(growable: false);
    final selectedIndex = modules.indexOf(widget.module);

    return IndexedStack(
      index: selectedIndex < 0 ? 0 : selectedIndex,
      children: [
        for (final module in modules)
          KeyedSubtree(
            key: ValueKey('desktop-module:${module.storageId}'),
            child: _moduleCache[module]!,
          ),
      ],
    );
  }
}
