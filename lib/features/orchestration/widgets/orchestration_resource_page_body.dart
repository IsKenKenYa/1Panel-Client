import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
import 'package:onepanel_client/shared/widgets/operations/partial_error_toast_listener.dart';

typedef OrchestrationResourceLoader = Future<void> Function();

/// Resolves a stable list key for compose/docker list items.
String orchestrationListItemKey(Object item) {
  if (item is ComposeProject) {
    final id = item.id.trim();
    if (id.isNotEmpty) {
      return 'compose:$id';
    }
    final path = item.path?.trim();
    if (path != null && path.isNotEmpty) {
      return 'compose:$path';
    }
    final name = item.name.trim();
    if (name.isNotEmpty) {
      return 'compose:$name';
    }
  }
  return 'orchestration:${item.hashCode}';
}

class OrchestrationResourcePageBody<T> extends StatelessWidget {
  const OrchestrationResourcePageBody({
    super.key,
    required this.items,
    required this.error,
    required this.isLoading,
    required this.onRefresh,
    required this.itemBuilder,
    this.emptyMessage,
    this.itemKey,
  });

  final List<T> items;
  final String? error;
  final bool isLoading;
  final OrchestrationResourceLoader onRefresh;
  final Widget Function(T item) itemBuilder;
  final String? emptyMessage;
  final String Function(T item)? itemKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && items.isEmpty) {
      return ModuleErrorStateWidget(
        message: error,
        onRetry: () => onRefresh(),
      );
    }

    if (items.isEmpty) {
      return Center(child: Text(emptyMessage ?? l10n.commonEmpty));
    }

    final resolveKey = itemKey ?? (T item) => orchestrationListItemKey(item as Object);
    final displayItems = _dedupeByKey(items, resolveKey);

    return Stack(
      fit: StackFit.expand,
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: AppDesignTokens.cardPadding,
            itemCount: displayItems.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (isLoading && index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }
              final itemIndex = isLoading ? index - 1 : index;
              final item = displayItems[itemIndex];
              return KeyedSubtree(
                key: ValueKey(resolveKey(item)),
                child: itemBuilder(item),
              );
            },
          ),
        ),
        PartialErrorToastListener(
          errorMessage: error,
          hasCachedData: displayItems.isNotEmpty,
          onRetry: () => onRefresh(),
        ),
      ],
    );
  }
}

List<T> _dedupeByKey<T>(List<T> items, String Function(T item) resolveKey) {
  final seen = <String>{};
  final unique = <T>[];
  for (final item in items) {
    if (seen.add(resolveKey(item))) {
      unique.add(item);
    }
  }
  return unique;
}
