import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';
import 'package:onepanel_client/features/server/widgets/server_list_view.dart';
import 'package:onepanel_client/shared/widgets/operations/page_visibility_listener.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({
    super.key,
    this.enableCoach = true,
  });

  final bool enableCoach;

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  late final ServerListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ServerListViewModel(
      enableCoach: widget.enableCoach,
      serverProvider: context.read<ServerProvider>(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: PageVisibilityListener(
        onChanged: (visible) => _viewModel.setVisible(context, visible),
        child: const AdaptiveLayoutViewport(child: ServerListView()),
      ),
    );
  }
}
