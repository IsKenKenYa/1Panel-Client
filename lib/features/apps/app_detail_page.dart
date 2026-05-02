import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../../core/i18n/l10n_x.dart';
import '../../../data/models/app_models.dart';
import 'app_service.dart';
import 'providers/app_store_provider.dart';
import 'widgets/app_install_dialog.dart';
import 'widgets/app_icon.dart';

class AppDetailPage extends StatefulWidget {
  final AppItem app;

  const AppDetailPage({super.key, required this.app});

  @override
  State<AppDetailPage> createState() => _AppDetailPageState();
}

class _AppDetailPageState extends State<AppDetailPage> {
  late AppItem _app;
  bool _isLoading = true;
  String? _error;
  String? _readme;

  @override
  void initState() {
    super.initState();
    _app = widget.app;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final appService = context.read<AppService>();
      
      // First, try to get app by key to fetch README content
      // This is more reliable than getAppDetail for display purposes
      try {
        final appByKey = await appService.getAppByKey(_app.key ?? '');
        if (mounted) {
          setState(() {
            _app = appByKey;
            _readme = appByKey.readMe;
          });
        }
      } catch (e) {
        // If getAppByKey fails, use the existing app data
        _readme = _app.readMe;
      }

      // Then try to get detailed info (may fail for some apps due to server-side issues)
      try {
        final version = _app.versions?.first ?? 'latest';
        final type = _app.type ?? 'unknown';

        final detail = await appService.getAppDetail(
          _app.id.toString(),
          version,
          type,
        );

        if (mounted) {
          setState(() {
            // Merge detail info but keep the README from getAppByKey
            _app = AppItem(
              description: detail.description ?? _app.description,
              github: detail.github ?? _app.github,
              gpuSupport: detail.gpuSupport ?? _app.gpuSupport,
              icon: detail.icon ?? _app.icon,
              id: detail.id ?? _app.id,
              installed: detail.installed ?? _app.installed,
              key: detail.key ?? _app.key,
              limit: detail.limit ?? _app.limit,
              name: detail.name ?? _app.name,
              readMe: _readme, // Keep README from getAppByKey
              recommend: detail.recommend ?? _app.recommend,
              resource: detail.resource ?? _app.resource,
              status: detail.status ?? _app.status,
              tags: detail.tags ?? _app.tags,
              type: detail.type ?? _app.type,
              versions: detail.versions ?? _app.versions,
              website: detail.website ?? _app.website,
            );
          });
        }
      } catch (e) {
        // getAppDetail failed, but we already have README from getAppByKey
        // Just log the error and continue with what we have
        if (mounted) {
          setState(() {
            _error = _formatError(e);
          });
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _formatError(e);
          _isLoading = false;
        });
      }
    }
  }

  /// 格式化错误信息,使其更友好
  String _formatError(Object error) {
    final errorStr = error.toString();
    
    // 处理 docker-compose.yml 获取失败的错误
    if (errorStr.contains('docker-compose.yml') && 
        errorStr.contains('unsupported protocol scheme')) {
      return '部分应用配置信息暂时无法获取，但不影响查看应用介绍。这是服务端数据问题，请联系管理员检查应用商店配置。';
    }
    
    // 处理其他常见错误
    if (errorStr.contains('DioException')) {
      // 提取 message 部分
      final messageMatch = RegExp(r'message:\s*(.+?)(?:,|$)').firstMatch(errorStr);
      if (messageMatch != null) {
        return messageMatch.group(1)?.trim() ?? errorStr;
      }
    }
    
    return errorStr;
  }

  Future<void> _showInstallDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AppInstallDialog(app: _app),
    );

    if (result == true && mounted) {
      setState(() {
        _app = AppItem(
          description: _app.description,
          github: _app.github,
          gpuSupport: _app.gpuSupport,
          icon: _app.icon,
          id: _app.id,
          installed: true,
          key: _app.key,
          limit: _app.limit,
          name: _app.name,
          readMe: _app.readMe,
          recommend: _app.recommend,
          resource: _app.resource,
          status: _app.status,
          tags: _app.tags,
          type: _app.type,
          versions: _app.versions,
          website: _app.website,
        );
      });
      // Refresh app store list in background
      context.read<AppStoreProvider>().loadApps(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_app.name ?? l10n.appStoreTitle),
      ),
      body: _buildBody(context, theme),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _app.installed == true
              ? FilledButton.tonal(
                  onPressed: null,
                  child: Text(l10n.appStoreInstalled),
                )
              : FilledButton(
                  onPressed: _showInstallDialog,
                  child: Text(l10n.appStoreInstall),
                ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    final l10n = context.l10n;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show warning banner if getAppDetail failed but we have README
    final hasReadme = _readme != null && _readme!.isNotEmpty;
    final showWarning = _error != null && hasReadme;
    final showError = _error != null && !hasReadme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showError)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style:
                          TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadDetail();
                    },
                  ),
                ],
              ),
            ),
          if (showWarning)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                          color: theme.colorScheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          _buildHeader(context, theme),
          const SizedBox(height: 24),
          Text(
            l10n.appDescription,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (hasReadme)
            MarkdownBody(
              data: _readme!,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: theme.textTheme.bodyMedium,
              ),
            )
          else
            Text(
              _app.description ?? context.l10n.commonEmpty,
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(app: _app, iconUrl: _app.icon, size: 80),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _app.name ?? '',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (_app.versions != null && _app.versions!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _app.versions!.first,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _app.description ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
