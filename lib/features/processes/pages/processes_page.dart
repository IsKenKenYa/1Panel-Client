import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/process_models.dart';
import 'package:onepanel_client/features/processes/providers/processes_provider.dart';
import 'package:onepanel_client/features/processes/widgets/process_filter_sheet_widget.dart';
import 'package:onepanel_client/features/processes/widgets/process_sort_bar_widget.dart';
import 'package:onepanel_client/features/processes/widgets/process_summary_card_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class ProcessesPage extends StatefulWidget {
  const ProcessesPage({super.key});

  @override
  State<ProcessesPage> createState() => _ProcessesPageState();
}

class _ProcessesPageState extends State<ProcessesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) return;
      context.read<ProcessesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<ProcessesProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsProcessesTitle,
          onServerChanged: () => context.read<ProcessesProvider>().load(),
          actions: <Widget>[
            IconButton(
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.filter_list_outlined),
              tooltip: l10n.commonSearch,
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.refresh,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: ProcessSortBarWidget(
                  currentField: provider.sortField,
                  onSelected: provider.updateSort,
                  cpuLabel: l10n.processesSortCpu,
                  memoryLabel: l10n.processesSortMemory,
                  nameLabel: l10n.processesSortName,
                  pidLabel: l10n.processesSortPid,
                ),
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage: provider.errorMessage,
                  onRetry: provider.load,
                  emptyTitle: l10n.processesEmptyTitle,
                  emptyDescription: l10n.processesEmptyDescription,
                  child: RefreshIndicator(
                    onRefresh: provider.refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return ProcessSummaryCardWidget(
                          item: item,
                          statusLabel: _statusLabel(context, item.status),
                          onOpenDetail: () => Navigator.pushNamed(
                            context,
                            AppRoutes.processDetail,
                            arguments: item.pid,
                          ),
                          onStop: () => _stopProcess(item),
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

  String _statusLabel(BuildContext context, String status) {
    final l10n = context.l10n;
    final normalized = status.toLowerCase();
    if (normalized.contains('running')) return l10n.processesStatusRunning;
    if (normalized.contains('sleep')) return l10n.processesStatusSleep;
    if (normalized.contains('stop')) return l10n.processesStatusStop;
    if (normalized.contains('idle')) return l10n.processesStatusIdle;
    if (normalized.contains('wait')) return l10n.processesStatusWait;
    if (normalized.contains('lock')) return l10n.processesStatusLock;
    if (normalized.contains('zombie')) return l10n.processesStatusZombie;
    return status;
  }

  Future<void> _openFilterSheet() async {
    final provider = context.read<ProcessesProvider>();
    final result = await showModalBottomSheet<ProcessListQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ProcessFilterSheetWidget(initialQuery: provider.query),
    );
    if (result == null || !mounted) return;
    await provider.applyQuery(result);
  }

  Future<void> _stopProcess(ProcessSummary item) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonStop,
      message: context.l10n.processesStopConfirm(item.name),
      confirmLabel: context.l10n.commonStop,
      confirmIcon: Icons.power_settings_new_outlined,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<ProcessesProvider>().stopProcess(item);
  }
}
