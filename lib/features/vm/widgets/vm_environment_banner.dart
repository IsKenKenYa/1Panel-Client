import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

/// 运行环境状态条。
///
/// 五项检查（架构、辅助程序、KVM、libvirt、存储目录）逐项展示；
/// 任一不满足时给「启用运行环境」入口，六个分区保持可见。
class VmEnvironmentBanner extends StatelessWidget {
  const VmEnvironmentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<VmProvider>();
    final environment = provider.environment;
    final scheme = Theme.of(context).colorScheme;

    if (provider.environmentState.isLoading &&
        environment.arch.isEmpty &&
        environment.helperMessage.isEmpty) {
      // 环境探测在未安装 KVM 的主机上可达 90 秒；加载态必须给出说明，
      // 否则用户只看到一条 2px 进度条，不知道页面在做什么。
      return _BannerSurface(
        icon: Icons.hourglass_top,
        iconColor: scheme.onSurfaceVariant,
        title: l10n.vmEnvironmentSectionTitle,
        message: l10n.commonLoading,
        content: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: LinearProgressIndicator(minHeight: 2),
        ),
      );
    }

    if (provider.environmentState.error != null) {
      return _BannerSurface(
        icon: Icons.error_outline,
        iconColor: scheme.error,
        title: l10n.vmEnvironmentNotReady,
        message: provider.environmentState.error!,
        action: TextButton(
          onPressed: provider.loadEnvironment,
          child: Text(l10n.commonRetry),
        ),
      );
    }

    if (environment.ready) {
      return const SizedBox.shrink();
    }

    return _BannerSurface(
      icon: Icons.warning_amber_outlined,
      iconColor: scheme.tertiary,
      title: l10n.vmEnvironmentNotReady,
      message: environment.arch.isEmpty && environment.helperMessage.isEmpty
          ? null
          : l10n.vmEnvironmentSectionTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _EnvironmentCheckRow(
            label: l10n.vmEnvironmentArchLabel,
            ok: environment.archSupported,
            detail: environment.arch,
          ),
          _EnvironmentCheckRow(
            label: l10n.vmEnvironmentHelperLabel,
            ok: environment.helperExist,
            detail: environment.helperMessage,
          ),
          _EnvironmentCheckRow(
            label: l10n.vmEnvironmentKvmLabel,
            ok: environment.kvmExist,
            detail: environment.kvmMessage,
          ),
          _EnvironmentCheckRow(
            label: l10n.vmEnvironmentLibvirtLabel,
            ok: environment.libvirtExist && environment.libvirtActive,
            detail: environment.libvirtExist && !environment.libvirtActive
                ? l10n.vmEnvironmentLibvirtInactive
                : environment.libvirtMessage,
          ),
          _EnvironmentCheckRow(
            label: l10n.vmEnvironmentStorageLabel,
            ok: environment.storageExist,
            detail: environment.storageMessage,
          ),
        ],
      ),
      action: TextButton(
        onPressed: provider.isMutating
            ? null
            : () => _confirmEnable(context, provider),
        child: Text(l10n.vmEnvironmentEnableAction),
      ),
    );
  }

  Future<void> _confirmEnable(
      BuildContext context, VmProvider provider) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmActionSheetWidget.show(
      context,
      title: l10n.vmEnvironmentEnableAction,
      message: l10n.vmEnvironmentEnableConfirm,
      confirmLabel: l10n.vmEnvironmentEnableAction,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      final success = await provider.enableEnvironment();
      if (!success || !context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (context.mounted) {
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }
}

class _EnvironmentCheckRow extends StatelessWidget {
  const _EnvironmentCheckRow({
    required this.label,
    required this.ok,
    required this.detail,
  });

  final String label;
  final bool ok;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.spacingXs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: ok ? scheme.primary : scheme.error,
          ),
          const SizedBox(width: AppDesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerSurface extends StatelessWidget {
  const _BannerSurface({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.content,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? content;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignTokens.spacingLg,
        AppDesignTokens.spacingSm,
        AppDesignTokens.spacingLg,
        0,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(AppDesignTokens.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: AppDesignTokens.spacingMd),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
              if (message != null) ...[
                const SizedBox(height: AppDesignTokens.spacingXs),
                Text(
                  message!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: AppDesignTokens.spacingMd),
                content!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
