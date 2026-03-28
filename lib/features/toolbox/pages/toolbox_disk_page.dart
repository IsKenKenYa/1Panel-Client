import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/disk_management_models.dart';
import 'package:onepanel_client/features/shell/widgets/server_aware_page_scaffold.dart';
import 'package:onepanel_client/features/toolbox/providers/toolbox_disk_provider.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_sections_widget.dart';
import 'package:provider/provider.dart';

class ToolboxDiskPage extends StatefulWidget {
  const ToolboxDiskPage({super.key});

  @override
  State<ToolboxDiskPage> createState() => _ToolboxDiskPageState();
}

class _ToolboxDiskPageState extends State<ToolboxDiskPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ToolboxDiskProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ToolboxDiskProvider>();

    return ServerAwarePageScaffold(
      title: l10n.toolboxDiskTitle,
      onServerChanged: () => context.read<ToolboxDiskProvider>().load(),
      actions: <Widget>[
        IconButton(
          onPressed: provider.isLoading ? null : provider.load,
          icon: const Icon(Icons.refresh),
          tooltip: l10n.commonRefresh,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (provider.isLoading) const LinearProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                provider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ToolboxSectionCardWidget(
            title: l10n.toolboxDiskOverviewTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ToolboxInfoRowWidget(
                  label: l10n.toolboxDiskTotalDisksLabel,
                  value: provider.diskInfo.totalDisks.toString(),
                ),
                ToolboxInfoRowWidget(
                  label: l10n.toolboxDiskTotalCapacityLabel,
                  value: _formatBytes(provider.diskInfo.totalCapacity),
                ),
              ],
            ),
          ),
          if (provider.diskInfo.unpartitionedDisks.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _DiskSection(
              title: l10n.toolboxDiskUnpartitionedSectionTitle,
              items: provider.diskInfo.unpartitionedDisks
                  .map((DiskBasicInfo item) => DiskInfo(
                        device: item.device,
                        size: item.size,
                        model: item.model,
                        diskType: item.diskType,
                        isRemovable: item.isRemovable,
                        isSystem: item.isSystem,
                        filesystem: item.filesystem,
                        used: item.used,
                        avail: item.avail,
                        usePercent: item.usePercent,
                        mountPoint: item.mountPoint,
                        isMounted: item.isMounted,
                        serial: item.serial,
                      ))
                  .toList(growable: false),
              onPartition: _showPartitionDialog,
            ),
          ],
          if (provider.diskInfo.systemDisks.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _DiskSection(
              title: l10n.toolboxDiskSystemSectionTitle,
              items: provider.diskInfo.systemDisks,
              isSystemSection: true,
              onUnmount: _handleUnmount,
              onMount: _showMountDialog,
            ),
          ],
          if (provider.dataDisks.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _DiskSection(
              title: l10n.toolboxDiskDataSectionTitle,
              items: provider.dataDisks,
              onUnmount: _handleUnmount,
              onMount: _showMountDialog,
              onPartition: _showPartitionDialog,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showMountDialog(DiskBasicInfo disk) async {
    final l10n = context.l10n;
    final diskProvider = context.read<ToolboxDiskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final filesystemController = TextEditingController(
        text: disk.filesystem.isEmpty ? 'ext4' : disk.filesystem);
    final mountPointController = TextEditingController(text: disk.mountPoint);
    bool autoMount = true;
    bool noFail = true;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
          return AlertDialog(
            title: Text(l10n.toolboxDiskMountAction),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: filesystemController,
                  decoration: InputDecoration(
                    labelText: l10n.toolboxDiskFilesystemLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mountPointController,
                  decoration: InputDecoration(
                    labelText: l10n.toolboxDiskMountPointLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  value: autoMount,
                  onChanged: (bool value) => setState(() => autoMount = value),
                  title: Text(l10n.toolboxDiskAutoMountLabel),
                ),
                SwitchListTile(
                  value: noFail,
                  onChanged: (bool value) => setState(() => noFail = value),
                  title: Text(l10n.toolboxDiskNoFailLabel),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () async {
                  final success = await diskProvider.mountDisk(
                    DiskMountRequest(
                      device: disk.device,
                      filesystem: filesystemController.text.trim(),
                      mountPoint: mountPointController.text.trim(),
                      autoMount: autoMount,
                      noFail: noFail,
                    ),
                  );
                  if (!mounted || !dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? l10n.toolboxDiskMountSuccess
                            : (diskProvider.error ?? l10n.commonSaveFailed),
                      ),
                    ),
                  );
                },
                child: Text(l10n.commonConfirm),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showPartitionDialog(DiskInfo disk) async {
    final l10n = context.l10n;
    final diskProvider = context.read<ToolboxDiskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final filesystemController = TextEditingController(text: 'ext4');
    final mountPointController = TextEditingController();
    final labelController = TextEditingController();
    bool autoMount = true;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
          return AlertDialog(
            title: Text(l10n.toolboxDiskPartitionAction),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: filesystemController,
                  decoration: InputDecoration(
                    labelText: l10n.toolboxDiskFilesystemLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mountPointController,
                  decoration: InputDecoration(
                    labelText: l10n.toolboxDiskMountPointLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: l10n.toolboxDiskLabelLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                SwitchListTile(
                  value: autoMount,
                  onChanged: (bool value) => setState(() => autoMount = value),
                  title: Text(l10n.toolboxDiskAutoMountLabel),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () async {
                  final success = await diskProvider.partitionDisk(
                    DiskPartitionRequest(
                      device: disk.device,
                      filesystem: filesystemController.text.trim(),
                      mountPoint: mountPointController.text.trim(),
                      label: labelController.text.trim(),
                      autoMount: autoMount,
                    ),
                  );
                  if (!mounted || !dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? l10n.toolboxDiskPartitionSuccess
                            : (diskProvider.error ?? l10n.commonSaveFailed),
                      ),
                    ),
                  );
                },
                child: Text(l10n.commonConfirm),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleUnmount(DiskBasicInfo disk) async {
    final l10n = context.l10n;
    final diskProvider = context.read<ToolboxDiskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final success = await diskProvider.unmountDisk(
      DiskUnmountRequest(mountPoint: disk.mountPoint),
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.toolboxDiskUnmountSuccess
              : (diskProvider.error ?? l10n.commonSaveFailed),
        ),
      ),
    );
  }

  String _formatBytes(int value) {
    if (value <= 0) return '0 B';
    const units = <String>['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var size = value.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex += 1;
    }
    return '${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unitIndex]}';
  }
}

class _DiskSection extends StatelessWidget {
  const _DiskSection({
    required this.title,
    required this.items,
    this.isSystemSection = false,
    this.onMount,
    this.onUnmount,
    this.onPartition,
  });

  final String title;
  final List<DiskInfo> items;
  final bool isSystemSection;
  final Future<void> Function(DiskBasicInfo disk)? onMount;
  final Future<void> Function(DiskBasicInfo disk)? onUnmount;
  final Future<void> Function(DiskInfo disk)? onPartition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ToolboxSectionCardWidget(
      title: title,
      child: Column(
        children: items.map((DiskInfo disk) {
          final rows = disk.partitions.isNotEmpty
              ? disk.partitions
              : <DiskBasicInfo>[
                  DiskBasicInfo(
                    device: disk.device,
                    size: disk.size,
                    model: disk.model,
                    diskType: disk.diskType,
                    isRemovable: disk.isRemovable,
                    isSystem: disk.isSystem,
                    filesystem: disk.filesystem,
                    used: disk.used,
                    avail: disk.avail,
                    usePercent: disk.usePercent,
                    mountPoint: disk.mountPoint,
                    isMounted: disk.isMounted,
                    serial: disk.serial,
                  ),
                ];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    disk.device,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('${l10n.toolboxDiskSizeLabel}: ${disk.size}'),
                  if (disk.model.isNotEmpty)
                    Text('${l10n.toolboxDiskModelLabel}: ${disk.model}'),
                  const SizedBox(height: 8),
                  if (!isSystemSection &&
                      disk.partitions.isEmpty &&
                      !disk.isMounted &&
                      onPartition != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => onPartition!(disk),
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(l10n.toolboxDiskPartitionAction),
                      ),
                    ),
                  ...rows.map((DiskBasicInfo row) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(row.device),
                      subtitle: Text(
                        '${l10n.toolboxDiskMountPointLabel}: ${row.mountPoint.isEmpty ? l10n.toolboxDiskUnmounted : row.mountPoint}\n'
                        '${l10n.toolboxDiskFilesystemLabel}: ${row.filesystem.isEmpty ? '-' : row.filesystem}',
                      ),
                      trailing: isSystemSection
                          ? Text(l10n.toolboxDiskSystemDiskTag)
                          : row.isMounted
                              ? TextButton(
                                  onPressed: () => onUnmount?.call(row),
                                  child: Text(l10n.toolboxDiskUnmountAction),
                                )
                              : TextButton(
                                  onPressed: () => onMount?.call(row),
                                  child: Text(l10n.toolboxDiskMountAction),
                                ),
                    );
                  }),
                ],
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
