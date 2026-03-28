import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart'
    as backup;
import 'package:onepanel_client/data/models/database_models.dart';
import 'package:onepanel_client/features/databases/database_support.dart';
import 'package:onepanel_client/features/databases/providers/database_backup_provider.dart';
import 'package:onepanel_client/features/databases/services/database_backup_service.dart';
import 'package:onepanel_client/features/databases/widgets/database_backup_record_card_widget.dart';
import 'package:onepanel_client/features/databases/widgets/database_page_feedback_widget.dart';
import 'package:onepanel_client/features/databases/widgets/database_summary_card_widget.dart';

class DatabaseBackupPage extends StatelessWidget {
  const DatabaseBackupPage({
    super.key,
    required this.item,
    this.service,
  });

  final DatabaseListItem item;
  final DatabaseBackupService? service;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseBackupProvider(
        item: item,
        service: service,
      )..load(),
      child: _DatabaseBackupPageView(item: item),
    );
  }
}

class _DatabaseBackupPageView extends StatelessWidget {
  const _DatabaseBackupPageView({required this.item});

  final DatabaseListItem item;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DatabaseBackupProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.databaseBackupsPageTitle)),
      body: !databaseSupportsBackups(item.scope)
          ? DatabasePageUnsupportedWidget(
              message: l10n.databaseBackupUnsupported,
            )
          : provider.state.isLoading && provider.state.items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : provider.state.error != null && provider.state.items.isEmpty
                  ? DatabasePageErrorWidget(
                      error: provider.state.error!,
                      onRetry: provider.refresh,
                    )
                  : RefreshIndicator(
                      onRefresh: provider.refresh,
                      child: ListView(
                        padding: AppDesignTokens.pagePadding,
                        children: [
                          DatabaseSummaryCardWidget(item: item),
                          const SizedBox(height: AppDesignTokens.spacingMd),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: provider.state.isSubmitting
                                  ? null
                                  : () => _showCreateBackupDialog(
                                        context,
                                        provider,
                                      ),
                              icon: const Icon(Icons.backup_outlined),
                              label: Text(l10n.databaseBackupCreateAction),
                            ),
                          ),
                          if (provider.state.error != null) ...[
                            const SizedBox(height: AppDesignTokens.spacingMd),
                            DatabasePageErrorWidget(
                              error: provider.state.error!,
                              onRetry: provider.refresh,
                            ),
                          ],
                          if (provider.state.items.isEmpty) ...[
                            const SizedBox(height: AppDesignTokens.spacingXl),
                            DatabasePageEmptyWidget(
                              message: l10n.databaseBackupEmpty,
                            ),
                          ] else ...[
                            const SizedBox(height: AppDesignTokens.spacingMd),
                            for (final record in provider.state.items) ...[
                              DatabaseBackupRecordCardWidget(
                                record: record,
                                onRestore: () => _showRestoreDialog(
                                  context,
                                  provider,
                                  record,
                                ),
                                onDelete: () => _confirmDelete(
                                  context,
                                  provider,
                                  record,
                                ),
                              ),
                              const SizedBox(height: AppDesignTokens.spacingSm),
                            ],
                          ],
                        ],
                      ),
                    ),
    );
  }

  Future<void> _showCreateBackupDialog(
    BuildContext context,
    DatabaseBackupProvider provider,
  ) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.databaseBackupCreateAction),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: context.l10n.databaseBackupSecretLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await provider.createBackup(secret: controller.text);
              if (ok && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _showRestoreDialog(
    BuildContext context,
    DatabaseBackupProvider provider,
    backup.BackupRecord record,
  ) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.databaseBackupRestoreAction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.databaseBackupRestoreConfirmMessage),
            const SizedBox(height: AppDesignTokens.spacingMd),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.l10n.databaseBackupSecretLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await provider.restoreBackup(
                record,
                secret: controller.text,
              );
              if (ok && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DatabaseBackupProvider provider,
    backup.BackupRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.databaseBackupDeleteAction),
        content: Text(context.l10n.databaseBackupDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteBackupRecord(record);
    }
  }
}
