import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

/// 空间充足时并列展示名称和值；空间不足时将值排在名称下面。
class LabelValueRow extends StatelessWidget {
  const LabelValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 128,
    this.labelStyle,
    this.valueStyle,
    this.padding = const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final double labelWidth;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelWidget = Text(
      label,
      style: labelStyle ?? theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final valueWidget = Text(value, style: valueStyle);
    final fontSize = valueStyle?.fontSize ?? theme.textTheme.bodyMedium?.fontSize ?? 14;
    final minValueWidth = 8 * MediaQuery.textScalerOf(context).scale(fontSize);
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!constraints.hasBoundedWidth ||
              constraints.maxWidth < labelWidth + minValueWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: AppDesignTokens.spacingXs),
                valueWidget,
              ],
            );
          }
          return Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              SizedBox(width: math.min(labelWidth, constraints.maxWidth * 0.45), child: labelWidget),
              Expanded(child: valueWidget),
            ],
          );
        },
      ),
    );
  }
}
