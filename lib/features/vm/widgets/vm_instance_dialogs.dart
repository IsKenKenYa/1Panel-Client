import 'package:flutter/material.dart';
import 'package:onepanel_client/shared/widgets/label_value_row.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/features/vm/vm_status.dart';
import 'package:onepanel_client/features/vm/widgets/vm_instance_card.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

/// 虚拟机详情弹层：基本信息、磁盘表与网卡表。
Future<void> showVmDetailDialog(
  BuildContext context,
  VMItem vm,
  VmProvider provider,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: _VmDetailBody(vm: vm),
      ),
    ),
  );
}

class _VmDetailBody extends StatelessWidget {
  const _VmDetailBody({required this.vm});

  final VMItem vm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  vm.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              VmStatusChip(status: vm.status),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DetailRow(label: l10n.vmInstanceUuidLabel, value: vm.uuid),
          _DetailRow(
            label: l10n.vmInstanceCpuColumn,
            value: '${vm.cpu} ${l10n.vmOverviewCoresUnit}',
          ),
          _DetailRow(
            label: l10n.vmInstanceMemoryColumn,
            value: '${vm.memory} MiB',
          ),
          _DetailRow(label: l10n.vmInstanceDiskBusColumn, value: vm.diskBus),
          _DetailRow(label: l10n.vmInstanceNetworkColumn, value: vm.network),
          _DetailRow(
            label: l10n.vmInstanceBootOrderLabel,
            value: vm.bootOrder,
          ),
          _DetailRow(
            label: l10n.vmInstanceIsoPathsLabel,
            value: vm.isoPaths.join(', '),
          ),
          _DetailRow(
            label: l10n.vmInstanceGraphicsLabel,
            value: vm.graphics == null
                ? ''
                : '${vm.graphics!.type} ${vm.graphics!.listen}:${vm.graphics!.port}',
          ),
          _DetailRow(
            label: l10n.commonDescription,
            value: vm.description,
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.vmInstanceDisksSectionTitle,
            child: vm.disks.isEmpty
                ? const Text('--')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: <DataColumn>[
                        DataColumn(label: Text(l10n.vmInstanceDiskDeviceColumn)),
                        DataColumn(label: Text(l10n.vmInstanceDiskTargetColumn)),
                        DataColumn(label: Text(l10n.vmInstanceDiskBusColumn)),
                        DataColumn(label: Text(l10n.vmInstanceDiskSourceColumn)),
                      ],
                      rows: <DataRow>[
                        for (final disk in vm.disks)
                          DataRow(cells: <DataCell>[
                            DataCell(Text(disk.device)),
                            DataCell(Text(disk.target)),
                            DataCell(Text(disk.bus)),
                            DataCell(Text(disk.source)),
                          ]),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.vmInstanceInterfacesSectionTitle,
            child: vm.interfaces.isEmpty
                ? const Text('--')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: <DataColumn>[
                        DataColumn(label: Text(l10n.vmInstanceNicTypeColumn)),
                        DataColumn(label: Text(l10n.vmInstanceNicNetworkColumn)),
                        DataColumn(label: Text(l10n.vmInstanceNicModelColumn)),
                        DataColumn(label: Text(l10n.vmInstanceNicMacColumn)),
                        DataColumn(label: Text(l10n.vmInstanceNicIpColumn)),
                      ],
                      rows: <DataRow>[
                        for (final nic in vm.interfaces)
                          DataRow(cells: <DataCell>[
                            DataCell(Text(nic.type)),
                            DataCell(Text(nic.source)),
                            DataCell(Text(nic.model)),
                            DataCell(Text(nic.mac)),
                            DataCell(Text(nic.ip)),
                          ]),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LabelValueRow(
      label: label,
      value: value.isEmpty ? '--' : value,
      labelWidth: 120,
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      padding: const EdgeInsets.symmetric(vertical: 3),
    );
  }
}

/// VNC 控制台：展示连接信息与面板网页端地址。
Future<void> showVmConsole(
  BuildContext context,
  VMItem vm,
  VmProvider provider,
) async {
  final l10n = context.l10n;
  if (!VmStatus.canOpenConsole(vm)) {
    SnackBarUtils.showWarning(context, l10n.vmInstanceConsoleUnavailable);
    return;
  }
  try {
    final graphics = await provider.loadConsole(vm.name);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _VmConsoleDialog(
        vmName: vm.name,
        graphics: graphics,
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    SnackBarUtils.showError(context, error.toString());
  }
}

class _VmConsoleDialog extends StatelessWidget {
  const _VmConsoleDialog({
    required this.vmName,
    required this.graphics,
  });

  final String vmName;
  final VMGraphics graphics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final address = _resolveConsoleAddress(context, graphics);
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.vmInstanceActionConsole),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _DetailRow(label: vmName, value: vmName),
          _DetailRow(
            label: l10n.vmInstanceGraphicsLabel,
            value: graphics.type,
          ),
          _DetailRow(label: l10n.commonAddress, value: graphics.listen),
          _DetailRow(label: l10n.commonPort, value: graphics.port),
          if (address != null) ...[
            const SizedBox(height: 12),
            Text(l10n.vmInstanceConsoleAddressLabel),
            const SizedBox(height: 4),
            SelectableText(address, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.vmInstanceConsoleOpenHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        if (address != null)
          FilledButton.icon(
            onPressed: () => _openInBrowser(context, address),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l10n.vmInstanceConsoleOpenAction),
          ),
      ],
    );
  }

