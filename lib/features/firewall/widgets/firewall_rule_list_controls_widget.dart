import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class FirewallRuleActionMenu extends StatelessWidget {
  const FirewallRuleActionMenu({
    super.key,
    required this.enabled,
    required this.canEdit,
    required this.canToggle,
    required this.onSelected,
  });

  final bool enabled;
  final bool canEdit;
  final bool canToggle;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      enabled: enabled,
      onSelected: onSelected,
      itemBuilder: (_) => [
        if (canEdit)
          PopupMenuItem(value: 'edit', child: Text(l10n.commonEdit)),
        if (canToggle)
          PopupMenuItem(value: 'toggle', child: Text(l10n.firewallToggleStrategyAction)),
        PopupMenuItem(value: 'delete', child: Text(l10n.commonDelete)),
      ],
    );
  }
}

class FirewallRuleListControls extends StatelessWidget {
  const FirewallRuleListControls({
    super.key,
    required this.searchController,
    required this.strategyFilter,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.isMutating,
    required this.onSearch,
    required this.onStrategyChanged,
    required this.onToggleSelectionMode,
    required this.onCreate,
    required this.onDeleteSelected,
    required this.onAcceptSelected,
    required this.onDropSelected,
    this.supportsLegacyChanges = true,
  });

  final TextEditingController searchController;
  final String strategyFilter;
  final bool isSelectionMode;
  final int selectedCount;
  final bool isMutating;
  final VoidCallback onSearch;
  final ValueChanged<String> onStrategyChanged;
  final VoidCallback onToggleSelectionMode;
  final VoidCallback onCreate;
  final VoidCallback onDeleteSelected;
  final VoidCallback onAcceptSelected;
  final VoidCallback onDropSelected;
  final bool supportsLegacyChanges;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasSelection = selectedCount > 0;
    return Column(
      children: [
        TextField(
          key: const Key('firewall.searchField'),
          controller: searchController,
          enabled: !isMutating,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: l10n.firewallSearchHint,
            suffixIcon: IconButton(
              key: const Key('firewall.searchButton'),
              tooltip: context.l10n.commonSearch,
              onPressed: isMutating ? null : onSearch,
              icon: const Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(height: AppDesignTokens.spacingSm),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: const Key('firewall.strategyFilter'),
                initialValue: strategyFilter,
                decoration: InputDecoration(
                  labelText: l10n.firewallStrategyLabel,
                ),
                onChanged: isMutating
                    ? null
                    : (value) {
                        if (value != null) {
                          onStrategyChanged(value);
                        }
                      },
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text(l10n.firewallStrategyAll),
                  ),
                  DropdownMenuItem(
                    value: 'accept',
                    child: Text(l10n.firewallStrategyAccept),
                  ),
                  DropdownMenuItem(
                    value: 'drop',
                    child: Text(l10n.firewallStrategyDrop),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDesignTokens.spacingSm),
            OutlinedButton.icon(
              onPressed: isMutating ? null : onCreate,
              icon: const Icon(Icons.add_outlined),
              label: Text(l10n.commonCreate),
            ),
            if (supportsLegacyChanges) ...[
              const SizedBox(width: AppDesignTokens.spacingSm),
              OutlinedButton.icon(
                key: const Key('firewall.selectionModeButton'),
                onPressed: isMutating ? null : onToggleSelectionMode,
                icon: Icon(isSelectionMode ? Icons.close : Icons.checklist),
                label: Text(
                  isSelectionMode
                      ? l10n.firewallSelectionModeDisable
                      : l10n.firewallSelectionModeEnable,
                ),
              ),
            ],
          ],
        ),
        if (supportsLegacyChanges && isSelectionMode) ...[
          const SizedBox(height: AppDesignTokens.spacingSm),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.firewallSelectedCount(selectedCount),
                ),
              ),
              FilledButton.tonal(
                key: const Key('firewall.bulkAcceptButton'),
                onPressed:
                    isMutating || !hasSelection ? null : onAcceptSelected,
                child: Text(l10n.firewallBatchAcceptAction),
              ),
              const SizedBox(width: AppDesignTokens.spacingSm),
              FilledButton.tonal(
                key: const Key('firewall.bulkDropButton'),
                onPressed: isMutating || !hasSelection ? null : onDropSelected,
                child: Text(l10n.firewallBatchDropAction),
              ),
              const SizedBox(width: AppDesignTokens.spacingSm),
              FilledButton.tonal(
                key: const Key('firewall.bulkDeleteButton'),
                onPressed:
                    isMutating || !hasSelection ? null : onDeleteSelected,
                child: Text(l10n.firewallBatchDeleteAction),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
