import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(l10n.appName,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(l10n.navServer),
            onTap: () {
              Navigator.pop(context);
              openRouteRespectingShell(context, AppRoutes.server);
            },
          ),
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: Text(l10n.containerManagement),
            onTap: () {
              Navigator.pop(context);
              openRouteRespectingShell(context, AppRoutes.containers);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.navSettings),
            onTap: () {
              Navigator.pop(context);
              openRouteRespectingShell(context, AppRoutes.settings);
            },
          ),
        ],
      ),
    );
  }
}
