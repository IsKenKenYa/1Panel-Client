import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxVisible = controller.maxVisibleItems;
        final visibleCount = constraints.maxWidth < 440 && maxVisible > 1
            ? maxVisible - 1
            : maxVisible;
        return _buildNavigation(context, orderedItems, visibleCount);
      },
    );
  }

  Widget _buildNavigation(
    BuildContext context,
    List<ModuleSubnavItem> orderedItems,
    int visibleCount,
  ) {
    final visible = orderedItems.take(visibleCount);
    final overflow = orderedItems.skip(visibleCount).toList(growable: false);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in visible)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppDesignTokens.spacingSm,
                    ),
                    child: ChoiceChip(
                      selected: selectedId == item.id,
                      showCheckmark: false,
                      avatar: Icon(
                        item.icon,
                        size: 18,
                        color: selectedId == item.id
                            ? scheme.onSecondaryContainer
                            : null,
                      ),
                      label: Text(item.label),
                      onSelected: (_) => onSelected(item.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (overflow.isNotEmpty) _buildOverflow(context, overflow),
        IconButton(
          onPressed: () => _showCustomize(context, orderedItems, visibleCount),
          tooltip: l10n.moduleSubnavCustomize,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }

  Widget _buildOverflow(
    BuildContext context,
    List<ModuleSubnavItem> overflow,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final selected = overflow.any((item) => item.id == selectedId);
    final style = selected
        ? IconButton.styleFrom(
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
          )
        : null;
    const icon = Icon(Icons.more_horiz_rounded);

    if (PlatformUtils.inputDeviceKinds(context) == InputDeviceKind.pointer) {
      return PopupMenuButton<String>(
        tooltip: l10n.commonMore,
        icon: icon,
        style: style,
        requestFocus: true,
        position: PopupMenuPosition.under,
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final item in overflow)
            CheckedPopupMenuItem<String>(
              value: item.id,
              checked: item.id == selectedId,
              child: Text(item.label),
            ),
        ],
      );
    }

    return IconButton(
      tooltip: l10n.commonMore,
      icon: icon,
      style: style,
      isSelected: selected,
      onPressed: () => _showOverflow(context, overflow),
    );
  }

  Future<void> _showOverflow(
    BuildContext context,
    List<ModuleSubnavItem> overflow,
  ) async {
    final selection = await showModalBottomSheet<String>(
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
                  selected: item.id == selectedId,
                  trailing:
                      item.id == selectedId ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(sheetContext, item.id),
                ),
            ],
          ),
        );
      },
    );
    if (context.mounted && selection != null) onSelected(selection);
  }

  Future<void> _showCustomize(
    BuildContext context,
    List<ModuleSubnavItem> orderedItems,
    int visibleCount,
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
                      l10n.moduleSubnavHint(visibleCount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        itemCount: mutable.length,
                        onReorderItem: (oldIndex, newIndex) {
                          setModalState(() {
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
                              index < visibleCount
                                  ? l10n.moduleSubnavVisible
                                  : l10n.moduleSubnavHidden,
                            ),
                            trailing: const Icon(Icons.drag_handle),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    OverflowBar(
                      alignment: MainAxisAlignment.end,
                      spacing: AppDesignTokens.spacingSm,
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
