import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

class MountsPage extends StatefulWidget {
  const MountsPage({super.key});

  @override
  State<MountsPage> createState() => _MountsPageState();
}

class _MountsPageState extends State<MountsPage> {
  List<FileMountInfo>? _mounts;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMounts();
  }

  Future<void> _loadMounts() async {
    try {
      final provider = context.read<FilesProvider>();
      final mounts = await provider.getMountInfo();
      if (mounted) {
        setState(() {
          _mounts = mounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.filesMounts),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _loadMounts();
            },
          ),
        ],
      ),
      body: _buildBody(context, l10n, theme),
    );
  }

  Widget _buildBody(BuildContext context, dynamic l10n, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)));
    }

    if (_mounts == null || _mounts!.isEmpty) {
      return Center(child: Text(l10n.commonEmpty));
    }

    return ListView.builder(
      itemCount: _mounts!.length,
      itemBuilder: (context, index) {
        final mount = _mounts![index];
        final usagePercent = mount.total > 0 ? (mount.used / mount.total) : 0.0;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.storage),
            title: Text(mount.mountPoint),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${mount.device} (${mount.fsType})'),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: usagePercent),
                const SizedBox(height: 4),
                Text('${_formatSize(mount.used)} / ${_formatSize(mount.total)}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                context.read<FilesProvider>().navigateTo(mount.mountPoint);
                Navigator.pop(context);
              },
              tooltip: l10n.filesActionOpen,
            ),
          ),
        );
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
