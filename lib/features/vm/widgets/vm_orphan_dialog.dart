import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/data/models/vm/vm_resource_models.dart';
import 'package:onepanel_client/features/vm/providers/vm_provider.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';

/// 打开孤儿文件清理弹层。
Future<void> showVmOrphanDialog(BuildContext context) {
  return showAdaptiveFormPanel<void>(
    context,
    builder: (_) => const VmOrphanDialog(),
  );
}

class VmOrphanDialog extends StatefulWidget {
  const VmOrphanDialog({super.key});

  @override
  State<VmOrphanDialog> createState() => _VmOrphanDialogState();
}

class _VmOrphanDialogState extends State<VmOrphanDialog> {
  List<VMOrphanItem> _items = const <VMOrphanItem>[];
  final Set<String> _selected = <String>{};
  bool _scanning = false;
  bool _cleaning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      final items = await context.read<VmProvider>().scanOrphans();
      if (!mounted) return;
      setState(() {
        _items = items;
        _selected
          ..clear()
          ..addAll(items.map((item) => item.path));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _clean() async {
    final l10n = context.l10n;
    final selected = _items
        .where((item) => _selected.contains(item.path))
        .toList(growable: false);
    if (selected.isEmpty) return;
    setState(() {
      _cleaning = true;
      _error = null;
    });
    try {
      final remaining = await context.read<VmProvider>().cleanOrphans(selected);
      if (!mounted) return;
      setState(() {
        _items = remaining;
        _selected.clear();
      });
      SnackBarUtils.showSuccess(context, l10n.commonOperationSuccess);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _cleaning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalSize = _items
        .where((item) => _selected.contains(item.path))
        .fold<int>(0, (sum, item) => sum + item.size);

    return AppFormPanel(
      title: l10n.vmOrphanDialogTitle,
      isSaving: _cleaning,
      confirmLabel: l10n.vmOrphanCleanAction,
      destructive: true,
      onConfirm: _clean,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.vmOrphanWarning),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _scanning || _cleaning ? null : _scan,
                icon: const Icon(Icons.search, size: 18),
                label: Text(l10n.vmOrphanScanAction),
              ),
              const SizedBox(width: 12),
              if (_scanning) const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          if (_items.isEmpty)
            Text(_scanning ? l10n.commonLoading : l10n.vmOrphanEmptyMessage)
          else
            Column(
              children: <Widget>[
                for (final item in _items)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(item.path),
                    onChanged: _cleaning
                        ? null
                        : (value) => setState(() {
                              if (value == true) {
                                _selected.add(item.path);
                              } else {
                                _selected.remove(item.path);
                              }
                            }),
                    title: Text(item.path, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${item.type} · ${_formatBytes(item.size)}',
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  l10n.vmOrphanSelectedSummary(
                    _selected.length,
                    _formatBytes(totalSize),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GiB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MiB';
    }
    return '$bytes B';
  }
}
