import 'package:flutter/material.dart';
import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/core/utils/debug_error_dialog.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/file_models.dart';
import 'package:onepanel_client/features/files/files_provider.dart';

void showPermissionDialog(
  BuildContext context,
  FilesProvider provider,
  FileInfo file,
  AppLocalizations l10n,
) {
  appLogger.dWithPackage('permission_dialog',
      'showPermissionDialog: 打开权限管理对话框, file=${file.path}');

  showDialog(
    context: context,
    builder: (dialogContext) => _PermissionDialog(
      file: file,
      provider: provider,
      l10n: l10n,
    ),
  );
}

class _PermissionDialog extends StatefulWidget {
  final FileInfo file;
  final FilesProvider provider;
  final AppLocalizations l10n;

  const _PermissionDialog({
    required this.file,
    required this.provider,
    required this.l10n,
  });

  @override
  State<_PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<_PermissionDialog> {
  FileUserGroupResponse? _userGroup;
  bool _isLoading = true;
  String? _error;

  int _ownerRead = 0;
  int _ownerWrite = 0;
  int _ownerExecute = 0;
  int _groupRead = 0;
  int _groupWrite = 0;
  int _groupExecute = 0;
  int _otherRead = 0;
  int _otherWrite = 0;
  int _otherExecute = 0;

  String? _selectedUser;
  String? _selectedGroup;
  bool _sub = false;

  @override
  void initState() {
    super.initState();
    _loadPermissionData();
  }

  Future<void> _loadPermissionData() async {
    try {
      final userGroup = await widget.provider.getUserGroup();

      final mode = widget.file.permission ?? widget.file.mode ?? '755';
      _parseMode(mode);

      setState(() {
        _userGroup = userGroup;
        _selectedUser = widget.file.user;
        _selectedGroup = widget.file.group;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      appLogger.eWithPackage('permission_dialog', '_loadPermissionData: 加载失败',
          error: e, stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _parseMode(String mode) {
    String cleanMode = mode;
    if (cleanMode.length > 3) {
      cleanMode = cleanMode.substring(cleanMode.length - 3);
    }

    int modeValue = int.tryParse(cleanMode, radix: 8) ?? 493;

    final ownerBits = (modeValue >> 6) & 7;
    final groupBits = (modeValue >> 3) & 7;
    final otherBits = modeValue & 7;

    _ownerRead = (ownerBits >> 2) & 1;
    _ownerWrite = (ownerBits >> 1) & 1;
    _ownerExecute = ownerBits & 1;

    _groupRead = (groupBits >> 2) & 1;
    _groupWrite = (groupBits >> 1) & 1;
    _groupExecute = groupBits & 1;

    _otherRead = (otherBits >> 2) & 1;
    _otherWrite = (otherBits >> 1) & 1;
    _otherExecute = otherBits & 1;
  }

  int _calculateMode() {
    final owner = (_ownerRead << 2) | (_ownerWrite << 1) | _ownerExecute;
    final group = (_groupRead << 2) | (_groupWrite << 1) | _groupExecute;
    final other = (_otherRead << 2) | (_otherWrite << 1) | _otherExecute;
    return (owner << 6) | (group << 3) | other;
  }

  String _calculateModeString() {
    final owner = (_ownerRead << 2) | (_ownerWrite << 1) | _ownerExecute;
    final group = (_groupRead << 2) | (_groupWrite << 1) | _groupExecute;
    final other = (_otherRead << 2) | (_otherWrite << 1) | _otherExecute;
    return '$owner$group$other';
  }

  Future<void> _savePermission() async {
    final mode = _calculateMode();
    appLogger.dWithPackage('permission_dialog',
        '_savePermission: mode=$mode, user=$_selectedUser, group=$_selectedGroup, sub=$_sub');

    try {
      if (_selectedUser != null && _selectedGroup != null) {
        await widget.provider.changeFileOwner(
          widget.file.path,
          _selectedUser!,
          _selectedGroup!,
          sub: _sub,
        );
      }

      await widget.provider.changeFileMode(
        widget.file.path,
        mode,
        sub: _sub,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.filesPermissionSuccess)),
        );
      }
    } catch (e, stackTrace) {
      appLogger.eWithPackage('permission_dialog', '_savePermission: 保存失败',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        DebugErrorDialog.show(context, widget.l10n.filesPermissionFailed, e,
            stackTrace: stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.l10n.filesPermissionTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: _buildContent(theme, colorScheme),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _savePermission,
          child: Text(widget.l10n.commonSave),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const SizedBox(
        width: 400,
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        width: 400,
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(widget.l10n.filesPermissionLoadFailed),
              const SizedBox(height: 8),
              Text(_error!,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFileInfo(theme, colorScheme),
            const SizedBox(height: 16),
            _buildModeSection(theme, colorScheme),
            const SizedBox(height: 16),
            _buildOwnerSection(theme, colorScheme),
            const SizedBox(height: 16),
            _buildRecursiveOption(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.name,
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              widget.file.path,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.l10n.filesPermissionMode,
                style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _calculateModeString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPermissionTable(theme, colorScheme),
      ],
    );
  }

  Widget _buildPermissionTable(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildPermissionHeader(theme),
            const Divider(),
            _buildPermissionRow(
              widget.l10n.filesPermissionOwnerLabel,
              _ownerRead,
              _ownerWrite,
              _ownerExecute,
              (r, w, x) => setState(() {
                _ownerRead = r;
                _ownerWrite = w;
                _ownerExecute = x;
              }),
              colorScheme,
            ),
            _buildPermissionRow(
              widget.l10n.filesPermissionGroupLabel,
              _groupRead,
              _groupWrite,
              _groupExecute,
              (r, w, x) => setState(() {
                _groupRead = r;
                _groupWrite = w;
                _groupExecute = x;
              }),
              colorScheme,
            ),
            _buildPermissionRow(
              widget.l10n.filesPermissionOtherLabel,
              _otherRead,
              _otherWrite,
              _otherExecute,
              (r, w, x) => setState(() {
                _otherRead = r;
                _otherWrite = w;
                _otherExecute = x;
              }),
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionHeader(ThemeData theme) {
    return Row(
      children: [
        const Expanded(child: SizedBox()),
        SizedBox(
          width: 60,
          child: Text(
            widget.l10n.filesPermissionRead,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            widget.l10n.filesPermissionWrite,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            widget.l10n.filesPermissionExecute,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRow(
    String label,
    int read,
    int write,
    int execute,
    void Function(int, int, int) onChanged,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        SizedBox(
          width: 60,
          child: Checkbox(
            value: read == 1,
            onChanged: (v) => onChanged(v == true ? 1 : 0, write, execute),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(
          width: 60,
          child: Checkbox(
            value: write == 1,
            onChanged: (v) => onChanged(read, v == true ? 1 : 0, execute),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(
          width: 60,
          child: Checkbox(
            value: execute == 1,
            onChanged: (v) => onChanged(read, write, v == true ? 1 : 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.l10n.filesPermissionChangeOwner,
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('user-$_selectedUser'),
                initialValue: _selectedUser,
                decoration: InputDecoration(
                  labelText: widget.l10n.filesPermissionUser,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _userGroup?.users
                        .map((u) => DropdownMenuItem(
                              value: u.user,
                              child: Text(u.user),
                            ))
                        .toList() ??
                    [],
                onChanged: (v) => setState(() => _selectedUser = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('group-$_selectedGroup'),
                initialValue: _selectedGroup,
                decoration: InputDecoration(
                  labelText: widget.l10n.filesPermissionGroup,
                  border: const OutlineInputBorder(),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _userGroup?.groups
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g),
                            ))
                        .toList() ??
                    [],
                onChanged: (v) => setState(() => _selectedGroup = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecursiveOption(ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: SwitchListTile(
        title: Text(widget.l10n.filesPermissionRecursive),
        subtitle: Text(
          widget.file.isDir
              ? widget.l10n.filesPermissionRecursive
              : widget.l10n.filesPermissionRecursive,
          style: theme.textTheme.bodySmall,
        ),
        value: _sub,
        onChanged: widget.file.isDir ? (v) => setState(() => _sub = v) : null,
      ),
    );
  }
}
