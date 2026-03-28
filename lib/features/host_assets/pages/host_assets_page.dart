import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/features/group/widgets/group_selector_sheet_widget.dart';
import 'package:onepanel_client/features/host_assets/providers/host_assets_provider.dart';
import 'package:onepanel_client/features/host_assets/widgets/host_asset_card_widget.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';
import 'package:provider/provider.dart';

class HostAssetsPage extends StatefulWidget {
  const HostAssetsPage({super.key});

  @override
  State<HostAssetsPage> createState() => _HostAssetsPageState();
}

class _HostAssetsPageState extends State<HostAssetsPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<CurrentServerController>().hasServer) {
        return;
      }
      context.read<HostAssetsProvider>().load();
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
    return Consumer<HostAssetsProvider>(
      builder: (context, provider, _) {
        final selectionMode = provider.selectedIds.isNotEmpty;
        return ServerAwarePageScaffold(
          title: l10n.operationsHostAssetsTitle,
          onServerChanged: () =>
              context.read<HostAssetsProvider>().load(forceRefresh: true),
          actions: <Widget>[
            if (selectionMode)
              IconButton(
                onPressed: provider.isMutating ? null : _deleteSelected,
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.commonDelete,
              ),
            IconButton(
              onPressed: () => _pickGroupFilter(provider),
              icon: const Icon(Icons.folder_outlined),
              tooltip: l10n.hostAssetsGroupFilterAction,
            ),
            IconButton(
              onPressed: provider.isLoading
                  ? null
                  : () => provider.load(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              tooltip: l10n.commonRefresh,
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: Text(l10n.commonCreate),
          ),
          body: Column(
            children: <Widget>[
              TextField(
                controller: _searchController,
                onChanged: provider.updateSearchQuery,
                onSubmitted: (_) => provider.load(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.hostAssetsSearchHint,
                  suffixIcon: IconButton(
                    onPressed: () => provider.load(),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: Text(
                    provider.selectedGroupId == null
                        ? l10n.hostAssetsFilterAllGroups
                        : _groupLabel(provider),
                  ),
                  selected: provider.selectedGroupId != null,
                  onSelected: (_) => _pickGroupFilter(provider),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AsyncStatePageBodyWidget(
                  isLoading: provider.isLoading,
                  isEmpty: provider.isEmpty,
                  errorMessage: provider.errorMessage,
                  onRetry: () => provider.load(forceRefresh: true),
                  emptyTitle: l10n.hostAssetsEmptyTitle,
                  emptyDescription: l10n.hostAssetsEmptyDescription,
                  emptyActionLabel: l10n.commonCreate,
                  onEmptyAction: _openForm,
                  child: RefreshIndicator(
                    onRefresh: () => provider.load(forceRefresh: true),
                    child: ListView.separated(
                      itemCount: provider.hosts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final host = provider.hosts[index];
                        return GestureDetector(
                          onLongPress: () => provider.toggleSelection(host.id),
                          child: HostAssetCardWidget(
                            host: host,
                            groupLabel: _hostGroupLabel(host, l10n),
                            testState: provider.testStateFor(host.id),
                            isSelected: provider.selectedIds.contains(host.id),
                            selectionMode: selectionMode,
                            onTap: () {
                              if (selectionMode) {
                                provider.toggleSelection(host.id);
                              }
                            },
                            onEdit: () => _openForm(host),
                            onTest: () => _testHost(host),
                            onDelete: () => _deleteSingle(host),
                            onMoveGroup: () => _moveGroup(host),
                          ),
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

  String _groupLabel(HostAssetsProvider provider) {
    if (provider.groups.isEmpty) {
      return context.l10n.operationsGroupDefaultLabel;
    }
    final match = provider.groups.firstWhere(
      (group) => group.id == provider.selectedGroupId,
      orElse: () => provider.groups.first,
    );
    return match.name?.trim().isNotEmpty == true
        ? match.name!
        : context.l10n.operationsGroupDefaultLabel;
  }

  String _hostGroupLabel(HostInfo host, dynamic l10n) {
    final name = host.groupBelong?.trim();
    return name == null || name.isEmpty
        ? l10n.operationsGroupDefaultLabel
        : name;
  }

  Future<void> _pickGroupFilter(HostAssetsProvider provider) async {
    final groupId = await GroupSelectorSheetWidget.show(
      context,
      groupType: 'host',
      initialSelectedGroupId: provider.selectedGroupId,
      allowClearSelection: true,
      clearOptionLabel: context.l10n.hostAssetsFilterAllGroups,
    );
    if (!mounted) return;
    provider.updateGroupFilter(groupId);
    await provider.load();
  }

  Future<void> _moveGroup(HostInfo host) async {
    final provider = context.read<HostAssetsProvider>();
    final groupId = await GroupSelectorSheetWidget.show(
      context,
      groupType: 'host',
      initialSelectedGroupId: host.groupID,
    );
    if (groupId == null || groupId == host.groupID) {
      return;
    }
    await provider.moveHostGroup(host: host, groupId: groupId);
  }

  Future<void> _testHost(HostInfo host) async {
    await context.read<HostAssetsProvider>().testHost(host);
  }

  Future<void> _deleteSingle(HostInfo host) async {
    final provider = context.read<HostAssetsProvider>();
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.hostAssetsDeleteConfirm(host.name),
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed) return;
    await provider.deleteHost(host);
  }

  Future<void> _deleteSelected() async {
    final provider = context.read<HostAssetsProvider>();
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: context.l10n.commonDelete,
      message: context.l10n.hostAssetsDeleteSelectedConfirm(
        provider.selectedIds.length,
      ),
      confirmLabel: context.l10n.commonDelete,
      confirmIcon: Icons.delete_outline,
      isDestructive: true,
    );
    if (!confirmed) return;
    await provider.deleteSelected();
  }

  Future<void> _openForm([HostInfo? host]) async {
    final refreshed = await Navigator.pushNamed(
      context,
      AppRoutes.hostAssetForm,
      arguments: host,
    );
    if (refreshed == true && mounted) {
      await context.read<HostAssetsProvider>().load(forceRefresh: true);
    }
  }
}
