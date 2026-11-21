import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';

class VmStorageUsage extends StatelessWidget {
  const VmStorageUsage({super.key, required this.storage, this.detailed = false});

  final VMStorageItem storage;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = storage.usagePercent;
    final color = percent >= 90
        ? scheme.error
        : (percent >= 80 ? scheme.tertiary : scheme.primary);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);
    final details = [
      if (detailed && storage.type.isNotEmpty) storage.type,
      if (detailed) '${l10n.vmStorageCapacityLabel} ${_formatBytes(storage.capacity)}',
      '${l10n.vmStorageAvailableLabel} ${_formatBytes(storage.available)}',
      '${l10n.vmNetworkVmCountLabel} ${storage.vmCount}',
      if (detailed && storage.autoStart) l10n.vmStorageAutoStartLabel,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                storage.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: titleStyle?.copyWith(
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        if (detailed) ...[
          const SizedBox(height: AppDesignTokens.spacingXs),
          Text(
            storage.path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppDesignTokens.spacingSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 8,
            color: color,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: AppDesignTokens.spacingSm),
        Text(
          details.join(' · '),
          maxLines: detailed ? 2 : null,
          overflow: detailed ? TextOverflow.ellipsis : null,
          style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    return '$bytes B';
  }
}
