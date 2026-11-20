import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class CommandPreviewBoxWidget extends StatelessWidget {
  const CommandPreviewBoxWidget({
    super.key,
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
      ),
      child: SelectableText(
        content.trim().isEmpty ? '-' : content,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.4,
            ),
      ),
    );
  }
}
