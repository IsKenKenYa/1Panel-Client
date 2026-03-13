import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../../core/i18n/l10n_x.dart';
import '../../../data/models/app_models.dart';
import 'app_service.dart';
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
      final version = _app.versions?.first ?? 'latest';
      final type = _app.type ?? 'unknown';
      
      final detail = await appService.getAppDetail(
        _app.id.toString(),
        version,
        type,
      );

      if (mounted) {
        setState(() {
          _app = detail;
          _readme = detail.readMe;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showInstallDialog() {
    showDialog(
      context: context,
      builder: (context) => AppInstallDialog(app: _app),
    );
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
          child: FilledButton(
            onPressed: _showInstallDialog,
            child: Text(l10n.appStoreInstall),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Even if error occurs, we show what we have, plus an error banner
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
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
          _buildHeader(context, theme),
          const SizedBox(height: 24),
          Text(
            l10n.appDescription,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (_readme != null && _readme!.isNotEmpty)
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
        AppIcon(app: _app, size: 80),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
