import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanel_client/features/shell/widgets/shell_drawer_scope.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';

class ServerAwarePageScaffold extends StatelessWidget {
  const ServerAwarePageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.requireServer = true,
    this.actions = const [],
    this.floatingActionButton,
    this.bottom,
    this.bottomNavigationBar,
    this.onServerChanged,
  });

  final String title;
  final Widget body;
  final bool requireServer;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final Widget? bottomNavigationBar;
  final Future<void> Function()? onServerChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentServerController>(
      builder: (context, currentServer, _) {
        final scheme = Theme.of(context).colorScheme;
        final showMissingServer = requireServer && !currentServer.hasServer;
        final canPop = Navigator.of(context).canPop();
        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            leading: canPop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                  )
                : buildShellDrawerLeading(
                    context,
                    key: const Key('shell-drawer-menu-button'),
                  ),
            title: Text(title),
            actions: [
              if (!showMissingServer) ...actions,
              if (requireServer)
                ServerSwitcherAction(onChanged: onServerChanged),
            ],
            bottom: bottom,
          ),
          body: showMissingServer
              ? ColoredBox(
                  color: scheme.surface,
                  child: NoServerSelectedState(moduleName: title),
                )
              : ColoredBox(
                  color: scheme.surface,
                  child: body,
                ),
          floatingActionButton: showMissingServer ? null : floatingActionButton,
          bottomNavigationBar: showMissingServer ? null : bottomNavigationBar,
        );
      },
    );
  }
}
