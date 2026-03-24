import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/features/containers/dialogs/compose_create_dialog.dart';
import 'package:onepanel_client/features/containers/dialogs/network_create_dialog.dart';
import 'package:onepanel_client/features/containers/dialogs/volume_create_dialog.dart';
import 'package:onepanel_client/features/containers/dialogs/repo_create_dialog.dart';
import 'package:onepanel_client/features/containers/dialogs/template_create_dialog.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';

class ContainersPageCreateDialogs {
  static Future<void> showCreateComposeDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<ContainerComposeCreate>(
      context: context,
      builder: (context) => const ComposeCreateDialog(),
    );

    if (result != null && context.mounted) {
      final provider = context.read<ComposeProvider>();
      final success = await provider.createCompose(result);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.containerOperateSuccess)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.containerOperateFailed(
                  provider.error ?? l10n.commonUnknownError,
                ),
              ),
            ),
          );
        }
      }
    }
  }

  static Future<void> showCreateNetworkDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const NetworkCreateDialog(),
    );

    if (result != null && context.mounted) {
      final provider = context.read<NetworkProvider>();
      final request = NetworkCreate(
        name: result['name'],
        driver: result['driver'],
        subnet: result['subnet'],
        gateway: result['gateway'],
        ipv4: true,
      );
      final success = await provider.createNetwork(request);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.containerOperateSuccess)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.containerOperateFailed(
                  provider.error ?? l10n.commonUnknownError,
                ),
              ),
            ),
          );
        }
      }
    }
  }

  static Future<void> showCreateVolumeDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const VolumeCreateDialog(),
    );

    if (result != null && context.mounted) {
      final provider = context.read<VolumeProvider>();
      final request = VolumeCreate(
        name: result['name'],
        driver: result['driver'],
      );
      final success = await provider.createVolume(request);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.containerOperateSuccess)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.containerOperateFailed(
                  provider.error ?? l10n.commonUnknownError,
                ),
              ),
            ),
          );
        }
      }
    }
  }

  static Future<void> showCreateRepoDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const RepoCreateDialog(),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.containerOperateSuccess)),
      );
    }
  }

  static Future<void> showCreateTemplateDialog(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const TemplateCreateDialog(),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.containerOperateSuccess)),
      );
    }
  }
}
