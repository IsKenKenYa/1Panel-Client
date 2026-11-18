import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';

class ModuleErrorStateWidget extends StatelessWidget {
  const ModuleErrorStateWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        primary: false,
        padding: AppDesignTokens.pagePadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                ),
                child: SizedBox.square(
                  dimension: 56,
                  child: Icon(
                    Icons.error_outline,
                    size: 28,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingMd),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  l10n.commonLoadFailedTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingXs),
              Text(
                _displayMessage(l10n),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppDesignTokens.spacingMd),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_outlined),
                  label: Text(l10n.commonRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _displayMessage(AppLocalizations l10n) {
    final raw = message?.trim() ?? '';
    if (raw.isEmpty) {
      return l10n.commonError;
    }
    return ErrorMessageUtils.localizeMessage(raw, l10n);
  }
}
