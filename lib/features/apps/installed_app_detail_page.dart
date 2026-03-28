import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/app_config_models.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/apps/dialogs/edit_app_config_dialog.dart';
import 'package:onepanel_client/features/apps/providers/installed_app_detail_provider.dart';
import 'package:onepanel_client/features/apps/providers/installed_apps_provider.dart';
import 'package:onepanel_client/features/apps/widgets/app_icon.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class InstalledAppDetailPage extends StatelessWidget {
  final AppInstallInfo? appInfo;
  final String? appId;

  const InstalledAppDetailPage({
    super.key,
    this.appInfo,
    this.appId,
  }) : assert(appInfo != null || appId != null);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InstalledAppDetailProvider(
        appService: context.read<AppService>(),
      )..initialize(appInfo: appInfo, appId: appId),
      child: const _InstalledAppDetailView(),
    );
  }
}

class _InstalledAppDetailView extends StatefulWidget {
  const _InstalledAppDetailView();

  @override
  State<_InstalledAppDetailView> createState() =>
      _InstalledAppDetailViewState();
}

class _InstalledAppDetailViewState extends State<_InstalledAppDetailView> {
  Future<void> _refresh() {
    return context.read<InstalledAppDetailProvider>().refresh();
  }

  Future<void> _handleUpgrade() async {
    final l10n = context.l10n;
    final detailProvider = context.read<InstalledAppDetailProvider>();
    final installedProvider = context.read<InstalledAppsProvider>();
    final app = detailProvider.appInfo;
    if (app?.id == null) return;

    final targetVersion = detailProvider.updateVersions.isNotEmpty
        ? detailProvider.updateVersions.first.version
        : 'latest';

    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.appUpdateTitle),
        content: Text(l10n.appUpdateConfirm(app?.name ?? '', targetVersion)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'ignore'),
            child: Text(l10n.appIgnoreUpdate),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'upgrade'),
            child: Text(l10n.appUpdate),
          ),
        ],
      ),
    );

    if (action == 'ignore') {
      await _handleIgnoreUpdate();
      return;
    }
    if (action != 'upgrade') return;

    try {
      await installedProvider.updateApp(app!.id.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appUpdateSuccess)),
        );
      }
      await detailProvider.refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appUpdateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _handleIgnoreUpdate() async {
    final l10n = context.l10n;
    final detailProvider = context.read<InstalledAppDetailProvider>();
    final installedProvider = context.read<InstalledAppsProvider>();
    final app = detailProvider.appInfo;
    if (app?.id == null) return;

    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.appIgnoreUpdate),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.appIgnoreUpdateReason,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await installedProvider.ignoreUpdate(app!.id!, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appIgnoreUpdateSuccess)),
        );
      }
      await detailProvider.refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appIgnoreUpdateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _handleEditConfig(
      AppConfig config, AppInstallInfo appInfo) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => EditAppConfigDialog(
        appInstallId: appInfo.id!,
        appConfig: config,
        appKey: appInfo.appKey ?? '',
        appName: appInfo.name ?? appInfo.appName ?? '',
        httpPort: appInfo.httpPort,
        httpsPort: appInfo.httpsPort,
      ),
    );

    if (changed == true) {
      await _refresh();
    }
  }

  Future<void> _showConnectionInfo() async {
    final l10n = context.l10n;
    try {
      final info =
          await context.read<InstalledAppDetailProvider>().getConnectionInfo();
      if (!mounted) return;
      final jsonText = const JsonEncoder.withIndent('  ').convert(info);
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.appConnInfo),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: SelectableText(jsonText)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonClose),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.appConnInfoFailed}: $e')),
        );
      }
    }
  }

  Future<void> _openWeb(String urlString) async {
    final l10n = context.l10n;
    final url = Uri.tryParse(urlString);
    if (url == null) return;

    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.appOperateFailed(l10n.commonUnknownError))),
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

  Future<void> _openContainer() async {
    final l10n = context.l10n;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final container = await context
          .read<InstalledAppDetailProvider>()
          .findInstalledContainer();
      if (!mounted) return;
      Navigator.pop(context);
      if (container == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notFoundDesc)),
        );
        return;
      }

      Navigator.pushNamed(
        context,
        AppRoutes.containerDetail,
        arguments: container,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.commonLoadFailedTitle}: $e')),
      );
    }
  }

  Future<void> _handleOperate(String operation) async {
    final l10n = context.l10n;
    final detailProvider = context.read<InstalledAppDetailProvider>();
    final installedProvider = context.read<InstalledAppsProvider>();
    final app = detailProvider.appInfo;
    if (app?.id == null) return;

    try {
      await installedProvider.operateApp(app!.id.toString(), operation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appOperateSuccess)),
        );
      }
      await detailProvider.syncInstallInfo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.appOperateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _handleUninstall() async {
    final l10n = context.l10n;
    final detailProvider = context.read<InstalledAppDetailProvider>();
    final installedProvider = context.read<InstalledAppsProvider>();
    final app = detailProvider.appInfo;
    if (app?.id == null) return;

    Map<String, dynamic> uninstallCheck = const {};
    try {
      uninstallCheck =
          await installedProvider.checkUninstall(app!.id.toString());
    } catch (_) {
      uninstallCheck = const {};
    }

    final String checkText = uninstallCheck.isEmpty
        ? ''
        : '\n\n${const JsonEncoder.withIndent('  ').convert(uninstallCheck)}';

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.appActionUninstall),
        content: SingleChildScrollView(
          child: SelectableText('${l10n.appUninstallConfirm}$checkText'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await installedProvider.uninstallApp(app!.id.toString());
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.appOperateSuccess)),
      );
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
    final l10n = context.l10n;

    return Consumer<InstalledAppDetailProvider>(
      builder: (context, provider, _) {
        final appInfo = provider.appInfo;
        final config = provider.appConfig;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.appDetailTitle),
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.appTabInfo),
                  Tab(text: l10n.appTabConfig),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.commonRefresh,
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _InfoTab(
                  appInfo: appInfo,
                  loading: provider.loading,
                  error: provider.error,
                  storeDetail: provider.storeDetail,
                  storeDetailError: provider.storeDetailError,
                  services: provider.services,
                  servicesError: provider.servicesError,
                  updateVersions: provider.updateVersions,
                  onShowConnInfo: _showConnectionInfo,
                  onUpgrade: _handleUpgrade,
                ),
                _ConfigTab(
                  appInfo: appInfo,
                  appConfig: config,
                  loading: provider.loading,
                  error: provider.error,
                  configError: provider.configError,
                  onEdit: (cfg, info) => _handleEditConfig(cfg, info),
                ),
              ],
            ),
            bottomNavigationBar: _BottomBar(
              appInfo: appInfo,
              loading: provider.loading,
              onOpenWeb: _openWeb,
              onOpenContainer: _openContainer,
              onStart: () => _handleOperate('start'),
              onStop: () => _handleOperate('stop'),
              onRestart: () => _handleOperate('restart'),
              onUninstall: _handleUninstall,
            ),
          ),
        );
      },
    );
  }
}

