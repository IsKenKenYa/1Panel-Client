import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class OpenRestyJsonView extends StatelessWidget {
  final String text;
  final String? emptyText;

  const OpenRestyJsonView({
    super.key,
    required this.text,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final content = text.trim().isEmpty ? (emptyText ?? '-') : text;
    return Padding(
      padding: AppDesignTokens.cardPadding,
      child: SingleChildScrollView(
        child: SelectableText(content),
      ),
    );
  }
}
