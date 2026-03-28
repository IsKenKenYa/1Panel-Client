import 'package:flutter/material.dart';

import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';

class DatabasePageUnsupportedWidget extends StatelessWidget {
  const DatabasePageUnsupportedWidget({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppDesignTokens.pagePadding,
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class DatabasePageErrorWidget extends StatelessWidget {
  const DatabasePageErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: AppDesignTokens.spacingSm),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}

class DatabasePageEmptyWidget extends StatelessWidget {
  const DatabasePageEmptyWidget({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, textAlign: TextAlign.center));
  }
}
