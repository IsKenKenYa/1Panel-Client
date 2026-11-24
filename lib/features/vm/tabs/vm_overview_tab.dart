import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/vm_status.dart';
import 'package:onepanel_client/features/vm/widgets/vm_orphan_dialog.dart';
import 'package:onepanel_client/features/vm/widgets/vm_storage_usage.dart';
import 'package:onepanel_client/shared/widgets/expressive_section.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

/// 概览分区：统计、资源分配、风险提醒与存储池概况。
class VmOverviewTab extends StatelessWidget {
  const VmOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<VmProvider>();

    if (provider.vmState.error != null && provider.vms.isEmpty) {
      return ModuleErrorStateWidget(
        message: provider.vmState.error,
        onRetry: provider.loadVms,
      );
    }

    final running = provider.vms.where(VmStatus.isRunning).length;
    final shutOff = provider.vms.where(VmStatus.isShutOff).length;
    final creating = provider.vms.where(VmStatus.isCreating).length;
    final abnormal = provider.vms
        .where((vm) =>
            !VmStatus.isRunning(vm) &&
            !VmStatus.isShutOff(vm) &&
            !VmStatus.isCreating(vm))
        .length;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingMd,
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingXl + MediaQuery.paddingOf(context).bottom,
      ),
      children: <Widget>[
        _InstanceSummary(
          running: running,
          shutOff: shutOff,
          creating: creating,
          abnormal: abnormal,
        ),
        const SizedBox(height: AppDesignTokens.spacingXl),
        _AllocationSection(provider: provider),
        const SizedBox(height: AppDesignTokens.spacingXl),
        _RisksSection(
          environment: provider.environment,
          vms: provider.vms,
          storages: provider.storages,
        ),
        const SizedBox(height: AppDesignTokens.spacingXl),
        ExpressiveSection(
          title: l10n.vmOverviewStorageSectionTitle,
          isBusy: provider.storageState.isLoading,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              tooltip: l10n.commonRefresh,
              onPressed:
                  provider.storageState.isLoading ? null : provider.loadStorages,
            ),
          ],
          children: <Widget>[
            if (provider.storages.isEmpty)
              ExpressiveHint(
                message: l10n.vmStorageEmptyTitle,
                icon: Icons.storage_outlined,
              )
            else
              for (final storage in provider.storages)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.spacingLg,
                    vertical: AppDesignTokens.spacingMd + 2,
                  ),
                  child: VmStorageUsage(storage: storage),
                ),
          ],
        ),
        const SizedBox(height: AppDesignTokens.spacingXl),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => showVmOrphanDialog(context),
            icon: const Icon(Icons.cleaning_services_outlined),
            label: Text(l10n.vmOverviewOrphanAction),
          ),
        ),
      ],
    );
  }

  static String formatMiB(int mib) {
    if (mib >= 1024 * 1024) {
      return '${(mib / (1024 * 1024)).toStringAsFixed(1)} TiB';
    }
    if (mib >= 1024) {
      return '${(mib / 1024).toStringAsFixed(1)} GiB';
    }
    return '$mib MiB';
  }
}

/// 实例状态概览：以一个大数值加三项次级计数呈现，替代四等分色块。
class _InstanceSummary extends StatelessWidget {
  const _InstanceSummary({
    required this.running,
    required this.shutOff,
    required this.creating,
    required this.abnormal,
  });

