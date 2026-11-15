import 'package:flutter/material.dart';
import 'package:onepanel_client/features/containers/dialogs/containers_ops_guard.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/dialogs/compose_create_dialog.dart';
import 'package:onepanel_client/features/containers/dialogs/network_create_dialog.dart';
import 'package:onepanel_client/features/containers/dialogs/volume_create_dialog.dart';
import 'package:onepanel_client/features/containers/dialogs/repo_create_dialog.dart';
import 'package:onepanel_client/features/containers/dialogs/template_create_dialog.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';

/// 容器模块创建对话框入口（collector 模式：对话框收集输入，这里执行）。
/// 全部写操作经 [ContainersOpsGuard] 互斥，防重复提交。
class ContainersPageCreateDialogs {
  static Future<void> showCreateComposeDialog(BuildContext context) async {
    if (!ContainersOpsGuard.begin('compose-create')) return;
    try {
      final l10n = context.l10n;
      final result = await showAdaptiveFormPanel<ContainerComposeCreate>(
        context,
        builder: (context) => const ComposeCreateDialog(),
      );

      if (result != null && context.mounted) {
        final provider = context.read<ComposeProvider>();
        final success = await provider.createCompose(result);
        if (context.mounted) {
          if (success) {
            SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
          } else {
            SnackBarUtils.showError(context,
                l10n.containerOperateFailed(provider.error ?? l10n.commonUnknownError));
          }
        }
      }
    } finally {
      ContainersOpsGuard.end('compose-create');
    }
  }

  static Future<void> showCreateNetworkDialog(BuildContext context) async {
    if (!ContainersOpsGuard.begin('network-create')) return;
    try {
      final l10n = context.l10n;
      final result = await showAdaptiveFormPanel<Map<String, dynamic>>(
        context,
        builder: (context) => const NetworkCreateDialog(),
      );

      if (result != null && context.mounted) {
        final provider = context.read<NetworkProvider>();
        final request = NetworkCreate(
          name: result['name'],
          driver: result['driver'],
          subnet: result['subnet'],
          gateway: result['gateway'],
          enableIPv6: result['enableIPv6'] as bool? ?? false,
          labels: _parseKeyValuePairs(result['labels'] as String? ?? ''),
          ipv4: true,
        );
        final success = await provider.createNetwork(request);
        if (context.mounted) {
          if (success) {
            SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
          } else {
            SnackBarUtils.showError(context,
                l10n.containerOperateFailed(provider.error ?? l10n.commonUnknownError));
          }
        }
      }
    } finally {
      ContainersOpsGuard.end('network-create');
    }
  }

  static Future<void> showCreateVolumeDialog(BuildContext context) async {
    if (!ContainersOpsGuard.begin('volume-create')) return;
    try {
      final l10n = context.l10n;
      final result = await showAdaptiveFormPanel<Map<String, dynamic>>(
        context,
        builder: (context) => const VolumeCreateDialog(),
      );

      if (result != null && context.mounted) {
        final provider = context.read<VolumeProvider>();
        final request = VolumeCreate(
          name: result['name'],
          driver: result['driver'],
          labels: _parseKeyValuePairs(result['labels'] as String? ?? ''),
          driverOpts: _parseKeyValuePairs(result['options'] as String? ?? ''),
        );
        final success = await provider.createVolume(request);
        if (context.mounted) {
          if (success) {
            SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
          } else {
            SnackBarUtils.showError(context,
                l10n.containerOperateFailed(provider.error ?? l10n.commonUnknownError));
          }
        }
      }
    } finally {
      ContainersOpsGuard.end('volume-create');
    }
  }

  static Future<void> showCreateRepoDialog(BuildContext context) async {
    if (!ContainersOpsGuard.begin('repo-create')) return;
    try {
      final l10n = context.l10n;
      final result = await showAdaptiveFormPanel<bool>(
        context,
        builder: (context) => const RepoCreateDialog(),
      );
      if (result == true && context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
      }
    } finally {
      ContainersOpsGuard.end('repo-create');
    }
  }

  static Future<void> showCreateTemplateDialog(BuildContext context) async {
    if (!ContainersOpsGuard.begin('template-create')) return;
    try {
      final l10n = context.l10n;
      final result = await showAdaptiveFormPanel<bool>(
        context,
        builder: (context) => const TemplateCreateDialog(),
      );
      if (result == true && context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.containerOperateSuccess);
      }
    } finally {
      ContainersOpsGuard.end('template-create');
    }
  }

  static Map<String, String>? _parseKeyValuePairs(String input) {
    if (input.trim().isEmpty) return null;
    final map = <String, String>{};
    for (final line in input.split(RegExp(r'[\n,]'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.contains('=')) continue;
      final idx = trimmed.indexOf('=');
      map[trimmed.substring(0, idx).trim()] = trimmed.substring(idx + 1).trim();
    }
    return map.isEmpty ? null : map;
  }
}
