import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/shell/controllers/module_subnav_controller.dart';

class ModuleSubnavItem {
  const ModuleSubnavItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class ModuleSubnav extends StatelessWidget {
  const ModuleSubnav({
    super.key,
    required this.controller,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final ModuleSubnavController controller;
  final List<ModuleSubnavItem> items;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ordered = controller.loaded
        ? controller.orderedIds
        : items.map((item) => item.id).toList();
    final orderedItems = ordered
        .map((id) => items.firstWhere((item) => item.id == id))
        .toList(growable: false);
    final visible =
        orderedItems.take(controller.maxVisibleItems).toList(growable: false);
    final overflow =
        orderedItems.skip(controller.maxVisibleItems).toList(growable: false);
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in visible)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: selectedId == item.id,
                      showCheckmark: false,
                      avatar: Icon(
                        item.icon,
                        size: 18,
                        color: selectedId == item.id
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : null,
                      ),
                      label: Text(item.label),
                      onSelected: (_) => onSelected(item.id),
                    ),
                  ),
                if (overflow.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.more_horiz, size: 18),
                      label: Text(l10n.commonMore),
                      onPressed: () => _showOverflow(context, overflow),
                    ),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () => _showCustomize(context, orderedItems),
          tooltip: l10n.moduleSubnavCustomize,
          icon: const Icon(Icons.tune),
        ),
      ],
    );
  }

  Future<void> _showOverflow(
    BuildContext context,
    List<ModuleSubnavItem> overflow,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final item in overflow)
                ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelected(item.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCustomize(
    BuildContext context,
    List<ModuleSubnavItem> orderedItems,
  ) async {
    final l10n = context.l10n;
    final mutable = orderedItems.map((item) => item.id).toList(growable: true);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.moduleSubnavCustomize,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.moduleSubnavHint(controller.maxVisibleItems),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        itemCount: mutable.length,
                        onReorder: (oldIndex, newIndex) {
                          setModalState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = mutable.removeAt(oldIndex);
                            mutable.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = items.firstWhere(
                              (entry) => entry.id == mutable[index]);
                          return ListTile(
                            key: ValueKey(item.id),
                            leading: Icon(item.icon),
                            title: Text(item.label),
                            subtitle: Text(
                              index < controller.maxVisibleItems
                                  ? l10n.moduleSubnavVisible
                                  : l10n.moduleSubnavHidden,
                            ),
                            trailing: const Icon(Icons.drag_handle),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            await controller.reset();
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(l10n.commonReset),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            await controller.reorder(mutable);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(l10n.commonSave),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
