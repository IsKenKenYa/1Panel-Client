import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';

class RuntimeDetailConfigTabWidget extends StatelessWidget {
  const RuntimeDetailConfigTabWidget({
    super.key,
    required this.runtime,
  });

  final RuntimeInfo runtime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final params = runtime.params ?? const <String, dynamic>{};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if ((runtime.image ?? '').isNotEmpty)
                  Text('${l10n.runtimeFieldImage}: ${runtime.image}'),
                if ((runtime.codeDir ?? '').isNotEmpty)
                  Text('${l10n.runtimeFieldCodeDir}: ${runtime.codeDir}'),
                if ((runtime.path ?? '').isNotEmpty)
                  Text('${l10n.runtimeFieldPath}: ${runtime.path}'),
                if ((runtime.source ?? '').isNotEmpty)
                  Text('${l10n.runtimeFieldSource}: ${runtime.source}'),
                if ((runtime.port ?? '').isNotEmpty)
                  Text('${l10n.runtimeFieldExternalPort}: ${runtime.port}'),
                if ((runtime.container ?? '').isNotEmpty)
                  Text(
                      '${l10n.runtimeFieldContainerName}: ${runtime.container}'),
                if ((runtime.containerStatus ?? '').isNotEmpty)
                  Text(
                      '${l10n.runtimeFieldContainerStatus}: ${runtime.containerStatus}'),
                if (params.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    l10n.runtimeFieldParams,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...params.entries.map(
                    (entry) => Text('${entry.key}: ${entry.value}'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
