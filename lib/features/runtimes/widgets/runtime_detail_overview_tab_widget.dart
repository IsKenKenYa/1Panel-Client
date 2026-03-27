import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';

class RuntimeDetailOverviewTabWidget extends StatelessWidget {
  const RuntimeDetailOverviewTabWidget({
    super.key,
    required this.runtime,
    required this.canStart,
    required this.canStop,
    required this.canRestart,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
  });

  final RuntimeInfo runtime;
  final bool canStart;
  final bool canStop;
  final bool canRestart;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(runtime.name ?? '-',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                    '${l10n.runtimeFieldType}: ${runtimeTypeLabel(l10n, runtime.type ?? '')}'),
                Text(
                    '${l10n.runtimeFieldStatus}: ${runtimeStatusLabel(l10n, runtime.status ?? '')}'),
                if ((runtime.version ?? '').isNotEmpty)
                  Text('${l10n.runtimeFieldVersion}: ${runtime.version}'),
                Text(
                    '${l10n.runtimeFieldResource}: ${runtimeResourceLabel(l10n, runtime.resource ?? '')}'),
                if ((runtime.createdAt ?? '').isNotEmpty)
                  Text('${l10n.runtimeFieldCreatedAt}: ${runtime.createdAt}'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilledButton.tonal(
                      onPressed: canStart ? onStart : null,
                      child: Text(l10n.runtimeActionStart),
                    ),
                    FilledButton.tonal(
                      onPressed: canStop ? onStop : null,
                      child: Text(l10n.runtimeActionStop),
                    ),
                    FilledButton.tonal(
                      onPressed: canRestart ? onRestart : null,
                      child: Text(l10n.runtimeActionRestart),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
