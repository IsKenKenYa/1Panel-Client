import 'package:flutter/material.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_manage_args.dart';

class RuntimeDetailAdvancedTabWidget extends StatelessWidget {
  const RuntimeDetailAdvancedTabWidget({
    super.key,
    required this.runtime,
    required this.remarkController,
    required this.onSaveRemark,
    required this.canOpenAdvanced,
    required this.isSavingRemark,
  });

  final RuntimeInfo runtime;
  final TextEditingController remarkController;
  final Future<void> Function() onSaveRemark;
  final bool canOpenAdvanced;
  final bool isSavingRemark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: remarkController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.runtimeFieldRemark,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: isSavingRemark ? null : onSaveRemark,
                  child: isSavingRemark
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.commonSave),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.runtimeAdvancedSummary(
                    runtime.exposedPorts?.length ?? 0,
                    runtime.environments?.length ?? 0,
                    runtime.volumes?.length ?? 0,
                    runtime.extraHosts?.length ?? 0,
                  ),
                ),
                if (!canOpenAdvanced) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(l10n.runtimeAdvancedRequiresRunning),
                ],
                if (canOpenAdvanced && runtime.id != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _buildAdvancedButtons(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAdvancedButtons(BuildContext context) {
    final l10n = context.l10n;
    final args = RuntimeManageArgs(
      runtimeId: runtime.id ?? 0,
      runtimeName: runtime.name,
      runtimeKind: runtime.type,
      codeDir: runtime.codeDir,
      packageManager: runtime.params?['PACKAGE_MANAGER']?.toString(),
    );

    if (runtime.type == 'php') {
      return <Widget>[
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.phpExtensions,
            arguments: args,
          ),
          icon: const Icon(Icons.extension_outlined),
          label: Text(l10n.operationsPhpExtensionsTitle),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.phpConfig,
            arguments: args,
          ),
          icon: const Icon(Icons.tune_outlined),
          label: Text(l10n.operationsPhpConfigTitle),
        ),
      ];
    }

    if (runtime.type == 'node') {
      return <Widget>[
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.nodeModules,
            arguments: args,
          ),
          icon: const Icon(Icons.inventory_2_outlined),
          label: Text(l10n.operationsNodeModulesTitle),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.nodeScripts,
            arguments: args,
          ),
          icon: const Icon(Icons.play_circle_outline),
          label: Text(l10n.operationsNodeScriptsTitle),
        ),
      ];
    }

    return const <Widget>[];
  }
}
