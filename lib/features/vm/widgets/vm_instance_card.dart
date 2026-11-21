import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/status_label_widget.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/features/vm/vm_status.dart';

/// 单台虚拟机的列表条目。
///
/// 标题行承载名称与电源状态，第二行是一行元数据（CPU、内存、磁盘、网络），
/// 描述另起一行。信息用排版层级区分，不使用灰底小标签堆叠。
class VmInstanceCard extends StatelessWidget {
  const VmInstanceCard({
    super.key,
    required this.vm,
    required this.onOpenActions,
  });

  final VMItem vm;
  final VoidCallback onOpenActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isRunning = VmStatus.isRunning(vm);

    final meta = <String>[
      '${vm.cpu} ${l10n.vmOverviewCoresUnit}',
      _formatMiB(vm.memory),
      _formatBytes(vm.diskSize),
      if (vm.network.isNotEmpty) vm.network,
      if (vm.storagePool.isNotEmpty) vm.storagePool,
    ];

    return InkWell(
      onTap: onOpenActions,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.spacingLg,
          vertical: AppDesignTokens.spacingMd + 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isRunning
                    ? scheme.secondaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSm),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.computer_outlined,
                size: 22,
                color: isRunning
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppDesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          vm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDesignTokens.spacingSm),
                      VmStatusChip(status: vm.status),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.spacingXs),
                  Text(
                    meta.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  if (vm.description.isNotEmpty) ...[
                    const SizedBox(height: AppDesignTokens.spacingXs),
                    Text(
                      vm.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDesignTokens.spacingXs),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  static String _formatMiB(int mib) {
    if (mib >= 1024) return '${(mib / 1024).toStringAsFixed(1)} GiB';
    return '$mib MiB';
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

/// 虚拟机状态标签：按状态给出语义色。
class VmStatusChip extends StatelessWidget {
  const VmStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = status.trim().toLowerCase();
    final Color foreground;
    switch (normalized) {
      case VmStatus.running:
        foreground = scheme.primary;
      case VmStatus.paused:
      case VmStatus.pmsuspended:
        foreground = scheme.tertiary;
      case VmStatus.creating:
        foreground = scheme.onSurfaceVariant;
      case VmStatus.shutOff:
        foreground = scheme.onSurfaceVariant;
      default:
        foreground = scheme.error;
    }
    return StatusLabelWidget(
      label: status,
      color: foreground,
      backgroundColor: foreground.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      radius: AppDesignTokens.radiusSm,
      textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
    );
  }
}
