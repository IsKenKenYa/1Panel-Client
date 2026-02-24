import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
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
      context.read<InstalledAppsProvider>().loadInstalledApps();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<InstalledAppsProvider>().loadInstalledApps();
  }

  void _showUninstallDialog(AppInstallInfo app) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('卸载应用'),
          content: Text('确定要卸载 ${app.appName} 吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await context
                      .read<InstalledAppsProvider>()
                      .uninstallApp(app.id.toString());
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('卸载成功')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('卸载失败: $e')),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('卸载'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleOperate(String id, String operation) async {
    String opName;
    switch (operation) {
      case 'start':
        opName = '启动';
        break;
      case 'stop':
        opName = '停止';
        break;
      case 'restart':
        opName = '重启';
        break;
      default:
        opName = '操作';
    }

    final messenger = ScaffoldMessenger.of(context);
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('正在$opName...'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    try {
      await context.read<InstalledAppsProvider>().operateApp(id, operation);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$opName成功')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$opName失败: $e')),
      );
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('${context.l10n.commonLoadFailedTitle}: ${provider.error}'),
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
            '暂无已安装应用',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '前往应用商店安装应用',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/app-store');
            },
            icon: const Icon(Icons.add),
            label: const Text('安装应用'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.commonRefresh),
          ),
        ],
      ),
    );
  }
}
