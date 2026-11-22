import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:provider/provider.dart';

import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/core/utils/keyboard_utils.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/shell/widgets/shell_list_bottom_padding.dart';

import '../providers/websites_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import '../../../shared/state/selection_controller.dart';
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
  final SelectionController<int> _selection = SelectionController<int>();
  bool _selectionMode = false;
  String? _typeFilter;
  int? _groupFilterId;
  int? _lastSelectedIndex;

  @override
  void initState() {
    super.initState();
    _selection.addListener(_onSelectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WebsitesProvider>().loadWebsites();
    });
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _selection.removeListener(_onSelectionChanged);
    _selection.dispose();
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
    _selection.clear();
    _selectionMode = false;
    _lastSelectedIndex = null;
    _typeFilter = null;
    _groupFilterId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WebsitesProvider>().onServerChanged();
    });
  }

  // Implements Shift+click range selection for desktop multi-select.
  void _handleSelectRange(int currentIndex, List<WebsiteInfo> websites) {
    if (_lastSelectedIndex == null) {
      final id = websites[currentIndex].id;
      if (id != null) {
        setState(() {
          _selection.select(id);
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
            _selection.select(id);
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
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () => context.read<WebsitesProvider>().refresh(),
          tooltip: l10n.commonRefresh,
        ),
        IconButton(
          icon: const Icon(Icons.description_outlined),
          onPressed: () =>
              openRouteRespectingShell(context, AppRoutes.websiteTemplates),
          tooltip: l10n.websitesTemplateTitle,
        ),
        IconButton(
          icon: const Icon(Icons.tune_outlined),
          onPressed: () =>
              openRouteRespectingShell(context, AppRoutes.openrestyCenter),
          tooltip: l10n.openrestyPageTitle,
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'website_list_create_fab',
        // 创建页 pop(true) 表示建站成功；返回后刷新列表，
        // 否则统计与列表停留在旧数据。
        onPressed: () async {
          // 保持单行：desktop_shell_stability_policy_test 以完整调用串做守卫。
          final created = await openRouteRespectingShell(context, AppRoutes.websiteCreate);
          if (created == true && context.mounted) {
            context.read<WebsitesProvider>().refresh();
          }
        },
        icon: const Icon(Icons.add_outlined),
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

          return PartialErrorToastListener(
            errorMessage: data.error != null
                ? l10n.websitesLoadFailedMessage(data.error!)
                : null,
            hasCachedData: data.websites.isNotEmpty,
            onRetry: provider.loadWebsites,
            child: RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView.separated(
              padding: AppDesignTokens.cardPadding +
                  shellListBottomPadding(context),
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
                    selectedCount: _selection.selectedCount,
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
                          _selection.clear();
                        }
                      });
                    },
                    onBatchStart: () => _batchOperate(context, 'start'),
                    onBatchStop: () => _batchOperate(context, 'stop'),
                    onBatchRestart: () => _batchOperate(context, 'restart'),
                    onBatchDelete: () async {
                      if (!_selection.hasSelection) return;
                      await _confirmDelete(
                        context,
                        context.read<WebsitesProvider>(),
                        _selection.toList(),
                        null,
                      );
                    },
                    onBatchSetGroup: () =>
                        _selectBatchGroup(context, data.groups),
                  );
                }
                if (data.websites.isEmpty) {
                  return ModuleEmptyStateWidget(
                    icon: Icons.language_outlined,
                    title: l10n.websitesEmptyTitle,
                    description: l10n.websitesEmptySubtitle,
                  );
                }
                final website = data.websites[index - 2];
                final id = website.id;
                final selected = id != null && _selection.isSelected(id);
                
                final isDesktop = PlatformUtils.isDesktop(context);

                Widget content = WebsiteListItemCard(
                  website: website,
                  selectionMode: _selectionMode,
                  selected: selected,
                  onTap: () {
                    if (isDesktop) {
                      // Desktop: Ctrl+click toggles individual items, Shift+click selects ranges.
                      if (id == null) return;
                      final isShiftPressed = KeyboardUtils.isShiftPressed();
                      final isControlPressed = KeyboardUtils.isModifierPressed();

                      setState(() {
                        if (isControlPressed) {
                          if (_selection.isSelected(id)) {
                            _selection.deselect(id);
                          } else {
                            _selection.select(id);
                          }
                          _lastSelectedIndex = index - 2;
                        } else if (isShiftPressed) {
                          _handleSelectRange(index - 2, data.websites);
                        } else {
                          _selection.clear();
                          _selection.select(id);
                          _lastSelectedIndex = index - 2;
                        }
                      });
                    } else {
                      _selectionMode && id != null
                        ? setState(() {
                            if (_selection.isSelected(id)) {
                              _selection.deselect(id);
                            } else {
                              _selection.select(id);
                            }
                          })
                        : _openDetailAndRefresh(context, provider, website);
                    }
                  },
                  onSelectedChanged: (value) {
                    if (id != null) {
                      setState(() {
                        if (value) {
                          _selection.select(id);
                        } else {
                          _selection.deselect(id);
                        }
                        _lastSelectedIndex = index - 2;
                      });
                    }
                  },
                  onAction: (action) =>
                      _handleAction(context, provider, website, action),
                );

                if (isDesktop) {
                  final desktopCardContent = content;
                  content = GestureDetector(
                    onDoubleTap: () => openWebsiteDetail(context, website),
                    onSecondaryTapDown: (details) {
                      if (!selected && id != null) {
                        setState(() {
                          _selection.clear();
                          _selection.select(id);
                          _lastSelectedIndex = index - 2;
                        });
                      }
                      _showDesktopContextMenu(context, details.globalPosition, provider, website, l10n);
                    },
                    child: desktopCardContent,
                  );
                }

                return content;
              },
            ),
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
    
    final currentContext = context;
    showMenu<WebsiteListAction>(
      context: currentContext,
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
            style: TextStyle(color: Theme.of(currentContext).colorScheme.error),
          ),
        ),
      ],
    ).then((value) {
      if (value != null && currentContext.mounted) {
        _handleAction(currentContext, provider, website, value);
      }
    });
  }

  /// 打开站点详情并在返回后刷新：详情页删除成功会 pop(true)。
  Future<void> _openDetailAndRefresh(
    BuildContext context,
    WebsitesProvider provider,
    WebsiteInfo website,
  ) async {
    final changed = await openWebsiteDetail(context, website);
    if (changed == true && context.mounted) {
      provider.refresh();
    }
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
    if (ok) {
      SnackBarUtils.showSuccess(context, context.l10n.websitesOperateSuccess);
    } else {
      SnackBarUtils.showError(context, context.l10n.websitesOperateFailed);
    }
  }

  Future<void> _batchOperate(BuildContext context, String action) async {
    if (!_selection.hasSelection) return;
    final ok = await context.read<WebsitesProvider>().batchOperate(
          ids: _selection.toList(),
          action: action,
        );
    if (!context.mounted) return;
    if (ok) {
      SnackBarUtils.showSuccess(context, context.l10n.websitesOperateSuccess);
      setState(() => _selection.clear());
    } else {
      SnackBarUtils.showError(context, context.l10n.websitesOperateFailed);
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
      clearSelection: () => setState(() => _selection.clear()),
    );
  }

  Future<void> _selectBatchGroup(
    BuildContext context,
    List<WebsiteGroup> groups,
  ) async {
    if (!_selection.hasSelection || groups.isEmpty) return;
    await runWebsiteBatchSetGroup(
      context,
      provider: context.read<WebsitesProvider>(),
      ids: _selection.toList(),
      groups: groups,
      clearSelection: () => setState(() => _selection.clear()),
    );
  }
}
