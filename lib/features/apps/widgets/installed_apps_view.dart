import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import '../../../data/models/app_models.dart';
import '../providers/installed_apps_provider.dart';
import 'installed_app_card.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';

import '../../../core/utils/snackbar_utils.dart';
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
                    SnackBarUtils.showSuccess(context, l10n.appOperateSuccess);
                  }
                } catch (e) {
                  if (mounted) {
                    SnackBarUtils.showError(context, l10n.appOperateFailed(e.toString()),
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
        SnackBarUtils.showSuccess(context, l10n.appOperateSuccess);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, l10n.appOperateFailed(e.toString()),
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
          return ModuleErrorStateWidget(
            message: provider.error,
            onRetry: _handleRefresh,
          );
        }

        if (provider.installedApps.isEmpty) {
          return _buildEmptyState();
        }

        return PartialErrorToastListener(
          errorMessage: provider.error,
          hasCachedData: provider.installedApps.isNotEmpty,
          onRetry: _handleRefresh,
          child: RefreshIndicator(
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
        ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = context.l10n;
    return ModuleEmptyStateWidget(
      title: l10n.commonEmpty,
      description: l10n.appsInstalledEmptyDescription,
      icon: Icons.apps_outlined,
      actionLabel: l10n.appStoreInstall,
      onAction: () => openRouteRespectingShell(context, AppRoutes.appStore),
      actions: [
        TextButton.icon(
          onPressed: _handleRefresh,
          icon: const Icon(Icons.refresh_outlined),
          label: Text(l10n.commonRefresh),
        ),
      ],
    );
  }
}
