import 'package:flutter/material.dart';

/// 带颜色的状态文字。调用方根据业务状态选择文案和颜色。
class StatusLabelWidget extends StatelessWidget {
  const StatusLabelWidget({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.radius = 12,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(radius),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Text(
          label,
          style: (textStyle ?? Theme.of(context).textTheme.labelSmall)
              ?.copyWith(color: color),
        ),
      );
}
