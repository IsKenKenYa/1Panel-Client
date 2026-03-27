import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';

class RuntimeSummaryCardWidget extends StatelessWidget {
  const RuntimeSummaryCardWidget({
    super.key,
    required this.item,
    required this.onOpenDetail,
    required this.onEdit,
    required this.onDelete,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.canEdit,
    required this.canStart,
    required this.canStop,
    required this.canRestart,
  });

  final RuntimeInfo item;
  final VoidCallback onOpenDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final bool canEdit;
  final bool canStart;
  final bool canStop;
  final bool canRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: InkWell(
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item.name ?? '-',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  Chip(label: Text(runtimeTypeLabel(l10n, item.type ?? ''))),
                  Chip(
                      label: Text(runtimeStatusLabel(l10n, item.status ?? ''))),
                  Chip(
                    label:
                        Text(runtimeResourceLabel(l10n, item.resource ?? '')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if ((item.version ?? '').isNotEmpty)
                Text('${l10n.runtimeFieldVersion}: ${item.version}'),
              if ((item.codeDir ?? '').isNotEmpty)
                Text('${l10n.runtimeFieldCodeDir}: ${item.codeDir}'),
              if ((item.port ?? '').isNotEmpty)
                Text('${l10n.runtimeFieldExternalPort}: ${item.port}'),
              if ((item.remark ?? '').isNotEmpty)
                Text('${l10n.runtimeFieldRemark}: ${item.remark}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: canStart ? onStart : null,
                    child: Text(l10n.runtimeActionStart),
                  ),
                  OutlinedButton(
                    onPressed: canStop ? onStop : null,
                    child: Text(l10n.runtimeActionStop),
                  ),
                  OutlinedButton(
                    onPressed: canRestart ? onRestart : null,
                    child: Text(l10n.runtimeActionRestart),
                  ),
                  OutlinedButton(
                    onPressed: canEdit ? onEdit : null,
                    child: Text(l10n.commonEdit),
                  ),
                  OutlinedButton(
                    onPressed: onDelete,
                    child: Text(l10n.commonDelete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