class _InfoTab extends StatelessWidget {
  final AppInstallInfo? appInfo;
  final bool loading;
  final String? error;
  final AppItem? storeDetail;
  final String? storeDetailError;
  final List<AppServiceResponse> services;
  final String? servicesError;
  final List<AppVersion> updateVersions;
  final VoidCallback onShowConnInfo;
  final VoidCallback onUpgrade;

  const _InfoTab({
    required this.appInfo,
    required this.loading,
    required this.error,
    required this.storeDetail,
    required this.storeDetailError,
    required this.services,
    required this.servicesError,
    required this.updateVersions,
    required this.onShowConnInfo,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (loading && appInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && appInfo == null) {
      return Center(child: Text('${l10n.commonLoadFailedTitle}: $error'));
    }
    if (appInfo == null) {
      return Center(child: Text(l10n.commonEmpty));
    }

    final isRunning = appInfo!.status?.toLowerCase() == 'running';
    final statusText =
        isRunning ? l10n.appStatusRunning : l10n.appStatusStopped;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(appKey: appInfo!.appKey, appId: appInfo!.appId, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appInfo!.appName ?? appInfo!.name ?? '-',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(statusText),
                  ],
                ),
              ),
              if (updateVersions.isNotEmpty)
                FilledButton.icon(
                  onPressed: onUpgrade,
                  icon: const Icon(Icons.upgrade, size: 16),
                  label: Text(l10n.appUpdate),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onShowConnInfo,
            icon: const Icon(Icons.link),
            label: Text(l10n.appConnInfo),
          ),
          if (storeDetailError != null) ...[
            const SizedBox(height: 16),
            Text('${l10n.commonLoadFailedTitle}: $storeDetailError'),
          ],
          if (storeDetail?.readMe != null &&
              storeDetail!.readMe!.isNotEmpty) ...[
            const SizedBox(height: 16),
            MarkdownBody(data: storeDetail!.readMe!),
          ],
          if (servicesError != null) ...[
            const SizedBox(height: 16),
            Text('${l10n.commonLoadFailedTitle}: $servicesError'),
          ],
          if (services.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...services.map(
                (s) => ListTile(title: Text(s.label), subtitle: Text(s.value))),
          ],
        ],
      ),
    );
  }
}

