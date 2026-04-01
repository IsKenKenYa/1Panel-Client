import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/server/pages/server_list_page_desktop.dart';
import 'package:onepanel_client/features/server/pages/server_list_page_mobile.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';

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
    _viewModel = ServerListViewModel(context, enableCoach: widget.enableCoach);
    _viewModel.init();
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
