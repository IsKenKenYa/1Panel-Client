import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';

class ScriptLibraryCardWidget extends StatelessWidget {
  const ScriptLibraryCardWidget({
    super.key,
    required this.item,
    required this.interactiveLabel,
    required this.onViewCode,
    required this.onRun,
    required this.onSync,
    this.onDelete,
  });

  final ScriptLibraryInfo item;
  final String interactiveLabel;
  final VoidCallback onViewCode;
  final VoidCallback onRun;
  final VoidCallback onSync;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final createdAt = item.createdAt == null
        ? '-'
        : DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt!.toLocal());
    final groups = item.groupBelong.isEmpty ? '-' : item.groupBelong.join(', ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(groups),
            if (item.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(item.description),
            ],
            const SizedBox(height: 4),
            Text('${l10n.scriptLibraryInteractiveLabel}: $interactiveLabel'),
            const SizedBox(height: 4),
            Text('${l10n.scriptLibraryCreatedAtLabel}: $createdAt'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: onViewCode,
                  child: Text(l10n.scriptLibraryViewCodeAction),
                ),
                OutlinedButton(
                  onPressed: onRun,
                  child: Text(l10n.scriptLibraryRunAction),
                ),
                OutlinedButton(
                  onPressed: onSync,
                  child: Text(l10n.scriptLibrarySyncAction),
                ),
                if (onDelete != null)
                  OutlinedButton(
                    onPressed: onDelete,
                    child: Text(l10n.scriptLibraryDeleteAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
