import 'package:flutter/material.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:provider/provider.dart';

class ToolboxServerScope<T extends ChangeNotifier> extends StatelessWidget {
  const ToolboxServerScope({
    super.key,
    required this.title,
    required this.create,
    required this.child,
  });

  final String title;
  final T Function(String serverId) create;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final server = context.watch<CurrentServerController>().currentServer;
    if (server == null) {
      return ServerAwarePageScaffold(
        title: title,
        body: const SizedBox.shrink(),
      );
    }
    return ChangeNotifierProvider<T>(
      key: ValueKey((server.id, server.revision)),
      create: (_) => create(server.id),
      child: child,
    );
  }
}
