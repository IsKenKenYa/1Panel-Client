import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/vm/vm_models.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';

/// 创建/编辑虚拟机表单。
class VmInstanceForm extends StatefulWidget {
  const VmInstanceForm({super.key, this.editing});

  final VMItem? editing;

  static Future<void> show(BuildContext context, {VMItem? editing}) {
    return showAdaptiveFormPanel<void>(
      context,
      builder: (_) => VmInstanceForm(editing: editing),
    );
  }

  @override
  State<VmInstanceForm> createState() => _VmInstanceFormState();
}

class _VmInstanceFormState extends State<VmInstanceForm> {
  final _nameController = TextEditingController();
  final _cpuController = TextEditingController(text: '2');
  final _memoryController = TextEditingController(text: '2048');
  final _diskController = TextEditingController(text: '20');
  final _descriptionController = TextEditingController();

  String? _storagePool;
  String? _network;
  String? _isoPath;
  bool _autoStart = true;
  bool _startAfterCreate = true;
  String _diskBus = 'virtio';
  String _bootOrder = 'hd';
  bool _saving = false;

  List<VMStorageItem> _storages = const <VMStorageItem>[];
  List<VMNetworkItem> _networks = const <VMNetworkItem>[];
  List<VMIsoItem> _isos = const <VMIsoItem>[];

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final vm = widget.editing;
    if (vm != null) {
      _nameController.text = vm.name;
      _cpuController.text = '${vm.cpu}';
      _memoryController.text = '${vm.memory}';
      _diskController.text = '${vm.diskSize}';
      _descriptionController.text = vm.description;
      _storagePool = vm.storagePool.isEmpty ? null : vm.storagePool;
      _network = vm.network.isEmpty ? null : vm.network;
      _isoPath = vm.isoPaths.isEmpty ? null : vm.isoPaths.first;
      _autoStart = vm.autoStart;
      _diskBus = vm.diskBus.isEmpty ? 'virtio' : vm.diskBus;
      _bootOrder = vm.bootOrder.isEmpty ? 'hd' : vm.bootOrder;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  Future<void> _loadOptions() async {
    final provider = context.read<VmProvider>();
    final results = await Future.wait(<Future<Object>>[
      provider.listInterfaces(),
      provider.listBridges().then((value) => value, onError: (Object _) => const <Object>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _storages = provider.storages;
      _networks = provider.networks;
      _isos = provider.isos.where((iso) => iso.isExist).toList(growable: false);
      if (_storagePool == null && _storages.isNotEmpty) {
        _storagePool = _storages.first.name;
      }
      if (_network == null && _networks.isNotEmpty) {
        _network = _networks.first.name;
      }
    });
    // 网络接口/网桥结果用于创建表单的类型联动，当前仅需触发读取，
    // 结果落在 provider 的缓存中由网络分区使用。
    results.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpuController.dispose();
    _memoryController.dispose();
    _diskController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title:
          _isEditing ? l10n.vmInstanceEditTitle : l10n.vmInstanceCreateTitle,
      isSaving: _saving,
      confirmLabel: l10n.commonSave,
      onConfirm: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            enabled: !_isEditing,
            decoration: InputDecoration(labelText: l10n.vmInstanceNameLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cpuController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.vmInstanceCpuLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoryController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.vmInstanceMemoryLabel,
              suffixText: 'MiB',
            ),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _diskController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.vmInstanceDiskSizeLabel,
                suffixText: 'GB',
              ),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _storagePool,
            decoration:
                InputDecoration(labelText: l10n.vmInstanceStoragePoolLabel),
            items: <DropdownMenuItem<String>>[
              for (final storage in _storages)
                DropdownMenuItem(
                  value: storage.name,
                  child: Text('${storage.name} · ${storage.path}'),
                ),
            ],
            onChanged: (value) => setState(() => _storagePool = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _network,
            decoration: InputDecoration(labelText: l10n.vmInstanceNetworkLabel),
            items: <DropdownMenuItem<String>>[
              for (final network in _networks)
                DropdownMenuItem(
                  value: network.name,
                  child: Text(network.name),
                ),
            ],
            onChanged: (value) => setState(() => _network = value),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _isoPath,
            decoration: InputDecoration(labelText: l10n.vmInstanceIsoLabel),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem(
                value: null,
                child: Text(l10n.vmInstanceIsoNone),
              ),
              for (final iso in _isos)
                DropdownMenuItem(
                  value: iso.path,
                  child: Text(iso.name),
                ),
            ],
            onChanged: (value) => setState(() => _isoPath = value),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _diskBus,
              decoration:
                  InputDecoration(labelText: l10n.vmInstanceDiskBusLabel),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'virtio', child: Text('VirtIO')),
                DropdownMenuItem(value: 'sata', child: Text('SATA (AHCI)')),
              ],
              onChanged: (value) =>
                  setState(() => _diskBus = value ?? 'virtio'),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _bootOrder,
            decoration:
                InputDecoration(labelText: l10n.vmInstanceBootOrderLabelCreate),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem(
                value: 'hd',
                child: Text(l10n.vmInstanceBootDiskFirst),
              ),
              DropdownMenuItem(
                value: 'cdrom',
                child: Text(l10n.vmInstanceBootCdFirst),
              ),
            ],
            onChanged: (value) => setState(() => _bootOrder = value ?? 'hd'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _autoStart,
            title: Text(l10n.vmInstanceAutoStartLabel),
            onChanged: (value) => setState(() => _autoStart = value),
          ),
          if (!_isEditing)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _startAfterCreate,
              title: Text(l10n.vmInstanceStartAfterCreateLabel),
              onChanged: (value) =>
                  setState(() => _startAfterCreate = value),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration:
                InputDecoration(labelText: l10n.commonDescription),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final provider = context.read<VmProvider>();
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final cpu = int.tryParse(_cpuController.text.trim()) ?? 0;
      final memory = int.tryParse(_memoryController.text.trim()) ?? 0;
      final diskSize = int.tryParse(_diskController.text.trim()) ?? 0;
      if (name.isEmpty || cpu <= 0 || memory <= 0) {
        throw StateError(l10n.commonErrorBadRequest);
      }
      if (_isEditing) {
        await provider.updateVm(VMUpdate(
          name: widget.editing!.name,
          cpu: cpu,
          memory: memory,
          isoPaths: _isoPath == null
              ? const <String>[]
              : <String>[_isoPath!],
          network: _network ?? widget.editing!.network,
          bootOrder: _bootOrder,
          autoStart: _autoStart,
          description: _descriptionController.text.trim(),
        ));
      } else {
        if (diskSize <= 0) {
          throw StateError(l10n.commonErrorBadRequest);
        }
        if (_network == null) {
          throw StateError(l10n.commonErrorBadRequest);
        }
        await provider.createVm(VMCreate(
          name: name,
          cpu: cpu,
          memory: memory,
          diskSize: diskSize,
          diskBus: _diskBus,
          storagePool: _storagePool,
          isoPaths: _isoPath == null
              ? const <String>[]
              : <String>[_isoPath!],
          network: _network!,
          bootOrder: _bootOrder,
          startAfterCreate: _startAfterCreate,
          autoStart: _autoStart,
          description: _descriptionController.text.trim(),
        ));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }
}