  final int running;
  final int shutOff;
  final int creating;
  final int abnormal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = running + shutOff + creating + abnormal;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.vmTabInstances,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppDesignTokens.spacingXs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  '$total',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
                const SizedBox(width: AppDesignTokens.spacingSm),
                Text(
                  l10n.vmInstanceCountUnit,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.spacingMd),
            Wrap(
              spacing: AppDesignTokens.spacingLg,
              runSpacing: AppDesignTokens.spacingSm,
              children: <Widget>[
                _SummaryCount(
                  label: l10n.vmOverviewRunningLabel,
                  value: running,
                  color: scheme.primary,
                ),
                _SummaryCount(
                  label: l10n.vmOverviewStoppedLabel,
                  value: shutOff,
                ),
                _SummaryCount(
                  label: l10n.vmOverviewCreatingLabel,
                  value: creating,
                ),
                _SummaryCount(
                  label: l10n.vmOverviewAbnormalLabel,
                  value: abnormal,
                  color: abnormal > 0 ? scheme.error : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCount extends StatelessWidget {
  const _SummaryCount({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            color: color ?? scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures(),
            ],
          ),
        ),
        const SizedBox(width: AppDesignTokens.spacingXs),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// 资源分配：CPU 与内存合并在同一张卡片内，两条进度并列。
class _AllocationSection extends StatelessWidget {
  const _AllocationSection({required this.provider});

  final VmProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ExpressiveSection(
      title: l10n.vmOverviewCpuAllocation,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingMd,
            AppDesignTokens.spacingLg,
            AppDesignTokens.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AllocationLine(
                label: l10n.vmOverviewCpuAllocation,
                value:
                    '${provider.allocatedCpu} ${l10n.vmOverviewCoresUnit}',
                ratio: null,
                color: scheme.primary,
              ),
              const SizedBox(height: AppDesignTokens.spacingLg),
              _AllocationLine(
                label: l10n.vmOverviewMemoryAllocation,
                value: VmOverviewTab.formatMiB(provider.allocatedMemory),
                ratio: null,
                color: scheme.tertiary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllocationLine extends StatelessWidget {
  const _AllocationLine({
    required this.label,
    required this.value,
    required this.color,
    this.ratio,
  });

  final String label;
  final String value;
  final Color color;

  /// 有分母时绘制进度条；缺少宿主总量时只显示已分配绝对值。
  final double? ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 缺少宿主机总量时无法给出比例，只显示已分配绝对值；绘制一条
    // 不确定进度会给用户「正在加载」的错误暗示。
    final resolved = ratio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ],
        ),
        if (resolved != null) ...[
          const SizedBox(height: AppDesignTokens.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusXl),
            child: LinearProgressIndicator(
              value: resolved,
              minHeight: 8,
              color: color,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ],
    );
  }
}

/// 风险提醒：环境、存储池使用率、异常与暂停实例。
class _RisksSection extends StatelessWidget {
  const _RisksSection({
    required this.environment,
    required this.vms,
    required this.storages,
  });

  final VMEnvironment? environment;
  final List<VMItem> vms;
  final List<VMStorageItem> storages;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final risks = _collectRisks(l10n);

    return ExpressiveSection(
      title: l10n.vmOverviewRiskSectionTitle,
      children: <Widget>[
        if (risks.isEmpty)
          ExpressiveHint(
            message: l10n.vmOverviewNoRisk,
            icon: Icons.verified_outlined,
          )
        else
          for (final risk in risks)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignTokens.spacingLg,
                vertical: AppDesignTokens.spacingMd,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    risk.critical
                        ? Icons.error_outline
                        : Icons.warning_amber_outlined,
                    size: 20,
                    color: risk.critical ? scheme.error : scheme.tertiary,
                  ),
                  const SizedBox(width: AppDesignTokens.spacingMd),
                  Expanded(
                    child: Text(
                      risk.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  List<_VmRisk> _collectRisks(l10n) {
    final risks = <_VmRisk>[];
    // 环境尚未加载或加载后不就绪，都按「环境未就绪」提示。
    if (environment?.ready != true) {
      risks.add(_VmRisk(l10n.vmOverviewRiskEnvironment, critical: true));
    }
    for (final storage in storages) {
      final percent = storage.usagePercent;
      if (percent >= 90) {
        risks.add(_VmRisk(
          l10n.vmOverviewRiskStorageCritical(storage.name),
          critical: true,
        ));
      } else if (percent >= 80) {
        risks.add(_VmRisk(l10n.vmOverviewRiskStorageHigh(
          storage.name,
          '${percent.toStringAsFixed(1)}%',
        )));
      }
    }
    final abnormal = vms
        .where((vm) =>
            !VmStatus.isRunning(vm) &&
            !VmStatus.isShutOff(vm) &&
            !VmStatus.isCreating(vm) &&
            !VmStatus.isPaused(vm))
        .length;
    if (abnormal > 0) {
      risks.add(_VmRisk(
        l10n.vmOverviewRiskAbnormalVm(abnormal),
        critical: true,
      ));
    }
    final paused = vms.where(VmStatus.isPaused).length;
    if (paused > 0) {
      risks.add(_VmRisk(l10n.vmOverviewRiskPausedVm(paused)));
    }
    return risks;
  }
}

class _VmRisk {
  const _VmRisk(this.message, {this.critical = false});

  final String message;
  final bool critical;
}
