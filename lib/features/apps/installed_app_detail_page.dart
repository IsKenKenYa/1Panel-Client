import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/config/app_router.dart';
import 'package:onepanelapp_app/core/i18n/l10n_x.dart';
import 'package:onepanelapp_app/data/models/app_config_models.dart';
import 'package:onepanelapp_app/data/models/app_models.dart';
import 'package:onepanelapp_app/features/apps/app_service.dart';
import 'package:onepanelapp_app/features/apps/dialogs/edit_app_config_dialog.dart';
import 'package:onepanelapp_app/features/apps/providers/installed_apps_provider.dart';
import 'package:onepanelapp_app/features/apps/widgets/app_icon.dart';
import 'package:onepanelapp_app/features/containers/container_service.dart';
import 'package:url_launcher/url_launcher.dart';

class InstalledAppDetailPage extends StatefulWidget {
  final AppInstallInfo? appInfo;
  final String? appId;

  const InstalledAppDetailPage({
    super.key,
    this.appInfo,
    this.appId,
  }) : assert(appInfo != null || appId != null,
            'Either appInfo or appId must be provided');

  @override
  State<InstalledAppDetailPage> createState() => _InstalledAppDetailPageState();
}

class _InstalledAppDetailPageState extends State<InstalledAppDetailPage> {
  final AppService _appService = AppService();
  final ContainerService _containerService = ContainerService();

