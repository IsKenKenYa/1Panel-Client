import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';
import 'package:onepanel_client/features/runtimes/utils/runtime_l10n_helper.dart';

class RuntimeTypeSelectorWidget extends StatelessWidget {
  const RuntimeTypeSelectorWidget({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final String selectedType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: RuntimeService.orderedTypes
            .map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(runtimeTypeLabel(l10n, type)),
                  selected: selectedType == type,
                  onSelected: (_) => onChanged(type),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
