import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/features/settings/panel_ssl/providers/panel_ssl_provider.dart';

class PanelSslPage extends StatelessWidget {
  const PanelSslPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PanelSslProvider()..loadSslInfo(),
      child: const _PanelSslBody(),
    );
  }
}

class _PanelSslBody extends StatelessWidget {
  const _PanelSslBody();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sslProvider = context.watch<PanelSslProvider>();

    if (sslProvider.isLoading && !sslProvider.hasData) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sslSettingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (sslProvider.error != null && !sslProvider.hasData) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sslSettingsTitle)),
        body: _ErrorView(
          message: sslProvider.error!,
          onRetry: sslProvider.loadSslInfo,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sslSettingsTitle),
        actions: [
          IconButton(
            onPressed: sslProvider.loadSslInfo,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.commonRefresh,
          ),
        ],
      ),
      body: ListView(
        padding: AppDesignTokens.pagePadding,
        children: [
          if (sslProvider.isLoading) const LinearProgressIndicator(),
          if (sslProvider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppDesignTokens.spacingSm),
              child: Text(
                sslProvider.error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          _buildSectionTitle(context, l10n.sslSettingsInfo, theme),
          Card(
            child: Column(
              children: [
                _buildInfoListTile(
                  title: l10n.sslSettingsDomain,
                  value: sslProvider.domain,
                  icon: Icons.domain_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.sslSettingsStatus,
                  value: sslProvider.status,
                  icon: Icons.verified_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.sslSettingsType,
                  value: sslProvider.sslType,
                  icon: Icons.category_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.sslSettingsProvider,
                  value: sslProvider.provider,
                  icon: Icons.business_outlined,
                ),
                _buildInfoListTile(
                  title: l10n.sslSettingsExpiration,
                  value: sslProvider.expiration,
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          _buildSectionTitle(context, l10n.sslSettingsActions, theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_outlined),
                  title: Text(l10n.sslSettingsUpload),
                  subtitle: Text(l10n.sslSettingsUploadDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showUploadDialog(context, sslProvider),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: Text(l10n.sslSettingsDownload),
                  subtitle: Text(l10n.sslSettingsDownloadDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _downloadSsl(context, sslProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoListTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(value),
    );
  }

  void _showUploadDialog(BuildContext context, PanelSslProvider sslProvider) {
    final l10n = context.l10n;
    final domainController = TextEditingController();
    final certController = TextEditingController();
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sslSettingsUpload),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: domainController,
                decoration: InputDecoration(labelText: l10n.sslSettingsDomain),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: certController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.sslSettingsCert,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.sslSettingsKey,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await sslProvider.uploadSsl(
                domain: domainController.text.trim(),
                sslType: 'selfSigned',
                cert: certController.text,
                key: keyController.text,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(success ? l10n.commonSaveSuccess : l10n.commonSaveFailed)),
              );
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadSsl(BuildContext context, PanelSslProvider sslProvider) async {
    final l10n = context.l10n;
    final success = await sslProvider.downloadSsl();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? l10n.sslSettingsDownloadSuccess : l10n.commonSaveFailed)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
