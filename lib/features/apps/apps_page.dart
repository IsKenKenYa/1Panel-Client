import 'package:flutter/material.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'widgets/app_store_view.dart';
import 'widgets/installed_apps_view.dart';

class AppsPage extends StatelessWidget {
  final int initialTabIndex;

  const AppsPage({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appsPageTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.appStoreInstalled),
              Tab(text: l10n.appStoreTitle),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            InstalledAppsView(),
            AppStoreView(),
          ],
        ),
      ),
    );
  }
}
