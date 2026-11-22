import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/task_log_models.dart';

import '../utils/logs_l10n_helper.dart';

class TaskLogCardWidget extends StatelessWidget {
  const TaskLogCardWidget({
    super.key,
    required this.item,
    required this.onCopy,
    required this.onOpenDetail,
  });

  final TaskLog item;
  final VoidCallback onCopy;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: AppDesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(item.name ?? '-',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if ((item.type ?? '').isNotEmpty)
              Text('${l10n.logsTaskTypeLabel}: ${item.type}'),
            if ((item.status ?? '').isNotEmpty)
              Text(
                  '${l10n.logsTaskDetailStatusLabel}: ${logsStatusLabel(l10n, item.status)}'),
            if ((item.currentStep ?? '').isNotEmpty)
              Text(
                  '${l10n.logsTaskDetailCurrentStepLabel}: ${item.currentStep}'),
            if ((item.createdAt ?? '').isNotEmpty)
              Text(
                  '${l10n.logsTaskDetailCreatedAtLabel}: ${formatLogsTimestamp(item.createdAt)}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(l10n.commonCopy),
                ),
                FilledButton.tonalIcon(
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.article_outlined),
                  label: Text(l10n.logsTaskOpenDetailAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
