import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
import 'package:onepanel_client/features/shell/shell_navigation.dart';
import 'package:onepanel_client/shared/state/selection_controller.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';

import '../../data/models/firewall_models.dart';

import 'firewall_rule_form_page.dart';
import 'providers/firewall_rule_list_provider.dart';
import 'widgets/firewall_rule_list_controls_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_empty_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

String _resolveFirewallError(String error, AppLocalizations l10n) {
  switch (error) {
    case 'firewallForwardStrategyToggleError':
      return l10n.firewallForwardStrategyToggleError;
    default:
      return error;
  }
}

class FirewallRulesTab extends StatefulWidget {
  const FirewallRulesTab({super.key});

  @override
  State<FirewallRulesTab> createState() => _FirewallRulesTabState();
}

class _FirewallRulesTabState extends State<FirewallRulesTab> {
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
    final provider = context.watch<FirewallRulesProvider>();

    if (provider.isLoading && provider.items.isEmpty) {
      return const _LoadingBody();
    }

    if (provider.error != null && provider.items.isEmpty) {
      return ModuleErrorStateWidget(
        message: _resolveFirewallError(provider.error!, context.l10n),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider.useFilterApi) ...[
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppDesignTokens.spacingSm),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                key: ValueKey(
                                    'filter-chain-${provider.filterChain}'),
                                initialValue: provider.filterChain,
                                decoration: const InputDecoration(
                                  labelText: 'Chain',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: '1PANEL_INPUT',
                                    child: Text('1PANEL_INPUT'),
                                  ),
                                  DropdownMenuItem(
                                    value: '1PANEL_OUTPUT',
                                    child: Text('1PANEL_OUTPUT'),
                                  ),
                                ],
                                onChanged: provider.isMutating
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          _onFilterChainChanged(value);
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(width: AppDesignTokens.spacingSm),
                            FilledButton.tonal(
                              onPressed: provider.isMutating
                                  ? null
                                  : () => _toggleFilterChainBinding(provider),
                              child: Text(
                                provider.isFilterChainBound
                                    ? context.l10n.firewallUnbindAction
                                    : context.l10n.firewallBindAction,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingSm),
                  ],
                  FirewallRuleListControls(
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
                        kind: FirewallRuleKind.port,
                      ),
                    ),
                    onDeleteSelected: () => _deleteSelected(provider),
                    onAcceptSelected: () => _toggleSelected(provider, 'accept'),
                    onDropSelected: () => _toggleSelected(provider, 'drop'),
                  ),
                  if (provider.items.isEmpty) ...[
                    const SizedBox(height: AppDesignTokens.spacingMd),
                    SizedBox(
                      height: constraints.maxHeight * 0.6,
                      child: ModuleEmptyStateWidget(
                        title: context.l10n.firewallRulesEmptyTitle,
                        description: context.l10n.firewallRulesEmptyHint,
                      ),
                    ),
                  ],
                ],
              );
          }
          final rule = provider.items[index - 1];
          final selected = _selection.isSelected(rule);
          return AppCard(
            title: _ruleTitle(rule),
            leading: _selectionMode
                ? Checkbox(
                    value: selected,
                    onChanged: provider.isMutating
                        ? null
                        : (_) => _selection.toggle(rule),
                  )
                : null,
            subtitle: _ruleSubtitle(rule),
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
                      if (!provider.useFilterApi)
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(context.l10n.commonEdit),
                        ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(context.l10n.firewallToggleStrategyAction),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.l10n.commonDelete),
                      ),
                    ],
                  ),
            onTap: _selectionMode ? () => _selection.toggle(rule) : null,
            child: _ruleDetail(rule),
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
    final provider = context.read<FirewallRulesProvider>();
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

  Future<void> _onFilterChainChanged(String chain) async {
    final provider = context.read<FirewallRulesProvider>();
    await provider.switchFilterChain(chain);
    if (!mounted) {
      return;
    }
    _selection.clear();
  }

  Future<void> _toggleFilterChainBinding(
    FirewallRulesProvider provider,
  ) async {
    await provider.toggleFilterChainBinding(!provider.isFilterChainBound);
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selection.clear();
      }
    });
  }


  Future<void> _deleteSelected(FirewallRulesProvider provider) async {
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
        final addressRules = selected.where(_isAddressRule).toList();
        final portRules = selected.where((rule) => !_isAddressRule(rule)).toList();
        if (addressRules.isNotEmpty) {
          await provider.deleteRules(addressRules);
        }
        if (portRules.isNotEmpty) {
          await provider.deleteRules(portRules);
        }
        if (mounted) {
          _selection.clear();
        }
      },
    );
  }

  Future<void> _toggleSelected(
    FirewallRulesProvider provider,
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

  bool _isAddressRule(FirewallRule rule) {
    return (rule.address ?? '').isNotEmpty && (rule.port ?? '').isEmpty;
  }

  Future<void> _handleAction(
    BuildContext context,
    FirewallRulesProvider provider,
    FirewallRule rule,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        final editArgs = FirewallRuleFormArguments(
          kind: (rule.port ?? '').isNotEmpty
              ? FirewallRuleKind.port
              : FirewallRuleKind.ip,
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

  String _ruleTitle(FirewallRule rule) {
    if (rule.description?.isNotEmpty == true) {
      return rule.description!;
    }
    if (rule.targetIP?.isNotEmpty == true || rule.targetPort?.isNotEmpty == true) {
      final ip = rule.targetIP?.isNotEmpty == true ? rule.targetIP! : '-';
      final port =
          rule.targetPort?.isNotEmpty == true ? rule.targetPort! : '-';
      return '$ip:$port';
    }
    if (rule.address?.isNotEmpty == true) {
      return rule.address!;
    }
    if (rule.destination?.isNotEmpty == true) {
      return rule.destination!;
    }
    return '${context.l10n.firewallRuleDefaultTitle} ${rule.id ?? '—'}';
  }

  Widget? _ruleSubtitle(FirewallRule rule) {
    final parts = <String>[];
    if (rule.protocol?.isNotEmpty == true) {
      parts.add(rule.protocol!);
    }
    if (rule.strategy?.isNotEmpty == true) {
      parts.add(rule.strategy!);
    }
    if (rule.port?.isNotEmpty == true) {
      parts.add('${context.l10n.firewallPortLabel} ${rule.port}');
    }
    if (parts.isEmpty) {
      return null;
    }
    return Text(parts.join(' · '));
  }

  Widget? _ruleDetail(FirewallRule rule) {
    final parts = <String>[];
    if (rule.family?.isNotEmpty == true) {
      parts.add('${context.l10n.firewallFamilyLabel}: ${rule.family}');
    }
    if (rule.srcPort?.isNotEmpty == true) {
      parts.add(
        '${context.l10n.firewallSourcePortLabel}: ${rule.srcPort}',
      );
    }
    if (rule.destPort?.isNotEmpty == true) {
      parts.add(
        '${context.l10n.firewallDestinationPortLabel}: ${rule.destPort}',
      );
    }
    if (rule.targetIP?.isNotEmpty == true) {
      parts.add('targetIP: ${rule.targetIP}');
    }
    if (rule.targetPort?.isNotEmpty == true) {
      parts.add('targetPort: ${rule.targetPort}');
    }
    if (rule.interface?.isNotEmpty == true) {
      parts.add('interface: ${rule.interface}');
    }
    if (parts.isEmpty) {
      return null;
    }
    return Text(parts.join(' · '));
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
