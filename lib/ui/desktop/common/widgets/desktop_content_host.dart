import 'package:flutter/material.dart';
import 'package:onepanel_client/features/shell/module_page_factory.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';

class DesktopContentHost extends StatelessWidget {
  const DesktopContentHost({
    super.key,
    required this.module,
    required this.serverId,
  });

  final ClientModule module;
  final String? serverId;

  @override
  Widget build(BuildContext context) {
    return buildShellModulePage(
      context,
      module: module,
      serverId: serverId,
    );
  }
}

