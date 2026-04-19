import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import '../../../data/models/app_models.dart';
import '../providers/installed_apps_provider.dart';
import 'installed_app_card.dart';

class InstalledAppsView extends StatefulWidget {
  const InstalledAppsView({super.key});

  @override
  State<InstalledAppsView> createState() => _InstalledAppsViewState();
}

class _InstalledAppsViewState extends State<InstalledAppsView> {
  @override
  void initState() {
    super.initState();
    // 初始加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<InstalledAppsProvider>().loadInstalledApps();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<InstalledAppsProvider>().loadInstalledApps();
  }

  Future<void> _showUninstallDialog(AppInstallInfo app) async {
    final l10n = context.l10n;
    final provider = context.read<InstalledAppsProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    Map<String, dynamic> checkResult = const {};
    try {
      checkResult = await provider.checkUninstall(app.id.toString());
    } catch (_) {
      checkResult = const {};
    }

    final String checkText = checkResult.isEmpty
        ? ''
        : '\n\n${const JsonEncoder.withIndent('  ').convert(checkResult)}';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.appActionUninstall),
          content: SingleChildScrollView(
            child: SelectableText('${l10n.appUninstallConfirm}$checkText'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await provider.uninstallApp(app.id.toString());
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text(l10n.appOperateSuccess)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                          content: Text(l10n.appOperateFailed(e.toString()))),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(l10n.appActionUninstall),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleOperate(String id, String operation) async {
    final l10n = context.l10n;
    try {
      await context.read<InstalledAppsProvider>().operateApp(id, operation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appOperateSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appOperateFailed(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InstalledAppsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.installedApps.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.installedApps.isEmpty) {
          final colorScheme = Theme.of(context).colorScheme;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                    '${context.l10n.commonLoadFailedTitle}: ${provider.error}'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _handleRefresh,
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          );
        }

        if (provider.installedApps.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.installedApps.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final app = provider.installedApps[index];
              return InstalledAppCard(
                app: app,
                onStart: () => _handleOperate(app.id.toString(), 'start'),
                onStop: () => _handleOperate(app.id.toString(), 'stop'),
                onRestart: () => _handleOperate(app.id.toString(), 'restart'),
                onUninstall: () => _showUninstallDialog(app),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.commonEmpty,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appStoreTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () =>
                openRouteRespectingShell(context, AppRoutes.appStore),
            icon: const Icon(Icons.add),
            label: Text(l10n.appStoreInstall),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.commonRefresh),
          ),
        ],
      ),
    );
  }
}
