import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';

class HostAssetFormConnectionSectionWidget extends StatelessWidget {
  const HostAssetFormConnectionSectionWidget({
    super.key,
    required this.isTesting,
    required this.isVerified,
    required this.testMessage,
    required this.onTest,
  });

  final bool isTesting;
  final bool isVerified;
  final String? testMessage;
  final Future<void> Function() onTest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final Color borderColor;
    final String label;
    if (isVerified) {
      borderColor = colorScheme.primary;
      label = l10n.hostAssetsConnectionVerified;
    } else if (testMessage?.isNotEmpty == true) {
      borderColor = colorScheme.error;
      label = testMessage!;
    } else {
      borderColor = colorScheme.outlineVariant;
      label = l10n.hostAssetsConnectionNeedsTest;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isTesting ? null : () => onTest(),
            icon: isTesting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.power_outlined),
            label: Text(l10n.hostAssetsTestAction),
          ),
        ],
      ),
    );
  }
}
