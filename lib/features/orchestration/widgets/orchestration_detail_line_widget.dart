import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/label_value_row.dart';

class OrchestrationDetailLineWidget extends StatelessWidget {
  const OrchestrationDetailLineWidget({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 120,
  });

  final String label;
  final String? value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return LabelValueRow(
      label: label,
      value: (value == null || value!.isEmpty) ? '-' : value!,
      labelWidth: labelWidth,
      labelStyle: Theme.of(context).textTheme.bodyMedium,
      valueStyle: Theme.of(context).textTheme.bodySmall,
      padding: const EdgeInsets.symmetric(vertical: 3),
    );
  }
}