/// 重命名弹层。
Future<void> showVmRenameDialog(
  BuildContext context,
  VMItem vm,
  VmProvider provider,
) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (panelContext) => _VmRenamePanel(vm: vm, provider: provider),
  );
}

class _VmRenamePanel extends StatefulWidget {
  const _VmRenamePanel({required this.vm, required this.provider});

  final VMItem vm;
  final VmProvider provider;

  @override
  State<_VmRenamePanel> createState() => _VmRenamePanelState();
}

class _VmRenamePanelState extends State<_VmRenamePanel> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.vm.name;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.vmInstanceRenameTitle,
      isSaving: _saving,
      confirmLabel: l10n.commonSave,
      onConfirm: _submit,
      content: TextField(
        controller: _controller,
        decoration:
            InputDecoration(labelText: l10n.vmInstanceRenameNewNameLabel),
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final newName = _controller.text.trim();
    if (newName.isEmpty || newName == widget.vm.name) {
      SnackBarUtils.showError(context, l10n.vmInstanceRenameSameName);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.provider.renameVm(widget.vm.name, newName);
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }
}

/// 删除弹层：要求输入名称完全一致。
Future<void> showVmDeleteDialog(
  BuildContext context,
  VMItem vm,
  VmProvider provider,
) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (panelContext) => _VmDeletePanel(vm: vm, provider: provider),
  );
}

class _VmDeletePanel extends StatefulWidget {
  const _VmDeletePanel({required this.vm, required this.provider});

  final VMItem vm;
  final VmProvider provider;

  @override
  State<_VmDeletePanel> createState() => _VmDeletePanelState();
}

class _VmDeletePanelState extends State<_VmDeletePanel> {
  final _controller = TextEditingController();
  bool _force = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.vmInstanceDeleteTitle,
      isSaving: _saving,
      confirmLabel: l10n.vmInstanceActionDelete,
      destructive: true,
      onConfirm: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n.vmInstanceDeleteConfirmHint(widget.vm.name)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(labelText: l10n.vmInstanceNameLabel),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _force,
            title: Text(l10n.vmInstanceDeleteForceLabel),
            onChanged: (value) => setState(() => _force = value),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_controller.text.trim() != widget.vm.name) {
      SnackBarUtils.showError(context, l10n.vmInstanceDeleteNameMismatch);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.provider.deleteVm(widget.vm.id, force: _force);
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonDeleted);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }
}

