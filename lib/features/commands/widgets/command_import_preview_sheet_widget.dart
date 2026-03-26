import 'package:flutter/material.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/shared/widgets/operations/async_state_page_body_widget.dart';

class CommandImportPreviewSheetWidget extends StatelessWidget {
  const CommandImportPreviewSheetWidget({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.isImporting,
    required this.onToggleItem,
    required this.onSelectAll,
    required this.onPickGroup,
    required this.onImport,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.importLabel,
    required this.selectAllLabel,
    required this.groupLabel,
  });

  final List<CommandInfo> items;
  final Set<int> selectedIds;
  final bool isImporting;
  final VoidCallback onSelectAll;
  final VoidCallback onPickGroup;
  final VoidCallback onImport;
  final void Function(int? id) onToggleItem;
  final String emptyTitle;
  final String emptyDescription;
  final String importLabel;
  final String selectAllLabel;
  final String groupLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            importLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: items.isEmpty ? null : onSelectAll,
                icon: const Icon(Icons.done_all_outlined),
                label: Text(selectAllLabel),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: items.isEmpty ? null : onPickGroup,
                icon: const Icon(Icons.folder_outlined),
                label: Text(groupLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 420,
            child: AsyncStatePageBodyWidget(
              isLoading: isImporting && items.isEmpty,
              isEmpty: items.isEmpty,
              emptyTitle: emptyTitle,
              emptyDescription: emptyDescription,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final itemId = item.id;
                  final isSelected =
                      itemId != null && selectedIds.contains(itemId);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: isImporting ? null : (_) => onToggleItem(itemId),
                    title: Text(item.name ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item.groupBelong ?? '-'),
                        const SizedBox(height: 4),
                        Text(
                          item.command ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                        ),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isImporting || selectedIds.isEmpty ? null : onImport,
              icon: isImporting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(importLabel),
            ),
          ),
        ],
      ),
    );
  }
}
