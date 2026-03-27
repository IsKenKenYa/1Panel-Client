import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/backups/models/backup_record_list_item.dart';
import 'package:onepanel_client/features/backups/models/backup_records_args.dart';
import 'package:onepanel_client/features/backups/models/backup_recover_args.dart';
import 'package:onepanel_client/features/backups/providers/backup_records_provider.dart';
import 'package:onepanel_client/features/backups/widgets/backup_record_card_widget.dart';
import 'package:onepanel_client/features/backups/widgets/backup_record_filter_sheet_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class BackupRecordsPage extends StatefulWidget {
  const BackupRecordsPage({
    super.key,
    this.args,
  });

  final BackupRecordsArgs? args;

  @override
  State<BackupRecordsPage> createState() => _BackupRecordsPageState();
}

class _BackupRecordsPageState extends State<BackupRecordsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<BackupRecordsProvider>().initialize(widget.args);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<BackupRecordsProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsBackupRecordsTitle,
          onServerChanged: () =>
              context.read<BackupRecordsProvider>().initialize(widget.args),
          actions: <Widget>[
            IconButton(
              onPressed: _openFilter,
              icon: const Icon(Icons.filter_alt_outlined),
              tooltip: 'Filter',
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: AsyncStatePageBodyWidget(
            isLoading: provider.isLoading,
            isEmpty: provider.isEmpty,
            errorMessage: provider.errorMessage,
            onRetry: provider.load,
            emptyTitle: 'No backup records',
            emptyDescription:
                'Backup records will appear here after backups run.',
            child: RefreshIndicator(
              onRefresh: provider.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = provider.items[index];
                  return BackupRecordCardWidget(
                    item: item,
                    onDownload: () => provider.download(item),
                    onDelete: () => _delete(item),
                    onRecover: () => Navigator.pushNamed(
                      context,
                      AppRoutes.backupRecover,
                      arguments: BackupRecoverArgs(
                        initialRecord: item.record,
                        type: provider.type,
                        name: provider.name,
                        detailName: provider.detailName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFilter() async {
    final provider = context.read<BackupRecordsProvider>();
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BackupRecordFilterSheetWidget(
        initialType: provider.type,
        initialName: provider.name,
        initialDetailName: provider.detailName,
      ),
    );
    if (!mounted || result == null) return;
    provider.updateFilters(
      type: result['type'],
      name: result['name'],
      detailName: result['detailName'],
    );
    await provider.load();
  }

  Future<void> _delete(BackupRecordListItem item) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: 'Delete backup record ${item.record.fileName ?? ''}?',
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<BackupRecordsProvider>().delete(item);
  }
}
