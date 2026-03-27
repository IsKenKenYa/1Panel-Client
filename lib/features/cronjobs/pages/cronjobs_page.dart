import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_form_args.dart';
import 'package:onepanel_client/features/cronjobs/models/cronjob_records_args.dart';
import 'package:onepanel_client/features/cronjobs/providers/cronjobs_provider.dart';
import 'package:onepanel_client/features/cronjobs/widgets/cronjob_card_widget.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_sheet_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class CronjobsPage extends StatefulWidget {
  const CronjobsPage({super.key});

  @override
  State<CronjobsPage> createState() => _CronjobsPageState();
}

class _CronjobsPageState extends State<CronjobsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<CronjobsProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<CronjobsProvider>(
      builder: (context, provider, _) {
        return ServerAwarePageScaffold(
          title: l10n.operationsCronjobsTitle,
          onServerChanged: () => context.read<CronjobsProvider>().load(),
          actions: <Widget>[
            IconButton(
              onPressed: () => _pickGroupFilter(provider),
              icon: const Icon(Icons.folder_outlined),
              tooltip: l10n.cronjobsGroupFilterAction,
            ),
            IconButton(
              onPressed: provider.isLoading ? null : provider.load,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.commonCreate),
          ),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      onChanged: provider.updateSearchQuery,
                      onSubmitted: (_) => provider.load(),
                      decoration: InputDecoration(
                        hintText: l10n.cronjobsSearchHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        label: Text(
                          provider.selectedGroupId == null
                              ? l10n.cronjobsFilterAllGroups
                              : _groupName(provider),
                        ),
                        selected: provider.selectedGroupId != null,
                        onSelected: (_) => _pickGroupFilter(provider),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage: provider.errorMessage,
                  onRetry: provider.load,
                  emptyTitle: l10n.cronjobsEmptyTitle,
                  emptyDescription: l10n.cronjobsEmptyDescription,
                  child: RefreshIndicator(
                    onRefresh: provider.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return CronjobCardWidget(
                          item: item,
                          statusLabel: _statusLabel(context, item.status),
                          typeLabel: _typeLabel(context, item.type),
                          toggleStatusLabel:
                              _toggleStatusLabel(context, item.status),
                          onToggleStatus: () => _toggleStatus(item),
                          onHandleOnce: () => _handleOnce(item),
                          onOpenRecords: () => Navigator.pushNamed(
                            context,
                            AppRoutes.cronjobRecords,
                            arguments: CronjobRecordsArgs(
                              cronjobId: item.id,
                              name: item.name,
                              status: item.status,
                            ),
                          ),
                          onEdit: () => _openEdit(item),
                          onDelete: () => _delete(item),
                          onStop: item.status == 'Pending'
                              ? () => _stop(item)
                              : null,
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

  String _groupName(CronjobsProvider provider) {
    if (provider.groups.isEmpty) {
      return context.l10n.cronjobsFilterAllGroups;
    }
    final match = provider.groups.firstWhere(
      (group) => group.id == provider.selectedGroupId,
      orElse: () => provider.groups.first,
    );
    final name = match.name?.trim();
    return name == null || name.isEmpty
        ? context.l10n.operationsGroupDefaultLabel
        : name;
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'Enable':
        return context.l10n.cronjobsStatusEnable;
      case 'Disable':
        return context.l10n.cronjobsStatusDisable;
      case 'Pending':
        return context.l10n.cronjobsStatusPending;
      default:
        return status;
    }
  }

  String _toggleStatusLabel(BuildContext context, String status) {
    return status == 'Enable'
        ? context.l10n.cronjobsDisableAction
        : context.l10n.cronjobsEnableAction;
  }

  String _typeLabel(BuildContext context, String type) {
    switch (type) {
      case 'shell':
        return context.l10n.cronjobsTypeShell;
      case 'website':
        return context.l10n.cronjobsTypeWebsite;
      case 'database':
        return context.l10n.cronjobsTypeDatabase;
      case 'directory':
        return context.l10n.cronjobsTypeDirectory;
      case 'snapshot':
        return context.l10n.cronjobsTypeSnapshot;
      case 'clean':
        return context.l10n.cronjobsTypeLog;
      default:
        return type;
    }
  }

  Future<void> _pickGroupFilter(CronjobsProvider provider) async {
    final groupId = await GroupSelectorSheetWidget.show(
      context,
      groupType: 'cronjob',
      initialSelectedGroupId: provider.selectedGroupId,
      allowClearSelection: true,
      clearOptionLabel: context.l10n.cronjobsFilterAllGroups,
    );
    if (!mounted) return;
    provider.updateGroupFilter(groupId);
    await provider.load();
  }

  Future<void> _toggleStatus(CronjobSummary item) async {
    final nextStatus = item.status == 'Enable' ? 'Disable' : 'Enable';
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.operationsCronjobsTitle,
      message: context.l10n.cronjobsUpdateStatusConfirm(
        item.name,
        _statusLabel(context, nextStatus),
      ),
      confirmLabel: context.l10n.commonConfirm,
    );
    if (!confirmed || !mounted) return;
    await context.read<CronjobsProvider>().updateStatus(item, nextStatus);
  }

  Future<void> _handleOnce(CronjobSummary item) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.cronjobsHandleOnceAction,
      message: context.l10n.cronjobsHandleOnceConfirm(item.name),
      confirmLabel: context.l10n.commonConfirm,
    );
    if (!confirmed || !mounted) return;
    await context.read<CronjobsProvider>().handleOnce(item);
  }

  Future<void> _stop(CronjobSummary item) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonStop,
      message: context.l10n.cronjobsStopConfirm(item.name),
      confirmLabel: context.l10n.commonStop,
      confirmIcon: Icons.stop_circle_outlined,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<CronjobsProvider>().stop(item);
  }

  Future<void> _delete(CronjobSummary item) async {
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.cronjobsDeleteConfirm(item.name),
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await context.read<CronjobsProvider>().delete(item);
  }

  Future<void> _openEdit(CronjobSummary item) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.cronjobForm,
      arguments: CronjobFormArgs(cronjobId: item.id),
    );
    if (!mounted) return;
    await context.read<CronjobsProvider>().load(forceRefresh: true);
  }

  Future<void> _openCreate() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.cronjobForm,
      arguments: const CronjobFormArgs(),
    );
    if (!mounted) return;
    await context.read<CronjobsProvider>().load(forceRefresh: true);
  }
}
