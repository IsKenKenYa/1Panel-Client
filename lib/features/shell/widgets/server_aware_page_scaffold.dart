import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/features/shell/controllers/current_server_controller.dart';
import 'package:onepanelapp_app/features/shell/widgets/no_server_selected_state.dart';
import 'package:onepanelapp_app/features/shell/widgets/server_switcher_action.dart';

class ServerAwarePageScaffold extends StatelessWidget {
  const ServerAwarePageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.requireServer = true,
    this.actions = const [],
    this.floatingActionButton,
    this.bottom,
    this.onServerChanged,
  });

  final String title;
  final Widget body;
  final bool requireServer;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final Future<void> Function()? onServerChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer<CurrentServerController>(
      builder: (context, currentServer, _) {
        final showMissingServer = requireServer && !currentServer.hasServer;
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              ...actions,
              if (requireServer)
                ServerSwitcherAction(onChanged: onServerChanged),
            ],
            bottom: bottom,
          ),
          body: showMissingServer
              ? NoServerSelectedState(moduleName: title)
              : body,
          floatingActionButton: showMissingServer ? null : floatingActionButton,
        );
      },
    );
  }
}
