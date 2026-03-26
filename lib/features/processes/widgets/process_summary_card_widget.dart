import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/process_models.dart';

class ProcessSummaryCardWidget extends StatelessWidget {
  const ProcessSummaryCardWidget({
    super.key,
    required this.item,
    required this.statusLabel,
    required this.onOpenDetail,
    required this.onStop,
  });

  final ProcessSummary item;
  final String statusLabel;
  final VoidCallback onOpenDetail;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ports = item.listeningPorts.isEmpty
        ? '-'
        : item.listeningPorts.join(', ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('PID ${item.pid} · ${item.username} · $statusLabel'),
            const SizedBox(height: 4),
            Text('CPU ${item.cpuPercent} · ${item.memoryText}'),
            Text('${l10n.processesConnectionsLabel}: ${item.numConnections}'),
            Text('${l10n.processesListeningPortsLabel}: $ports'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: onOpenDetail,
                  child: Text(l10n.operationsProcessDetailTitle),
                ),
                OutlinedButton(
                  onPressed: onStop,
                  child: Text(l10n.commonStop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
