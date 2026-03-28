import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/website_group_models.dart';

class WebsiteListDialogs {
  static Future<bool> confirmDelete(
    BuildContext context, {
    required List<int> ids,
    String? domain,
  }) async {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: Text(l10n.websitesDeleteTitle),
        content: Text(
          domain == null
              ? l10n.websitesBatchDeleteMessage(ids.length)
              : l10n.websitesDeleteMessage(
                  domain.isEmpty ? l10n.websitesUnknownDomain : domain,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<int?> selectBatchGroup(
    BuildContext context,
    List<WebsiteGroup> groups,
  ) async {
    int? selectedId = groups.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.websitesSetGroupAction),
          content: DropdownButtonFormField<int>(
            initialValue: selectedId,
            items: [
              for (final group in groups)
                DropdownMenuItem<int>(
                  value: group.id,
                  child: Text(group.name ?? '${group.id}'),
                ),
            ],
            onChanged: (value) => setState(() => selectedId = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.commonConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      return selectedId;
    }
    return null;
  }
}
