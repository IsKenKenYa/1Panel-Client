import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/apps/providers/app_store_provider.dart';
import 'package:onepanel_client/features/apps/widgets/app_store_view.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';

import '../../core/utils/snackbar_utils.dart';

class AppStorePage extends StatelessWidget {
  const AppStorePage({super.key, this.provider});

  final AppStoreProvider? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => provider ?? AppStoreProvider(),
      child: Builder(
        builder: (innerContext) {
          final l10n = innerContext.l10n;
          return Scaffold(
            backgroundColor: Theme.of(innerContext).colorScheme.surface,
            appBar: AppBar(
              title: Text(l10n.appStoreTitle),
              actions: [
                PopupMenuButton<String>(
                  tooltip: l10n.commonMore,
                  onSelected: (value) {
                    if (value == 'syncLocal') {
                      _syncLocalApps(innerContext);
                    } else if (value == 'ignored') {
                      _showIgnoredAppsDialog(innerContext);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'syncLocal',
                      child: Text(l10n.appStoreSyncLocal),
                    ),
                    PopupMenuItem(
                      value: 'ignored',
                      child: Text(l10n.appIgnoredUpdatesTitle),
                    ),
                  ],
                ),
              ],
            ),
            body: const AppStoreView(),
          );
        },
      ),
    );
  }

  Future<void> _syncLocalApps(BuildContext context) async {
    final l10n = context.l10n;
    final provider = context.read<AppStoreProvider>();
    try {
      await provider.syncLocalApps();
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.appStoreSyncLocalSuccess);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, '${l10n.appStoreSyncLocalFailed}: $e');
      }
    }
  }

  Future<void> _showIgnoredAppsDialog(BuildContext context) async {
    final l10n = context.l10n;
    final provider = context.read<AppStoreProvider>();
    List<AppInstallInfo> ignoredApps = [];

    try {
      ignoredApps = await provider.loadIgnoredUpdates();
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          '${l10n.appIgnoredUpdatesLoadFailed}: $e',
        );
      }
      return;
    }

    if (!context.mounted) return;

    await showAppFormSheet<void>(
      context,
      title: l10n.appIgnoredUpdatesTitle,
      builder: (_) => StatefulBuilder(
        builder: (sheetContext, setState) => ignoredApps.isEmpty
            ? Center(
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.appIgnoredUpdatesEmpty),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemBuilder: (context, index) {
                  final app = ignoredApps[index];
                  return ListTile(
                    title: Text(app.name ?? '-'),
                    subtitle: Text(app.version ?? '-'),
                    trailing: TextButton(
                      onPressed: () async {
                        if (app.id == null) return;
                        await provider.cancelIgnoreUpdate(app.id!);
                        if (!sheetContext.mounted) return;
                        setState(() => ignoredApps.remove(app));
                      },
                      child: Text(l10n.appIgnoreUpdateCancel),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
                itemCount: ignoredApps.length,
              ),
      ),
    );
  }
}
