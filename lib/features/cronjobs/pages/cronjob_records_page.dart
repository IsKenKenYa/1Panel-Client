import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_records_args.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjob_records_provider.dart';
import 'package:onepanel_client/features/cronjobs/widgets/cronjob_record_card_widget.dart';
import 'package:onepanel_client/features/cronjobs/widgets/cronjob_record_log_sheet_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class CronjobRecordsPage extends StatefulWidget {
  const CronjobRecordsPage({
    super.key,
    required this.args,
  });

  final CronjobRecordsArgs args;

  @override
  State<CronjobRecordsPage> createState() => _CronjobRecordsPageState();
}

class _CronjobRecordsPageState extends State<CronjobRecordsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<CronjobRecordsProvider>().load(widget.args.cronjobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<CronjobRecordsProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsCronjobRecordsTitle,
          onServerChanged: () => context
              .read<CronjobRecordsProvider>()
              .load(widget.args.cronjobId),
          actions: <Widget>[
            IconButton(
              onPressed: _cleanRecords,
              icon: const Icon(Icons.cleaning_services_outlined),
              tooltip: l10n.cronjobRecordsCleanAction,
            ),
            IconButton(
              onPressed: provider.isLoading
                  ? null
                  : () => provider.load(widget.args.cronjobId),
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    _statusChip(provider, '', l10n.cronjobRecordsStatusAll),
                    _statusChip(
                        provider, 'Success', l10n.cronjobRecordsStatusSuccess),
                    _statusChip(
                        provider, 'Waiting', l10n.cronjobRecordsStatusWaiting),
                    _statusChip(provider, 'Unexecuted',
                        l10n.cronjobRecordsStatusUnexecuted),
                    _statusChip(
                        provider, 'Failed', l10n.cronjobRecordsStatusFailed),
                  ],
                ),
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage: provider.errorMessage,
                  onRetry: () => provider.load(widget.args.cronjobId),
                  emptyTitle: l10n.cronjobRecordsEmptyTitle,
                  emptyDescription: l10n.cronjobRecordsEmptyDescription,
                  child: RefreshIndicator(
                    onRefresh: () => provider.load(widget.args.cronjobId),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return CronjobRecordCardWidget(
                          item: item,
                          statusLabel: _statusLabel(item.status),
                          onTap: () => _openLog(item.id),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(
    CronjobRecordsProvider provider,
    String status,
    String label,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: provider.statusFilter == status,
      onSelected: (_) => provider.updateStatusFilter(status),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Success':
        return context.l10n.cronjobRecordsStatusSuccess;
      case 'Waiting':
        return context.l10n.cronjobRecordsStatusWaiting;
      case 'Unexecuted':
        return context.l10n.cronjobRecordsStatusUnexecuted;
      case 'Failed':
        return context.l10n.cronjobRecordsStatusFailed;
      default:
        return status;
    }
  }

  Future<void> _openLog(int id) async {
    final provider = context.read<CronjobRecordsProvider>();
    await provider.loadRecordLog(id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CronjobRecordLogSheetWidget(
        title: context.l10n.cronjobRecordsViewLogTitle,
        content: provider.selectedLog,
      ),
    );
  }

  Future<void> _cleanRecords() async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.cronjobRecordsCleanAction,
      message: context.l10n.cronjobRecordsCleanConfirm,
      confirmLabel: context.l10n.commonConfirm,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<CronjobRecordsProvider>().cleanRecords(
          cleanData: true,
          cleanRemoteData: false,
        );
  }
}
