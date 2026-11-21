import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/label_value_row.dart';

class ToolboxInfoRowWidget extends StatelessWidget {
  const ToolboxInfoRowWidget({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LabelValueRow(
      label: label,
      value: value,
      labelWidth: 120,
      labelStyle: Theme.of(context).textTheme.bodySmall,
      valueStyle: Theme.of(context).textTheme.bodyMedium,
      padding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
