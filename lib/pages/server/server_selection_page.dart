import 'package:flutter/material.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';

class ServerSelectionPage extends StatelessWidget {
  const ServerSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServerListPage(enableCoach: false);
  }
}
