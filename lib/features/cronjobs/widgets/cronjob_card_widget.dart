import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/cronjob_list_models.dart';

class CronjobCardWidget extends StatelessWidget {
  const CronjobCardWidget({
    super.key,
    required this.item,
    required this.statusLabel,
    required this.typeLabel,
    required this.toggleStatusLabel,
    required this.onToggleStatus,
    required this.onHandleOnce,
    required this.onOpenRecords,
    required this.onEdit,
    required this.onDelete,
    this.onStop,
  });

  final CronjobSummary item;
  final String statusLabel;
  final String typeLabel;
  final String toggleStatusLabel;
  final VoidCallback onToggleStatus;
  final VoidCallback onHandleOnce;
  final VoidCallback onOpenRecords;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('$typeLabel · $statusLabel'),
            if (item.groupBelong.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(item.groupBelong),
            ],
            if (item.spec.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text('${l10n.cronjobsSpecLabel}: ${item.spec}'),
            ],
            if ((item.nextHandlePreview ?? '').isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('${l10n.cronjobsNextRunLabel}: ${item.nextHandlePreview!}'),
            ],
            if (item.lastRecordTime.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text('${l10n.cronjobsLastRecordLabel}: ${item.lastRecordTime}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: onToggleStatus,
                  child: Text(toggleStatusLabel),
                ),
                OutlinedButton(
                  onPressed: onHandleOnce,
                  child: Text(l10n.cronjobsHandleOnceAction),
                ),
                OutlinedButton(
                  onPressed: onOpenRecords,
                  child: Text(l10n.cronjobsRecordsAction),
                ),
                OutlinedButton(
                  onPressed: onEdit,
                  child: Text(l10n.commonEdit),
                ),
                OutlinedButton(
                  onPressed: onDelete,
                  child: Text(l10n.commonDelete),
                ),
                if (onStop != null)
                  OutlinedButton(
                    onPressed: onStop,
                    child: Text(l10n.cronjobsStopAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
