import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/logs/providers/system_logs_provider.dart';

class SystemLogSourceFilter extends StatelessWidget {
  const SystemLogSourceFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SystemLogSource value;
  final ValueChanged<SystemLogSource> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        children: [
          for (final source in SystemLogSource.values)
            ChoiceChip(
              label: Text(switch (source) {
                SystemLogSource.agent => context.l10n.logsSystemSourceAgent,
                SystemLogSource.core => context.l10n.logsSystemSourceCore,
              }),
              selected: value == source,
              onSelected: (_) => onChanged(source),
            ),
        ],
      );
}