class _ConfigTab extends StatelessWidget {
  final AppInstallInfo? appInfo;
  final AppConfig? appConfig;
  final bool loading;
  final String? error;
  final String? configError;
  final Future<void> Function(AppConfig config, AppInstallInfo appInfo) onEdit;

  const _ConfigTab({
    required this.appInfo,
    required this.appConfig,
    required this.loading,
    required this.error,
    required this.configError,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (loading && appConfig == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && appConfig == null) {
      return Center(child: Text('${l10n.commonLoadFailedTitle}: $error'));
    }
    if (configError != null && appConfig == null) {
      return Center(child: Text('${l10n.commonLoadFailedTitle}: $configError'));
    }
    if (appInfo == null || appConfig == null) {
      return Center(child: Text(l10n.commonEmpty));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.appTabConfig,
                  style: Theme.of(context).textTheme.titleLarge),
              FilledButton.icon(
                onPressed: () => onEdit(appConfig!, appInfo!),
                icon: const Icon(Icons.edit),
                label: Text(l10n.commonEdit),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
              '${l10n.commonPort}: ${appInfo!.httpPort ?? '-'} / ${appInfo!.httpsPort ?? '-'}'),
          const SizedBox(height: 8),
          Text('${l10n.appInstallContainerName}: ${appConfig!.containerName}'),
          const SizedBox(height: 8),
          Text('${l10n.env}: ${appInfo!.env?.length ?? 0}'),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final AppInstallInfo? appInfo;
  final bool loading;
  final Future<void> Function(String url) onOpenWeb;
  final Future<void> Function() onOpenContainer;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onUninstall;

  const _BottomBar({
    required this.appInfo,
    required this.loading,
    required this.onOpenWeb,
    required this.onOpenContainer,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (loading || appInfo == null) {
      return const SizedBox.shrink();
    }

    final isRunning = appInfo!.status?.toLowerCase() == 'running';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (appInfo!.webUI != null && appInfo!.webUI!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onOpenWeb(appInfo!.webUI!),
                      icon: const Icon(Icons.web),
                      label: Text(l10n.appActionWeb),
                    ),
                  ),
                if (appInfo!.container != null &&
                    appInfo!.container!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenContainer,
                      icon: const Icon(Icons.layers),
                      label: Text(l10n.viewContainer),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isRunning
                      ? OutlinedButton.icon(
                          onPressed: onStop,
                          icon: const Icon(Icons.stop),
                          label: Text(l10n.appActionStop),
                        )
                      : FilledButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.appActionStart),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.appActionRestart),
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: l10n.appActionUninstall,
                  child: IconButton.filledTonal(
                    onPressed: onUninstall,
                    icon: const Icon(Icons.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