/// 磁盘扩容弹层。
Future<void> showVmResizeDialog(
  BuildContext context,
  VMItem vm,
  VmProvider provider,
) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (panelContext) => _VmResizePanel(vm: vm, provider: provider),
  );
}

class _VmResizePanel extends StatefulWidget {
  const _VmResizePanel({required this.vm, required this.provider});

  final VMItem vm;
  final VmProvider provider;

  @override
  State<_VmResizePanel> createState() => _VmResizePanelState();
}

class _VmResizePanelState extends State<_VmResizePanel> {
  final _controller = TextEditingController();
  String? _target;
  bool _saving = false;
  bool _loading = false;
  List<VMDisk> _disks = const <VMDisk>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDisks());
  }

  Future<void> _loadDisks() async {
    setState(() => _loading = true);
    try {
      final detail = await widget.provider.loadVmDetail(
        widget.vm.name,
        checkDisks: true,
      );
      if (!mounted) return;
      setState(() {
        _disks = detail.disks;
        _target = detail.disks.isEmpty ? null : detail.disks.first.target;
      });
    } catch (error) {
      if (!mounted) return;
      SnackBarUtils.showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  VMDisk? _resolveCurrentDisk() {
    final target = _target;
    if (target == null) return null;
    for (final disk in _disks) {
      if (disk.target == target) return disk;
    }
    throw StateError('在磁盘列表中找不到目标磁盘 $target');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentDisk = _resolveCurrentDisk();
    return AppFormPanel(
      title: l10n.vmInstanceDiskResizeTitle,
      isSaving: _saving,
      confirmLabel: l10n.commonSave,
      onConfirm: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          DropdownButtonFormField<String>(
            initialValue: _target,
            decoration: InputDecoration(labelText: l10n.vmInstanceDiskTargetColumn),
            items: <DropdownMenuItem<String>>[
              for (final disk in _disks)
                DropdownMenuItem(
                  value: disk.target,
                  child: Text(
                    '${disk.target} · ${_formatBytes(disk.capacity)}'
                    '${disk.resizeBlocked.isEmpty ? '' : ' · ${disk.resizeBlocked}'}',
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _target = value),
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.vmInstanceDiskCapacityLabel}: '
            '${currentDisk == null ? '-' : _formatBytes(currentDisk.capacity)}',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.vmInstanceDiskNewCapacityLabel,
              helperText: l10n.vmInstanceDiskResizeHint,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final target = _target;
    final size = int.tryParse(_controller.text.trim()) ?? 0;
    if (target == null || size <= 0) {
      SnackBarUtils.showError(context, l10n.commonErrorBadRequest);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.provider.resizeDisk(
        name: widget.vm.name,
        target: target,
        sizeGiB: size,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB';
    }
    return '$bytes B';
  }
}

/// 转为模板弹层。
Future<void> showVmConvertTemplateDialog(
  BuildContext context,
  VMItem vm,
  VmProvider provider,
) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (panelContext) => _VmTemplatePanel(vm: vm, provider: provider),
  );
}

class _VmTemplatePanel extends StatefulWidget {
  const _VmTemplatePanel({required this.vm, required this.provider});

  final VMItem vm;
  final VmProvider provider;

  @override
  State<_VmTemplatePanel> createState() => _VmTemplatePanelState();
}

class _VmTemplatePanelState extends State<_VmTemplatePanel> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _storagePool;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = '${widget.vm.name}-template';
    _storagePool =
        widget.provider.storages.isEmpty ? null : widget.provider.storages.first.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: l10n.vmInstanceTemplateDialogTitle,
      isSaving: _saving,
      confirmLabel: l10n.commonConfirm,
      onConfirm: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            decoration:
                InputDecoration(labelText: l10n.vmInstanceTemplateNameLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _storagePool,
            decoration:
                InputDecoration(labelText: l10n.vmInstanceStoragePoolLabel),
            items: <DropdownMenuItem<String>>[
              for (final storage in widget.provider.storages)
                DropdownMenuItem(value: storage.name, child: Text(storage.name)),
            ],
            onChanged: (value) => setState(() => _storagePool = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: InputDecoration(labelText: l10n.commonDescription),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final templateName = _nameController.text.trim();
    if (templateName.isEmpty) {
      SnackBarUtils.showError(context, l10n.commonErrorBadRequest);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.provider.createTemplate(VMTemplateCreate(
        name: widget.vm.name,
        templateName: templateName,
        storagePool: _storagePool,
        description: _descriptionController.text.trim(),
      ));
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }
}
