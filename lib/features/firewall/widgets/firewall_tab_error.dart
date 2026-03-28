import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class FirewallTabError extends StatelessWidget {
  const FirewallTabError({
    required this.error,
    required this.onRetry,
    required this.l10n,
    super.key,
  });

  final String error;
  final VoidCallback onRetry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDesignTokens.spacingLg),
            child: Text(error, textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppDesignTokens.spacingMd),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(l10n.commonRefresh),
          ),
        ],
      ),
    );
  }
}
