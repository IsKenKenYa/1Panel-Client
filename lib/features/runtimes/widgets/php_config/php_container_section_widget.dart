import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/features/runtimes/widgets/php_config/php_container_shared_widgets.dart';

class PhpContainerSectionWidget extends StatelessWidget {
  const PhpContainerSectionWidget({
    super.key,
    required this.config,
    required this.onContainerNameChanged,
    required this.onAddEnvironment,
    required this.onUpdateEnvironment,
    required this.onRemoveEnvironment,
    required this.onAddExposedPort,
    required this.onUpdateExposedPort,
    required this.onRemoveExposedPort,
    required this.onAddExtraHost,
    required this.onUpdateExtraHost,
    required this.onRemoveExtraHost,
    required this.onAddVolume,
    required this.onUpdateVolume,
    required this.onRemoveVolume,
    required this.onSave,
    required this.isSaving,
  });

  final PHPContainerConfig config;
  final ValueChanged<String> onContainerNameChanged;
  final VoidCallback onAddEnvironment;
  final void Function(int index, {String? key, String? value})
      onUpdateEnvironment;
  final ValueChanged<int> onRemoveEnvironment;
  final VoidCallback onAddExposedPort;
  final void Function(
    int index, {
    int? containerPort,
    String? hostIP,
    int? hostPort,
  }) onUpdateExposedPort;
  final ValueChanged<int> onRemoveExposedPort;
  final VoidCallback onAddExtraHost;
  final void Function(int index, {String? hostname, String? ip})
      onUpdateExtraHost;
  final ValueChanged<int> onRemoveExtraHost;
  final VoidCallback onAddVolume;
  final void Function(int index, {String? source, String? target})
      onUpdateVolume;
  final ValueChanged<int> onRemoveVolume;
  final Future<void> Function() onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final environments = config.safeEnvironments;
    final exposedPorts = config.safeExposedPorts;
    final extraHosts = config.safeExtraHosts;
    final volumes = config.safeVolumes;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        TextFormField(
          initialValue: config.containerName ?? '',
          onChanged: onContainerNameChanged,
          decoration: InputDecoration(labelText: l10n.appInstallContainerName),
        ),
        const SizedBox(height: 20),
        PhpContainerSectionHeaderWidget(
          title: l10n.containerInfoEnv,
          onAdd: onAddEnvironment,
        ),
        ...List<Widget>.generate(
          environments.length,
          (index) => PhpContainerInlineRowWidget(
            first: TextFormField(
              initialValue: environments[index].key ?? '',
              onChanged: (value) => onUpdateEnvironment(index, key: value),
              decoration: InputDecoration(labelText: l10n.appInstallEnvKey),
            ),
            second: TextFormField(
              initialValue: environments[index].value ?? '',
              onChanged: (value) => onUpdateEnvironment(index, value: value),
              decoration: InputDecoration(labelText: l10n.appInstallEnvValue),
            ),
            onRemove: () => onRemoveEnvironment(index),
          ),
        ),
        const SizedBox(height: 20),
        PhpContainerSectionHeaderWidget(
          title: l10n.containerInfoPorts,
          onAdd: onAddExposedPort,
        ),
        ...List<Widget>.generate(
          exposedPorts.length,
          (index) => PhpContainerInlineRowWidget(
            first: TextFormField(
              initialValue: exposedPorts[index].containerPort?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (value) => onUpdateExposedPort(
                index,
                containerPort: int.tryParse(value),
              ),
              decoration:
                  InputDecoration(labelText: l10n.runtimePhpContainerPort),
            ),
            second: TextFormField(
              initialValue: exposedPorts[index].hostPort?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged: (value) => onUpdateExposedPort(
                index,
                hostPort: int.tryParse(value),
              ),
              decoration: InputDecoration(labelText: l10n.runtimePhpHostPort),
            ),
            third: TextFormField(
              initialValue: exposedPorts[index].hostIP ?? '',
              onChanged: (value) => onUpdateExposedPort(index, hostIP: value),
              decoration: InputDecoration(labelText: l10n.runtimePhpHostIp),
            ),
            onRemove: () => onRemoveExposedPort(index),
          ),
        ),
        const SizedBox(height: 20),
        PhpContainerSectionHeaderWidget(
          title: l10n.runtimePhpContainerExtraHosts,
          onAdd: onAddExtraHost,
        ),
        ...List<Widget>.generate(
          extraHosts.length,
          (index) => PhpContainerInlineRowWidget(
            first: TextFormField(
              initialValue: extraHosts[index].hostname ?? '',
              onChanged: (value) => onUpdateExtraHost(index, hostname: value),
              decoration:
                  InputDecoration(labelText: l10n.dashboardHostNameLabel),
            ),
            second: TextFormField(
              initialValue: extraHosts[index].ip ?? '',
              onChanged: (value) => onUpdateExtraHost(index, ip: value),
              decoration: InputDecoration(labelText: l10n.runtimePhpHostIp),
            ),
            onRemove: () => onRemoveExtraHost(index),
          ),
        ),
        const SizedBox(height: 20),
        PhpContainerSectionHeaderWidget(
          title: l10n.volumes,
          onAdd: onAddVolume,
        ),
        ...List<Widget>.generate(
          volumes.length,
          (index) => PhpContainerInlineRowWidget(
            first: TextFormField(
              initialValue: volumes[index].source ?? '',
              onChanged: (value) => onUpdateVolume(index, source: value),
              decoration: InputDecoration(labelText: l10n.runtimeFieldSource),
            ),
            second: TextFormField(
              initialValue: volumes[index].target ?? '',
              onChanged: (value) => onUpdateVolume(index, target: value),
              decoration:
                  InputDecoration(labelText: l10n.runtimePhpVolumeTarget),
            ),
            onRemove: () => onRemoveVolume(index),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonSave),
        ),
      ],
    );
  }
}