  /// 服务端给出 url 时直接使用；否则以图形监听地址组装 VNC 地址。
  String? _resolveConsoleAddress(BuildContext context, VMGraphics graphics) {
    final explicit = graphics.url;
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    if (graphics.listen.isEmpty || graphics.port.isEmpty) return null;
    final scheme = graphics.listen.startsWith('0.0.0.0') ? 'vnc' : 'vnc';
    return '$scheme://${graphics.listen.replaceAll('0.0.0.0', '127.0.0.1')}:${graphics.port}';
  }

  Future<void> _openInBrowser(BuildContext context, String address) async {
    final uri = Uri.tryParse(address);
    if (uri == null) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: address));
      if (!context.mounted) return;
      SnackBarUtils.showWarning(
        context,
        context.l10n.vmInstanceConsoleOpenHint,
      );
    }
  }
}

/// 健康检查弹层：汇总计数与逐项结果。
Future<void> showVmHealthCheckDialog(
  BuildContext context,
  VMItem vm,
  VmProvider provider,
) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (panelContext) => _VmHealthCheckPanel(vm: vm, provider: provider),
  );
}

class _VmHealthCheckPanel extends StatefulWidget {
  const _VmHealthCheckPanel({required this.vm, required this.provider});

  final VMItem vm;
  final VmProvider provider;

  @override
  State<_VmHealthCheckPanel> createState() => _VmHealthCheckPanelState();
}

