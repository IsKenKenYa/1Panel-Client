import 'package:flutter/material.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart' as api;
import 'package:onepanel_client/core/network/api_client_manager.dart';

class BackupAccountPage extends StatefulWidget {
  const BackupAccountPage({super.key});

  @override
  State<BackupAccountPage> createState() => _BackupAccountPageState();
}

class _BackupAccountPageState extends State<BackupAccountPage> {
  List<Map<String, dynamic>>? _accounts;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = await ApiClientManager.instance.getSettingApi();
      final response = await apiClient.getBackupAccountOptions();
      setState(() {
        _accounts = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteAccount(int id) async {
    try {
      final apiClient = await ApiClientManager.instance.getSettingApi();
      await apiClient.deleteBackupAccount(api.BackupAccountDelete(id: id));
      _loadAccounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: const Text('备份账户管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadAccounts,
            tooltip: l10n.systemSettingsRefresh,
          ),
        ],
      ),
      body: _buildBody(context, theme, l10n),
    );
  }

  Widget _buildBody(
      BuildContext context, ThemeData theme, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadAccounts,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (_accounts == null || _accounts!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无备份账户'),
            const SizedBox(height: 8),
            const Text('备份账户用于存储系统快照和备份文件',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _showAddAccountDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('添加备份账户'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppDesignTokens.pagePadding,
      itemCount: _accounts!.length,
      itemBuilder: (context, index) {
        final account = _accounts![index];
        return _buildAccountCard(context, theme, account);
      },
    );
  }

  Widget _buildAccountCard(
      BuildContext context, ThemeData theme, Map<String, dynamic> account) {
    final id = account['id'] as int?;
    final name = account['name'] as String? ?? 'Unknown';
    final type = account['type'] as String? ?? 'Unknown';
    final isPublic = account['isPublic'] as bool? ?? false;

    IconData typeIcon;
    Color typeColor;

    switch (type.toUpperCase()) {
      case 'LOCAL':
        typeIcon = Icons.folder_outlined;
        typeColor = Colors.blue;
        break;
      case 'S3':
      case 'OSS':
      case 'COS':
        typeIcon = Icons.cloud_outlined;
        typeColor = Colors.green;
        break;
      case 'SFTP':
        typeIcon = Icons.storage_outlined;
        typeColor = Colors.orange;
        break;
      case 'WEBDAV':
        typeIcon = Icons.cloud_sync_outlined;
        typeColor = Colors.purple;
        break;
      default:
        typeIcon = Icons.backup_outlined;
        typeColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppDesignTokens.spacingSm),
      child: ListTile(
        leading: Icon(typeIcon, color: typeColor),
        title: Row(
          children: [
            Text(name),
            if (isPublic) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('公共',
                    style: TextStyle(fontSize: 10, color: Colors.green)),
              ),
            ],
          ],
        ),
        subtitle: Text('类型: $type'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAccountAction(context, value, id),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'browse', child: Text('浏览文件')),
            const PopupMenuDivider(),
            const PopupMenuItem(
                value: 'delete',
                child: Text('删除', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _handleAccountAction(BuildContext context, String action, int? id) {
    if (id == null) return;

    switch (action) {
      case 'browse':
        _showBrowseFilesDialog(context, id);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, id);
        break;
    }
  }

  void _showAddAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加备份账户'),
        content: const Text('请前往1Panel Web控制台添加备份账户。\n\n路径: 面板设置 → 备份账户'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  void _showBrowseFilesDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('浏览文件'),
        content: const Text('此功能需要进一步开发'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份账户'),
        content: const Text('确定要删除此备份账户吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(id);
            },
            child: Text(context.l10n.commonDelete),
          ),
        ],
      ),
    );
  }
}
