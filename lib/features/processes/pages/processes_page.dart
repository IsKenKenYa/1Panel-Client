import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/process_models.dart';
import 'package:onepanel_client/features/processes/providers/processes_provider.dart';
import 'package:onepanel_client/features/processes/widgets/process_sort_bar_widget.dart';
import 'package:onepanel_client/features/processes/widgets/process_summary_card_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/shared/widgets/operations/page_visibility_listener.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

class ProcessesPage extends StatefulWidget {
  const ProcessesPage({super.key});

  @override
  State<ProcessesPage> createState() => _ProcessesPageState();
}

class _ProcessesPageState extends State<ProcessesPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connection = context.select(
      (CurrentServerController state) =>
          (state.currentServerId, state.currentServer?.revision),
    );
    return Consumer<ProcessesProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsProcessesTitle,
          actions: <Widget>[
            IconButton(
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.filter_list_outlined),
              tooltip: l10n.commonSearch,
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.refresh,
              icon: const Icon(Icons.refresh_outlined),
              tooltip: l10n.commonRefresh,
            ),
          ],
          body: PageVisibilityListener(
            key: ValueKey(connection),
            onChanged: provider.setPageVisible,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: AppDesignTokens.cardPadding,
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
          ),
        );
      },
    );
  }

  Future<void> _openFilterSheet() async {
    final provider = context.read<ProcessesProvider>();
    final result = await showAdaptiveFormPanel<ProcessListQuery>(
      context,
      builder: (_) => _ProcessFilterForm(initialQuery: provider.query),
    );
    if (result == null || !mounted) {
      return;
    }
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
    if (!confirmed || !mounted) {
      return;
    }
    await context.read<ProcessesProvider>().stopProcess(item);
  }
}

String _statusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  final normalized = status.toLowerCase();
  if (normalized.contains('running')) {
    return l10n.processesStatusRunning;
  }
  if (normalized.contains('sleep')) {
    return l10n.processesStatusSleep;
  }
  if (normalized.contains('stop')) {
    return l10n.processesStatusStop;
  }
  if (normalized.contains('idle')) {
    return l10n.processesStatusIdle;
  }
  if (normalized.contains('wait')) {
    return l10n.processesStatusWait;
  }
  if (normalized.contains('lock')) {
    return l10n.processesStatusLock;
  }
  if (normalized.contains('zombie')) {
    return l10n.processesStatusZombie;
  }
  return status;
}

class _ProcessFilterForm extends StatefulWidget {
  const _ProcessFilterForm({required this.initialQuery});

  final ProcessListQuery initialQuery;

  @override
  State<_ProcessFilterForm> createState() => _ProcessFilterFormState();
}

class _ProcessFilterFormState extends State<_ProcessFilterForm> {
  late final _pidController = TextEditingController(
    text: widget.initialQuery.pid?.toString() ?? '',
  );
  late final _nameController = TextEditingController(
    text: widget.initialQuery.name,
  );
  late final _userController = TextEditingController(
    text: widget.initialQuery.username,
  );
  late final _selectedStatuses = widget.initialQuery.statuses.toSet();

  @override
  void dispose() {
    _pidController.dispose();
    _nameController.dispose();
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.commonSearch,
      onConfirm: () async => Navigator.of(context).pop(
        ProcessListQuery(
          pid: int.tryParse(_pidController.text.trim()),
          name: _nameController.text.trim(),
          username: _userController.text.trim(),
          statuses: _selectedStatuses.toList(growable: false),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _pidController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.processesSearchPidLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.processesSearchNameLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _userController,
            decoration: InputDecoration(
              labelText: l10n.processesSearchUserLabel,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.processesFilterStatusLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in const [
                'running',
                'sleep',
                'stop',
                'idle',
                'wait',
                'lock',
                'zombie',
              ])
                FilterChip(
                  label: Text(_statusLabel(context, status)),
                  selected: _selectedStatuses.contains(status),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.standard,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _selectedStatuses.add(status);
                    } else {
                      _selectedStatuses.remove(status);
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