class _VmHealthCheckPanelState extends State<_VmHealthCheckPanel> {
  VMHealthCheckResult? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.provider.healthCheck(widget.vm.name);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final result = _result;
    return AppFormPanel(
      title: l10n.vmHealthCheckTitle,
      isSaving: _loading,
      confirmLabel: l10n.commonClose,
      onConfirm: () async => Navigator.of(context).pop(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Text(_error!, style: TextStyle(color: scheme.error)),
          if (result != null) ...[
            Text(
              l10n.vmHealthCheckSummary(result.pass, result.warn, result.fail),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final item in result.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _HealthLevelChip(level: item.level),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.check,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    if (item.reason != null && item.reason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 2),
                        child: Text(
                          item.reason!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (item.fixCommand != null &&
                        item.fixCommand!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 4),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: SelectableText(
                                item.fixCommand!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              tooltip: l10n.commonCopy,
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: item.fixCommand!),
                                );
                                if (!context.mounted) return;
                                SnackBarUtils.showSuccess(
                                    context, l10n.commonCopySuccess);
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HealthLevelChip extends StatelessWidget {
  const _HealthLevelChip({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalized = level.toUpperCase();
    final color = switch (normalized) {
      'FAIL' => scheme.error,
      'WARN' => scheme.tertiary,
      'PASS' => scheme.primary,
      _ => scheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        normalized,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color),
      ),
    );
  }
}

/// 快照弹层：时间线、创建与恢复。
Future<void> showVmSnapshotDialog(
  BuildContext context,
  VMItem vm,
  VmProvider provider,
) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (panelContext) => VmSnapshotView(vm: vm, provider: provider),
  );
}

class VmSnapshotView extends StatefulWidget {
  const VmSnapshotView({
    super.key,
    required this.vm,
    required this.provider,
  });

  final VMItem vm;
  final VmProvider provider;

  @override
  State<VmSnapshotView> createState() => _VmSnapshotViewState();
}

class _VmSnapshotViewState extends State<VmSnapshotView> {
  List<VMSnapshotItem> _snapshots = const <VMSnapshotItem>[];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.provider.listSnapshots(widget.vm.name);
      if (!mounted) return;
      setState(() => _snapshots = items);    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return AppFormPanel(
      title: l10n.vmInstanceSnapshotTitle,
      isSaving: _saving,
      confirmLabel: l10n.commonClose,
      onConfirm: () async => Navigator.of(context).pop(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _loading || _saving
                    ? null
                    : () => _createSnapshot(context),
                icon: const Icon(Icons.add_outlined, size: 18),
                label: Text(l10n.vmInstanceSnapshotCreateAction),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _loading || _saving ? null : _load,
                icon: const Icon(Icons.refresh_outlined, size: 18),
                label: Text(l10n.commonRefresh),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: scheme.error)),
          if (!_loading && _snapshots.isEmpty && _error == null)
            Text(l10n.vmInstanceSnapshotEmptyMessage),
          for (final snapshot in _snapshots)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      snapshot.description.isEmpty
                          ? snapshot.name
                          : '${snapshot.name} · ${snapshot.description}',
                    ),
                  ),
                  if (snapshot.current)
                    Chip(label: Text(l10n.vmInstanceSnapshotCurrentLabel)),
                ],
              ),
              subtitle: Text(
                '${_formatTimestamp(snapshot.createdAt)} · '
                '${_formatBytes(snapshot.size)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.restore),
                    tooltip: l10n.vmInstanceSnapshotRecoverAction,
                    onPressed: _saving
                        ? null
                        : () => _recoverSnapshot(context, snapshot),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.vmInstanceSnapshotDeleteAction,
                    onPressed: _saving
                        ? null
                        : () => _deleteSnapshot(context, snapshot),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _createSnapshot(BuildContext context) async {
    final l10n = context.l10n;
    final nameController = TextEditingController(
      text: 'snapshot-${DateTime.now().millisecondsSinceEpoch}',
    );
    final descriptionController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vmInstanceSnapshotCreateAction),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration:
                  InputDecoration(labelText: l10n.vmInstanceSnapshotNameLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: l10n.commonDescription),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _saving = true);
    try {
      await widget.provider.createSnapshot(VMSnapshotReq(
        name: widget.vm.name,
        snapshotName: nameController.text.trim(),
        description: descriptionController.text.trim(),
      ));
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (context.mounted) {
        SnackBarUtils.showError(context, error.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _recoverSnapshot(
      BuildContext context, VMSnapshotItem snapshot) async {
    final l10n = context.l10n;
    if (!VmStatus.isShutOff(widget.vm)) {
      SnackBarUtils.showWarning(context, l10n.vmInstanceSnapshotNeedShutOff);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vmInstanceSnapshotRecoverAction),
        content: Text(l10n.vmInstanceSnapshotRecoverConfirm(snapshot.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.vmInstanceSnapshotRecoverAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _saving = true);
    try {
      await widget.provider.recoverSnapshot(VMSnapshotReq(
        name: widget.vm.name,
        snapshotName: snapshot.name,
      ));
      if (!mounted) return;
      await _load();
      if (!context.mounted) return;
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (context.mounted) {
        SnackBarUtils.showError(context, error.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteSnapshot(
      BuildContext context, VMSnapshotItem snapshot) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vmInstanceSnapshotDeleteAction),
        content: Text(snapshot.name),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.vmInstanceSnapshotDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _saving = true);
    try {
      await widget.provider.deleteSnapshot(VMSnapshotReq(
        name: widget.vm.name,
        snapshotName: snapshot.name,
      ));
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (context.mounted) {
        SnackBarUtils.showError(context, error.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _formatTimestamp(int value) {
    if (value <= 0) return '--';
    final asSeconds = value > 100000000000
        ? DateTime.fromMillisecondsSinceEpoch(value)
        : DateTime.fromMillisecondsSinceEpoch(value * 1000);
    return asSeconds.toLocal().toString().split('.').first;
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