  AppInstallInfo? _appInfo;
  AppItem? _storeDetail;
  List<AppServiceResponse>? _services;
  AppConfig? _appConfig;
  List<AppVersion>? _updateVersions;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.appInfo != null) {
      _appInfo = widget.appInfo;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Ensure we have AppInstallInfo
      if (_appInfo == null && widget.appId != null) {
        _appInfo = await _appService.getAppInstallInfo(widget.appId!);
      }

      if (_appInfo == null) {
        throw Exception('Failed to load app info');
      }

      // 2. Fetch Store Detail (for README)
      // Use appKey (or key) and version. If version is missing, use 'latest'.
      // Also need 'type' which might be in appType.
      final appKey = _appInfo!.appKey;
      final version = _appInfo!.version ?? 'latest';
      // Default to 'app' type if unknown, but usually it's passed or can be inferred?
      // AppInstallInfo has appType.
      final type = _appInfo!.appType ?? 'app';

      if (appKey != null) {
        try {
          // getAppDetail requires appId (string), version, type.
          // Wait, getAppDetail first argument is 'appId'. Is it the store ID or the key?
          // Looking at AppService.getAppDetail signature: (String appId, String version, String type).
          // In AppDetailPage it uses app.id.toString().
          // AppInstallInfo has appId (int).
          if (_appInfo!.appId != null) {
             _storeDetail = await _appService.getAppDetail(
              _appInfo!.appId!.toString(),
              version,
              type,
            );
          }
        } catch (e) {
          debugPrint('Failed to load store detail: $e');
        }
      }

      // 3. Fetch Services
      List<AppServiceResponse> services = [];
      if (appKey != null) {
        try {
          services = await _appService.getAppServices(appKey);
        } catch (e) {
          debugPrint('Failed to load services: $e');
        }
      }

      // 4. Fetch Config
      AppConfig? config;
      if (_appInfo!.id != null) {
        try {
          config = await _appService.getAppInstallParams(_appInfo!.id.toString());
        } catch (e) {
          debugPrint('Failed to load config: $e');
        }
      }

      // 5. Check Updates
      List<AppVersion>? updateVersions;
      if (_appInfo!.canUpdate == true && _appInfo!.id != null) {
        try {
          updateVersions = await _appService.getAppUpdateVersions(_appInfo!.id.toString());
        } catch (e) {
          debugPrint('Failed to load update versions: $e');
        }
      }

      if (mounted) {
        setState(() {
          _services = services;
          _appConfig = config;
          _updateVersions = updateVersions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleUpgrade() async {
    if (_appInfo?.id == null) return;
    
    final l10n = context.l10n;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final provider = context.read<InstalledAppsProvider>();

    // If multiple versions, we could show a selection dialog.
    // For now, assume update to latest or the one provided by API implicitly.
    final targetVersion = _updateVersions?.isNotEmpty == true 
        ? _updateVersions!.first.version 
        : 'latest';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.appUpdateTitle),
        content: Text(l10n.appUpdateConfirm(_appInfo!.name ?? '', targetVersion)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.appUpdate),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await provider.updateApp(_appInfo!.id.toString());
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.appUpdateSuccess)),
        );
        // Refresh
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.appUpdateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _handleEditConfig() async {
    if (_appConfig == null || _appInfo?.id == null) return;

    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => EditAppConfigDialog(
        appInstallId: _appInfo!.id!,
        appConfig: _appConfig!,
        httpPort: _appInfo!.httpPort,
        httpsPort: _appInfo!.httpsPort,
      ),
    );

    if (changed == true) {
      _loadData();
    }
  }

  Future<void> _handleAction(String operation) async {
    if (_appInfo == null || _appInfo!.id == null) return;

    final l10n = context.l10n;
    final provider = context.read<InstalledAppsProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      if (operation == 'uninstall') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.appActionUninstall),
            content: Text(l10n.appUninstallConfirm),
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

        await provider.uninstallApp(_appInfo!.id.toString());
        if (mounted) {
          navigator.pop(); // Close detail page
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.appOperateSuccess)),
          );
        }
      } else {
        await provider.operateApp(_appInfo!.id.toString(), operation);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.appOperateSuccess)),
        );
        // Refresh data (status might change)
        // We can just re-fetch app info
        if (_appInfo?.id != null) {
           final newInfo = await _appService.getAppInstallInfo(_appInfo!.id.toString());
           if(mounted) {
             setState(() {
               _appInfo = newInfo;
             });
           }
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.appOperateFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _openWeb() async {
    if (_appInfo?.webUI == null) return;
    // webUI might be just "http://IP:PORT" or just port?
    // Usually it's a full URL or we need to construct it.
    // Assuming it's a full URL or at least has http prefix.
    // If not, we might need to prepend http://<server_ip>
    // But for now let's assume it's usable.
    
    // Note: The backend usually returns a partial URL or template.
    // But let's try to launch it.
    
    final urlString = _appInfo!.webUI!;
    final Uri? url = Uri.tryParse(urlString);
    
    if (url != null) {
       try {
         if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
            throw 'Could not launch $url';
         }
       } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to open web: $e')),
           );
         }
       }
    }
  }

  Future<void> _openContainer() async {
    if (_appInfo?.container == null) return;
    
    final l10n = context.l10n;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final containers = await _containerService.listContainers();
      // Filter by name. _appInfo.container is the name.
      final containerName = _appInfo!.container!;
      
      try {
        final container = containers.firstWhere((c) => c.name == containerName || c.name == '/$containerName'); // Sometimes names have leading slash
        
        if (mounted) {
          Navigator.pop(context); // Close loading
          Navigator.pushNamed(
            context,
            AppRoutes.containerDetail,
            arguments: container,
          );
        }
      } catch (e) {
         if (mounted) {
          Navigator.pop(context); // Close loading
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(l10n.notFoundDesc)), // Or "Container not found"
          );
        }
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('${l10n.commonLoadFailedTitle}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.appDetailTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.appTabInfo), // "概览"
              Tab(text: l10n.appTabConfig), // "配置"
            ],
          ),
          actions: [
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildBody(l10n),
            _buildConfigTab(l10n),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(l10n),
      ),
    );
  }

  Widget _buildConfigTab(AppLocalizations l10n) {
    if (_loading && _appConfig == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _appConfig == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.commonLoadFailedTitle),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadData,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_appConfig == null) {
      return Center(child: Text(l10n.commonEmpty));
    }

    final envs = _appInfo?.env;
    final compose = _appConfig!.dockerCompose;
    final containerName = _appConfig!.containerName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.appTabConfig, style: Theme.of(context).textTheme.titleLarge),
              FilledButton.icon(
                onPressed: _handleEditConfig,
                icon: const Icon(Icons.edit),
                label: Text(l10n.commonEdit),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(l10n.commonPort),
          if (_appInfo?.httpPort != null || _appInfo?.httpsPort != null)
            Card(
              child: ListTile(
                title: Text(
                  [
                    if (_appInfo?.httpPort != null) '${_appInfo!.httpPort} (HTTP)',
                    if (_appInfo?.httpsPort != null) '${_appInfo!.httpsPort} (HTTPS)',
                  ].join(', '),
                ),
                leading: const Icon(Icons.router),
              ),
            )
          else
             const Text('No port info'),
          
          const SizedBox(height: 16),
          if (containerName.isNotEmpty) ...[
            _buildSectionTitle('Container Name'),
            Card(
              child: ListTile(
                title: Text(containerName, style: const TextStyle(fontFamily: 'monospace')),
                leading: const Icon(Icons.layers),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          _buildSectionTitle('Environment'),
          if (envs != null && envs.isNotEmpty)
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: envs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final key = envs.keys.elementAt(index);
                  final value = envs[key];
                  return ListTile(
                    title: Text(key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(value?.toString() ?? '', style: const TextStyle(fontFamily: 'monospace')),
                  );
                },
              ),
            )
          else
            Text(l10n.commonEmpty),

          const SizedBox(height: 16),
          _buildSectionTitle('Compose'),
          if (compose.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  compose,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            )
          else
            Text(l10n.commonEmpty),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading && _appInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _appInfo == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.commonLoadFailedTitle),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadData,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_appInfo == null) {
      return Center(child: Text(l10n.commonEmpty));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n),
          const SizedBox(height: 24),
          _buildBasicInfo(l10n),
          const SizedBox(height: 24),
          if (_storeDetail?.readMe != null && _storeDetail!.readMe!.isNotEmpty) ...[
             Text(
              'README', 
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                 padding: const EdgeInsets.all(16),
                 child: MarkdownBody(
                   data: _storeDetail!.readMe!,
                   imageBuilder: (uri, title, alt) {
                     if (uri.scheme == 'http' || uri.scheme == 'https') {
                       return Image.network(uri.toString());
                     }
                     return Tooltip(
                       message: 'Image not supported: $uri',
                       child: const Icon(Icons.broken_image, size: 16, color: Colors.grey),
                     );
                   },
                 ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _buildServicesList(l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final status = _appInfo!.status?.toLowerCase() ?? '';
    Color statusColor;
    String statusText;

    if (status == 'running') {
      statusColor = Colors.green;
      statusText = l10n.appStatusRunning;
    } else if (status == 'stopped') {
      statusColor = Colors.orange;
      statusText = l10n.appStatusStopped;
    } else {
      statusColor = Colors.grey;
      statusText = status;
    }

    return Row(
      children: [
        AppIcon(
          appKey: _appInfo!.appKey,
          appId: _appInfo!.appId,
          size: 64,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _appInfo!.appName ?? _appInfo!.name ?? '-',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (_appInfo!.name != null && _appInfo!.name != _appInfo!.appName)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _appInfo!.name!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              if (_updateVersions != null && _updateVersions!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.icon(
                    onPressed: _handleUpgrade,
                    icon: const Icon(Icons.upgrade, size: 16),
                    label: Text(l10n.appUpdate),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appBaseInfo,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(l10n.appInfoVersion, _appInfo!.version ?? '-'),
                const Divider(),
                _buildInfoRow(l10n.appInfoCreated, _appInfo!.createdAt ?? '-'),
                if (_appInfo!.description != null) ...[
                  const Divider(),
                  _buildInfoRow('Description', _appInfo!.description!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList(AppLocalizations l10n) {
    if (_services == null || _services!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appServiceList,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final service = _services![index];
              return ListTile(
                title: Text(service.label),
                subtitle: Text(service.value),
                trailing: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: service.status == 'running' ? Colors.green : Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    if (_loading || _appInfo == null) return const SizedBox.shrink();

    final status = _appInfo!.status?.toLowerCase();
    final isRunning = status == 'running';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                 if (_appInfo!.webUI != null && _appInfo!.webUI!.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton.icon(
                        onPressed: _openWeb,
                        icon: const Icon(Icons.web),
                        label: const Text('Web'),
                      ),
                    ),
                  ),
                  
                if (_appInfo!.container != null && _appInfo!.container!.isNotEmpty)
                  Expanded(
                    child: Padding(
                       padding: const EdgeInsets.only(left: 8),
                       child: OutlinedButton.icon(
                        onPressed: _openContainer,
                        icon: const Icon(Icons.layers),
                        label: const Text('Container'),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isRunning
                      ? OutlinedButton.icon(
                          onPressed: () => _handleAction('stop'),
                          icon: const Icon(Icons.stop),
                          label: Text(l10n.appActionStop),
                        )
                      : FilledButton.icon(
                          onPressed: () => _handleAction('start'),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.appActionStart),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleAction('restart'),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.appActionRestart),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  onPressed: () => _handleAction('uninstall'),
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.appActionUninstall,
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
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
