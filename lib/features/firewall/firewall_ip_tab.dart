import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/shared/state/selection_controller.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

import 'firewall_rule_form_page.dart';
import 'providers/firewall_rule_list_provider.dart';
import 'widgets/firewall_rule_list_controls_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

class FirewallIpTab extends StatefulWidget {
  const FirewallIpTab({super.key});

  @override
  State<FirewallIpTab> createState() => _FirewallIpTabState();
}

class _FirewallIpTabState extends State<FirewallIpTab> {
  bool _initialized = false;
  final TextEditingController _searchController = TextEditingController();
  final SelectionController<FirewallRule> _selection =
      SelectionController<FirewallRule>();
  String _strategyFilter = 'all';
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _selection.addListener(_onSelectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) {
        return;
      }
      _initialized = true;
      _loadRules();
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
  Widget build(BuildContext context) {
    final provider = context.watch<FirewallIpProvider>();
    final l10n = context.l10n;

    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.items.isEmpty) {
      return ModuleErrorStateWidget(
        message: provider.error,
        onRetry: () => provider.load(),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppDesignTokens.scrollPagePadding(context),
          itemCount: provider.items.length + 1,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDesignTokens.spacingSm),
          itemBuilder: (context, index) {
            if (index == 0) {
              final controls = FirewallRuleListControls(
                searchController: _searchController,
                strategyFilter: _strategyFilter,
                isSelectionMode: _selectionMode,
                selectedCount: _selection.selectedCount,
                isMutating: provider.isMutating,
                onSearch: _loadRules,
                onStrategyChanged: _onStrategyChanged,
                onToggleSelectionMode: _toggleSelectionMode,
                onCreate: () => openRouteRespectingShell(
                  context,
                  AppRoutes.firewallRuleForm,
                  arguments: const FirewallRuleFormArguments(
                    kind: FirewallRuleKind.ip,
                  ),
                ),
                onDeleteSelected: () => _deleteSelected(provider),
                onAcceptSelected: () => _toggleSelected(provider, 'accept'),
                onDropSelected: () => _toggleSelected(provider, 'drop'),
              );
              if (provider.items.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    controls,
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    SizedBox(
                      height: constraints.maxHeight * 0.6,
                      child: ModuleEmptyStateWidget(
                        title: l10n.firewallIpsEmptyTitle,
                        description: l10n.firewallIpsEmptyHint,
                      ),
                    ),
                  ],
                );
              }
              return controls;
            }
          final rule = provider.items[index - 1];
          final selected = _selection.isSelected(rule);
          return AppCard(
            title: rule.address ?? '${l10n.firewallTabIps} ${rule.id ?? '—'}',
            leading: _selectionMode
                ? Checkbox(
                    value: selected,
                    onChanged: provider.isMutating
                        ? null
                        : (_) => _selection.toggle(rule),
                  )
                : null,
            subtitle: rule.strategy != null ? Text(rule.strategy!) : null,
            trailing: _selectionMode
                ? null
                : PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(
                      context,
                      provider,
                      rule,
                      value,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.commonEdit),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(l10n.firewallToggleStrategyAction),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.commonDelete),
                      ),
                    ],
                  ),
            onTap: _selectionMode ? () => _selection.toggle(rule) : null,
            child: Text(rule.description ?? '-'),
          );
            },
          ),
        ),
      );
  }

  Future<void> _loadRules() async {
    if (!mounted) {
      return;
    }
    final provider = context.read<FirewallIpProvider>();
    await provider.load(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      strategy: _strategyFilter == 'all' ? null : _strategyFilter,
    );
    if (!mounted) {
      return;
    }
    _selection.clear();
  }

  Future<void> _onStrategyChanged(String value) async {
    setState(() {
      _strategyFilter = value;
    });
    await _loadRules();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selection.clear();
      }
    });
  }


  Future<void> _deleteSelected(FirewallIpProvider provider) async {
    if (!_selection.hasSelection) {
      return;
    }
    final l10n = context.l10n;
    final selected = _selection.toList();
    await showAppFormDialog(
      context,
      title: l10n.firewallOperationConfirmTitle,
      destructive: true,
      content: Text(l10n.firewallDeleteSelectedConfirm(selected.length)),
      onConfirm: () async {
        await provider.deleteRules(selected);
        if (mounted) {
          _selection.clear();
        }
      },
    );
  }

  Future<void> _toggleSelected(
    FirewallIpProvider provider,
    String strategy,
  ) async {
    if (!_selection.hasSelection) {
      return;
    }
    for (final rule in _selection.toList()) {
      final current = (rule.strategy ?? '').toLowerCase();
      if (current == strategy) {
        continue;
      }
      await provider.toggleStrategy(rule, strategy);
    }
    if (!mounted) {
      return;
    }
    _selection.clear();
  }

  Future<void> _handleAction(
    BuildContext context,
    FirewallIpProvider provider,
    FirewallRule rule,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        final editArgs = FirewallRuleFormArguments(
          kind: FirewallRuleKind.ip,
          rule: rule,
        );
        if (PlatformUtils.isDesktop(context)) {
          await openRouteRespectingShell(
            context,
            AppRoutes.firewallRuleForm,
            arguments: editArgs,
          );
        } else {
          await Navigator.pushNamed(
            context,
            AppRoutes.firewallRuleForm,
            arguments: editArgs,
          );
          if (context.mounted) {
            await provider.refresh();
          }
        }
        break;
      case 'toggle':
        await provider.toggleStrategy(
          rule,
          (rule.strategy ?? '').toLowerCase() == 'accept' ? 'drop' : 'accept',
        );
        break;
      case 'delete':
        await showAppFormDialog(
          context,
          title: context.l10n.firewallOperationConfirmTitle,
          destructive: true,
          content: Text(context.l10n.commonDeleteConfirm),
          onConfirm: () => provider.deleteRules([rule]),
        );
        break;
    }
    if (mounted) {
      _selection.clear();
    }
  }
}
