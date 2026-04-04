import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/core/utils/keyboard_utils.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';

import '../providers/websites_provider.dart';
import '../widgets/website_async_state_view.dart';
import '../widgets/website_list_controls_widget.dart';
import '../widgets/website_list_helpers.dart';
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
  int? _lastSelectedIndex;

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
    _lastSelectedIndex = null;
    _typeFilter = null;
    _groupFilterId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WebsitesProvider>().onServerChanged();
    });
  }

  void _handleSelectRange(int currentIndex, List<WebsiteInfo> websites) {
    if (_lastSelectedIndex == null) {
      final id = websites[currentIndex].id;
      if (id != null) {
        setState(() {
          _selectedIds.add(id);
          _lastSelectedIndex = currentIndex;
        });
      }
      return;
    }

    final start = _lastSelectedIndex!;
    final end = currentIndex;

    final lower = start < end ? start : end;
    final upper = start > end ? start : end;

    setState(() {
      for (int i = lower; i <= upper; i++) {
        if (i >= 0 && i < websites.length) {
          final id = websites[i].id;
          if (id != null) {
            _selectedIds.add(id);
          }
        }
      }
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
                    onSearch: () => applyWebsiteFilters(
                      context.read<WebsitesProvider>(),
                      query: _searchController.text.trim(),
                      type: _typeFilter,
                      websiteGroupId: _groupFilterId,
                    ),
                    onGroupChanged: (value) {
                      setState(() => _groupFilterId = value);
                      applyWebsiteFilters(
                        context.read<WebsitesProvider>(),
                        query: _searchController.text.trim(),
                        type: _typeFilter,
                        websiteGroupId: _groupFilterId,
                      );
                    },
                    onTypeChanged: (value) {
                      setState(() => _typeFilter = value);
                      applyWebsiteFilters(
                        context.read<WebsitesProvider>(),
                        query: _searchController.text.trim(),
                        type: _typeFilter,
                        websiteGroupId: _groupFilterId,
                      );
                    },
                    onToggleSelectionMode: () {
                      setState(() {
                        _selectionMode = !_selectionMode;
                        if (!_selectionMode) {
                          _selectedIds.clear();
                        }
                      });
                    },
                    onBatchStart: () => _batchOperate(context, 'start'),
                    onBatchStop: () => _batchOperate(context, 'stop'),
                    onBatchRestart: () => _batchOperate(context, 'restart'),
                    onBatchDelete: () async {
                      if (_selectedIds.isEmpty) return;
                      await _confirmDelete(
                        context,
                        context.read<WebsitesProvider>(),
                        _selectedIds.toList(growable: false),
                        null,
                      );
                    },
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
                
                final isDesktop = PlatformUtils.isDesktop(context);

                Widget content = WebsiteListItemCard(
                  website: website,
                  selectionMode: _selectionMode,
                  selected: selected,
                  onTap: () {
                    if (isDesktop) {
                      if (id == null) return;
                      final isShiftPressed = KeyboardUtils.isShiftPressed();
                      final isControlPressed = KeyboardUtils.isModifierPressed();

                      setState(() {
                        if (isControlPressed) {
                          if (_selectedIds.contains(id)) {
                            _selectedIds.remove(id);
                          } else {
                            _selectedIds.add(id);
                          }
                          _lastSelectedIndex = index - 2;
                        } else if (isShiftPressed) {
                          _handleSelectRange(index - 2, data.websites);
                        } else {
                          _selectedIds.clear();
                          _selectedIds.add(id);
                          _lastSelectedIndex = index - 2;
                        }
                      });
                    } else {
                      _selectionMode && id != null
                        ? setState(() {
                            if (_selectedIds.contains(id)) {
                              _selectedIds.remove(id);
                            } else {
                              _selectedIds.add(id);
                            }
                          })
                        : openWebsiteDetail(context, website);
                    }
                  },
                  onSelectedChanged: (value) {
                    if (id != null) {
                      setState(() {
                        if (value) {
                          _selectedIds.add(id);
                        } else {
                          _selectedIds.remove(id);
                        }
                        _lastSelectedIndex = index - 2;
                      });
                    }
                  },
                  onAction: (action) =>
                      _handleAction(context, provider, website, action),
                );

                if (isDesktop) {
                  content = GestureDetector(
                    onDoubleTap: () => openWebsiteDetail(context, website),
                    onSecondaryTapDown: (details) {
                      if (!selected && id != null) {
                        setState(() {
                          _selectedIds.clear();
                          _selectedIds.add(id);
                          _lastSelectedIndex = index - 2;
                        });
                      }
                      _showDesktopContextMenu(context, details.globalPosition, provider, website, l10n);
                    },
                    child: content,
                  );
                }

                return content;
              },
            ),
          );
        },
      ),
    );
  }

  void _showDesktopContextMenu(
    BuildContext context,
    Offset position,
    WebsitesProvider provider,
    WebsiteInfo website,
    AppLocalizations l10n,
  ) {
    final isRunning = website.status?.toLowerCase() == 'running';
    
    showMenu<WebsiteListAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        if (!isRunning)
          PopupMenuItem(
            value: WebsiteListAction.start,
            child: Text(l10n.websitesActionStart),
          ),
        if (isRunning)
          PopupMenuItem(
            value: WebsiteListAction.stop,
            child: Text(l10n.websitesActionStop),
          ),
        if (isRunning)
          PopupMenuItem(
            value: WebsiteListAction.restart,
            child: Text(l10n.websitesActionRestart),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: WebsiteListAction.delete,
          child: Text(
            l10n.websitesActionDelete,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleAction(context, provider, website, value);
      }
    });
  }

  Future<void> _handleAction(
    BuildContext context,
    WebsitesProvider provider,
    WebsiteInfo website,
    WebsiteListAction action,
  ) async {
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
        content: Text(
          ok
              ? context.l10n.websitesOperateSuccess
              : context.l10n.websitesOperateFailed,
        ),
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

  Future<void> _confirmDelete(
    BuildContext context,
    WebsitesProvider provider,
    List<int> ids,
    String? domain,
  ) async {
    await runWebsiteBatchDelete(
      context,
      provider: provider,
      ids: ids,
      domain: domain,
      clearSelection: () => setState(() => _selectedIds.clear()),
    );
  }

  Future<void> _selectBatchGroup(
    BuildContext context,
    List<WebsiteGroup> groups,
  ) async {
    if (_selectedIds.isEmpty || groups.isEmpty) return;
    await runWebsiteBatchSetGroup(
      context,
      provider: context.read<WebsitesProvider>(),
      ids: _selectedIds.toList(growable: false),
      groups: groups,
      clearSelection: () => setState(() => _selectedIds.clear()),
    );
  }
}
