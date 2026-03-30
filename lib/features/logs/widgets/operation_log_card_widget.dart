import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/logs_models.dart';

class OperationLogCardWidget extends StatelessWidget {
  const OperationLogCardWidget({
    super.key,
    required this.item,
    required this.onCopy,
  });

  final OperationLogEntry item;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final detail = locale.startsWith('zh')
        ? (item.detailZh ?? item.detailEn ?? item.message ?? '-')
        : (item.detailEn ?? item.detailZh ?? item.message ?? '-');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if ((item.source ?? '').isNotEmpty)
              _buildInfoLine(
                context,
                '${l10n.logsOperationSourceLabel}: ${item.source}',
              ),
            if ((item.method ?? '').isNotEmpty || (item.path ?? '').isNotEmpty)
              _buildInfoLine(
                context,
                '${item.method ?? '-'} ${item.path ?? ''}'.trim(),
              ),
            if ((item.status ?? '').isNotEmpty)
              _buildInfoLine(
                context,
                '${l10n.logsTaskDetailStatusLabel}: ${item.status}',
              ),
            if ((item.createdAt ?? '').isNotEmpty)
              _buildInfoLine(
                context,
                '${l10n.logsTaskDetailCreatedAtLabel}: ${item.createdAt}',
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.commonCopy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLine(BuildContext context, String value) {
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
