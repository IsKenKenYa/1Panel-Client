import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';

class WebsitesListControls extends StatelessWidget {
  const WebsitesListControls({
    super.key,
    required this.searchController,
    required this.groups,
    required this.selectedGroupId,
    required this.selectedType,
    required this.selectionMode,
    required this.selectedCount,
    required this.onSearch,
    required this.onGroupChanged,
    required this.onTypeChanged,
    required this.onToggleSelectionMode,
    required this.onBatchStart,
    required this.onBatchStop,
    required this.onBatchRestart,
    required this.onBatchDelete,
    required this.onBatchSetGroup,
  });

  final TextEditingController searchController;
  final List<WebsiteGroup> groups;
  final int? selectedGroupId;
  final String? selectedType;
  final bool selectionMode;
  final int selectedCount;
  final VoidCallback onSearch;
  final ValueChanged<int?> onGroupChanged;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onToggleSelectionMode;
  final Future<void> Function() onBatchStart;
  final Future<void> Function() onBatchStop;
  final Future<void> Function() onBatchRestart;
  final Future<void> Function() onBatchDelete;
  final Future<void> Function() onBatchSetGroup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                labelText: l10n.commonSearch,
                suffixIcon: IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: selectedGroupId,
                    decoration:
                        InputDecoration(labelText: l10n.websitesGroupLabel),
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(l10n.websitesFilterAllGroups),
                      ),
                      for (final group in groups)
                        DropdownMenuItem<int>(
                          value: group.id,
                          child: Text(group.name ?? '${group.id}'),
                        ),
                    ],
                    onChanged: onGroupChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: l10n.websitesLifecycleTypeLabel,
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text(l10n.websitesFilterAllTypes),
                      ),
                      DropdownMenuItem<String>(
                        value: 'runtime',
                        child: Text(l10n.websitesLifecycleTypeRuntime),
                      ),
                      DropdownMenuItem<String>(
                        value: 'proxy',
                        child: Text(l10n.websitesLifecycleTypeProxy),
                      ),
                      DropdownMenuItem<String>(
                        value: 'subsite',
                        child: Text(l10n.websitesLifecycleTypeSubsite),
                      ),
                      DropdownMenuItem<String>(
                        value: 'static',
                        child: Text(l10n.websitesLifecycleTypeStatic),
                      ),
                    ],
                    onChanged: onTypeChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onToggleSelectionMode,
                icon: Icon(selectionMode ? Icons.close : Icons.checklist),
                label: Text(
                  selectionMode
                      ? l10n.websitesSelectionDisable
                      : l10n.websitesSelectionEnable,
                ),
              ),
            ),
            if (selectionMode) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.websitesSelectedCount(selectedCount)),
                  ),
                  TextButton(
                    onPressed: onBatchStart,
                    child: Text(l10n.websitesActionStart),
                  ),
                  TextButton(
                    onPressed: onBatchStop,
                    child: Text(l10n.websitesActionStop),
                  ),
                  TextButton(
                    onPressed: onBatchRestart,
                    child: Text(l10n.websitesActionRestart),
                  ),
                  TextButton(
                    onPressed: onBatchSetGroup,
                    child: Text(l10n.websitesSetGroupAction),
                  ),
                  TextButton(
                    onPressed: onBatchDelete,
                    child: Text(l10n.commonDelete),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
