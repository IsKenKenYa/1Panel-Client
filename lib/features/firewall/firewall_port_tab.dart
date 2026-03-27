import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';

import 'firewall_rule_form_page.dart';
import 'providers/firewall_rule_list_provider.dart';
import 'widgets/firewall_rule_list_controls_widget.dart';
import 'widgets/firewall_tab_error.dart';

class FirewallPortTab extends StatefulWidget {
  const FirewallPortTab({super.key});

  @override
  State<FirewallPortTab> createState() => _FirewallPortTabState();
}

class _FirewallPortTabState extends State<FirewallPortTab> {
  bool _initialized = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<FirewallRule> _selected = <FirewallRule>{};
  String _strategyFilter = 'all';
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) {
        return;
      }
      _initialized = true;
      _loadRules();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FirewallPortsProvider>();
    final l10n = context.l10n;

    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.items.isEmpty) {
      return FirewallTabError(
        error: provider.error!,
        onRetry: () => provider.load(),
        l10n: l10n,
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.separated(
        padding: AppDesignTokens.pagePadding,
        itemCount: provider.items.length + 1,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppDesignTokens.spacingSm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return FirewallRuleListControls(
              searchController: _searchController,
              strategyFilter: _strategyFilter,
              isSelectionMode: _selectionMode,
              selectedCount: _selected.length,
              isMutating: provider.isMutating,
              onSearch: _loadRules,
              onStrategyChanged: _onStrategyChanged,
              onToggleSelectionMode: _toggleSelectionMode,
              onCreate: () => Navigator.pushNamed(
                context,
                AppRoutes.firewallRuleForm,
                arguments: const FirewallRuleFormArguments(
                  kind: FirewallRuleKind.port,
                ),
              ),
              onDeleteSelected: () => _deleteSelected(provider),
              onAcceptSelected: () => _toggleSelected(provider, 'accept'),
              onDropSelected: () => _toggleSelected(provider, 'drop'),
            );
          }
          final rule = provider.items[index - 1];
          final selected = _selected.contains(rule);
          return AppCard(
            title: rule.description ??
                '${l10n.firewallPortLabel} ${rule.port ?? '—'}',
            leading: _selectionMode
                ? Checkbox(
                    value: selected,
                    onChanged: provider.isMutating
                        ? null
                        : (_) => _toggleRuleSelection(rule),
                  )
                : null,
            subtitle: Text(
              '${l10n.firewallProtocolLabel}: ${rule.protocol ?? '-'}',
            ),
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
            onTap: _selectionMode ? () => _toggleRuleSelection(rule) : null,
            child: Text('${l10n.firewallAddressLabel}: ${rule.address ?? '-'}'),
          );
        },
      ),
    );
  }

  Future<void> _loadRules() async {
    if (!mounted) {
      return;
    }
    final provider = context.read<FirewallPortsProvider>();
    await provider.load(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      strategy: _strategyFilter == 'all' ? null : _strategyFilter,
    );
    if (!mounted) {
      return;
    }
    setState(_selected.clear);
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
        _selected.clear();
      }
    });
  }

  void _toggleRuleSelection(FirewallRule rule) {
    setState(() {
      if (_selected.contains(rule)) {
        _selected.remove(rule);
      } else {
        _selected.add(rule);
      }
    });
  }

  Future<void> _deleteSelected(FirewallPortsProvider provider) async {
    if (_selected.isEmpty) {
      return;
    }
    await provider.deleteRules(_selected.toList(growable: false));
    if (!mounted) {
      return;
    }
    setState(_selected.clear);
  }

  Future<void> _toggleSelected(
    FirewallPortsProvider provider,
    String strategy,
  ) async {
    if (_selected.isEmpty) {
      return;
    }
    for (final rule in _selected) {
      final current = (rule.strategy ?? '').toLowerCase();
      if (current == strategy) {
        continue;
      }
      await provider.toggleStrategy(rule, strategy);
    }
    if (!mounted) {
      return;
    }
    setState(_selected.clear);
  }

  Future<void> _handleAction(
    BuildContext context,
    FirewallPortsProvider provider,
    FirewallRule rule,
    String action,
  ) async {
    switch (action) {
      case 'edit':
        await Navigator.pushNamed(
          context,
          AppRoutes.firewallRuleForm,
          arguments: FirewallRuleFormArguments(
            kind: FirewallRuleKind.port,
            rule: rule,
          ),
        );
        if (context.mounted) {
          await provider.refresh();
        }
        break;
      case 'toggle':
        await provider.toggleStrategy(
          rule,
          (rule.strategy ?? '').toLowerCase() == 'accept' ? 'drop' : 'accept',
        );
        break;
      case 'delete':
        await provider.deleteRules([rule]);
        break;
    }
    if (mounted) {
      setState(_selected.clear);
    }
  }
}
