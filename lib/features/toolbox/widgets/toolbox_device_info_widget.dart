import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/label_value_row.dart';

class ToolboxDeviceInfoRowWidget extends StatelessWidget {
  const ToolboxDeviceInfoRowWidget({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LabelValueRow(
      label: label,
      value: value,
      labelWidth: 120,
      labelStyle: theme.textTheme.bodyMedium,
      valueStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      padding: const EdgeInsets.only(bottom: 8),
    );
  }
}
