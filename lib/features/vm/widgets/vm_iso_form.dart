import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/files/services/file_transfer_service.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';

/// ISO 创建/编辑弹层，支持服务器文件、本地上传与服务器下载三种来源。
Future<void> showVmIsoForm(BuildContext context, {VMIsoItem? editing}) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (_) => VmIsoForm(editing: editing),
  );
}

enum _IsoSource { serverFile, upload, download }

class VmIsoForm extends StatefulWidget {
  const VmIsoForm({super.key, this.editing});

  final VMIsoItem? editing;

  @override
  State<VmIsoForm> createState() => _VmIsoFormState();
}

class _VmIsoFormState extends State<VmIsoForm> {
  static const List<String> _osTypes = <String>[
    'Debian',
    'Ubuntu',
    'CentOS',
    'Rocky',
    'AlmaLinux',
    'Fedora',
    'openSUSE',
    'RHEL',
    'OracleLinux',
    'Arch',
    'Windows',
    'FreeBSD',
  ];

  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  final _urlController = TextEditingController();
  final _targetDirController = TextEditingController(text: '/opt/1panel/tmp');
  final _descriptionController = TextEditingController();

  String _osType = 'Ubuntu';
  _IsoSource _source = _IsoSource.serverFile;
  bool _saving = false;
  bool _importing = false;
  double _progress = 0;
  String? _pickedFile;
  CanceledUpload? _uploadToken;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final iso = widget.editing;
    if (iso != null) {
      _nameController.text = iso.name;
      _pathController.text = iso.path;
      _descriptionController.text = iso.description;
      if (_osTypes.contains(iso.type)) {
        _osType = iso.type;
      }
    } else {
      _nameController.text = 'iso-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    _urlController.dispose();
    _targetDirController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppFormPanel(
      title: _isEditing ? l10n.vmIsoEditAction : l10n.vmIsoCreateAction,
      isSaving: _saving,
      confirmLabel: _isEditing ? l10n.commonSave : l10n.vmIsoImportStartAction,
      onConfirm: _submit,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.vmIsoNameLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _osType,
            decoration: InputDecoration(labelText: l10n.vmIsoTypeLabel),
            items: <DropdownMenuItem<String>>[
              for (final type in _osTypes)
                DropdownMenuItem(value: type, child: Text(type)),
            ],
            onChanged: _isEditing
                ? null
                : (value) => setState(() => _osType = value ?? _osType),
          ),
          if (!_isEditing) ...[
            const SizedBox(height: 16),
            Text(l10n.vmIsoSourceSectionTitle,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<_IsoSource>(
              segments: <ButtonSegment<_IsoSource>>[
                ButtonSegment(
                  value: _IsoSource.serverFile,
                  label: Text(l10n.vmIsoSourceServerFile),
                  icon: const Icon(Icons.folder_outlined, size: 18),
                ),
                ButtonSegment(
                  value: _IsoSource.upload,
                  label: Text(l10n.vmIsoSourceUpload),
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                ),
                ButtonSegment(
                  value: _IsoSource.download,
                  label: Text(l10n.vmIsoSourceDownload),
                  icon: const Icon(Icons.link_outlined, size: 18),
                ),
              ],
              selected: <_IsoSource>{_source},
              onSelectionChanged: _importing
                  ? null
                  : (values) => setState(() => _source = values.first),
            ),
            const SizedBox(height: 12),
            if (_source == _IsoSource.serverFile)
              TextField(
                controller: _pathController,
                decoration:
                    InputDecoration(labelText: l10n.vmIsoServerPathLabel),
              ),
            if (_source == _IsoSource.upload) ...[
              OutlinedButton.icon(
                onPressed: _importing ? null : _pickFile,
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(_pickedFile ?? l10n.vmIsoSourceUpload),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _targetDirController,
                decoration:
                    InputDecoration(labelText: l10n.vmIsoTargetDirLabel),
              ),
            ],
            if (_source == _IsoSource.download) ...[
              TextField(
                controller: _urlController,
                decoration:
                    InputDecoration(labelText: l10n.vmIsoDownloadUrlLabel),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _targetDirController,
                decoration:
                    InputDecoration(labelText: l10n.vmIsoTargetDirLabel),
              ),
            ],
            if (_importing) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${l10n.vmIsoImportProgressLabel}: '
                      '${(_progress * 100).toStringAsFixed(0)}%',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _cancelImport,
                    icon: const Icon(Icons.stop, size: 18),
                    label: Text(l10n.vmIsoImportCancelAction),
                  ),
                ],
              ),
            ],
          ],
          if (_isEditing) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _pathController,
              decoration: InputDecoration(labelText: l10n.vmIsoServerPathLabel),
            ),
          ],
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

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['iso', 'img'],
    );
    if (!mounted || picked == null) return;
    setState(() => _pickedFile = picked.files.single.path);
  }

  void _cancelImport() {
    _uploadToken?.cancel();
    setState(() {
      _importing = false;
      _progress = 0;
    });
  }

  Future<void> _submit() async {
    if (_isEditing) {
      await _submitEdit();
      return;
    }
    switch (_source) {
      case _IsoSource.serverFile:
        await _submitServerFile();
      case _IsoSource.upload:
        await _submitUpload();
      case _IsoSource.download:
        await _submitDownload();
    }
  }

  Future<void> _submitEdit() async {
    final l10n = context.l10n;
    final provider = context.read<VmProvider>();
    setState(() => _saving = true);
    try {
      await provider.updateIso(VMIsoUpdate(
        id: widget.editing!.id,
        type: _osType,
        name: _nameController.text.trim(),
        path: _pathController.text.trim(),
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

  Future<void> _submitServerFile() async {
    final l10n = context.l10n;
    final provider = context.read<VmProvider>();
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      SnackBarUtils.showError(context, l10n.commonErrorBadRequest);
      return;
    }
    setState(() => _saving = true);
    try {
      await provider.createIso(VMIsoCreate(
        type: _osType,
        name: _nameController.text.trim(),
        path: path,
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

  /// 本地上传：先登记导入记录，再走分片上传，最后回报 ready/failed。
  Future<void> _submitUpload() async {
    final l10n = context.l10n;
    final provider = context.read<VmProvider>();
    final localPath = _pickedFile;
    if (localPath == null) {
      SnackBarUtils.showError(context, l10n.commonErrorBadRequest);
      return;
    }
    final targetDir = _targetDirController.text.trim();
    final fileName = localPath.split(Platform.pathSeparator).last;
    final remotePath =
        targetDir.endsWith('/') ? '$targetDir$fileName' : '$targetDir/$fileName';
    final uploadId = 'iso-${DateTime.now().microsecondsSinceEpoch}-$fileName';

    setState(() {
      _importing = true;
      _progress = 0;
    });

    var importId = 0;
    try {
      importId = await provider.startIsoImport(VMIsoImportStart(
        type: _osType,
        name: _nameController.text.trim(),
        path: remotePath,
        description: _descriptionController.text.trim(),
        status: 'uploading',
        tempFileID: uploadId,
        tempFileType: 'upload',
      ));
      final token = CanceledUpload();
      _uploadToken = token;
      await FileTransferService(
        repository: null,
      ).uploadChunkedLocalFile(
        localPath: localPath,
        targetPath: targetDir,
        fileName: fileName,
        uploadID: uploadId,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
        cancelled: () => token.isCanceled,
      );
      await provider.updateIsoImport(
        VMIsoImportUpdate(id: importId, status: 'ready'),
      );
      if (!mounted) return;
      await provider.loadIsos();
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (importId > 0) {
        await provider
            .updateIsoImport(VMIsoImportUpdate(
              id: importId,
              status: 'failed',
              error: error.toString(),
            ))
            .catchError((Object _) {});
      }
      if (mounted) {
        setState(() {
          _importing = false;
          _saving = false;
        });
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }

  /// 服务器下载：由服务端拉取，客户端登记导入记录并刷新列表。
  Future<void> _submitDownload() async {
    final l10n = context.l10n;
    final provider = context.read<VmProvider>();
    final url = _urlController.text.trim();
    final targetDir = _targetDirController.text.trim();
    if (url.isEmpty) {
      SnackBarUtils.showError(context, l10n.commonErrorBadRequest);
      return;
    }
    final fileName = Uri.tryParse(url)?.pathSegments.lastOrNull ?? 'image.iso';
    final remotePath =
        targetDir.endsWith('/') ? '$targetDir$fileName' : '$targetDir/$fileName';

    setState(() {
      _importing = true;
      _progress = 0;
    });
    var importId = 0;
    try {
      importId = await provider.startIsoImport(VMIsoImportStart(
        type: _osType,
        name: _nameController.text.trim(),
        path: remotePath,
        description: _descriptionController.text.trim(),
        status: 'downloading',
      ));
      // 服务端下载进度经文件模块的 wget 进度接口读取。
      final transfer = FileTransferService();
      await transfer.wgetDownload(
        url: url,
        path: targetDir,
        name: fileName,
      );
      await _watchDownloadProgress(transfer, fileName);
      await provider.updateIsoImport(
        VMIsoImportUpdate(id: importId, status: 'ready'),
      );
      if (!mounted) return;
      await provider.loadIsos();
      if (!mounted) return;
      Navigator.of(context).pop();
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (importId > 0) {
        await provider
            .updateIsoImport(VMIsoImportUpdate(
              id: importId,
              status: 'failed',
              error: error.toString(),
            ))
            .catchError((Object _) {});
      }
      if (mounted) {
        setState(() => _importing = false);
        SnackBarUtils.showError(context, error.toString());
      }
    }
  }

  /// 轮询 wget 进度直到完成或失败；超时上限 30 分钟。
  Future<void> _watchDownloadProgress(
      FileTransferService transfer, String fileName) async {
    const interval = Duration(seconds: 2);
    final deadline = DateTime.now().add(const Duration(minutes: 30));
    while (mounted && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(interval);
      if (!mounted) return;
      final process = await transfer.getWgetProcess();
      final progress = _resolveWgetProgress(process, fileName);
      if (progress != null && mounted) {
        setState(() => _progress = progress);
        if (progress >= 1) return;
      }
    }
  }

  /// 从 wget 进度响应中读取指定文件的百分比；无法判定时返回 null。
  double? _resolveWgetProgress(
      Map<String, dynamic> process, String fileName) {
    final value = process[fileName];
    if (value is Map) {
      final raw = value['progress'] ?? value['percent'] ?? value['total'];
      if (raw is num) {
        return raw > 1 ? (raw / 100).clamp(0, 1).toDouble() : raw.toDouble();
      }
    }
    return null;
  }
}

/// 供本地上传取消使用的令牌。
class CanceledUpload {
  bool _canceled = false;

  bool get isCanceled => _canceled;

  void cancel() => _canceled = true;
}

extension on List<String> {
  String? get lastOrNull => isEmpty ? null : last;
}
