import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';

import '../providers/websites_provider.dart';
import '../widgets/website_async_state_view.dart';
import '../widgets/website_list_controls_widget.dart';
import '../widgets/website_list_item_card_widget.dart';
import '../widgets/website_stats_card_widget.dart';

class WebsiteListPageBody extends StatefulWidget {
  const WebsiteListPageBody({super.key});

  @override
  State<WebsiteListPageBody> createState() => _WebsiteListPageBodyState();
}

class _WebsiteListPageBodyState extends State<WebsiteListPageBody> {
  String? _activeServerId;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = <int>{};
  bool _selectionMode = false;
  String? _typeFilter;
  int? _groupFilterId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WebsitesProvider>().loadWebsites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final serverId =
        Provider.of<CurrentServerController>(context).currentServerId;
    if (_activeServerId == null) {
      _activeServerId = serverId;
      return;
    }
    if (serverId == null || serverId == _activeServerId) {
      return;
    }
    _activeServerId = serverId;
    _searchController.clear();
    _selectedIds.clear();
    _selectionMode = false;
    _typeFilter = null;
    _groupFilterId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WebsitesProvider>().onServerChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ServerAwarePageScaffold(
      title: l10n.websitesPageTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<WebsitesProvider>().refresh(),
          tooltip: l10n.commonRefresh,
        ),
        IconButton(
          icon: const Icon(Icons.tune_outlined),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.openrestyCenter),
          tooltip: l10n.openrestyPageTitle,
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.websiteCreate),
        icon: const Icon(Icons.add),
        label: Text(l10n.commonCreate),
      ),
      body: Consumer<WebsitesProvider>(
        builder: (context, provider, _) {
          final data = provider.data;
          if (data.isLoading && data.websites.isEmpty) {
            return const WebsiteAsyncStateView(isLoading: true);
          }
          if (data.error != null && data.websites.isEmpty) {
            return WebsiteAsyncStateView(
              error: l10n.websitesLoadFailedMessage(data.error!),
              onRetry: provider.loadWebsites,
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.websites.isEmpty ? 3 : data.websites.length + 2,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return WebsitesStatsCard(stats: data.stats);
                }
                if (index == 1) {
                  return WebsitesListControls(
                    searchController: _searchController,
                    groups: data.groups,
                    selectedGroupId: _groupFilterId,
                    selectedType: _typeFilter,
                    selectionMode: _selectionMode,
                    selectedCount: _selectedIds.length,
                    onSearch: () => _applyFilters(context),
                    onGroupChanged: (value) {
                      setState(() => _groupFilterId = value);
                      _applyFilters(context);
                    },
                    onTypeChanged: (value) {
                      setState(() => _typeFilter = value);
                      _applyFilters(context);
                    },
                    onToggleSelectionMode: _toggleSelectionMode,
                    onBatchStart: () => _batchOperate(context, 'start'),
                    onBatchStop: () => _batchOperate(context, 'stop'),
                    onBatchRestart: () => _batchOperate(context, 'restart'),
                    onBatchDelete: () => _batchDelete(context),
                    onBatchSetGroup: () =>
                        _selectBatchGroup(context, data.groups),
                  );
                }
                if (data.websites.isEmpty) {
                  return WebsitesEmptyView(
                    title: l10n.websitesEmptyTitle,
                    subtitle: l10n.websitesEmptySubtitle,
                  );
                }
                final website = data.websites[index - 2];
                final id = website.id;
                final selected = id != null && _selectedIds.contains(id);
                return WebsiteListItemCard(
                  website: website,
                  selectionMode: _selectionMode,
                  selected: selected,
                  onTap: () => _selectionMode && id != null
                      ? _toggleSelected(id)
                      : _openDetail(context, website),
                  onSelectedChanged: (value) {
                    if (id != null) {
                      _setSelected(id, value);
                    }
                  },
                  onAction: (action) =>
                      _handleAction(context, provider, website, action),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _applyFilters(BuildContext context) {
    context.read<WebsitesProvider>().loadWebsites(
          query: _searchController.text.trim(),
          type: _typeFilter,
          websiteGroupId: _groupFilterId,
        );
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelected(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _setSelected(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _openDetail(BuildContext context, WebsiteInfo website) {
    final id = website.id;
    if (id == null) return;
    Navigator.pushNamed(
      context,
      AppRoutes.websiteDetail,
      arguments: {'websiteId': id},
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WebsitesProvider provider,
    WebsiteInfo website,
    WebsiteListAction action,
  ) async {
    final l10n = context.l10n;
    final id = website.id;
    if (id == null) return;
    if (action == WebsiteListAction.delete) {
      await _confirmDelete(context, provider, [id], website.displayDomain);
      return;
    }
    final ok = await provider.batchOperate(
      ids: [id],
      action: switch (action) {
        WebsiteListAction.start => 'start',
        WebsiteListAction.stop => 'stop',
        WebsiteListAction.restart => 'restart',
        WebsiteListAction.delete => 'delete',
      },
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(ok ? l10n.websitesOperateSuccess : l10n.websitesOperateFailed),
      ),
    );
  }

  Future<void> _batchOperate(BuildContext context, String action) async {
    if (_selectedIds.isEmpty) return;
    final ok = await context.read<WebsitesProvider>().batchOperate(
          ids: _selectedIds.toList(growable: false),
          action: action,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? context.l10n.websitesOperateSuccess
              : context.l10n.websitesOperateFailed,
        ),
      ),
    );
    if (ok) {
      setState(() => _selectedIds.clear());
    }
  }

  Future<void> _batchDelete(BuildContext context) async {
    if (_selectedIds.isEmpty) return;
    await _confirmDelete(
      context,
      context.read<WebsitesProvider>(),
      _selectedIds.toList(growable: false),
      null,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WebsitesProvider provider,
    List<int> ids,
    String? domain,
  ) async {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: Text(l10n.websitesDeleteTitle),
        content: Text(
          domain == null
              ? l10n.websitesBatchDeleteMessage(ids.length)
              : l10n.websitesDeleteMessage(
                  domain.isEmpty ? l10n.websitesUnknownDomain : domain,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await provider.batchDelete(ids);
      if (!context.mounted) return;
      if (ok) {
        setState(() => _selectedIds.clear());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.websitesDeleteSuccess : l10n.websitesOperateFailed,
          ),
        ),
      );
    }
  }

  Future<void> _selectBatchGroup(
    BuildContext context,
    List<WebsiteGroup> groups,
  ) async {
    if (_selectedIds.isEmpty || groups.isEmpty) return;
    final provider = context.read<WebsitesProvider>();
    int? selectedId = groups.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.websitesSetGroupAction),
          content: DropdownButtonFormField<int>(
            initialValue: selectedId,
            items: [
              for (final group in groups)
                DropdownMenuItem<int>(
                  value: group.id,
                  child: Text(group.name ?? '${group.id}'),
                ),
            ],
            onChanged: (value) => setState(() => selectedId = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && selectedId != null) {
      final ok = await provider.batchSetGroup(
        ids: _selectedIds.toList(growable: false),
        groupId: selectedId!,
      );
      if (!context.mounted) return;
      if (ok) {
        setState(() => _selectedIds.clear());
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? context.l10n.websitesOperateSuccess
                : context.l10n.websitesOperateFailed,
          ),
        ),
      );
    }
  }
}
