import 'package:flutter/material.dart';

/// 列表搜索框。调用方负责更新查询、提交搜索以及后缀按钮的行为。
class ModuleSearchField extends StatelessWidget {
  const ModuleSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.hintText,
    this.labelText,
    this.suffixIcon,
    this.border,
    this.filled,
    this.autofocus = false,
    this.contentPadding,
    this.fillColor,
  }) : assert(hintText != null || labelText != null);

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final String? hintText;
  final String? labelText;
  final Widget? suffixIcon;
  final InputBorder? border;
  final bool? filled;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: hintText,
          labelText: labelText,
          suffixIcon: suffixIcon,
          border: border,
          filled: filled,
          contentPadding: contentPadding,
          fillColor: fillColor,
        ),
      );
}
