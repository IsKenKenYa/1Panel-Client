import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/server/pages/server_list_page_desktop.dart';
import 'package:onepanel_client/features/server/pages/server_list_page_mobile.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';

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
  String? _activeServerId;
  int _serverCount = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = ServerListViewModel(
      enableCoach: widget.enableCoach,
      serverProvider: context.read<ServerProvider>(),
    );
    _viewModel.init(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentServerController =
        Provider.of<CurrentServerController>(context);
    final nextServerId = currentServerController.currentServerId;
    final nextServerCount = currentServerController.servers.length;

    final serverChanged = _activeServerId != nextServerId;
    final serverListChanged = _serverCount != nextServerCount;

    _activeServerId = nextServerId;
    _serverCount = nextServerCount;

    if (!serverChanged && !serverListChanged) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel.refresh();
    });
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
      child: PlatformUtils.isDesktop(context)
          ? const ServerListPageDesktop()
          : const ServerListPageMobile(),
    );
  }
}
